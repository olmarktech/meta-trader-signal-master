"""
Configuration settings for the MT5 Signal Bot Python Interface
"""

import os
from dotenv import load_dotenv

# Load environment variables from .env file if present
load_dotenv()

# MT5 Connection Settings
MT5_HOST = os.getenv('MT5_HOST', '127.0.0.1')
MT5_PORT = int(os.getenv('MT5_PORT', '5555'))
MT5_TIMEOUT = int(os.getenv('MT5_TIMEOUT', '10'))

# Web Server Settings
WEB_HOST = os.getenv('WEB_HOST', '0.0.0.0')
WEB_PORT = int(os.getenv('WEB_PORT', '5000'))
DEBUG_MODE = os.getenv('DEBUG_MODE', 'True').lower() == 'true'

# Security Settings
SECRET_KEY = os.getenv('SECRET_KEY', 'change_this_in_production')
ENABLE_AUTH = os.getenv('ENABLE_AUTH', 'False').lower() == 'true'
USERNAME = os.getenv('USERNAME', 'admin')
PASSWORD = os.getenv('PASSWORD', 'password')

# Notification Settings
ENABLE_EMAIL = os.getenv('ENABLE_EMAIL', 'False').lower() == 'true'
EMAIL_SERVER = os.getenv('EMAIL_SERVER', 'smtp.gmail.com')
EMAIL_PORT = int(os.getenv('EMAIL_PORT', '587'))
EMAIL_USE_TLS = os.getenv('EMAIL_USE_TLS', 'True').lower() == 'true'
EMAIL_USERNAME = os.getenv('EMAIL_USERNAME', '')
EMAIL_PASSWORD = os.getenv('EMAIL_PASSWORD', '')
EMAIL_RECIPIENT = os.getenv('EMAIL_RECIPIENT', '')

# Telegram Notification Settings
ENABLE_TELEGRAM = os.getenv('ENABLE_TELEGRAM', 'False').lower() == 'true'
TELEGRAM_BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN', '')
TELEGRAM_CHAT_ID = os.getenv('TELEGRAM_CHAT_ID', '')

# Paths
PRESETS_PATH = os.getenv('PRESETS_PATH', 'Presets')