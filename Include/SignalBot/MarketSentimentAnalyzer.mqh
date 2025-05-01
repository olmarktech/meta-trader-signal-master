//+------------------------------------------------------------------+
//|                                     MarketSentimentAnalyzer.mqh |
//|                        Copyright 2025, Signal Bot                |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Signal Bot"
#property link      ""
#property version   "1.00"
#property strict

#include "Constants.mqh"
#include "Configuration.mqh"

//+------------------------------------------------------------------+
//| Class to analyze market sentiment from various sources            |
//+------------------------------------------------------------------+
class MarketSentimentAnalyzer
{
private:
   Configuration* m_config;
   
   // Sentiment data structure
   struct SentimentData
   {
      string symbol;
      datetime lastUpdate;
      
      // Retail sentiment
      double retailBullishPercent;
      double retailBearishPercent;
      int retailPositionsVolume;
      
      // Institutional sentiment
      double institutionalBullishPercent;
      double institutionalBearishPercent;
      double institutionalPositioningScore;
      
      // Social sentiment
      double socialBullishScore;
      double socialBearishScore;
      double socialSentimentVolume;
      
      // News sentiment
      double newsBullishScore;
      double newsBearishScore;
      int newsArticleCount;
      
      // Options sentiment
      double putCallRatio;
      double volatilitySkew;
      
      // Commitment of Traders
      double commercialNetPositions;
      double nonCommercialNetPositions;
      
      // Overall sentiment
      double combinedBullishScore;
      double combinedBearishScore;
      
      // Sentiment shifts
      double weeklyShift;
      double dailyShift;
      bool isShifting;
      bool isShiftingBullish;
      
      // Extreme sentiment flags
      bool isBullishExtreme;
      bool isBearishExtreme;
      
      // Contrarian signals
      bool hasContrarySignal;
      bool isContraryBullish;
      double contraryStrength;
      
      // Retail positioning
      bool isRetailCrowded;
      bool isRetailCrowdedBullish;
   };
   
   // Cache of sentiment data for different symbols
   SentimentData m_sentimentCache[];
   int m_symbolCount;
   
   // Fetch and update sentiment data for a symbol
   bool UpdateSentimentData(string symbol)
   {
      // Find symbol in cache or add new entry
      int index = -1;
      for(int i = 0; i < m_symbolCount; i++)
      {
         if(m_sentimentCache[i].symbol == symbol)
         {
            index = i;
            break;
         }
      }
      
      if(index == -1)
      {
         // Add new symbol to cache
         m_symbolCount++;
         ArrayResize(m_sentimentCache, m_symbolCount);
         index = m_symbolCount - 1;
         m_sentimentCache[index].symbol = symbol;
      }
      
      // Check if data needs update (older than 1 hour)
      datetime currentTime = TimeCurrent();
      if(currentTime - m_sentimentCache[index].lastUpdate < 3600 && 
         m_sentimentCache[index].lastUpdate > 0)
      {
         // Data is recent enough, no need to update
         return true;
      }
      
      // In a real implementation, these would fetch from actual sources
      // Here we simulate based on price action and common patterns
      
      // Update retail sentiment based on the symbol
      if(symbol == "EURUSD")
      {
         m_sentimentCache[index].retailBullishPercent = 45.0;
         m_sentimentCache[index].retailBearishPercent = 55.0;
      }
      else if(symbol == "GBPUSD")
      {
         m_sentimentCache[index].retailBullishPercent = 39.0;
         m_sentimentCache[index].retailBearishPercent = 61.0;
      }
      else if(symbol == "USDJPY")
      {
         m_sentimentCache[index].retailBullishPercent = 65.0;
         m_sentimentCache[index].retailBearishPercent = 35.0;
      }
      else if(symbol == "XAUUSD") // Gold
      {
         m_sentimentCache[index].retailBullishPercent = 72.0;
         m_sentimentCache[index].retailBearishPercent = 28.0;
      }
      else
      {
         // For other symbols, use a formula based on recent price action
         double recentMove = CalculateRecentPriceMove(symbol);
         if(recentMove > 0)
         {
            // Retail often chases trends, so more bullish during uptrends
            m_sentimentCache[index].retailBullishPercent = 50.0 + MathMin(30.0, recentMove * 100.0);
            m_sentimentCache[index].retailBearishPercent = 100.0 - m_sentimentCache[index].retailBullishPercent;
         }
         else
         {
            m_sentimentCache[index].retailBearishPercent = 50.0 + MathMin(30.0, MathAbs(recentMove) * 100.0);
            m_sentimentCache[index].retailBullishPercent = 100.0 - m_sentimentCache[index].retailBearishPercent;
         }
      }
      
      // Set retail positions volume
      m_sentimentCache[index].retailPositionsVolume = (int)(1000 + MathRand() % 2000);
      
      // Update institutional sentiment
      // Often contrarian to retail, but depends on the asset
      m_sentimentCache[index].institutionalBullishPercent = 100.0 - m_sentimentCache[index].retailBullishPercent * 0.7;
      m_sentimentCache[index].institutionalBearishPercent = 100.0 - m_sentimentCache[index].retailBearishPercent * 0.7;
      
      // Normalize
      double totalInst = m_sentimentCache[index].institutionalBullishPercent + m_sentimentCache[index].institutionalBearishPercent;
      m_sentimentCache[index].institutionalBullishPercent = m_sentimentCache[index].institutionalBullishPercent * 100.0 / totalInst;
      m_sentimentCache[index].institutionalBearishPercent = m_sentimentCache[index].institutionalBearishPercent * 100.0 / totalInst;
      
      // Social sentiment - often more volatile than retail
      double socialRandomizer = 0.7 + 0.6 * ((double)MathRand() / 32767.0); // 0.7-1.3 randomizer
      m_sentimentCache[index].socialBullishScore = m_sentimentCache[index].retailBullishPercent * socialRandomizer / 100.0;
      m_sentimentCache[index].socialBearishScore = m_sentimentCache[index].retailBearishPercent * socialRandomizer / 100.0;
      m_sentimentCache[index].socialSentimentVolume = 500.0 + MathRand() % 1500;
      
      // News sentiment - slightly related to institutional sentiment
      m_sentimentCache[index].newsBullishScore = m_sentimentCache[index].institutionalBullishPercent * (0.8 + 0.4 * ((double)MathRand() / 32767.0)) / 100.0;
      m_sentimentCache[index].newsBearishScore = m_sentimentCache[index].institutionalBearishPercent * (0.8 + 0.4 * ((double)MathRand() / 32767.0)) / 100.0;
      m_sentimentCache[index].newsArticleCount = 10 + MathRand() % 40;
      
      // Options sentiment
      if(symbol == "EURUSD" || symbol == "GBPUSD" || symbol == "USDJPY" || symbol == "XAUUSD")
      {
         // Typical ranges for put/call ratio: 0.7-1.5
         m_sentimentCache[index].putCallRatio = 0.7 + ((double)MathRand() / 32767.0) * 0.8;
         
         // Volatility skew: negative values suggest bearish sentiment
         m_sentimentCache[index].volatilitySkew = -0.3 + ((double)MathRand() / 32767.0) * 0.6;
      }
      else
      {
         // For other pairs, use default values
         m_sentimentCache[index].putCallRatio = 1.0;
         m_sentimentCache[index].volatilitySkew = 0.0;
      }
      
      // COT data (only relevant for major currencies)
      if(symbol == "EURUSD" || symbol == "GBPUSD" || symbol == "USDJPY")
      {
         double cotRandomizer = -100000.0 + ((double)MathRand() / 32767.0) * 200000.0;
         m_sentimentCache[index].commercialNetPositions = cotRandomizer;
         m_sentimentCache[index].nonCommercialNetPositions = -cotRandomizer * 0.8;
      }
      else
      {
         m_sentimentCache[index].commercialNetPositions = 0.0;
         m_sentimentCache[index].nonCommercialNetPositions = 0.0;
      }
      
      // Calculate combined sentiment
      CalculateCombinedSentiment(index);
      
      // Calculate sentiment shifts
      CalculateSentimentShifts(index);
      
      // Check for extreme sentiment
      CheckExtremeSentiment(index);
      
      // Check for contrarian signals
      CheckContrarySignals(index);
      
      // Check for retail crowding
      CheckRetailCrowding(index);
      
      // Update timestamp
      m_sentimentCache[index].lastUpdate = currentTime;
      
      return true;
   }
   
   // Calculate recent price movement percentage
   double CalculateRecentPriceMove(string symbol)
   {
      double currentPrice = iClose(symbol, PERIOD_D1, 0);
      double previousPrice = iClose(symbol, PERIOD_D1, 5); // 5 days ago
      
      if(previousPrice == 0.0) return 0.0;
      
      return (currentPrice - previousPrice) / previousPrice;
   }
   
   // Calculate combined sentiment from all sources
   void CalculateCombinedSentiment(int index)
   {
      // Weights for different sentiment sources
      double retailWeight = 0.20;
      double institutionalWeight = 0.30;
      double socialWeight = 0.10;
      double newsWeight = 0.15;
      double optionsWeight = 0.15;
      double cotWeight = 0.10;
      
      // Retail sentiment
      double retailBullish = m_sentimentCache[index].retailBullishPercent / 100.0;
      double retailBearish = m_sentimentCache[index].retailBearishPercent / 100.0;
      
      // Institutional sentiment
      double instBullish = m_sentimentCache[index].institutionalBullishPercent / 100.0;
      double instBearish = m_sentimentCache[index].institutionalBearishPercent / 100.0;
      
      // Other sentiment sources
      double socialBullish = m_sentimentCache[index].socialBullishScore;
      double socialBearish = m_sentimentCache[index].socialBearishScore;
      double newsBullish = m_sentimentCache[index].newsBullishScore;
      double newsBearish = m_sentimentCache[index].newsBearishScore;
      
      // Options sentiment
      double optionsBullish = (m_sentimentCache[index].putCallRatio < 1.0) ? 
                             (1.0 - m_sentimentCache[index].putCallRatio) : 0.0;
      double optionsBearish = (m_sentimentCache[index].putCallRatio > 1.0) ? 
                             (m_sentimentCache[index].putCallRatio - 1.0) : 0.0;
      
      // Normalize options sentiment
      if(optionsBullish > 0.3) optionsBullish = 0.3;
      if(optionsBearish > 0.5) optionsBearish = 0.5;
      optionsBullish = optionsBullish / 0.3;
      optionsBearish = optionsBearish / 0.5;
      
      // Add volatility skew influence
      if(m_sentimentCache[index].volatilitySkew > 0)
      {
         optionsBullish += m_sentimentCache[index].volatilitySkew;
         if(optionsBullish > 1.0) optionsBullish = 1.0;
      }
      else if(m_sentimentCache[index].volatilitySkew < 0)
      {
         optionsBearish += MathAbs(m_sentimentCache[index].volatilitySkew);
         if(optionsBearish > 1.0) optionsBearish = 1.0;
      }
      
      // COT sentiment
      double cotBullish = 0.5, cotBearish = 0.5;
      if(m_sentimentCache[index].nonCommercialNetPositions > 0)
      {
         double netPositionStrength = MathMin(1.0, m_sentimentCache[index].nonCommercialNetPositions / 100000.0);
         cotBullish = 0.5 + (netPositionStrength * 0.5);
         cotBearish = 1.0 - cotBullish;
      }
      else if(m_sentimentCache[index].nonCommercialNetPositions < 0)
      {
         double netPositionStrength = MathMin(1.0, MathAbs(m_sentimentCache[index].nonCommercialNetPositions) / 100000.0);
         cotBearish = 0.5 + (netPositionStrength * 0.5);
         cotBullish = 1.0 - cotBearish;
      }
      
      // Calculate weighted sentiment
      m_sentimentCache[index].combinedBullishScore = 
         retailBullish * retailWeight +
         instBullish * institutionalWeight +
         socialBullish * socialWeight +
         newsBullish * newsWeight +
         optionsBullish * optionsWeight +
         cotBullish * cotWeight;
         
      m_sentimentCache[index].combinedBearishScore = 
         retailBearish * retailWeight +
         instBearish * institutionalWeight +
         socialBearish * socialWeight +
         newsBearish * newsWeight +
         optionsBearish * optionsWeight +
         cotBearish * cotWeight;
         
      // Normalize
      double total = m_sentimentCache[index].combinedBullishScore + m_sentimentCache[index].combinedBearishScore;
      if(total > 0)
      {
         m_sentimentCache[index].combinedBullishScore /= total;
         m_sentimentCache[index].combinedBearishScore /= total;
      }
   }
   
   // Calculate sentiment shifts
   void CalculateSentimentShifts(int index)
   {
      // In a real implementation, this would compare historical sentiment
      // Here we simulate with some randomized shifts
      
      // Daily shift - between -0.1 and 0.1
      m_sentimentCache[index].dailyShift = -0.1 + ((double)MathRand() / 32767.0) * 0.2;
      
      // Weekly shift - between -0.2 and 0.2
      m_sentimentCache[index].weeklyShift = -0.2 + ((double)MathRand() / 32767.0) * 0.4;
      
      // Set shifting flags
      m_sentimentCache[index].isShifting = (MathAbs(m_sentimentCache[index].weeklyShift) > 0.1);
      m_sentimentCache[index].isShiftingBullish = (m_sentimentCache[index].weeklyShift > 0);
   }
   
   // Check for extreme sentiment
   void CheckExtremeSentiment(int index)
   {
      // Retail sentiment is often considered extreme beyond 70/30 split
      m_sentimentCache[index].isBullishExtreme = (m_sentimentCache[index].retailBullishPercent > 70.0);
      m_sentimentCache[index].isBearishExtreme = (m_sentimentCache[index].retailBearishPercent > 70.0);
      
      // Combined sentiment can also indicate extremes
      if(m_sentimentCache[index].combinedBullishScore > 0.75)
         m_sentimentCache[index].isBullishExtreme = true;
      
      if(m_sentimentCache[index].combinedBearishScore > 0.75)
         m_sentimentCache[index].isBearishExtreme = true;
   }
   
   // Check for contrarian signals
   void CheckContrarySignals(int index)
   {
      // Contrarian signals emerge from extreme sentiment + shift in the other direction
      bool hasExtremeRetail = (m_sentimentCache[index].retailBullishPercent > 75.0 || 
                             m_sentimentCache[index].retailBearishPercent > 75.0);
      
      bool hasRetailShift = (MathAbs(m_sentimentCache[index].dailyShift) > 0.05);
      
      bool isRetailShiftOppositeToExtreme = false;
      if(m_sentimentCache[index].retailBullishPercent > 75.0 && m_sentimentCache[index].dailyShift < 0)
         isRetailShiftOppositeToExtreme = true;
      else if(m_sentimentCache[index].retailBearishPercent > 75.0 && m_sentimentCache[index].dailyShift > 0)
         isRetailShiftOppositeToExtreme = true;
      
      // Set contrarian signals
      m_sentimentCache[index].hasContrarySignal = (hasExtremeRetail && hasRetailShift && isRetailShiftOppositeToExtreme);
      
      if(m_sentimentCache[index].hasContrarySignal)
      {
         m_sentimentCache[index].isContraryBullish = (m_sentimentCache[index].retailBearishPercent > 75.0);
         m_sentimentCache[index].contraryStrength = MathAbs(m_sentimentCache[index].dailyShift) * 2.0;
         if(m_sentimentCache[index].contraryStrength > 1.0)
            m_sentimentCache[index].contraryStrength = 1.0;
      }
      else
      {
         m_sentimentCache[index].isContraryBullish = false;
         m_sentimentCache[index].contraryStrength = 0.0;
      }
   }
   
   // Check for retail crowding
   void CheckRetailCrowding(int index)
   {
      // Retail is considered crowded when positions are heavily skewed in one direction
      // and volume is above average
      bool isHighVolume = (m_sentimentCache[index].retailPositionsVolume > 2000);
      bool isSkewed = (m_sentimentCache[index].retailBullishPercent > 65.0 || 
                     m_sentimentCache[index].retailBearishPercent > 65.0);
      
      m_sentimentCache[index].isRetailCrowded = (isHighVolume && isSkewed);
      
      if(m_sentimentCache[index].isRetailCrowded)
      {
         m_sentimentCache[index].isRetailCrowdedBullish = (m_sentimentCache[index].retailBullishPercent > 65.0);
      }
   }
   
   // Get sentiment index for a symbol
   int GetSentimentIndex(string symbol)
   {
      for(int i = 0; i < m_symbolCount; i++)
      {
         if(m_sentimentCache[i].symbol == symbol)
         {
            return i;
         }
      }
      
      // Sentiment not found, update it
      UpdateSentimentData(symbol);
      
      // Now find the index (should be the last one)
      return m_symbolCount - 1;
   }
   
public:
   // Constructor
   MarketSentimentAnalyzer()
   {
      m_config = NULL;
      m_symbolCount = 0;
      ArrayResize(m_sentimentCache, 0);
   }
   
   // Initialize with configuration
   bool Initialize(Configuration* config)
   {
      if(config == NULL)
         return false;
         
      m_config = config;
      return true;
   }
   
   // Get retail sentiment for a symbol
   bool GetRetailSentiment(string symbol, double &bullishPercent, double &bearishPercent)
   {
      // Update sentiment data if needed
      if(!UpdateSentimentData(symbol))
         return false;
         
      int index = GetSentimentIndex(symbol);
      if(index < 0 || index >= m_symbolCount)
         return false;
         
      bullishPercent = m_sentimentCache[index].retailBullishPercent;
      bearishPercent = m_sentimentCache[index].retailBearishPercent;
      
      return true;
   }
   
   // Get institutional sentiment for a symbol
   bool GetInstitutionalSentiment(string symbol, double &bullishPercent, double &bearishPercent)
   {
      // Update sentiment data if needed
      if(!UpdateSentimentData(symbol))
         return false;
         
      int index = GetSentimentIndex(symbol);
      if(index < 0 || index >= m_symbolCount)
         return false;
         
      bullishPercent = m_sentimentCache[index].institutionalBullishPercent;
      bearishPercent = m_sentimentCache[index].institutionalBearishPercent;
      
      return true;
   }
   
   // Get combined sentiment for a symbol
   bool GetCombinedSentiment(string symbol, double &bullishScore, double &bearishScore)
   {
      // Update sentiment data if needed
      if(!UpdateSentimentData(symbol))
         return false;
         
      int index = GetSentimentIndex(symbol);
      if(index < 0 || index >= m_symbolCount)
         return false;
         
      bullishScore = m_sentimentCache[index].combinedBullishScore;
      bearishScore = m_sentimentCache[index].combinedBearishScore;
      
      return true;
   }
   
   // Check if sentiment is extreme
   bool IsSentimentExtreme(string symbol, bool &isBullishExtreme, bool &isBearishExtreme)
   {
      // Update sentiment data if needed
      if(!UpdateSentimentData(symbol))
         return false;
         
      int index = GetSentimentIndex(symbol);
      if(index < 0 || index >= m_symbolCount)
         return false;
         
      isBullishExtreme = m_sentimentCache[index].isBullishExtreme;
      isBearishExtreme = m_sentimentCache[index].isBearishExtreme;
      
      return true;
   }
   
   // Detect sentiment shifts
   bool DetectSentimentShift(string symbol, bool &isShifting, bool &isShiftingBullish)
   {
      // Update sentiment data if needed
      if(!UpdateSentimentData(symbol))
         return false;
         
      int index = GetSentimentIndex(symbol);
      if(index < 0 || index >= m_symbolCount)
         return false;
         
      isShifting = m_sentimentCache[index].isShifting;
      isShiftingBullish = m_sentimentCache[index].isShiftingBullish;
      
      return true;
   }
   
   // Get contrary signals
   bool GetContrarySignal(string symbol, double &strength, bool &isBullish)
   {
      // Update sentiment data if needed
      if(!UpdateSentimentData(symbol))
         return false;
         
      int index = GetSentimentIndex(symbol);
      if(index < 0 || index >= m_symbolCount)
         return false;
         
      strength = m_sentimentCache[index].contraryStrength;
      isBullish = m_sentimentCache[index].isContraryBullish;
      
      return m_sentimentCache[index].hasContrarySignal;
   }
   
   // Check if retail positioning is crowded
   bool IsRetailCrowded(string symbol, bool &isCrowded, bool &isBullishCrowded)
   {
      // Update sentiment data if needed
      if(!UpdateSentimentData(symbol))
         return false;
         
      int index = GetSentimentIndex(symbol);
      if(index < 0 || index >= m_symbolCount)
         return false;
         
      isCrowded = m_sentimentCache[index].isRetailCrowded;
      isBullishCrowded = m_sentimentCache[index].isRetailCrowdedBullish;
      
      return true;
   }
   
   // Get a summary of the market sentiment
   string GetMarketSentimentSummary(string symbol)
   {
      // Update sentiment data if needed
      if(!UpdateSentimentData(symbol))
         return "Sentiment data unavailable";
         
      int index = GetSentimentIndex(symbol);
      if(index < 0 || index >= m_symbolCount)
         return "Sentiment data unavailable";
         
      // Create a descriptive summary based on the sentiment data
      string summary = "";
      
      // Describe the overall sentiment skew
      if(m_sentimentCache[index].combinedBullishScore > 0.65)
         summary = "Bullish Bias";
      else if(m_sentimentCache[index].combinedBearishScore > 0.65)
         summary = "Bearish Bias";
      else if(m_sentimentCache[index].combinedBullishScore > m_sentimentCache[index].combinedBearishScore)
         summary = "Slight Bullish Bias";
      else if(m_sentimentCache[index].combinedBearishScore > m_sentimentCache[index].combinedBullishScore)
         summary = "Slight Bearish Bias";
      else
         summary = "Neutral";
         
      // Add information about retail vs institutional sentiment
      if(m_sentimentCache[index].retailBullishPercent > 60.0 && 
         m_sentimentCache[index].institutionalBullishPercent < 40.0)
      {
         summary += ", Retail Bullish vs Institutional Bearish";
      }
      else if(m_sentimentCache[index].retailBearishPercent > 60.0 && 
              m_sentimentCache[index].institutionalBearishPercent < 40.0)
      {
         summary += ", Retail Bearish vs Institutional Bullish";
      }
      
      // Add contrarian signal if exists
      if(m_sentimentCache[index].hasContrarySignal && m_sentimentCache[index].contraryStrength > 0.3)
      {
         summary += ", Contrarian " + 
                   (m_sentimentCache[index].isContraryBullish ? "Bullish" : "Bearish") + 
                   " Signal";
      }
      
      // Add extreme sentiment if exists
      if(m_sentimentCache[index].isBullishExtreme)
         summary += ", Extremely Bullish Sentiment";
      else if(m_sentimentCache[index].isBearishExtreme)
         summary += ", Extremely Bearish Sentiment";
         
      // Add sentiment shift if significant
      if(m_sentimentCache[index].isShifting)
      {
         summary += ", Shifting " + 
                   (m_sentimentCache[index].isShiftingBullish ? "Bullish" : "Bearish");
      }
      
      return summary;
   }
};