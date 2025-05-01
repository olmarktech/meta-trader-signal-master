import json
import os
import time
import logging
from datetime import datetime
from sqlalchemy.orm import scoped_session
from sqlalchemy.exc import OperationalError, SQLAlchemyError
from db_models import get_session, Settings, Preset, Signal, BotStatus, init_db

# Configure logging
logger = logging.getLogger(__name__)

# Maximum number of retry attempts for database operations
MAX_RETRIES = 3
# Delay between retries (in seconds)
RETRY_DELAY = 1.0

class DBManager:
    """Database manager for the MT5 Signal Bot"""
    
    def __init__(self):
        """Initialize the database manager"""
        self.Session = scoped_session(get_session)
        # Initialize database if needed
        self._initialize_with_retry(init_db)
        # Initialize bot status if not exists
        self._init_bot_status()
    
    def _execute_with_retry(self, func, *args, **kwargs):
        """Execute a database operation with retry logic for transient errors"""
        retry_count = 0
        last_error = None
        
        while retry_count < MAX_RETRIES:
            try:
                return func(*args, **kwargs)
            except (OperationalError, SQLAlchemyError) as e:
                last_error = e
                retry_count += 1
                logger.warning(f"Database operation failed (attempt {retry_count}/{MAX_RETRIES}): {str(e)}")
                
                if retry_count < MAX_RETRIES:
                    # Wait before retrying, with increasing delay
                    time.sleep(RETRY_DELAY * retry_count)
                    
                    # If it's a connection issue, get a fresh session
                    if isinstance(e, OperationalError) and "connection" in str(e).lower():
                        self.Session.remove()  # Clear the session registry
        
        # If we get here, all retries failed
        logger.error(f"Database operation failed after {MAX_RETRIES} attempts: {last_error}")
        raise last_error
    
    def _initialize_with_retry(self, init_func):
        """Initialize database components with retry logic"""
        def _init_wrapper():
            try:
                init_func()
                return True
            except Exception as e:
                logger.error(f"Initialization error: {e}")
                raise e
                
        return self._execute_with_retry(_init_wrapper)
    
    def _init_bot_status(self):
        """Initialize bot status if not exists"""
        def _init_status():
            session = self.Session()
            try:
                status = session.query(BotStatus).first()
                if not status:
                    status = BotStatus()
                    session.add(status)
                    session.commit()
                return True
            except Exception as e:
                session.rollback()
                raise e
            finally:
                session.close()
                
        return self._execute_with_retry(_init_status)
    
    # Settings methods
    def get_settings(self, key):
        """Get a setting value by key"""
        def _get_setting():
            session = self.Session()
            try:
                setting = session.query(Settings).filter_by(key=key).first()
                return setting.value if setting else None
            finally:
                session.close()
        
        return self._execute_with_retry(_get_setting)
    
    def save_settings(self, key, value):
        """Save a setting value"""
        def _save_setting():
            session = self.Session()
            try:
                setting = session.query(Settings).filter_by(key=key).first()
                if setting:
                    setting.value = value
                else:
                    setting = Settings(key=key, value=value)
                    session.add(setting)
                session.commit()
                return True
            except Exception as e:
                session.rollback()
                raise e
            finally:
                session.close()
        
        return self._execute_with_retry(_save_setting)
    
    def delete_settings(self, key):
        """Delete a setting by key"""
        def _delete_setting():
            session = self.Session()
            try:
                setting = session.query(Settings).filter_by(key=key).first()
                if setting:
                    session.delete(setting)
                    session.commit()
                    return True
                return False
            except Exception as e:
                session.rollback()
                raise e
            finally:
                session.close()
        
        return self._execute_with_retry(_delete_setting)
    
    # Preset methods
    def get_preset(self, name):
        """Get a preset by name"""
        def _get_preset():
            session = self.Session()
            try:
                preset = session.query(Preset).filter_by(name=name).first()
                if preset:
                    return preset.get_parameters_dict()
                return {}
            finally:
                session.close()
        
        return self._execute_with_retry(_get_preset)
    
    def get_all_presets(self):
        """Get all presets"""
        def _get_all_presets():
            session = self.Session()
            try:
                presets = {}
                for preset in session.query(Preset).all():
                    presets[preset.name] = preset.get_parameters_dict()
                return presets
            finally:
                session.close()
        
        return self._execute_with_retry(_get_all_presets)
    
    def save_preset(self, name, parameters, description=None):
        """Save a preset"""
        def _save_preset():
            session = self.Session()
            try:
                preset = session.query(Preset).filter_by(name=name).first()
                params_json = json.dumps(parameters)
                
                if preset:
                    preset.parameters = params_json
                    if description:
                        preset.description = description
                else:
                    preset = Preset(name=name, parameters=params_json, description=description)
                    session.add(preset)
                    
                session.commit()
                return True
            except Exception as e:
                session.rollback()
                raise e
            finally:
                session.close()
                
        return self._execute_with_retry(_save_preset)
    
    def delete_preset(self, name):
        """Delete a preset by name"""
        def _delete_preset():
            session = self.Session()
            try:
                preset = session.query(Preset).filter_by(name=name).first()
                if preset:
                    session.delete(preset)
                    session.commit()
                    return True
                return False
            except Exception as e:
                session.rollback()
                raise e
            finally:
                session.close()
                
        return self._execute_with_retry(_delete_preset)
    
    # Signal methods
    def save_signal(self, signal_data):
        """Save a signal"""
        def _save_signal():
            session = self.Session()
            try:
                # Extract sentiment data if present
                sentiment_data = None
                if 'sentiment' in signal_data:
                    sentiment_data = json.dumps(signal_data['sentiment'])
                
                signal = Signal(
                    symbol=signal_data['symbol'],
                    direction=signal_data['direction'],
                    strength=signal_data['strength'],
                    entry_price=signal_data['entry_price'],
                    stop_loss=signal_data.get('stop_loss'),
                    take_profit=signal_data.get('take_profit'),
                    reason=signal_data.get('reason'),
                    sentiment_data=sentiment_data
                )
                
                session.add(signal)
                
                # Update status
                status = session.query(BotStatus).first()
                if status:
                    status.total_signals_today += 1
                    status.last_update = datetime.now()
                
                session.commit()
                return signal.id
            except Exception as e:
                session.rollback()
                raise e
            finally:
                session.close()
        
        return self._execute_with_retry(_save_signal)
    
    def get_signals(self, limit=10):
        """Get the latest signals"""
        def _get_signals():
            session = self.Session()
            try:
                signals = session.query(Signal).order_by(Signal.created_at.desc()).limit(limit).all()
                return [signal.to_dict() for signal in signals]
            finally:
                session.close()
        
        return self._execute_with_retry(_get_signals)
    
    def update_signal_execution(self, signal_id, executed=True):
        """Update signal execution status"""
        def _update_signal_execution():
            session = self.Session()
            try:
                signal = session.query(Signal).filter_by(id=signal_id).first()
                if signal:
                    signal.executed = executed
                    signal.execution_time = datetime.now() if executed else None
                    
                    # Update status
                    if executed:
                        status = session.query(BotStatus).first()
                        if status:
                            status.total_trades_today += 1
                    
                    session.commit()
                    return True
                return False
            except Exception as e:
                session.rollback()
                raise e
            finally:
                session.close()
        
        return self._execute_with_retry(_update_signal_execution)
    
    # Status methods
    def get_status(self):
        """Get the current bot status"""
        def _get_status():
            session = self.Session()
            try:
                status = session.query(BotStatus).first()
                if status:
                    return status.to_dict()
                return {}
            finally:
                session.close()
        
        return self._execute_with_retry(_get_status)
    
    def update_status(self, status_data):
        """Update bot status"""
        def _update_status():
            session = self.Session()
            try:
                status = session.query(BotStatus).first()
                if not status:
                    status = BotStatus()
                    session.add(status)
                
                # Update status fields
                for key, value in status_data.items():
                    if hasattr(status, key):
                        setattr(status, key, value)
                
                status.last_update = datetime.now()
                session.commit()
                return True
            except Exception as e:
                session.rollback()
                raise e
            finally:
                session.close()
        
        return self._execute_with_retry(_update_status)
    
    def reset_daily_counts(self):
        """Reset daily trade and signal counts"""
        def _reset_counts():
            session = self.Session()
            try:
                status = session.query(BotStatus).first()
                if status:
                    status.total_trades_today = 0
                    status.total_signals_today = 0
                    session.commit()
                    return True
                return False
            except Exception as e:
                session.rollback()
                raise e
            finally:
                session.close()
        
        return self._execute_with_retry(_reset_counts)
    
    # Initial data loading
    def import_presets_from_files(self, presets_path):
        """Import presets from files"""
        if not os.path.exists(presets_path):
            return False
        
        # Get all .set files in the presets directory
        preset_files = [f for f in os.listdir(presets_path) if f.endswith('.set')]
        
        for preset_file in preset_files:
            preset_name = os.path.splitext(preset_file)[0]
            preset_data = {}
            
            try:
                with open(os.path.join(presets_path, preset_file), 'r') as file:
                    for line in file:
                        line = line.strip()
                        # Skip comments and empty lines
                        if line.startswith('#') or not line:
                            continue
                        if '=' in line:
                            key, value = line.split('=', 1)
                            preset_data[key.strip()] = value.strip()
                
                self.save_preset(preset_name, preset_data)
            except Exception as e:
                print(f"Error importing preset {preset_name}: {e}")
        
        return True

# Create a singleton instance
db_manager = DBManager()