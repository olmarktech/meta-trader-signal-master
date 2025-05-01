import os
import json
import time
from datetime import datetime
from sqlalchemy import create_engine, Column, Integer, String, Float, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy.pool import QueuePool

# Get database URL from environment variable
DATABASE_URL = os.environ.get('DATABASE_URL')

# Add connection parameters to handle connection issues
# Note: We're not adding SSL parameters here as they may conflict with existing ones
query_params = {
    'connect_timeout': '10',
    'keepalives': '1',
    'keepalives_idle': '5',
    'keepalives_interval': '2',
    'keepalives_count': '2'
}

if DATABASE_URL and 'postgresql' in DATABASE_URL:
    # Avoid adding duplicate parameters
    if '?' in DATABASE_URL:
        prefix, params = DATABASE_URL.split('?', 1)
        existing_params = params.split('&')
        
        # Extract existing parameter names
        existing_param_names = set()
        for param in existing_params:
            if '=' in param:
                name, _ = param.split('=', 1)
                existing_param_names.add(name)
        
        # Add only new parameters
        for name, value in query_params.items():
            if name not in existing_param_names:
                DATABASE_URL += f"&{name}={value}"
    else:
        # No existing parameters, add all new ones
        DATABASE_URL += '?' + '&'.join([f"{name}={value}" for name, value in query_params.items()])

# Create engine with connection pooling and retry on failure
engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=5,
    max_overflow=10,
    pool_timeout=30,
    pool_recycle=1800,  # Recycle connections after 30 minutes
    pool_pre_ping=True  # Check connection validity before using it
)

Session = sessionmaker(bind=engine)
Base = declarative_base()

class Settings(Base):
    """Model for storing bot settings"""
    __tablename__ = 'settings'
    
    id = Column(Integer, primary_key=True)
    key = Column(String(255), unique=True, nullable=False)
    value = Column(Text, nullable=True)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    def __repr__(self):
        return f"<Settings(key='{self.key}', value='{self.value}')>"

class Preset(Base):
    """Model for storing strategy presets"""
    __tablename__ = 'presets'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(255), unique=True, nullable=False)
    description = Column(Text, nullable=True)
    parameters = Column(Text, nullable=False)  # JSON string
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    def get_parameters_dict(self):
        """Convert JSON parameters to dictionary"""
        return json.loads(self.parameters)
    
    def __repr__(self):
        return f"<Preset(name='{self.name}')>"

class Signal(Base):
    """Model for storing trading signals"""
    __tablename__ = 'signals'
    
    id = Column(Integer, primary_key=True)
    symbol = Column(String(20), nullable=False)
    direction = Column(String(10), nullable=False)  # BUY or SELL
    strength = Column(Integer, nullable=False)
    entry_price = Column(Float, nullable=False)
    stop_loss = Column(Float, nullable=True)
    take_profit = Column(Float, nullable=True)
    reason = Column(Text, nullable=True)
    sentiment_data = Column(Text, nullable=True)  # JSON string
    created_at = Column(DateTime, default=datetime.now)
    executed = Column(Boolean, default=False)
    execution_time = Column(DateTime, nullable=True)
    
    def to_dict(self):
        """Convert signal to dictionary"""
        signal_dict = {
            'id': self.id,
            'symbol': self.symbol,
            'direction': self.direction,
            'strength': self.strength,
            'entry_price': self.entry_price,
            'stop_loss': self.stop_loss,
            'take_profit': self.take_profit,
            'reason': self.reason,
            'time': self.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            'executed': self.executed
        }
        
        # Add sentiment data if available
        if self.sentiment_data:
            try:
                signal_dict['sentiment'] = json.loads(self.sentiment_data)
            except:
                signal_dict['sentiment'] = {}
                
        return signal_dict
    
    def __repr__(self):
        return f"<Signal(symbol='{self.symbol}', direction='{self.direction}', created_at='{self.created_at}')>"

class BotStatus(Base):
    """Model for storing bot status"""
    __tablename__ = 'bot_status'
    
    id = Column(Integer, primary_key=True)
    running = Column(Boolean, default=True)
    connected = Column(Boolean, default=False)
    last_update = Column(DateTime, default=datetime.now)
    bot_version = Column(String(20), default="1.0")
    account_balance = Column(Float, default=10000.0)
    total_trades_today = Column(Integer, default=0)
    total_signals_today = Column(Integer, default=0)
    
    def to_dict(self):
        """Convert status to dictionary"""
        return {
            'running': self.running,
            'connected': self.connected,
            'last_update': self.last_update.strftime("%Y-%m-%d %H:%M:%S"),
            'bot_version': self.bot_version,
            'account_balance': self.account_balance,
            'total_trades_today': self.total_trades_today,
            'total_signals_today': self.total_signals_today
        }
    
    def __repr__(self):
        return f"<BotStatus(running={self.running}, connected={self.connected}, last_update='{self.last_update}')>"

# Create all tables
def init_db():
    Base.metadata.create_all(engine)

# Helper function to get a session
def get_session():
    return Session()