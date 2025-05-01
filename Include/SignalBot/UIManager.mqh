//+------------------------------------------------------------------+
//|                                                    UIManager.mqh |
//|                        Copyright 2023, Your Company               |
//|                                       https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include "Constants.mqh"
#include "Configuration.mqh"

// Structure to hold dashboard signal data
struct DashboardSignal
{
   string symbol;
   ENUM_SIGNAL_DIRECTION direction;
   int strength;
   string reason;
   datetime time;
   double entryPrice;
   double stopLoss;
   double takeProfit;
   double lotSize;
};

//+------------------------------------------------------------------+
//| Class to manage UI elements                                       |
//+------------------------------------------------------------------+
class UIManager
{
private:
   Configuration* m_config;
   
   // Dashboard properties
   int m_dashboardX;
   int m_dashboardY;
   int m_dashboardFontSize;
   string m_dashboardObjectPrefix;
   int m_maxSignals;
   
   // Dashboard data
   DashboardSignal m_signals[];
   int m_signalCount;
   
   // Create dashboard background
   void CreateDashboardBackground()
   {
      string objName = m_dashboardObjectPrefix + "Background";
      
      // Calculate size based on content
      int width = 400;
      int height = 40 + (m_maxSignals + 1) * (m_dashboardFontSize + 10);
      
      // Create background rectangle
      if(ObjectFind(0, objName) < 0)
      {
         ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      }
      
      ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, m_dashboardX);
      ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, m_dashboardY);
      ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, COLOR_BACKGROUND);
      ObjectSetInteger(0, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clrGray);
      ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, objName, OBJPROP_BACK, false);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
   }
   
   // Create dashboard title
   void CreateDashboardTitle()
   {
      string objName = m_dashboardObjectPrefix + "Title";
      
      if(ObjectFind(0, objName) < 0)
      {
         ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
      }
      
      ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, m_dashboardX + 10);
      ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, m_dashboardY + 10);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, COLOR_HEADER);
      ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, m_dashboardFontSize + 2);
      ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
      ObjectSetString(0, objName, OBJPROP_TEXT, "MT5 TRADING SIGNALS DASHBOARD");
      ObjectSetString(0, objName, OBJPROP_FONT, "Arial Bold");
   }
   
   // Create dashboard headers
   void CreateDashboardHeaders()
   {
      string headerNames[] = {"Symbol", "Direction", "Strength", "Entry", "Time"};
      int headerPositions[] = {10, 80, 150, 220, 290};
      
      for(int i = 0; i < ArraySize(headerNames); i++)
      {
         string objName = m_dashboardObjectPrefix + "Header" + IntegerToString(i);
         
         if(ObjectFind(0, objName) < 0)
         {
            ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
         }
         
         ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, m_dashboardX + headerPositions[i]);
         ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, m_dashboardY + 40);
         ObjectSetInteger(0, objName, OBJPROP_COLOR, COLOR_HEADER);
         ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, m_dashboardFontSize);
         ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
         ObjectSetString(0, objName, OBJPROP_TEXT, headerNames[i]);
         ObjectSetString(0, objName, OBJPROP_FONT, "Arial Bold");
      }
   }
   
   // Update dashboard signals
   void UpdateDashboardSignals()
   {
      // Clear existing signal objects
      ClearDashboardSignals();
      
      // Create new signals
      for(int i = 0; i < m_signalCount; i++)
      {
         // Skip if we've reached maximum signals to display
         if(i >= m_maxSignals) break;
         
         DashboardSignal signal = m_signals[i];
         
         // Signal base Y position
         int yPos = m_dashboardY + 70 + i * (m_dashboardFontSize + 10);
         
         // Symbol
         string objNameSymbol = m_dashboardObjectPrefix + "Signal" + IntegerToString(i) + "Symbol";
         if(ObjectFind(0, objNameSymbol) < 0)
         {
            ObjectCreate(0, objNameSymbol, OBJ_LABEL, 0, 0, 0);
         }
         ObjectSetInteger(0, objNameSymbol, OBJPROP_XDISTANCE, m_dashboardX + 10);
         ObjectSetInteger(0, objNameSymbol, OBJPROP_YDISTANCE, yPos);
         ObjectSetInteger(0, objNameSymbol, OBJPROP_COLOR, COLOR_TEXT);
         ObjectSetInteger(0, objNameSymbol, OBJPROP_FONTSIZE, m_dashboardFontSize);
         ObjectSetInteger(0, objNameSymbol, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, objNameSymbol, OBJPROP_HIDDEN, true);
         ObjectSetString(0, objNameSymbol, OBJPROP_TEXT, signal.symbol);
         
         // Direction
         string objNameDirection = m_dashboardObjectPrefix + "Signal" + IntegerToString(i) + "Direction";
         if(ObjectFind(0, objNameDirection) < 0)
         {
            ObjectCreate(0, objNameDirection, OBJ_LABEL, 0, 0, 0);
         }
         ObjectSetInteger(0, objNameDirection, OBJPROP_XDISTANCE, m_dashboardX + 80);
         ObjectSetInteger(0, objNameDirection, OBJPROP_YDISTANCE, yPos);
         ObjectSetInteger(0, objNameDirection, OBJPROP_COLOR, 
                          signal.direction == SIGNAL_BUY ? COLOR_BUY_SIGNAL : COLOR_SELL_SIGNAL);
         ObjectSetInteger(0, objNameDirection, OBJPROP_FONTSIZE, m_dashboardFontSize);
         ObjectSetInteger(0, objNameDirection, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, objNameDirection, OBJPROP_HIDDEN, true);
         ObjectSetString(0, objNameDirection, OBJPROP_TEXT, signal.direction == SIGNAL_BUY ? "BUY" : "SELL");
         
         // Strength
         string objNameStrength = m_dashboardObjectPrefix + "Signal" + IntegerToString(i) + "Strength";
         if(ObjectFind(0, objNameStrength) < 0)
         {
            ObjectCreate(0, objNameStrength, OBJ_LABEL, 0, 0, 0);
         }
         ObjectSetInteger(0, objNameStrength, OBJPROP_XDISTANCE, m_dashboardX + 150);
         ObjectSetInteger(0, objNameStrength, OBJPROP_YDISTANCE, yPos);
         ObjectSetInteger(0, objNameStrength, OBJPROP_COLOR, COLOR_TEXT);
         ObjectSetInteger(0, objNameStrength, OBJPROP_FONTSIZE, m_dashboardFontSize);
         ObjectSetInteger(0, objNameStrength, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, objNameStrength, OBJPROP_HIDDEN, true);
         ObjectSetString(0, objNameStrength, OBJPROP_TEXT, IntegerToString(signal.strength) + "/10");
         
         // Entry
         string objNameEntry = m_dashboardObjectPrefix + "Signal" + IntegerToString(i) + "Entry";
         if(ObjectFind(0, objNameEntry) < 0)
         {
            ObjectCreate(0, objNameEntry, OBJ_LABEL, 0, 0, 0);
         }
         ObjectSetInteger(0, objNameEntry, OBJPROP_XDISTANCE, m_dashboardX + 220);
         ObjectSetInteger(0, objNameEntry, OBJPROP_YDISTANCE, yPos);
         ObjectSetInteger(0, objNameEntry, OBJPROP_COLOR, COLOR_TEXT);
         ObjectSetInteger(0, objNameEntry, OBJPROP_FONTSIZE, m_dashboardFontSize);
         ObjectSetInteger(0, objNameEntry, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, objNameEntry, OBJPROP_HIDDEN, true);
         ObjectSetString(0, objNameEntry, OBJPROP_TEXT, 
                         DoubleToString(signal.entryPrice, (int)SymbolInfoInteger(signal.symbol, SYMBOL_DIGITS)));
         
         // Time
         string objNameTime = m_dashboardObjectPrefix + "Signal" + IntegerToString(i) + "Time";
         if(ObjectFind(0, objNameTime) < 0)
         {
            ObjectCreate(0, objNameTime, OBJ_LABEL, 0, 0, 0);
         }
         ObjectSetInteger(0, objNameTime, OBJPROP_XDISTANCE, m_dashboardX + 290);
         ObjectSetInteger(0, objNameTime, OBJPROP_YDISTANCE, yPos);
         ObjectSetInteger(0, objNameTime, OBJPROP_COLOR, COLOR_TEXT);
         ObjectSetInteger(0, objNameTime, OBJPROP_FONTSIZE, m_dashboardFontSize);
         ObjectSetInteger(0, objNameTime, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, objNameTime, OBJPROP_HIDDEN, true);
         ObjectSetString(0, objNameTime, OBJPROP_TEXT, TimeToString(signal.time, TIME_MINUTES));
      }
   }
   
   // Clear dashboard signals
   void ClearDashboardSignals()
   {
      for(int i = 0; i < m_maxSignals; i++)
      {
         string objPrefixes[] = {"Symbol", "Direction", "Strength", "Entry", "Time"};
         
         for(int j = 0; j < ArraySize(objPrefixes); j++)
         {
            string objName = m_dashboardObjectPrefix + "Signal" + IntegerToString(i) + objPrefixes[j];
            if(ObjectFind(0, objName) >= 0)
            {
               ObjectDelete(0, objName);
            }
         }
      }
   }

public:
   // Constructor
   UIManager()
   {
      m_config = NULL;
      m_dashboardObjectPrefix = "SignalBot_Dashboard_";
      m_maxSignals = 10;
      m_signalCount = 0;
      ArrayResize(m_signals, m_maxSignals);
   }
   
   // Initialize the UI manager
   bool Initialize(Configuration* config)
   {
      if(config == NULL) return false;
      
      m_config = config;
      return true;
   }
   
   // Create dashboard
   void CreateDashboard(int x, int y, int fontSize)
   {
      m_dashboardX = x;
      m_dashboardY = y;
      m_dashboardFontSize = fontSize;
      
      CreateDashboardBackground();
      CreateDashboardTitle();
      CreateDashboardHeaders();
   }
   
   // Destroy dashboard
   void DestroyDashboard()
   {
      // Delete all dashboard objects
      ObjectsDeleteAll(0, m_dashboardObjectPrefix);
   }
   
   // Update dashboard
   void UpdateDashboard()
   {
      CreateDashboardBackground();
      UpdateDashboardSignals();
   }
   
   // Add signal to dashboard
   void AddSignalToDashboard(string symbol, SignalInfo &signal, TradeParameters &params)
   {
      // Check if signal already exists for this symbol
      for(int i = 0; i < m_signalCount; i++)
      {
         if(m_signals[i].symbol == symbol)
         {
            // Update existing signal
            m_signals[i].direction = signal.direction;
            m_signals[i].strength = signal.strength;
            m_signals[i].reason = signal.reason;
            m_signals[i].time = signal.time;
            m_signals[i].entryPrice = params.entryPrice;
            m_signals[i].stopLoss = params.stopLoss;
            m_signals[i].takeProfit = params.takeProfit;
            m_signals[i].lotSize = params.lotSize;
            return;
         }
      }
      
      // Add new signal if we haven't reached the maximum
      if(m_signalCount < m_maxSignals)
      {
         m_signals[m_signalCount].symbol = symbol;
         m_signals[m_signalCount].direction = signal.direction;
         m_signals[m_signalCount].strength = signal.strength;
         m_signals[m_signalCount].reason = signal.reason;
         m_signals[m_signalCount].time = signal.time;
         m_signals[m_signalCount].entryPrice = params.entryPrice;
         m_signals[m_signalCount].stopLoss = params.stopLoss;
         m_signals[m_signalCount].takeProfit = params.takeProfit;
         m_signals[m_signalCount].lotSize = params.lotSize;
         m_signalCount++;
      }
      else
      {
         // Find the weakest or oldest signal to replace
         int indexToReplace = 0;
         int minStrength = m_signals[0].strength;
         datetime oldestTime = m_signals[0].time;
         
         for(int i = 1; i < m_signalCount; i++)
         {
            if(m_signals[i].strength < minStrength)
            {
               minStrength = m_signals[i].strength;
               indexToReplace = i;
            }
            else if(m_signals[i].strength == minStrength && m_signals[i].time < oldestTime)
            {
               oldestTime = m_signals[i].time;
               indexToReplace = i;
            }
         }
         
         // Replace the signal
         m_signals[indexToReplace].symbol = symbol;
         m_signals[indexToReplace].direction = signal.direction;
         m_signals[indexToReplace].strength = signal.strength;
         m_signals[indexToReplace].reason = signal.reason;
         m_signals[indexToReplace].time = signal.time;
         m_signals[indexToReplace].entryPrice = params.entryPrice;
         m_signals[indexToReplace].stopLoss = params.stopLoss;
         m_signals[indexToReplace].takeProfit = params.takeProfit;
         m_signals[indexToReplace].lotSize = params.lotSize;
      }
   }
   
   // Clear all signals
   void ClearSignals()
   {
      m_signalCount = 0;
      ArrayFree(m_signals);
      ArrayResize(m_signals, m_maxSignals);
   }
};
