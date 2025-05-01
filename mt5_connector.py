"""
MT5 Connector Module for Signal Bot
This module handles communication between the Python interface and MetaTrader 5
"""

import json
import logging
import os
import time
from datetime import datetime
import socket
import threading
import traceback

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class MT5Connector:
    """
    Class to handle the connection between Python and MT5
    In a real environment, this would use the MetaTrader5 package
    """
    
    def __init__(self, host="127.0.0.1", port=5555, timeout=10):
        """Initialize the MT5 connection"""
        self.host = host
        self.port = port
        self.timeout = timeout
        self.connected = False
        self.socket = None
        self.lock = threading.Lock()
        
    def connect(self):
        """Establish connection to the MT5 Expert Advisor socket server"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(self.timeout)
            self.socket.connect((self.host, self.port))
            self.connected = True
            logger.info(f"Connected to MT5 Signal Bot at {self.host}:{self.port}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to MT5: {str(e)}")
            self.connected = False
            return False
            
    def disconnect(self):
        """Close the connection to MT5"""
        if self.socket:
            try:
                self.socket.close()
            except:
                pass
        self.connected = False
        logger.info("Disconnected from MT5")
        
    def send_command(self, command, params=None):
        """
        Send a command to MT5 and get the response
        
        Args:
            command (str): Command to send (SET_SETTINGS, GET_SIGNALS, etc.)
            params (dict): Optional parameters for the command
            
        Returns:
            dict: Response from MT5 or error information
        """
        if not self.connected:
            if not self.connect():
                return {"error": "Not connected to MT5"}
                
        # Prepare the message
        message = {
            "command": command,
            "params": params or {},
            "timestamp": datetime.now().isoformat()
        }
        
        # Convert to JSON and add null terminator
        message_str = json.dumps(message) + "\0"
        
        with self.lock:
            try:
                # Send the message
                self.socket.sendall(message_str.encode('utf-8'))
                
                # Receive the response
                response = self._receive_response()
                
                # Parse the response
                if response:
                    try:
                        return json.loads(response)
                    except json.JSONDecodeError:
                        return {"error": "Invalid response format", "response": response}
                else:
                    return {"error": "Empty response from MT5"}
                    
            except socket.timeout:
                logger.error("Connection to MT5 timed out")
                self.disconnect()
                return {"error": "Connection timeout"}
                
            except Exception as e:
                logger.error(f"Error communicating with MT5: {str(e)}")
                logger.error(traceback.format_exc())
                self.disconnect()
                return {"error": str(e)}
    
    def _receive_response(self):
        """
        Receive and assemble the complete response from MT5
        
        Returns:
            str: Complete response string
        """
        chunks = []
        while True:
            chunk = self.socket.recv(4096)
            if not chunk:
                break
                
            # Check for null terminator
            if chunk[-1] == 0:
                chunks.append(chunk[:-1])  # Exclude the null terminator
                break
            else:
                chunks.append(chunk)
                
        return b''.join(chunks).decode('utf-8')
        
    def get_signals(self):
        """Get the current trading signals from MT5"""
        return self.send_command("GET_SIGNALS")
        
    def get_status(self):
        """Get the current status of the signal bot"""
        return self.send_command("GET_STATUS")
        
    def update_settings(self, settings):
        """Update the bot settings in MT5"""
        return self.send_command("SET_SETTINGS", settings)
        
    def load_preset(self, preset_name):
        """Load a strategy preset in MT5"""
        return self.send_command("LOAD_PRESET", {"preset": preset_name})
        
    def test_connection(self):
        """Test if we can connect to MT5"""
        if self.connect():
            self.disconnect()
            return True
        return False
        
    def subscribe_to_signals(self, callback):
        """
        Start a background thread to listen for new signals
        
        Args:
            callback (function): Function to call when a new signal is received
        """
        def listener_thread():
            while self.connected:
                try:
                    response = self.send_command("SUBSCRIBE_SIGNALS")
                    if "error" not in response and "signal" in response:
                        callback(response["signal"])
                    time.sleep(1)  # Sleep to avoid high CPU usage
                except Exception as e:
                    logger.error(f"Error in signal listener: {str(e)}")
                    time.sleep(5)  # Longer sleep on error
                    
        thread = threading.Thread(target=listener_thread, daemon=True)
        thread.start()
        return thread


# Singleton instance
_mt5_connector = None

def get_connector():
    """Get or create the MT5Connector singleton instance"""
    global _mt5_connector
    if _mt5_connector is None:
        _mt5_connector = MT5Connector()
    return _mt5_connector