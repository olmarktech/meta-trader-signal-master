//+------------------------------------------------------------------+
//|                                                       Utils.mqh |
//|                        Copyright 2023, Your Company               |
//|                                       https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include "Constants.mqh"

//+------------------------------------------------------------------+
//| Utility class for common functions                                |
//+------------------------------------------------------------------+
class Utils
{
public:
   // Calculate volatility of a symbol over N periods
   static double CalculateVolatility(string symbol, ENUM_TIMEFRAMES timeframe, int periods)
   {
      if(periods <= 1) return 0;
      
      double sum = 0;
      double avg = 0;
      double volatility = 0;
      
      // Get ATR for the period
      int atrHandle = iATR(symbol, timeframe, periods);
      if(atrHandle == INVALID_HANDLE)
      {
         Print("Failed to create ATR handle for ", symbol);
         return 0;
      }
      
      double atrValues[];
      if(CopyBuffer(atrHandle, 0, 0, 1, atrValues) <= 0)
      {
         Print("Failed to copy ATR values for ", symbol);
         IndicatorRelease(atrHandle);
         return 0;
      }
      
      IndicatorRelease(atrHandle);
      
      // Normalize ATR to percentage of price
      double currentPrice = (SymbolInfoDouble(symbol, SYMBOL_ASK) + SymbolInfoDouble(symbol, SYMBOL_BID)) / 2;
      volatility = atrValues[0] / currentPrice * 100.0;
      
      return volatility;
   }
   
   // Detect most volatile pairs from a list
   static int DetectVolatilePairs(string &volatilePairs[], int maxPairs = 5)
   {
      string allPairs[] = {"EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "USDCAD", "USDCHF", "NZDUSD", 
                          "EURJPY", "GBPJPY", "EURGBP", "AUDJPY", "EURAUD", "GBPAUD"};
                          
      int count = ArraySize(allPairs);
      double volatility[];
      ArrayResize(volatility, count);
      
      // Calculate volatility for each pair
      for(int i = 0; i < count; i++)
      {
         volatility[i] = CalculateVolatility(allPairs[i], PERIOD_H1, 14);
      }
      
      // Sort pairs by volatility (bubble sort for simplicity)
      for(int i = 0; i < count - 1; i++)
      {
         for(int j = 0; j < count - i - 1; j++)
         {
            if(volatility[j] < volatility[j+1])
            {
               // Swap volatility
               double tempVol = volatility[j];
               volatility[j] = volatility[j+1];
               volatility[j+1] = tempVol;
               
               // Swap pairs
               string tempPair = allPairs[j];
               allPairs[j] = allPairs[j+1];
               allPairs[j+1] = tempPair;
            }
         }
      }
      
      // Select top N pairs
      int resultCount = MathMin(maxPairs, count);
      ArrayResize(volatilePairs, resultCount);
      
      for(int i = 0; i < resultCount; i++)
      {
         volatilePairs[i] = allPairs[i];
      }
      
      return resultCount;
   }
   
   // Calculate distance between prices in pips
   static double CalculatePipDistance(string symbol, double price1, double price2)
   {
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double multiplier = (digits == 3 || digits == 5) ? 10 : 1;
      
      return MathAbs(price1 - price2) / (point * multiplier);
   }
   
   // Convert points to pips
   static double PointsToPips(string symbol, double points)
   {
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double multiplier = (digits == 3 || digits == 5) ? 10 : 1;
      
      return points / multiplier;
   }
   
   // Convert pips to points
   static double PipsToPoints(string symbol, double pips)
   {
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double multiplier = (digits == 3 || digits == 5) ? 10 : 1;
      
      return pips * multiplier;
   }
   
   // Convert pips to price
   static double PipsToPrice(string symbol, double pips)
   {
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double multiplier = (digits == 3 || digits == 5) ? 10 : 1;
      
      return pips * point * multiplier;
   }
   
   // Format price with proper digits
   static string FormatPrice(string symbol, double price)
   {
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      return DoubleToString(price, digits);
   }
   
   // Check if current time is within trading hours
   static bool IsWithinTradingHours(int startHour = 0, int startMinute = 0, int endHour = 23, int endMinute = 59)
   {
      datetime currentTime = TimeCurrent();
      MqlDateTime time_struct;
      TimeToStruct(currentTime, time_struct);
      
      int currentHour = time_struct.hour;
      int currentMinute = time_struct.min;
      
      int currentTimeMinutes = currentHour * 60 + currentMinute;
      int startTimeMinutes = startHour * 60 + startMinute;
      int endTimeMinutes = endHour * 60 + endMinute;
      
      if(startTimeMinutes <= endTimeMinutes)
      {
         // Normal case: startTime < endTime (e.g., 8:00 - 17:00)
         return (currentTimeMinutes >= startTimeMinutes && currentTimeMinutes <= endTimeMinutes);
      }
      else
      {
         // Overnight case: startTime > endTime (e.g., 22:00 - 6:00)
         return (currentTimeMinutes >= startTimeMinutes || currentTimeMinutes <= endTimeMinutes);
      }
   }
   
   // Check if day of week is a trading day
   static bool IsTradingDay(int day = -1)
   {
      if(day == -1)
      {
         datetime currentTime = TimeCurrent();
         MqlDateTime time_struct;
         TimeToStruct(currentTime, time_struct);
         day = time_struct.day_of_week;
      }
      
      // 0 = Sunday, 6 = Saturday
      return (day > 0 && day < 6);
   }
   
   // Check if chart symbol is in a list of symbols
   static bool IsSymbolInList(string symbol, string symbolsList)
   {
      string symbols[];
      int count = StringSplit(symbolsList, ',', symbols);
      
      for(int i = 0; i < count; i++)
      {
         string s = StringTrim(symbols[i]);
         if(s == symbol)
         {
            return true;
         }
      }
      
      return false;
   }
   
   // Load settings from a file
   static bool LoadSettingsFromFile(string filename, string &settings[])
   {
      if(!FileIsExist(filename))
      {
         Print("Settings file not found: ", filename);
         return false;
      }
      
      int handle = FileOpen(filename, FILE_READ|FILE_TXT);
      if(handle == INVALID_HANDLE)
      {
         Print("Failed to open settings file: ", filename, ", error: ", GetLastError());
         return false;
      }
      
      ArrayFree(settings);
      int count = 0;
      
      while(!FileIsEnding(handle))
      {
         string line = FileReadString(handle);
         if(line != "")
         {
            ArrayResize(settings, count + 1);
            settings[count] = line;
            count++;
         }
      }
      
      FileClose(handle);
      return true;
   }
   
   // Save settings to a file
   static bool SaveSettingsToFile(string filename, string &settings[])
   {
      int handle = FileOpen(filename, FILE_WRITE|FILE_TXT);
      if(handle == INVALID_HANDLE)
      {
         Print("Failed to open settings file for writing: ", filename, ", error: ", GetLastError());
         return false;
      }
      
      for(int i = 0; i < ArraySize(settings); i++)
      {
         FileWriteString(handle, settings[i] + "\n");
      }
      
      FileClose(handle);
      return true;
   }
   
   // Print debug message with timestamp
   static void DebugPrint(string message)
   {
      Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), ": ", message);
   }
   
   // Normalize price to tick size
   static double NormalizePrice(string symbol, double price)
   {
      double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      if(tickSize == 0) return price;
      
      return MathRound(price / tickSize) * tickSize;
   }
   
   // Calculate trading sessions overlap
   static bool IsSessionsOverlap(int session1Start, int session1End, int session2Start, int session2End)
   {
      // Convert all times to minutes for easy comparison
      
      // Check if sessions overlap
      if(session1Start <= session1End)
      {
         if(session2Start <= session2End)
         {
            // Both sessions are within the same day
            return (session1Start < session2End && session2Start < session1End);
         }
         else
         {
            // Session 2 crosses midnight
            return (session1Start < session2End || session2Start < session1End);
         }
      }
      else
      {
         // Session 1 crosses midnight
         if(session2Start <= session2End)
         {
            // Session 2 is within the same day
            return (session1Start < session2End || session2Start < session1End);
         }
         else
         {
            // Both sessions cross midnight - they always overlap
            return true;
         }
      }
   }
   
   // Check if RSI is diverging from price
   static bool IsRSIDivergence(string symbol, ENUM_TIMEFRAMES timeframe, bool bullish)
   {
      int rsiPeriod = 14; // Default RSI period
      
      // Create RSI indicator
      int rsiHandle = iRSI(symbol, timeframe, rsiPeriod, PRICE_CLOSE);
      if(rsiHandle == INVALID_HANDLE)
      {
         Print("Failed to create RSI handle for divergence check");
         return false;
      }
      
      // Copy RSI values
      double rsiValues[];
      if(CopyBuffer(rsiHandle, 0, 0, 3, rsiValues) <= 0)
      {
         Print("Failed to copy RSI values for divergence check");
         IndicatorRelease(rsiHandle);
         return false;
      }
      
      IndicatorRelease(rsiHandle);
      
      // Get price data
      double close[];
      if(CopyClose(symbol, timeframe, 0, 3, close) <= 0)
      {
         Print("Failed to copy price data for divergence check");
         return false;
      }
      
      // Check for bullish divergence
      if(bullish)
      {
         // Price makes lower lows but RSI makes higher lows
         return (close[1] < close[2] && rsiValues[1] > rsiValues[2]);
      }
      else
      {
         // Price makes higher highs but RSI makes lower highs
         return (close[1] > close[2] && rsiValues[1] < rsiValues[2]);
      }
   }
};
