from flask import Flask, render_template, request, jsonify, redirect, url_for, flash
from flask_socketio import SocketIO
import json
import os
from datetime import datetime
import logging
import threading
import time
from functools import wraps

# Import custom modules
import config
from mt5_connector import get_connector
from notifier import SignalNotifier
from db_manager import db_manager

app = Flask(__name__)
app.config['SECRET_KEY'] = config.SECRET_KEY
socketio = SocketIO(app, cors_allowed_origins="*")

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global flag to track if we're in simulation mode (no real MT5 connection)
SIMULATION_MODE = True

# Import presets from files on startup
db_manager.import_presets_from_files(config.PRESETS_PATH)

# MT5 Signal Bot data interface
# Uses database for persistence and connects to MT5 in non-simulation mode
class SignalBotData:
    def __init__(self):
        self._default_settings = {
            'strategy_preset': 'STRATEGY_TREND_FOLLOWING',
            'time_frame': 'H1',
            'trading_symbols': 'EURUSD,GBPUSD,USDJPY,AUDUSD',
            'max_daily_trades': 5,
            'risk_percent': 1.0,
            'stop_loss_pips': 50,
            'take_profit_pips': 100,
            'minimum_signal_strength': 5,
            'enable_news_filter': True,
            'enable_ai_analysis': True,
            'enable_sentiment_analysis': True
        }
        
        # Initialize settings in database if not exists
        self._init_settings()
        
        # Cache for settings and signals to avoid frequent database access
        self._settings_cache = self._load_settings_from_db()
        self._signals_cache = db_manager.get_signals(10)
        self._status_cache = db_manager.get_status()
        
        # Load presets
        self.presets = db_manager.get_all_presets()
        if not self.presets:
            # Initialize presets from files if not in database
            self._init_presets()
            self.presets = db_manager.get_all_presets()
    
    def _init_settings(self):
        """Initialize settings in database if they don't exist"""
        for key, value in self._default_settings.items():
            if db_manager.get_settings(key) is None:
                db_manager.save_settings(key, str(value))
    
    def _init_presets(self):
        """Initialize presets from files"""
        # Define preset names both in standard format and with STRATEGY_ prefix
        preset_mapping = {
            'TrendFollowing': 'STRATEGY_TREND_FOLLOWING',
            'SwingTrading': 'STRATEGY_SWING_TRADING',
            'Scalping': 'STRATEGY_SCALPING',
            'Reversal': 'STRATEGY_REVERSAL'
        }
        
        for file_name, strategy_name in preset_mapping.items():
            preset_data = self._parse_preset_file(file_name)
            if preset_data:
                # Save with both naming conventions for maximum compatibility
                db_manager.save_preset(file_name, preset_data)
                db_manager.save_preset(strategy_name, preset_data)
                
        # Also load any additional .set files in the presets directory
        if os.path.exists(config.PRESETS_PATH):
            for file_name in os.listdir(config.PRESETS_PATH):
                if file_name.endswith('.set'):
                    preset_name = os.path.splitext(file_name)[0]
                    # Skip already processed presets
                    if preset_name in preset_mapping:
                        continue
                    preset_data = self._parse_preset_file(preset_name)
                    if preset_data:
                        db_manager.save_preset(preset_name, preset_data)
    
    def _parse_preset_file(self, preset_name):
        """Parse a preset file into a dictionary"""
        try:
            preset_path = os.path.join(config.PRESETS_PATH, f'{preset_name}.set')
            preset_data = {}
            
            if os.path.exists(preset_path):
                with open(preset_path, 'r') as file:
                    for line in file:
                        line = line.strip()
                        # Skip comments and empty lines
                        if line.startswith('#') or not line:
                            continue
                        if '=' in line:
                            key, value = line.split('=', 1)
                            preset_data[key.strip()] = value.strip()
            return preset_data
        except Exception as e:
            logger.error(f"Error loading preset {preset_name}: {e}")
            return {}
    
    def _load_settings_from_db(self):
        """Load all settings from database"""
        settings = {}
        for key in self._default_settings.keys():
            value = db_manager.get_settings(key)
            if value is not None:
                # Clean up value - remove comments
                if isinstance(value, str) and '#' in value:
                    value = value.split('#')[0].strip()
                
                # Convert to appropriate type
                if key in ['max_daily_trades', 'stop_loss_pips', 'take_profit_pips', 'minimum_signal_strength']:
                    try:
                        value = int(value)
                    except ValueError:
                        logger.warning(f"Failed to convert {key}={value} to integer, using default")
                        value = self._default_settings[key]
                elif key in ['risk_percent']:
                    try:
                        value = float(value)
                    except ValueError:
                        logger.warning(f"Failed to convert {key}={value} to float, using default")
                        value = self._default_settings[key]
                elif key in ['enable_news_filter', 'enable_ai_analysis', 'enable_sentiment_analysis']:
                    if isinstance(value, str):
                        value = value.lower() in ['true', '1', 'yes', 'on']
                    else:
                        value = bool(value)
                
                settings[key] = value
            else:
                settings[key] = self._default_settings[key]
        
        logger.info(f"Loaded settings from database: {settings}")
        return settings
    
    def add_signal(self, signal):
        """Add a new trading signal"""
        # Set the current time if not provided
        if 'time' not in signal:
            signal['time'] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # Save to database
        signal_id = db_manager.save_signal(signal)
        
        # Update cache
        self._signals_cache = db_manager.get_signals(10)
        self._status_cache = db_manager.get_status()
        
        # Send notifications for this signal
        if not SIMULATION_MODE:
            SignalNotifier.notify(signal)
            
        return signal
    
    def update_settings(self, new_settings):
        """Update bot settings"""
        logger.info(f"Updating settings with: {new_settings}")
        
        # Process and validate settings before saving
        processed_settings = {}
        
        # Process boolean values
        boolean_keys = ['enable_news_filter', 'enable_ai_analysis', 'enable_sentiment_analysis']
        for key in boolean_keys:
            if key in new_settings:
                if isinstance(new_settings[key], str):
                    processed_settings[key] = new_settings[key].lower() in ['true', '1', 'yes', 'on', 'checked']
                else:
                    processed_settings[key] = bool(new_settings[key])
        
        # Process numeric values
        int_keys = ['max_daily_trades', 'stop_loss_pips', 'take_profit_pips', 'minimum_signal_strength']
        for key in int_keys:
            if key in new_settings:
                try:
                    if isinstance(new_settings[key], str):
                        # Remove comments and whitespace
                        cleaned_value = new_settings[key].split('#')[0].strip() if '#' in new_settings[key] else new_settings[key].strip()
                        processed_settings[key] = int(cleaned_value)
                    else:
                        processed_settings[key] = int(new_settings[key])
                except (ValueError, TypeError):
                    # If conversion fails, use the original value
                    processed_settings[key] = new_settings[key]
        
        # Process float values
        float_keys = ['risk_percent']
        for key in float_keys:
            if key in new_settings:
                try:
                    if isinstance(new_settings[key], str):
                        # Remove comments and whitespace
                        cleaned_value = new_settings[key].split('#')[0].strip() if '#' in new_settings[key] else new_settings[key].strip()
                        processed_settings[key] = float(cleaned_value)
                    else:
                        processed_settings[key] = float(new_settings[key])
                except (ValueError, TypeError):
                    # If conversion fails, use the original value
                    processed_settings[key] = new_settings[key]
        
        # Copy remaining keys that don't need special processing
        for key, value in new_settings.items():
            if key not in processed_settings:
                processed_settings[key] = value
        
        # Update database with processed settings
        for key, value in processed_settings.items():
            db_manager.save_settings(key, str(value))
        
        # Update cache
        self._settings_cache = self._load_settings_from_db()
        
        # Log the updated settings for debugging
        logger.info(f"Settings updated: {self._settings_cache}")
        
        # In a real environment, sync with MT5
        if not SIMULATION_MODE:
            mt5 = get_connector()
            if mt5.connected or mt5.connect():
                result = mt5.update_settings(self._settings_cache)
                if "error" in result:
                    logger.error(f"Failed to update MT5 settings: {result['error']}")
        
        return self._settings_cache
    
    def update_status(self, new_status):
        """Update bot status"""
        # Update database
        db_manager.update_status(new_status)
        
        # Update cache
        self._status_cache = db_manager.get_status()
        
        return self._status_cache
    
    def load_preset(self, preset_name):
        """Load a specific preset configuration"""
        if preset_name in self.presets:
            # Get preset data
            preset_data = self.presets[preset_name]
            
            # Map preset settings to our settings format
            mappings = {
                'TimeFrame': 'time_frame',
                'TradingSymbols': 'trading_symbols',
                'MaxDailyTrades': 'max_daily_trades',
                'RiskPercent': 'risk_percent',
                'StopLossPips': 'stop_loss_pips',
                'TakeProfitPips': 'take_profit_pips',
                'MinimumSignalStrength': 'minimum_signal_strength',
                'EnableNewsFilter': 'enable_news_filter',
                'EnableAIAnalysis': 'enable_ai_analysis',
                'EnableSentimentAnalysis': 'enable_sentiment_analysis'
            }
            
            # Timeframe mapping from MT5 numeric codes to human-readable values
            timeframe_mapping = {
                '1': 'M1',
                '2': 'M2',
                '3': 'M3',
                '4': 'M4',
                '5': 'M5',
                '6': 'M6',
                '10': 'M10',
                '12': 'M12',
                '15': 'M15',
                '20': 'M20',
                '30': 'M30',
                '16385': 'H1',
                '16386': 'H2',
                '16387': 'H3',
                '16388': 'H4',
                '16390': 'H6',
                '16392': 'H8',
                '16396': 'H12',
                '16408': 'D1',
                '32769': 'W1',
                '49153': 'MN1'
            }
            
            # Boolean value mapping
            boolean_keys = ['EnableNewsFilter', 'EnableAIAnalysis', 'EnableSentimentAnalysis']
            
            new_settings = {}
            for preset_key, our_key in mappings.items():
                if preset_key in preset_data:
                    value = preset_data[preset_key]
                    
                    # Clean up value - remove comments
                    if isinstance(value, str) and '#' in value:
                        value = value.split('#')[0].strip()
                    
                    # Convert timeframe from numeric code to readable value
                    if preset_key == 'TimeFrame' and value in timeframe_mapping:
                        value = timeframe_mapping[value]
                    
                    # Convert boolean values
                    if preset_key in boolean_keys:
                        value = value.lower() in ['true', '1', 'yes', 'on']
                    
                    # Convert numeric values
                    if preset_key in ['MaxDailyTrades', 'StopLossPips', 'TakeProfitPips', 'MinimumSignalStrength']:
                        try:
                            value = int(value)
                        except (ValueError, TypeError):
                            pass  # Keep as is if not convertible
                    
                    if preset_key == 'RiskPercent':
                        try:
                            value = float(value)
                        except (ValueError, TypeError):
                            pass  # Keep as is if not convertible
                    
                    new_settings[our_key] = value
            
            # Add strategy preset
            new_settings['strategy_preset'] = preset_name
            
            # Update settings
            self.update_settings(new_settings)
            
            # Log the applied settings for debugging
            logger.info(f"Applied preset {preset_name} with settings: {new_settings}")
            
            # In a real environment, sync with MT5
            if not SIMULATION_MODE:
                mt5 = get_connector()
                if mt5.connected or mt5.connect():
                    result = mt5.load_preset(preset_name)
                    if "error" in result:
                        logger.error(f"Failed to load preset in MT5: {result['error']}")
            
            return True
        return False
    
    def sync_with_mt5(self):
        """Synchronize data with MT5 (in non-simulation mode)"""
        if SIMULATION_MODE:
            return False
            
        mt5 = get_connector()
        if not mt5.connected and not mt5.connect():
            status_update = {'connected': False}
            self.update_status(status_update)
            return False
            
        # Get current status
        status_result = mt5.get_status()
        if "error" not in status_result:
            self.update_status(status_result)
            self.update_status({'connected': True})
            
        # Get current signals
        signals_result = mt5.get_signals()
        if "error" not in signals_result and "signals" in signals_result:
            # Save signals to database
            for signal in signals_result["signals"]:
                db_manager.save_signal(signal)
            
            # Update cache
            self._signals_cache = db_manager.get_signals(10)
            
        return True
    
    @property
    def signals(self):
        """Get signals from cache"""
        return self._signals_cache
    
    @property
    def settings(self):
        """Get settings from cache"""
        return self._settings_cache
    
    @property
    def status(self):
        """Get status from cache"""
        return self._status_cache
        
    def debug_presets(self):
        """Debug presets - get a list of preset names in the database"""
        return list(self.presets.keys())

# Initialize data storage
signal_bot = SignalBotData()

# Sample signals for demonstration (only in simulation mode)
if SIMULATION_MODE:
    sample_signals = [
        {
            'symbol': 'EURUSD',
            'direction': 'BUY',
            'strength': 7,
            'entry_price': 1.08762,
            'stop_loss': 1.08262,
            'take_profit': 1.09762,
            'reason': 'MA Cross + RSI Oversold + ADX Trend (28.5) + Neural Network Prediction (87% confidence)',
            'time': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            'sentiment': {
                'retail_bullish': 42.3,
                'retail_bearish': 57.7,
                'institutional_bullish': 63.8,
                'institutional_bearish': 36.2,
                'overall_condition': 'Bullish Bias, Retail Crowded Bearish',
                'confidence': 0.87
            }
        },
        {
            'symbol': 'GBPUSD',
            'direction': 'SELL',
            'strength': 6,
            'entry_price': 1.26543,
            'stop_loss': 1.27043,
            'take_profit': 1.25543,
            'reason': 'MA Cross + ADX Trend (26.2) + AI Pattern Recognition + RSI',
            'time': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            'sentiment': {
                'retail_bullish': 68.2,
                'retail_bearish': 31.8,
                'institutional_bullish': 42.5,
                'institutional_bearish': 57.5,
                'overall_condition': 'Bearish Bias, Retail Crowded Bullish',
                'confidence': 0.82
            }
        }
    ]

    # Add sample signals
    for signal in sample_signals:
        signal_bot.add_signal(signal)

# Authentication decorator for protected routes
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not config.ENABLE_AUTH:
            return f(*args, **kwargs)
            
        auth = request.authorization
        if auth and auth.username == config.USERNAME and auth.password == config.PASSWORD:
            return f(*args, **kwargs)
            
        return jsonify({"error": "Unauthorized"}), 401
    return decorated_function

# Routes
@app.route('/')
def index():
    # In real mode, sync with MT5 first
    if not SIMULATION_MODE:
        signal_bot.sync_with_mt5()
        
    return render_template('index.html', 
                          signals=signal_bot.signals, 
                          settings=signal_bot.settings,
                          status=signal_bot.status,
                          simulation=SIMULATION_MODE)

@app.route('/settings', methods=['GET', 'POST'])
def settings():
    if request.method == 'POST':
        new_settings = request.form.to_dict()
        # Convert checkbox values (on/off) to boolean
        for key in ['enable_news_filter', 'enable_ai_analysis', 'enable_sentiment_analysis']:
            if key in new_settings:
                new_settings[key] = new_settings[key] == 'on'
            else:
                new_settings[key] = False
        
        # Convert numeric values
        for key in ['max_daily_trades', 'risk_percent', 'stop_loss_pips', 
                   'take_profit_pips', 'minimum_signal_strength']:
            if key in new_settings:
                try:
                    if '.' in new_settings[key]:
                        new_settings[key] = float(new_settings[key])
                    else:
                        new_settings[key] = int(new_settings[key])
                except ValueError:
                    pass  # Keep as string if conversion fails
        
        signal_bot.update_settings(new_settings)
        return redirect(url_for('index'))
    
    return render_template('settings.html', 
                          settings=signal_bot.settings,
                          presets=list(signal_bot.presets.keys()),
                          simulation=SIMULATION_MODE)

@app.route('/load_preset/<preset_name>')
def load_preset(preset_name):
    # Handle both formats - with and without STRATEGY_ prefix
    # First try as provided
    success = signal_bot.load_preset(preset_name)
    
    if not success:
        # Try alternative formats
        if preset_name.startswith('STRATEGY_'):
            # Remove the STRATEGY_ prefix and try with just the name
            alt_name = preset_name[9:]  # Remove "STRATEGY_"
            success = signal_bot.load_preset(alt_name)
        else:
            # Add the STRATEGY_ prefix and try again
            alt_name = f"STRATEGY_{preset_name}"
            success = signal_bot.load_preset(alt_name)
    
    if success:
        return redirect(url_for('settings'))
    
    # If still not found, try with corrected casing
    possible_matches = []
    for preset in signal_bot.presets.keys():
        if preset.lower() == preset_name.lower() or preset.lower() == f"strategy_{preset_name.lower()}":
            possible_matches.append(preset)
    
    if possible_matches:
        success = signal_bot.load_preset(possible_matches[0])
        if success:
            return redirect(url_for('settings'))
    
    return "Preset not found", 404

@app.route('/api/signals', methods=['GET'])
@login_required
def get_signals():
    # In real mode, sync with MT5 first
    if not SIMULATION_MODE:
        signal_bot.sync_with_mt5()
    return jsonify(signal_bot.signals)

@app.route('/api/settings', methods=['GET', 'PUT'])
@login_required
def api_settings():
    if request.method == 'GET':
        return jsonify(signal_bot.settings)
    elif request.method == 'PUT':
        data = request.json
        updated_settings = signal_bot.update_settings(data)
        return jsonify(updated_settings)

@app.route('/api/status', methods=['GET', 'PUT'])
@login_required
def api_status():
    # In real mode, sync with MT5 first for GET requests
    if request.method == 'GET' and not SIMULATION_MODE:
        signal_bot.sync_with_mt5()
        
    if request.method == 'GET':
        return jsonify(signal_bot.status)
    elif request.method == 'PUT':
        data = request.json
        updated_status = signal_bot.update_status(data)
        return jsonify(updated_status)

@app.route('/api/add_signal', methods=['POST'])
@login_required
def api_add_signal():
    signal = request.json
    signal = signal_bot.add_signal(signal)
    
    # Emit a socket.io event to update connected clients
    socketio.emit('new_signal', signal)
    
    return jsonify({"status": "success", "message": "Signal added"})

@app.route('/api/connection', methods=['GET'])
@login_required
def api_connection():
    if SIMULATION_MODE:
        return jsonify({"status": "simulation", "message": "Running in simulation mode"})
        
    mt5 = get_connector()
    connected = mt5.test_connection()
    return jsonify({"status": "connected" if connected else "disconnected"})
    
@app.route('/api/debug/presets', methods=['GET'])
def debug_presets():
    """Debug endpoint to list all available presets"""
    presets = signal_bot.debug_presets()
    return jsonify({"presets": presets})

# Background MT5 Sync Thread (only in non-simulation mode)
def mt5_sync_thread():
    """Thread to periodically sync data with MT5"""
    if SIMULATION_MODE:
        return
        
    logger.info("Starting MT5 sync thread")
    while True:
        try:
            # Sync data with MT5
            success = signal_bot.sync_with_mt5()
            
            if success:
                # Broadcast updates to all connected clients
                socketio.emit('signals_update', signal_bot.signals)
                socketio.emit('status_update', signal_bot.status)
                
        except Exception as e:
            logger.error(f"Error in MT5 sync thread: {str(e)}")
            
        # Sleep for 5 seconds before next sync
        time.sleep(5)

# Socket.IO events
@socketio.on('connect')
def handle_connect():
    logger.info("Client connected")
    # Send current data to the newly connected client
    socketio.emit('signals_update', signal_bot.signals)
    socketio.emit('status_update', signal_bot.status)
    socketio.emit('simulation_mode', SIMULATION_MODE)

@socketio.on('request_signals')
def handle_request_signals():
    # In real mode, sync with MT5 first
    if not SIMULATION_MODE:
        signal_bot.sync_with_mt5()
    socketio.emit('signals_update', signal_bot.signals)

@socketio.on('request_status')
def handle_request_status():
    # In real mode, sync with MT5 first
    if not SIMULATION_MODE:
        signal_bot.sync_with_mt5()
    socketio.emit('status_update', signal_bot.status)

# Feature: Simulate signals in development mode
@app.route('/dev/simulate_signal', methods=['POST'])
def simulate_signal():
    """Generate a simulated signal (only in simulation mode)"""
    if not SIMULATION_MODE:
        return jsonify({"error": "Not available in production mode"}), 400
        
    # Generate a random signal for testing
    import random
    
    symbols = ['EURUSD', 'GBPUSD', 'USDJPY', 'AUDUSD', 'USDCAD', 'EURGBP', 'EURJPY']
    directions = ['BUY', 'SELL']
    
    symbol = random.choice(symbols)
    direction = random.choice(directions)
    strength = random.randint(4, 10)
    
    # Generate realistic prices based on the currency pair
    base_price = 1.1000 if symbol.startswith('EUR') else (
                0.7500 if symbol.startswith('AUD') else (
                1.3000 if symbol.startswith('GBP') else (
                110.00 if symbol.endswith('JPY') else 1.2000)))
    
    # Add some randomness to the price
    price_variation = random.uniform(-0.02, 0.02)
    entry_price = round(base_price + price_variation, 5)
    
    # Calculate stop loss and take profit
    pip_size = 0.01 if symbol.endswith('JPY') else 0.0001
    stop_loss_pips = random.randint(20, 100)
    take_profit_pips = random.randint(40, 200)
    
    stop_loss = round(entry_price - (pip_size * stop_loss_pips) if direction == 'BUY' 
                     else entry_price + (pip_size * stop_loss_pips), 5)
    take_profit = round(entry_price + (pip_size * take_profit_pips) if direction == 'BUY'
                       else entry_price - (pip_size * take_profit_pips), 5)
    
    # Generate signal reason
    reasons = [
        'MA Cross + RSI Oversold',
        'MACD Divergence + Support',
        'Bollinger Band Bounce + Stochastic',
        'Support/Resistance Break + Volume',
        'Double Bottom + RSI Confirmation',
        'Triple Top + MACD Divergence',
        'ADX Trend Strength + MA Alignment'
    ]
    
    # AI-enhanced reasons if AI is enabled
    ai_reasons = [
        'Neural Network Prediction (87% confidence)',
        'AI Pattern Recognition + RSI',
        'Market Sentiment Analysis + Technical Confluence',
        'Deep Learning Price Pattern + Volume Analysis',
        'AI Risk Assessment + MA Cross Confirmation'
    ]
    
    # Market sentiment data
    sentiment_conditions = [
        'Bullish Bias, Retail Crowded Bearish',
        'Bearish Bias, Institutional Positioning Bearish',
        'Neutral with Bullish Shift Detected',
        'Extreme Bullish Sentiment, Contrarian Warning',
        'Sentiment Divergence from Price Action'
    ]
    
    # Add AI reason if enabled
    if signal_bot.settings['enable_ai_analysis']:
        selected_reason = random.choice(reasons) + ' + ' + random.choice(ai_reasons)
        ai_confidence = round(random.uniform(0.75, 0.98), 2)
        ai_prediction_accuracy = round(random.uniform(80, 95), 1)
    else:
        selected_reason = random.choice(reasons)
        ai_confidence = None
        ai_prediction_accuracy = None
    
    signal = {
        'symbol': symbol,
        'direction': direction,
        'strength': strength,
        'entry_price': entry_price,
        'stop_loss': stop_loss,
        'take_profit': take_profit,
        'reason': selected_reason,
        'time': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    
    # Add AI analysis data if enabled
    if signal_bot.settings['enable_ai_analysis']:
        signal['ai_analysis'] = {
            'confidence': ai_confidence,
            'prediction_accuracy': ai_prediction_accuracy,
            'model_used': 'Neural Network v2.1',
            'pattern_strength': round(random.uniform(60, 95), 1),
            'technical_alignment': round(random.uniform(0.7, 0.95), 2),
            'historical_similarity': round(random.uniform(65, 90), 1)
        }
    
    # Add market sentiment data if enabled
    if signal_bot.settings['enable_sentiment_analysis']:
        signal['sentiment'] = {
            'retail_bullish': round(random.uniform(30, 70), 1),
            'retail_bearish': 0,  # Will be calculated to sum to 100%
            'institutional_bullish': round(random.uniform(40, 60), 1),
            'institutional_bearish': 0,  # Will be calculated to sum to 100%
            'overall_condition': random.choice(sentiment_conditions),
            'confidence': round(random.uniform(0.6, 0.95), 2)
        }
        # Calculate bearish percentages
        signal['sentiment']['retail_bearish'] = round(100 - signal['sentiment']['retail_bullish'], 1)
        signal['sentiment']['institutional_bearish'] = round(100 - signal['sentiment']['institutional_bullish'], 1)
    
    # Add the signal and broadcast to clients
    signal = signal_bot.add_signal(signal)
    socketio.emit('new_signal', signal)
    
    return jsonify({"status": "success", "signal": signal})

@app.route('/api/execute_signal', methods=['POST'])
def api_execute_signal():
    """Execute a trading signal"""
    try:
        # Check if we're executing an existing signal or creating a new one
        data = request.json
        signal_id = data.get('signal_id', None)
        
        if signal_id:
            # Find the signal in database
            signal = None
            for s in signal_bot.signals:
                if 'id' in s and s['id'] == signal_id:
                    signal = s
                    break
                    
            if not signal:
                return jsonify({"status": "error", "error": f"Signal with ID {signal_id} not found"}), 404
                
            # Set parameters from the existing signal
            symbol = signal['symbol']
            direction = signal['direction']
            entry_price = float(signal['entry_price'])
            stop_loss = float(signal['stop_loss']) if signal.get('stop_loss') else None
            take_profit = float(signal['take_profit']) if signal.get('take_profit') else None
        elif all(key in data for key in ['symbol', 'direction', 'entry_price']):
            # Create a new signal to execute immediately
            symbol = data['symbol']
            direction = data['direction']
            entry_price = float(data['entry_price'])
            stop_loss = float(data['stop_loss']) if 'stop_loss' in data else None
            take_profit = float(data['take_profit']) if 'take_profit' in data else None
        else:
            return jsonify({"status": "error", "error": "Invalid signal data - need either signal_id or complete signal details"}), 400
        
        # If in simulation mode, simulate the execution
        if SIMULATION_MODE:
            import random
            
            # Simulate a trade ticket ID
            ticket_id = random.randint(10000000, 99999999)
            
            # Calculate trade size based on risk settings
            risk_percent = signal_bot.settings['risk_percent']
            account_balance = signal_bot.status['account_balance']
            
            # Simple calculation for trade size
            pip_value = 10  # Assume $10 per pip as a standard calculation
            pip_size = 0.01 if symbol.endswith('JPY') else 0.0001
            stop_loss_pips = abs(entry_price - stop_loss) / pip_size if stop_loss else 50 * pip_size
            risk_amount = account_balance * (risk_percent / 100)
            
            # Simulate a standard lot size
            lot_size = round(risk_amount / (stop_loss_pips * pip_value), 2)
            lot_size = max(0.01, min(lot_size, 10.0))  # Limit between 0.01 and 10.0 lots
            
            # Calculate a simulated commission
            commission = round(lot_size * 7, 2)  # Simulate $7 per standard lot
            
            # Update the simulated account balance (subtract commission)
            new_balance = round(account_balance - commission, 2)
            
            # Update database
            status_update = {
                'account_balance': new_balance,
                'total_trades_today': signal_bot.status['total_trades_today'] + 1
            }
            db_manager.update_status(status_update)
            
            # Update signal execution status if we have a signal_id
            if signal_id:
                db_manager.update_signal_execution(signal_id, True)
            
            # Update caches
            signal_bot._status_cache = db_manager.get_status()
            signal_bot._signals_cache = db_manager.get_signals(10)
            
            # Create a simulated trade response
            return jsonify({
                "status": "success",
                "ticket_id": ticket_id,
                "symbol": symbol,
                "direction": direction,
                "entry_price": entry_price,
                "stop_loss": stop_loss,
                "take_profit": take_profit,
                "lot_size": lot_size,
                "commission": commission,
                "new_balance": new_balance
            })
        else:
            # In production mode, use the MT5 connector to execute the trade
            connector = get_connector()
            
            if not connector.is_connected():
                return jsonify({"status": "error", "error": "Not connected to MT5"}), 500
                
            # Calculate trade size based on risk settings
            risk_percent = signal_bot.settings['risk_percent']
            
            # Get the current account info from MT5
            account_info = connector.get_account_info()
            if not account_info:
                return jsonify({"status": "error", "error": "Failed to get account information"}), 500
                
            account_balance = account_info['balance']
            
            # Calculate position size based on risk parameters
            risk_amount = account_balance * (risk_percent / 100)
            
            # Execute the trade in MT5
            result = connector.execute_trade(
                symbol=symbol,
                order_type=direction,
                entry_price=entry_price,
                stop_loss=stop_loss,
                take_profit=take_profit,
                risk_amount=risk_amount
            )
            
            if not result or 'error' in result:
                error_msg = result.get('error', 'Unknown error') if result else 'Failed to execute trade'
                return jsonify({"status": "error", "error": error_msg}), 500
            
            # Update signal execution status if we have a signal_id
            if signal_id:
                db_manager.update_signal_execution(signal_id, True)
                
            # Update the account balance
            signal_bot.sync_with_mt5()
            
            # Return the trade execution result
            return jsonify({
                "status": "success",
                "ticket_id": result['ticket_id'],
                "symbol": symbol,
                "direction": direction,
                "entry_price": entry_price,
                "stop_loss": stop_loss,
                "take_profit": take_profit,
                "lot_size": result['lot_size'],
                "commission": result.get('commission', 0),
                "new_balance": signal_bot.status['account_balance']
            })
            
    except Exception as e:
        logger.error(f"Error executing signal: {str(e)}")
        return jsonify({"status": "error", "error": str(e)}), 500

if __name__ == '__main__':
    # Create templates directory if it doesn't exist
    if not os.path.exists('templates'):
        os.makedirs('templates')
        
    # Start MT5 sync thread if not in simulation mode
    if not SIMULATION_MODE:
        sync_thread = threading.Thread(target=mt5_sync_thread, daemon=True)
        sync_thread.start()
        
    # Start web server
    socketio.run(app, host=config.WEB_HOST, port=config.WEB_PORT, debug=config.DEBUG_MODE)