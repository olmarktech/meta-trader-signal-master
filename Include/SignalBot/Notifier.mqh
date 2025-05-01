//+------------------------------------------------------------------+
//|                                                     Notifier.mqh |
//|                        Copyright 2023, Your Company               |
//|                                       https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include "Constants.mqh"
#include "Configuration.mqh"

//+------------------------------------------------------------------+
//| Class to handle notifications                                     |
//+------------------------------------------------------------------+
class Notifier
{
private:
   Configuration* m_config;
   
   // Send alert via MT5
   void SendMT5Alert(string message)
   {
      Alert(message);
   }
   
   // Send email notification
   bool SendEmail(string subject, string message)
   {
      return SendMail(subject, message);
   }
   
   // Send Telegram notification
   bool SendTelegram(string message)
   {
      string token = m_config.GetTelegramBotToken();
      string chatID = m_config.GetTelegramChatID();
      
      if(token == "" || chatID == "")
      {
         Print("Telegram notification failed: Bot token or Chat ID not set");
         return false;
      }
      
      string url = "https://api.telegram.org/bot" + token + "/sendMessage?chat_id=" + chatID + "&text=" + message;
      string headers = "Content-Type: application/x-www-form-urlencoded";
      char result[];
      char post[];
      
      int res = WebRequest("GET", url, headers, 0, post, result, headers);
      
      if(res == -1)
      {
         Print("Telegram error: ", GetLastError());
         return false;
      }
      
      return true;
   }
   
   // Format signal message
   string FormatSignalMessage(string symbol, SignalInfo &signal, TradeParameters &params)
   {
      string direction = (signal.direction == SIGNAL_BUY) ? "BUY" : "SELL";
      string message = direction + " " + symbol + " Signal";
      message += "\n\nStrength: " + IntegerToString(signal.strength) + "/10";
      message += "\nReason: " + signal.reason;
      message += "\n\nEntry: " + DoubleToString(params.entryPrice, SymbolInfoInteger(symbol, SYMBOL_DIGITS));
      message += "\nStop Loss: " + DoubleToString(params.stopLoss, SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + 
                 " (" + IntegerToString(params.stopLossPips) + " pips)";
      message += "\nTake Profit: " + DoubleToString(params.takeProfit, SymbolInfoInteger(symbol, SYMBOL_DIGITS)) + 
                 " (" + IntegerToString(params.takeProfitPips) + " pips)";
      message += "\nLot Size: " + DoubleToString(params.lotSize, 2);
      
      if(params.useTrailingStop)
      {
         message += "\nTrailing Stop: " + IntegerToString(params.trailingStopPips) + " pips";
      }
      
      message += "\n\nTime: " + TimeToString(signal.time, TIME_DATE|TIME_MINUTES|TIME_SECONDS);
      
      return message;
   }

public:
   // Constructor
   Notifier()
   {
      m_config = NULL;
   }
   
   // Initialize the notifier
   bool Initialize(Configuration* config)
   {
      if(config == NULL) return false;
      
      m_config = config;
      return true;
   }
   
   // Send signal alert through configured channels
   void SendSignalAlert(string symbol, SignalInfo &signal, TradeParameters &params)
   {
      string message = FormatSignalMessage(symbol, signal, params);
      string subject = (signal.direction == SIGNAL_BUY ? "BUY" : "SELL") + " Signal: " + symbol;
      
      // Send MT5 alert if enabled
      if(m_config.GetEnableMT5Alerts())
      {
         SendMT5Alert(message);
      }
      
      // Send email if enabled
      if(m_config.GetEnableEmailAlerts())
      {
         SendEmail(subject, message);
      }
      
      // Send Telegram if enabled
      if(m_config.GetEnableTelegramAlerts())
      {
         SendTelegram(message);
      }
   }
   
   // Send simple notification through all enabled channels
   void SendNotification(string message)
   {
      // Send MT5 alert if enabled
      if(m_config.GetEnableMT5Alerts())
      {
         SendMT5Alert(message);
      }
      
      // Send email if enabled
      if(m_config.GetEnableEmailAlerts())
      {
         SendEmail("MT5 Signal Bot Notification", message);
      }
      
      // Send Telegram if enabled
      if(m_config.GetEnableTelegramAlerts())
      {
         SendTelegram(message);
      }
   }
};
