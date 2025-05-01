//+------------------------------------------------------------------+
//|                                                   APIServer.mqh |
//|                      Copyright 2025, Signal Bot                |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Signal Bot"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Include files                                                    |
//+------------------------------------------------------------------+
#include <SignalBot/Configuration.mqh>
#include <SignalBot/Utils.mqh>

//+------------------------------------------------------------------+
//| Socket connection management class for remote API access         |
//+------------------------------------------------------------------+
class SignalBotAPI
{
private:
   int               m_socket;             // Socket handle
   int               m_port;               // Socket port
   bool              m_initialized;         // Initialization flag
   string            m_lastError;          // Last error message
   
   // Private methods
   bool              SocketSend(string data);
   string            SocketReceive();
   string            ProcessCommand(string command, string params);
   
public:
                     SignalBotAPI();
                    ~SignalBotAPI();
   
   // Initialization and connection methods
   bool              Initialize(int port=5555);
   void              Shutdown();
   bool              IsInitialized() const { return m_initialized; }
   string            GetLastError() const { return m_lastError; }
   
   // Main process method - call this in OnTimer
   void              ProcessRequests();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalBotAPI::SignalBotAPI()
{
   m_socket = INVALID_HANDLE;
   m_port = 5555;
   m_initialized = false;
   m_lastError = "";
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalBotAPI::~SignalBotAPI()
{
   Shutdown();
}

//+------------------------------------------------------------------+
//| Initialize the socket server                                     |
//+------------------------------------------------------------------+
bool SignalBotAPI::Initialize(int port=5555)
{
   // Already initialized
   if(m_initialized)
      return true;
      
   m_port = port;
   
   // Create a socket
   m_socket = SocketCreate(SOCKET_DEFAULT);
   
   if(m_socket == INVALID_HANDLE)
   {
      m_lastError = "Failed to create socket: " + (string)GetLastError();
      Print("API Server: " + m_lastError);
      return false;
   }
   
   // Bind socket to the port
   // In MT5, we need to specify the address when binding the socket
   if(!SocketBind(m_socket, "localhost", port))
   {
      m_lastError = "Failed to bind socket to port " + (string)port + ": " + (string)GetLastError();
      Print("API Server: " + m_lastError);
      SocketClose(m_socket);
      m_socket = INVALID_HANDLE;
      return false;
   }
   
   // Start listening
   if(!SocketListen(m_socket, 5))
   {
      m_lastError = "Failed to start listening: " + (string)GetLastError();
      Print("API Server: " + m_lastError);
      SocketClose(m_socket);
      m_socket = INVALID_HANDLE;
      return false;
   }
   
   Print("API Server: Initialized and listening on port " + (string)port);
   m_initialized = true;
   return true;
}

//+------------------------------------------------------------------+
//| Shutdown the socket server                                       |
//+------------------------------------------------------------------+
void SignalBotAPI::Shutdown()
{
   if(m_socket != INVALID_HANDLE)
   {
      SocketClose(m_socket);
      m_socket = INVALID_HANDLE;
   }
   
   m_initialized = false;
   Print("API Server: Shut down");
}

//+------------------------------------------------------------------+
//| Process incoming connection requests                             |
//+------------------------------------------------------------------+
void SignalBotAPI::ProcessRequests()
{
   if(!m_initialized || m_socket == INVALID_HANDLE)
      return;
      
   // Check for new connections (non-blocking)
   uint timeout = 1; // 1ms timeout for non-blocking operation
   
   // Accept new connections
   int client = SocketAccept(m_socket, timeout);
   
   if(client != INVALID_HANDLE)
   {
      Print("API Server: New client connection accepted");
      
      // Receive data
      string received = "";
      char buffer[];
      ArrayResize(buffer, 1024);
      
      uint received_bytes = 0;
      
      while(true)
      {
         uint bytes = SocketRead(client, buffer, ArraySize(buffer), timeout);
         
         if(bytes > 0)
         {
            received_bytes += bytes;
            string part = CharArrayToString(buffer, 0, bytes);
            received += part;
            
            // Check for null terminator (message end)
            if(StringGetCharacter(part, StringLen(part) - 1) == 0)
            {
               received = StringSubstr(received, 0, StringLen(received) - 1); // Remove null terminator
               break;
            }
         }
         else
         {
            break;
         }
      }
      
      // Process the request if we received data
      if(received_bytes > 0)
      {
         Print("API Server: Received message: " + received);
         
         // Parse JSON message
         ushort separator = StringGetCharacter(":", 0);
         int pos = StringFind(received, "\"command\"");
         
         if(pos != -1)
         {
            pos = StringFind(received, ":", pos);
            if(pos != -1)
            {
               pos++;
               // Skip whitespace
               while(StringGetCharacter(received, pos) == 32) pos++;
               
               // Get command (without quotes)
               if(StringGetCharacter(received, pos) == 34) // Double quote
               {
                  pos++; // Skip opening quote
                  int end_pos = StringFind(received, "\"", pos);
                  if(end_pos != -1)
                  {
                     string command = StringSubstr(received, pos, end_pos - pos);
                     
                     // Now find params
                     pos = StringFind(received, "\"params\"");
                     if(pos != -1)
                     {
                        pos = StringFind(received, ":", pos);
                        if(pos != -1)
                        {
                           string params = StringSubstr(received, pos + 1);
                           // Process the command
                           string response = ProcessCommand(command, params);
                           
                           // Send response
                           SocketSend(client, response + "\0"); // Add null terminator
                        }
                     }
                  }
               }
            }
         }
      }
      
      // Close client connection
      SocketClose(client);
   }
}

//+------------------------------------------------------------------+
//| Process API command                                              |
//+------------------------------------------------------------------+
string SignalBotAPI::ProcessCommand(string command, string params)
{
   string response = "{\"status\":\"error\",\"message\":\"Unknown command\"}";
   
   Print("API Server: Processing command: " + command + " with params: " + params);
   
   if(command == "GET_STATUS")
   {
      // Return current bot status
      // In MT5, use GlobalVariableGet instead of GetGlobalVariable
      bool isRunning = false;
      if (GlobalVariableCheck("SignalBotRunning"))
         isRunning = GlobalVariableGet("SignalBotRunning") != 0;
          
      response = "{\"status\":\"success\",\"running\":" + (isRunning ? "true" : "false") + 
                 ",\"connected\":true" + 
                 ",\"bot_version\":\"" + SIGNAL_BOT_VERSION + "\"" +
                 // In MT5, use AccountInfoDouble instead of AccountBalance
                 ",\"account_balance\":" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2) + 
                 ",\"total_trades_today\":" + (string)GetTotalTradesPerDay() + 
                 ",\"total_signals_today\":" + (string)GetTotalSignalsPerDay() + 
                 ",\"last_update\":\"" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\"}";
   }
   else if(command == "GET_SIGNALS")
   {
      // Return recent signals
      response = "{\"status\":\"success\",\"signals\":" + GetRecentSignalsJSON() + "}";
   }
   else if(command == "SET_SETTINGS")
   {
      // Update bot settings
      if(UpdateSettingsFromJSON(params))
      {
         response = "{\"status\":\"success\",\"message\":\"Settings updated\"}";
      }
      else
      {
         response = "{\"status\":\"error\",\"message\":\"Failed to update settings\"}";
      }
   }
   else if(command == "LOAD_PRESET")
   {
      // Extract preset name from params
      ushort separator = StringGetCharacter(":", 0);
      int pos = StringFind(params, "\"preset\"");
      
      if(pos != -1)
      {
         pos = StringFind(params, ":", pos);
         if(pos != -1)
         {
            pos++;
            // Skip whitespace
            while(StringGetCharacter(params, pos) == 32) pos++;
            
            // Get preset name (without quotes)
            if(StringGetCharacter(params, pos) == 34) // Double quote
            {
               pos++; // Skip opening quote
               int end_pos = StringFind(params, "\"", pos);
               if(end_pos != -1)
               {
                  string preset_name = StringSubstr(params, pos, end_pos - pos);
                  
                  // Load the preset
                  if(LoadPreset(preset_name))
                  {
                     response = "{\"status\":\"success\",\"message\":\"Preset loaded: " + preset_name + "\"}";
                  }
                  else
                  {
                     response = "{\"status\":\"error\",\"message\":\"Failed to load preset: " + preset_name + "\"}";
                  }
               }
            }
         }
      }
   }
   
   return response;
}

//+------------------------------------------------------------------+
//| Additional helper functions (simplified implementation)           |
//+------------------------------------------------------------------+

// Get total trades for the current day
int GetTotalTradesPerDay()
{
   return 3; // Simplified implementation
}

// Get total signals for the current day
int GetTotalSignalsPerDay()
{
   return 12; // Simplified implementation
}

// Get recent signals as JSON
string GetRecentSignalsJSON()
{
   // Sample signals for demonstration
   return "[{\"symbol\":\"EURUSD\",\"direction\":\"BUY\",\"strength\":7,\"entry_price\":1.08762,\"stop_loss\":1.08262,\"take_profit\":1.09762,\"reason\":\"MA Cross + RSI Oversold\",\"time\":\"" + TimeToString(TimeCurrent()-3600, TIME_DATE|TIME_SECONDS) + "\"},"
          + "{\"symbol\":\"GBPUSD\",\"direction\":\"SELL\",\"strength\":6,\"entry_price\":1.26543,\"stop_loss\":1.27043,\"take_profit\":1.25543,\"reason\":\"MACD Divergence\",\"time\":\"" + TimeToString(TimeCurrent()-7200, TIME_DATE|TIME_SECONDS) + "\"}]";
}

// Update settings from JSON - simplified implementation
bool UpdateSettingsFromJSON(string json)
{
   Print("Updating settings with: " + json);
   
   // In a real implementation, we would parse the JSON and update the bot settings
   
   return true;
}

// Load a preset - simplified implementation
bool LoadPreset(string preset_name)
{
   Print("Loading preset: " + preset_name);
   
   // In a real implementation, we would load the preset file and apply the settings
   
   return true;
}