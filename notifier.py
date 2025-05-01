"""
Notification module for the MT5 Signal Bot
Handles email and Telegram notifications for trading signals
"""

import logging
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import requests
import traceback
import config

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SignalNotifier:
    """
    Class to handle notifications for the MT5 Signal Bot
    """
    
    @staticmethod
    def send_email_notification(signal):
        """
        Send an email notification for a new trading signal
        
        Args:
            signal (dict): The trading signal data
        
        Returns:
            bool: True if successful, False otherwise
        """
        if not config.ENABLE_EMAIL:
            return False
            
        try:
            # Create a multipart message and set headers
            message = MIMEMultipart()
            message["From"] = config.EMAIL_USERNAME
            message["To"] = config.EMAIL_RECIPIENT
            message["Subject"] = f"MT5 Signal Bot: New {signal['direction']} Signal for {signal['symbol']}"
            
            # Signal strength assessment
            strength_assessment = "Low"
            if signal['strength'] >= 8:
                strength_assessment = "Very Strong"
            elif signal['strength'] >= 6:
                strength_assessment = "Strong"
            elif signal['strength'] >= 4:
                strength_assessment = "Moderate"
                
            # Create the email body
            email_body = f"""
            <html>
            <body>
                <h2>MT5 Signal Bot: New Trading Signal</h2>
                <table border="1" cellpadding="5">
                    <tr>
                        <th colspan="2" style="background-color: {'#4CAF50' if signal['direction'] == 'BUY' else '#F44336'}; color: white;">
                            {signal['direction']} SIGNAL ({strength_assessment} - {signal['strength']}/10)
                        </th>
                    </tr>
                    <tr>
                        <td><strong>Symbol</strong></td>
                        <td>{signal['symbol']}</td>
                    </tr>
                    <tr>
                        <td><strong>Entry Price</strong></td>
                        <td>{signal['entry_price']}</td>
                    </tr>
                    <tr>
                        <td><strong>Stop Loss</strong></td>
                        <td>{signal['stop_loss']}</td>
                    </tr>
                    <tr>
                        <td><strong>Take Profit</strong></td>
                        <td>{signal['take_profit']}</td>
                    </tr>
                    <tr>
                        <td><strong>Reason</strong></td>
                        <td>{signal['reason']}</td>
                    </tr>
                    <tr>
                        <td><strong>Time</strong></td>
                        <td>{signal['time']}</td>
                    </tr>
                </table>
                <p>This is an automated message from your MT5 Signal Bot.</p>
            </body>
            </html>
            """
            
            # Add HTML/plain-text parts to MIMEMultipart message
            message.attach(MIMEText(email_body, "html"))
            
            # Create secure connection with server and send email
            with smtplib.SMTP(config.EMAIL_SERVER, config.EMAIL_PORT) as server:
                if config.EMAIL_USE_TLS:
                    server.starttls()
                server.login(config.EMAIL_USERNAME, config.EMAIL_PASSWORD)
                server.sendmail(
                    config.EMAIL_USERNAME, config.EMAIL_RECIPIENT, message.as_string()
                )
                
            logger.info(f"Email notification sent for {signal['symbol']} {signal['direction']} signal")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send email notification: {str(e)}")
            logger.error(traceback.format_exc())
            return False
            
    @staticmethod
    def send_telegram_notification(signal):
        """
        Send a Telegram notification for a new trading signal
        
        Args:
            signal (dict): The trading signal data
        
        Returns:
            bool: True if successful, False otherwise
        """
        if not config.ENABLE_TELEGRAM:
            return False
            
        try:
            # Create the message text
            emoji = "🟢" if signal['direction'] == 'BUY' else "🔴"
            
            message_text = (
                f"{emoji} <b>NEW {signal['direction']} SIGNAL</b> {emoji}\n\n"
                f"<b>Symbol:</b> {signal['symbol']}\n"
                f"<b>Entry Price:</b> {signal['entry_price']}\n"
                f"<b>Stop Loss:</b> {signal['stop_loss']}\n"
                f"<b>Take Profit:</b> {signal['take_profit']}\n"
                f"<b>Signal Strength:</b> {signal['strength']}/10\n"
                f"<b>Reason:</b> {signal['reason']}\n"
                f"<b>Time:</b> {signal['time']}\n"
            )
            
            # Send the message using the Telegram Bot API
            url = f"https://api.telegram.org/bot{config.TELEGRAM_BOT_TOKEN}/sendMessage"
            payload = {
                "chat_id": config.TELEGRAM_CHAT_ID,
                "text": message_text,
                "parse_mode": "HTML"
            }
            
            response = requests.post(url, data=payload)
            response.raise_for_status()
            
            logger.info(f"Telegram notification sent for {signal['symbol']} {signal['direction']} signal")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send Telegram notification: {str(e)}")
            logger.error(traceback.format_exc())
            return False
            
    @staticmethod
    def notify(signal):
        """
        Send notifications across all configured channels
        
        Args:
            signal (dict): The trading signal data
        """
        results = {}
        
        # Send email notification if enabled
        if config.ENABLE_EMAIL:
            results['email'] = SignalNotifier.send_email_notification(signal)
            
        # Send Telegram notification if enabled
        if config.ENABLE_TELEGRAM:
            results['telegram'] = SignalNotifier.send_telegram_notification(signal)
            
        return results