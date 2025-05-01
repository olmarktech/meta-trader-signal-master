A highly customizable and intelligent MetaTrader 5 trading signals bot with an independent Python web interface.

Features
Advanced Signal Generation: Uses multiple technical indicators to generate trading signals
Customizable Strategies: Pre-defined strategy presets and ability to customize your own
Risk Management: Built-in risk calculation and management
Multiple Timeframes: Works with any timeframe from M1 to D1
Multi-Symbol: Monitor multiple trading symbols simultaneously
News Filtering: Avoid trading during high-impact news events
Notifications: MT5 alerts, email, and Telegram notifications
Visual Dashboard: Real-time display of signals and statistics
Remote Management: Python web interface to manage the bot from anywhere
Historical Backtesting: Test strategies on historical data
Components
The system consists of two main parts:

MT5 Signal Bot (MQL5): The core bot that runs in MetaTrader 5
Web Interface (Python): Remote management interface that communicates with MT5
Installation
MT5 Signal Bot Installation
Copy the entire directory structure to your MetaTrader 5 MQL5/Experts directory:

MT5_Signal_Bot.mq5: Main EA file
Include/SignalBot/: All supporting files
Presets/: Strategy preset files
Open MT5 and compile the MT5_Signal_Bot.mq5 file

Add the EA to your chart and configure the parameters:

General trading settings
Risk management parameters
Strategy selection
Notification options
Enable Remote API (for web interface)
Web Interface Installation
Install Python 3.8+ and required packages:

pip install flask flask-socketio pandas numpy websockets python-dotenv
Update the .env file with your configuration settings:

Web server settings
MT5 connection details
Security credentials
Email and Telegram notification settings (if used)
Run the web application:

python app.py
Access the web interface at http://localhost:5000

Strategy Presets
The system includes four pre-configured strategy presets:

Trend Following: Identify and follow strong market trends using moving averages, RSI, and ADX
Reversal: Capture market reversals at extreme levels using price action, RSI, and Bollinger Bands
Scalping: Fast-paced trading on lower timeframes with quick entry/exit
Swing Trading: Medium-term trading based on price action and major levels
Remote API Integration
The MT5 Signal Bot includes an API server that allows the Python web interface to:

Get current trading signals
Monitor the bot status
Update settings in real-time
Load different strategy presets
Receive signal notifications
Customization
You can customize the bot by:

Modifying Strategy Presets: Edit the preset files in the Presets/ directory
Creating New Indicators: Add new indicators to Include/SignalBot/IndicatorProcessor.mqh
Extending the Signal Generator: Modify Include/SignalBot/SignalGenerator.mqh
Customizing Risk Management: Adjust parameters in Include/SignalBot/RiskManager.mqh
Enhancing the Web Interface: Modify the Python application files
Security Considerations
Enable authentication for the web interface in production environments
Set strong passwords for access
Run the web interface on a secure, private network or use HTTPS
Be careful when exposing the API server to external networks
Troubleshooting
MT5 Connection Issues: Ensure WebRequest is allowed in MT5 Tools > Options > Expert Advisors
API Server Not Starting: Check port availability and firewall settings
Notification Failures: Verify API keys and authentication details for email/Telegram
License
This project is licensed under the MIT License - see the LICENSE file for details.
