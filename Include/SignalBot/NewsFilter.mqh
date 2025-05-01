//+------------------------------------------------------------------+
//|                                                  NewsFilter.mqh |
//|                        Copyright 2023, Your Company               |
//|                                       https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include "Constants.mqh"
#include "Configuration.mqh"

// News event structure
struct NewsEvent
{
   string currency;       // Currency affected (e.g., "USD", "EUR")
   string title;          // News title
   datetime time;         // News release time
   ENUM_NEWS_IMPORTANCE importance; // News importance
};

//+------------------------------------------------------------------+
//| Class to filter trades based on economic news events              |
//+------------------------------------------------------------------+
class NewsFilter
{
private:
   Configuration* m_config;
   
   // Array of upcoming news events
   NewsEvent m_upcomingEvents[];
   datetime m_lastNewsUpdate;
   
   // Time window around news events (minutes)
   int m_minutesBefore;
   int m_minutesAfter;
   
   // Update news events data
   bool UpdateNewsEvents()
   {
      // In a full implementation, this would connect to a news API
      // or parse an economic calendar
      // For this simplified version, we'll add some sample events
      
      // Only update once per hour
      datetime currentTime = TimeCurrent();
      if(currentTime - m_lastNewsUpdate < 3600) // 1 hour
      {
         return true; // Use cached data
      }
      
      m_lastNewsUpdate = currentTime;
      
      // Clear existing events
      ArrayFree(m_upcomingEvents);
      
      // For demonstration, add some sample news events
      // In a real implementation, these would come from an external source
      
      // Add events for today and the next few days
      datetime today = StringToTime(TimeToString(currentTime, TIME_DATE));
      
      // Add sample NFP release (first Friday of the month)
      datetime firstDay = today;
      
      // In MT5, we use MqlDateTime structure instead of TimeXXX functions
      MqlDateTime firstDay_struct;
      TimeToStruct(firstDay, firstDay_struct);
      
      // Find first Friday (day_of_week = 5 in MqlDateTime)
      while(firstDay_struct.day_of_week != 5) // Friday
      {
         firstDay += 86400; // Add 1 day
         TimeToStruct(firstDay, firstDay_struct);
      }
      
      // Check if it's past the first week
      if(firstDay_struct.day > 7) 
      {
         // Go to next month
         datetime nextMonth = today;
         MqlDateTime nextMonth_struct;
         TimeToStruct(nextMonth, nextMonth_struct);
         int currentMonth = nextMonth_struct.mon;
         
         while(nextMonth_struct.mon == currentMonth)
         {
            nextMonth += 86400; // Add 1 day
            TimeToStruct(nextMonth, nextMonth_struct);
         }
         
         // Find first Friday of next month
         firstDay = nextMonth;
         TimeToStruct(firstDay, firstDay_struct);
         
         while(firstDay_struct.day_of_week != 5) // Friday
         {
            firstDay += 86400; // Add 1 day
            TimeToStruct(firstDay, firstDay_struct);
         }
      }
      
      // NFP release at 8:30 AM EST
      datetime nfpTime = firstDay + 8 * 3600 + 30 * 60; // 8:30 AM
      
      AddNewsEvent("USD", "Non-Farm Payrolls", nfpTime, NEWS_IMPORTANCE_HIGH);
      
      // Add FOMC meeting (just an example, not the actual schedule)
      datetime fomc = today + 86400 * 15; // ~15 days from now
      fomc += 14 * 3600; // 2 PM EST
      
      AddNewsEvent("USD", "FOMC Statement", fomc, NEWS_IMPORTANCE_HIGH);
      
      // Add ECB meeting
      datetime ecb = today + 86400 * 7; // ~7 days from now
      ecb += 13 * 3600 + 45 * 60; // 1:45 PM Central European Time
      
      AddNewsEvent("EUR", "ECB Interest Rate Decision", ecb, NEWS_IMPORTANCE_HIGH);
      
      // Add a medium importance event
      datetime retail = today + 86400 * 3; // 3 days from now
      retail += 13 * 3600; // 1 PM
      
      AddNewsEvent("USD", "Retail Sales m/m", retail, NEWS_IMPORTANCE_MEDIUM);
      
      // Add a low importance event
      datetime speech = today + 86400; // Tomorrow
      speech += 10 * 3600; // 10 AM
      
      AddNewsEvent("GBP", "MPC Member Speech", speech, NEWS_IMPORTANCE_LOW);
      
      return true;
   }
   
   // Add a news event to the array
   void AddNewsEvent(string currency, string title, datetime time, ENUM_NEWS_IMPORTANCE importance)
   {
      int count = ArraySize(m_upcomingEvents);
      ArrayResize(m_upcomingEvents, count + 1);
      
      m_upcomingEvents[count].currency = currency;
      m_upcomingEvents[count].title = title;
      m_upcomingEvents[count].time = time;
      m_upcomingEvents[count].importance = importance;
   }
   
   // Check if symbol is affected by a currency
   bool IsSymbolAffectedByCurrency(string symbol, string currency)
   {
      // Convert to uppercase (in MT5 we use StringToUpper)
      string curr = StringToUpper(currency);
      
      // Check if currency is part of the symbol
      if(StringFind(symbol, curr) >= 0)
      {
         return true;
      }
      
      return false;
   }
   
   // Get base and quote currencies from symbol
   void GetSymbolCurrencies(string symbol, string &baseCurrency, string &quoteCurrency)
   {
      baseCurrency = "";
      quoteCurrency = "";
      
      int len = StringLen(symbol);
      
      // Most forex pairs are 6 characters (EURUSD, GBPJPY, etc.)
      if(len == 6)
      {
         baseCurrency = StringSubstr(symbol, 0, 3);
         quoteCurrency = StringSubstr(symbol, 3, 3);
      }
      // Some exotic pairs might be different
      else if(len == 7 && symbol == "EURTRY")
      {
         baseCurrency = "EUR";
         quoteCurrency = "TRY";
      }
      // For other symbols, try to determine the currencies
      else
      {
         // This is a simplified logic and may not work for all symbols
         string commonCurrencies[] = {"USD", "EUR", "GBP", "JPY", "AUD", "NZD", "CAD", "CHF", "TRY"};
         
         for(int i = 0; i < ArraySize(commonCurrencies); i++)
         {
            string curr = commonCurrencies[i];
            if(StringFind(symbol, curr) == 0)
            {
               baseCurrency = curr;
               int baseLen = StringLen(curr);
               if(len > baseLen)
               {
                  quoteCurrency = StringSubstr(symbol, baseLen, len - baseLen);
               }
               break;
            }
         }
      }
   }

public:
   // Constructor
   NewsFilter()
   {
      m_config = NULL;
      m_lastNewsUpdate = 0;
      m_minutesBefore = 30; // Default: 30 minutes before news
      m_minutesAfter = 30;  // Default: 30 minutes after news
   }
   
   // Initialize the news filter
   bool Initialize(Configuration* config)
   {
      if(config == NULL) return false;
      
      m_config = config;
      return UpdateNewsEvents();
   }
   
   // Check if a symbol has high-impact news at the current time
   bool IsHighImpactNewsTime(string symbol)
   {
      // Skip if news filter is disabled
      if(!m_config.GetEnableNewsFilter()) return false;
      
      // Update news events if needed
      UpdateNewsEvents();
      
      // Get minimum news importance to filter
      ENUM_NEWS_IMPORTANCE minImportance = m_config.GetMinNewsImportance();
      
      // Get base and quote currencies
      string baseCurrency, quoteCurrency;
      GetSymbolCurrencies(symbol, baseCurrency, quoteCurrency);
      
      // Get current time
      datetime currentTime = TimeCurrent();
      
      // Check each upcoming event
      for(int i = 0; i < ArraySize(m_upcomingEvents); i++)
      {
         NewsEvent event = m_upcomingEvents[i];
         
         // Skip if importance is lower than configured minimum
         if(event.importance < minImportance) continue;
         
         // Check if event affects this symbol
         if(!IsSymbolAffectedByCurrency(symbol, event.currency) && 
            event.currency != baseCurrency && event.currency != quoteCurrency)
         {
            continue;
         }
         
         // Check if current time is within the news window
         if(currentTime >= event.time - m_minutesBefore * 60 && 
            currentTime <= event.time + m_minutesAfter * 60)
         {
            return true;
         }
      }
      
      return false;
   }
   
   // Get the closest news event for a symbol
   bool GetNextNewsEvent(string symbol, NewsEvent &event)
   {
      // Update news events if needed
      UpdateNewsEvents();
      
      // Get base and quote currencies
      string baseCurrency, quoteCurrency;
      GetSymbolCurrencies(symbol, baseCurrency, quoteCurrency);
      
      // Get current time
      datetime currentTime = TimeCurrent();
      
      // Find the closest upcoming event
      datetime closestTime = D'2099.12.31 23:59:59';
      bool found = false;
      
      // Check each upcoming event
      for(int i = 0; i < ArraySize(m_upcomingEvents); i++)
      {
         // Check if event affects this symbol
         if(!IsSymbolAffectedByCurrency(symbol, m_upcomingEvents[i].currency) && 
            m_upcomingEvents[i].currency != baseCurrency && m_upcomingEvents[i].currency != quoteCurrency)
         {
            continue;
         }
         
         // Check if event is in the future
         if(m_upcomingEvents[i].time > currentTime && m_upcomingEvents[i].time < closestTime)
         {
            closestTime = m_upcomingEvents[i].time;
            event = m_upcomingEvents[i];
            found = true;
         }
      }
      
      return found;
   }
   
   // Set the news window times
   void SetNewsWindow(int minutesBefore, int minutesAfter)
   {
      m_minutesBefore = minutesBefore;
      m_minutesAfter = minutesAfter;
   }
   
   // Get all upcoming news events for a symbol
   int GetUpcomingEvents(string symbol, NewsEvent &events[], int maxEvents = 5)
   {
      // Update news events if needed
      UpdateNewsEvents();
      
      // Get base and quote currencies
      string baseCurrency, quoteCurrency;
      GetSymbolCurrencies(symbol, baseCurrency, quoteCurrency);
      
      // Get current time
      datetime currentTime = TimeCurrent();
      
      // Clear events array
      ArrayFree(events);
      int count = 0;
      
      // Get minimum news importance to filter
      ENUM_NEWS_IMPORTANCE minImportance = m_config.GetMinNewsImportance();
      
      // First, collect all relevant events
      NewsEvent tempEvents[];
      int tempCount = 0;
      
      for(int i = 0; i < ArraySize(m_upcomingEvents); i++)
      {
         // Skip if importance is lower than configured minimum
         if(m_upcomingEvents[i].importance < minImportance) continue;
         
         // Check if event affects this symbol
         if(!IsSymbolAffectedByCurrency(symbol, m_upcomingEvents[i].currency) && 
            m_upcomingEvents[i].currency != baseCurrency && m_upcomingEvents[i].currency != quoteCurrency)
         {
            continue;
         }
         
         // Check if event is in the future
         if(m_upcomingEvents[i].time > currentTime)
         {
            ArrayResize(tempEvents, tempCount + 1);
            tempEvents[tempCount] = m_upcomingEvents[i];
            tempCount++;
         }
      }
      
      // Sort by time (bubble sort for simplicity)
      for(int i = 0; i < tempCount - 1; i++)
      {
         for(int j = 0; j < tempCount - i - 1; j++)
         {
            if(tempEvents[j].time > tempEvents[j+1].time)
            {
               NewsEvent temp = tempEvents[j];
               tempEvents[j] = tempEvents[j+1];
               tempEvents[j+1] = temp;
            }
         }
      }
      
      // Copy top N events
      int resultCount = MathMin(maxEvents, tempCount);
      ArrayResize(events, resultCount);
      
      for(int i = 0; i < resultCount; i++)
      {
         events[i] = tempEvents[i];
      }
      
      return resultCount;
   }
   
   // Format news event for display
   string FormatNewsEvent(NewsEvent &event)
   {
      string importance = "";
      switch(event.importance)
      {
         case NEWS_IMPORTANCE_LOW:
            importance = "Low";
            break;
         case NEWS_IMPORTANCE_MEDIUM:
            importance = "Medium";
            break;
         case NEWS_IMPORTANCE_HIGH:
            importance = "High";
            break;
      }
      
      string result = TimeToString(event.time, TIME_DATE|TIME_MINUTES) + " ";
      result += event.currency + " " + event.title + " (";
      result += importance + " Impact)";
      
      return result;
   }
};
