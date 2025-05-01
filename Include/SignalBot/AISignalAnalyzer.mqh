//+------------------------------------------------------------------+
//|                                           AISignalAnalyzer.mqh |
//|                     Copyright 2025, Signal Bot                 |
//|                                                                 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Signal Bot"
#property link      ""
#property version   "1.00"
#property strict

#include "Constants.mqh"
#include "Configuration.mqh"
#include "IndicatorProcessor.mqh"

//+------------------------------------------------------------------+
//| Class to analyze signals using AI techniques                      |
//+------------------------------------------------------------------+
class AISignalAnalyzer
{
private:
   Configuration* m_config;
   IndicatorProcessor* m_indicatorProcessor;
   
   // AI model state
   double m_lastSignalConfidence;
   double m_lastSignalReliability;
   double m_lastMarketSuitability;
   
   // Market state
   struct MarketState
   {
      string symbol;
      double volatility;
      double trendStrength;
      double correlation;
      string condition;
      double conditionScore;
      bool supplyDemandConflict;
   };
   
   MarketState m_marketState;
   
   // Historical signals performance data
   int m_totalSignals;
   int m_successfulSignals;
   
   // Cache of price data for analysis
   double m_priceData[][6]; // [time][open,high,low,close,volume,volatility]
   
   // Initialize market state
   void InitializeMarketState(string symbol)
   {
      m_marketState.symbol = symbol;
      m_marketState.volatility = 0.0;
      m_marketState.trendStrength = 0.0;
      m_marketState.correlation = 0.0;
      m_marketState.condition = "Unknown";
      m_marketState.conditionScore = 0.0;
      m_marketState.supplyDemandConflict = false;
   }
   
   // Get current market volatility as a ratio relative to historical average
   double CalculateVolatility(string symbol, ENUM_TIMEFRAMES timeframe)
   {
      // Fixed parameter count for MT5 version of iATR
      int atrPeriod = 14;
      // In MT5, indicator functions return a handle rather than buffer values directly
      int atrHandle = iATR(symbol, timeframe, atrPeriod);
      
      if(atrHandle == INVALID_HANDLE) {
         Print("Error: Failed to create ATR indicator handle");
         return 1.0; // Return neutral value on error
      }
      
      double atrBuffer[];
      ArraySetAsSeries(atrBuffer, true);
      
      // Copy current ATR value
      if(CopyBuffer(atrHandle, 0, 0, 31, atrBuffer) <= 0) {
         Print("Error: Failed to copy ATR buffer data");
         IndicatorRelease(atrHandle);
         return 1.0; // Return neutral value on error
      }
      
      double currATR = atrBuffer[0];
      double avgATR = 0.0;
      
      // Get average ATR over the last 30 periods
      for(int i = 1; i <= 30; i++) {
         avgATR += atrBuffer[i];
      }
      avgATR /= 30.0;
      
      // Cleanup
      IndicatorRelease(atrHandle);
      
      // Avoid division by zero
      if(avgATR < 0.00001) avgATR = 0.00001;
      
      // Return volatility ratio
      return currATR / avgATR;
   }
   
   // Determine the trend strength and direction
   void AnalyzeTrend(string symbol, ENUM_TIMEFRAMES timeframe, double &strength, int &direction)
   {
      // Fixed parameter count for MT5 version of iADX
      int adxPeriod = 14;
      // In MT5, ADX returns a handle with multiple buffers
      int adxHandle = iADX(symbol, timeframe, adxPeriod);
      
      if(adxHandle == INVALID_HANDLE) {
         Print("Error: Failed to create ADX indicator handle");
         strength = 0.0;
         direction = 0;
         return;
      }
      
      // Buffer 0 = main ADX line, Buffer 1 = +DI, Buffer 2 = -DI in MT5
      double mainBuffer[], plusBuffer[], minusBuffer[];
      ArraySetAsSeries(mainBuffer, true);
      ArraySetAsSeries(plusBuffer, true);
      ArraySetAsSeries(minusBuffer, true);
      
      // Copy ADX data from the indicator buffers
      if(CopyBuffer(adxHandle, 0, 0, 1, mainBuffer) <= 0 ||
         CopyBuffer(adxHandle, 1, 0, 1, plusBuffer) <= 0 || 
         CopyBuffer(adxHandle, 2, 0, 1, minusBuffer) <= 0) {
         Print("Error: Failed to copy ADX buffer data");
         IndicatorRelease(adxHandle);
         strength = 0.0;
         direction = 0;
         return;
      }
      
      strength = mainBuffer[0];
      double plusDI = plusBuffer[0];
      double minusDI = minusBuffer[0];
      
      // Cleanup
      IndicatorRelease(adxHandle);
      
      if(plusDI > minusDI)
         direction = 1;  // Bullish
      else if(minusDI > plusDI)
         direction = -1; // Bearish
      else
         direction = 0;  // Neutral
   }
   
   // Check correlation with major markets
   double CheckCorrelation(string symbol, int direction)
   {
      // Get correlation with major indices or pairs
      string majorSymbols[3] = {"EURUSD", "USDJPY", "XAUUSD"};
      double correlations[3];
      double correlationScore = 0.0;
      
      // Calculate correlation with each major symbol
      for(int i = 0; i < ArraySize(majorSymbols); i++)
      {
         // Skip self correlation
         if(symbol == majorSymbols[i])
         {
            correlations[i] = 1.0;
            continue;
         }
         
         // Calculate price correlation
         correlations[i] = CalculatePriceCorrelation(symbol, majorSymbols[i]);
         
         // Adjust score based on correlation and signal direction
         if(direction > 0 && correlations[i] > 0.7)
            correlationScore += 0.2;
         else if(direction < 0 && correlations[i] < -0.7)
            correlationScore += 0.2;
      }
      
      return correlationScore;
   }
   
   // Calculate price correlation between two symbols
   double CalculatePriceCorrelation(string symbol1, string symbol2)
   {
      int period = 20;
      double prices1[20];
      double prices2[20];
      
      // Get close prices for both symbols
      for(int i = 0; i < period; i++)
      {
         prices1[i] = iClose(symbol1, PERIOD_H1, i);
         prices2[i] = iClose(symbol2, PERIOD_H1, i);
      }
      
      // Calculate correlation
      double correlation = 0.0;
      double mean1 = 0.0, mean2 = 0.0;
      double stdDev1 = 0.0, stdDev2 = 0.0;
      
      // Calculate means
      for(int i = 0; i < period; i++)
      {
         mean1 += prices1[i];
         mean2 += prices2[i];
      }
      mean1 /= period;
      mean2 /= period;
      
      // Calculate correlation
      double numerator = 0.0;
      double denominator1 = 0.0;
      double denominator2 = 0.0;
      
      for(int i = 0; i < period; i++)
      {
         numerator += (prices1[i] - mean1) * (prices2[i] - mean2);
         denominator1 += MathPow(prices1[i] - mean1, 2);
         denominator2 += MathPow(prices2[i] - mean2, 2);
      }
      
      if(denominator1 > 0.0 && denominator2 > 0.0)
         correlation = numerator / MathSqrt(denominator1 * denominator2);
      
      return correlation;
   }
   
   // Check supply and demand zones
   bool CheckSupplyDemandZones(string symbol, ENUM_TIMEFRAMES timeframe, int direction, double price)
   {
      int period = 20;
      double highestHigh = 0.0;
      double lowestLow = 999999.9;
      int highestHighBar = 0;
      int lowestLowBar = 0;
      
      // Find recent highs and lows
      for(int i = 1; i < period; i++)
      {
         double high = iHigh(symbol, timeframe, i);
         double low = iLow(symbol, timeframe, i);
         
         if(high > highestHigh)
         {
            highestHigh = high;
            highestHighBar = i;
         }
         
         if(low < lowestLow)
         {
            lowestLow = low;
            lowestLowBar = i;
         }
      }
      
      // Calculate supply zone (resistance) threshold
      double supplyZoneThreshold = highestHigh - (highestHigh - lowestLow) * 0.1;
      
      // Calculate demand zone (support) threshold
      double demandZoneThreshold = lowestLow + (highestHigh - lowestLow) * 0.1;
      
      // Check if price is in a supply or demand zone
      bool inSupplyZone = (price >= supplyZoneThreshold && price <= highestHigh);
      bool inDemandZone = (price <= demandZoneThreshold && price >= lowestLow);
      
      // For buy signals, avoid supply zones
      if(direction > 0 && inSupplyZone)
         return false;
      
      // For sell signals, avoid demand zones
      if(direction < 0 && inDemandZone)
         return false;
      
      return true;
   }
   
   // Machine learning based signal confidence calculation
   double CalculateSignalConfidence(string symbol, ENUM_TIMEFRAMES timeframe, int direction)
   {
      // In a real implementation, this would use an actual machine learning model
      // Here we simulate with a rules-based approach
      
      // Start with base confidence
      double confidence = 0.5;
      
      // Adjust based on trend alignment
      double trendStrength = 0.0;
      int trendDirection = 0;
      AnalyzeTrend(symbol, timeframe, trendStrength, trendDirection);
      
      // Trend alignment boost
      if(trendDirection == direction)
         confidence += 0.2 * (trendStrength / 50.0);
      else if(trendDirection != 0)
         confidence -= 0.2 * (trendStrength / 50.0);
      
      // Adjust based on market volatility
      double volatility = CalculateVolatility(symbol, timeframe);
      if(volatility > 1.5)
         confidence -= 0.1 * (volatility - 1.5);
      
      // Adjust based on indicator confluence
      int confirmedIndicators = 0;
      if(m_indicatorProcessor != NULL)
      {
         if(m_config.GetUseMACross() && 
            (direction > 0 && m_indicatorProcessor.GetMACrossSignal() == SIGNAL_BUY) ||
            (direction < 0 && m_indicatorProcessor.GetMACrossSignal() == SIGNAL_SELL))
            confirmedIndicators++;
            
         if(m_config.GetUseRSI() && 
            (direction > 0 && m_indicatorProcessor.GetRSISignal() == SIGNAL_BUY) ||
            (direction < 0 && m_indicatorProcessor.GetRSISignal() == SIGNAL_SELL))
            confirmedIndicators++;
            
         if(m_config.GetUseMACD() && 
            (direction > 0 && m_indicatorProcessor.GetMACDSignal() == SIGNAL_BUY) ||
            (direction < 0 && m_indicatorProcessor.GetMACDSignal() == SIGNAL_SELL))
            confirmedIndicators++;
      }
      
      confidence += 0.1 * confirmedIndicators;
      
      // Ensure confidence is within [0,1] range
      confidence = MathMax(0.0, MathMin(1.0, confidence));
      
      return confidence;
   }
   
   // Calculate signal reliability based on historical performance
   double CalculateSignalReliability()
   {
      if(m_totalSignals == 0)
         return 0.5; // Default reliability if no historical data
      
      return (double)m_successfulSignals / m_totalSignals;
   }
   
   // Calculate market suitability for trading
   double CalculateMarketSuitability(string symbol, ENUM_TIMEFRAMES timeframe)
   {
      // Start with base suitability
      double suitability = 0.8;
      
      // Adjust based on market volatility
      double volatility = CalculateVolatility(symbol, timeframe);
      if(volatility > 2.0)
         suitability -= 0.3 * (volatility - 2.0);
      else if(volatility < 0.5)
         suitability -= 0.2 * (0.5 - volatility);
      
      // Adjust based on spread
      double currentSpread = SymbolInfoInteger(symbol, SYMBOL_SPREAD) * SymbolInfoDouble(symbol, SYMBOL_POINT);
      double avgSpread = 0.0001; // Average spread for major pairs
      
      if(currentSpread > avgSpread * 2)
         suitability -= 0.2 * (currentSpread / avgSpread - 2);
      
      // Check for major economic events
      datetime now = TimeCurrent();
      bool majorEvent = false; // In a real implementation, check economic calendar
      
      if(majorEvent)
         suitability -= 0.3;
      
      // Ensure suitability is within [0,1] range
      suitability = MathMax(0.0, MathMin(1.0, suitability));
      
      return suitability;
   }
   
   // Neural network based price movement prediction
   // This is a simplified simulation of what a neural network might produce
   void PredictPriceMovement(string symbol, ENUM_TIMEFRAMES timeframe, double &upProb, double &downProb)
   {
      // In a real implementation, this would use an actual neural network
      // Here we simulate with indicator-based probability
      
      double trendStrength = 0.0;
      int trendDirection = 0;
      AnalyzeTrend(symbol, timeframe, trendStrength, trendDirection);
      
      // Base probabilities
      upProb = 0.5;
      downProb = 0.5;
      
      // Adjust based on trend
      if(trendDirection > 0)
      {
         upProb += 0.2 * (trendStrength / 50.0);
         downProb -= 0.2 * (trendStrength / 50.0);
      }
      else if(trendDirection < 0)
      {
         downProb += 0.2 * (trendStrength / 50.0);
         upProb -= 0.2 * (trendStrength / 50.0);
      }
      
      // Adjust based on RSI
      if(m_indicatorProcessor != NULL && m_config.GetUseRSI())
      {
         double rsiValue = m_indicatorProcessor.GetRSIValue();
         if(rsiValue < 30)
         {
            upProb += 0.15;
            downProb -= 0.15;
         }
         else if(rsiValue > 70)
         {
            downProb += 0.15;
            upProb -= 0.15;
         }
      }
      
      // Ensure probabilities sum to 1 and are non-negative
      upProb = MathMax(0.0, upProb);
      downProb = MathMax(0.0, downProb);
      
      double sum = upProb + downProb;
      if(sum > 0)
      {
         upProb /= sum;
         downProb /= sum;
      }
      else
      {
         // Default to equal probability if something went wrong
         upProb = 0.5;
         downProb = 0.5;
      }
   }
   
   // Analyze market condition
   bool DetermineMarketCondition(string symbol, ENUM_TIMEFRAMES timeframe, string &condition, double &score)
   {
      double volatility = CalculateVolatility(symbol, timeframe);
      double trendStrength = 0.0;
      int trendDirection = 0;
      AnalyzeTrend(symbol, timeframe, trendStrength, trendDirection);
      
      // Determine condition
      if(trendStrength > 40)
      {
         condition = trendDirection > 0 ? "Strong Uptrend" : "Strong Downtrend";
         score = trendStrength / 100.0;
      }
      else if(trendStrength > 25)
      {
         condition = trendDirection > 0 ? "Uptrend" : "Downtrend";
         score = trendStrength / 100.0;
      }
      else if(volatility > 1.5)
      {
         condition = "Volatile Ranging";
         score = volatility / 3.0;
      }
      else if(volatility < 0.7)
      {
         condition = "Low Volatility Ranging";
         score = 1.0 - (volatility / 0.7);
      }
      else
      {
         condition = "Neutral Ranging";
         score = 0.5;
      }
      
      return true;
   }
   
public:
   // Constructor
   AISignalAnalyzer()
   {
      m_config = NULL;
      m_indicatorProcessor = NULL;
      m_lastSignalConfidence = 0.0;
      m_lastSignalReliability = 0.0;
      m_lastMarketSuitability = 0.0;
      m_totalSignals = 0;
      m_successfulSignals = 0;
      InitializeMarketState("");
   }
   
   // Initialize with configuration and indicator processor
   bool Initialize(Configuration* config, IndicatorProcessor* indicatorProcessor)
   {
      if(config == NULL || indicatorProcessor == NULL)
         return false;
         
      m_config = config;
      m_indicatorProcessor = indicatorProcessor;
      
      // Initialize historical performance with default values
      // In a real implementation, this would load from a file
      m_totalSignals = 100;
      m_successfulSignals = 60;
      
      return true;
   }
   
   // Analyze a trading signal
   bool AnalyzeSignal(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_ORDER_TYPE direction, double &aiStrength)
   {
      // Initialize market state for this symbol
      InitializeMarketState(symbol);
      
      // Calculate market metrics
      m_marketState.volatility = CalculateVolatility(symbol, timeframe);
      
      double trendStrength = 0.0;
      int trendDirection = 0;
      AnalyzeTrend(symbol, timeframe, trendStrength, trendDirection);
      m_marketState.trendStrength = trendStrength;
      
      // Convert ENUM_ORDER_TYPE to simple integer direction
      int signalDirection = (direction == ORDER_TYPE_BUY) ? 1 : -1;
      
      // Calculate signal confidence
      m_lastSignalConfidence = CalculateSignalConfidence(symbol, timeframe, signalDirection);
      
      // Calculate signal reliability
      m_lastSignalReliability = CalculateSignalReliability();
      
      // Calculate market suitability
      m_lastMarketSuitability = CalculateMarketSuitability(symbol, timeframe);
      
      // Calculate overall AI signal strength (0-10 scale)
      aiStrength = (m_lastSignalConfidence * 0.5 + 
                  m_lastSignalReliability * 0.3 + 
                  m_lastMarketSuitability * 0.2) * 10.0;
      
      // Determine market condition
      DetermineMarketCondition(symbol, timeframe, m_marketState.condition, m_marketState.conditionScore);
      
      return true;
   }
   
   // Filter signal by market volatility
   bool FilterSignalByMarketVolatility(string symbol, ENUM_TIMEFRAMES timeframe)
   {
      double volatility = CalculateVolatility(symbol, timeframe);
      
      // Reject signals during extreme volatility
      if(volatility > 2.5)
      {
         Print("Signal rejected due to extreme volatility: ", DoubleToString(volatility, 2));
         return false;
      }
      
      return true;
   }
   
   // Filter signal by trend strength
   bool FilterSignalByTrendStrength(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_ORDER_TYPE direction)
   {
      double trendStrength = 0.0;
      int trendDirection = 0;
      AnalyzeTrend(symbol, timeframe, trendStrength, trendDirection);
      
      // Convert ENUM_ORDER_TYPE to simple integer direction
      int signalDirection = (direction == ORDER_TYPE_BUY) ? 1 : -1;
      
      // For strong trends, reject signals that go against the trend
      if(trendStrength > 35.0 && trendDirection != 0 && trendDirection != signalDirection)
      {
         Print("Signal rejected as it goes against a strong trend (", 
               DoubleToString(trendStrength, 1), ")");
         return false;
      }
      
      return true;
   }
   
   // Filter signal by correlation with major markets
   bool FilterSignalByCorrelation(string symbol, ENUM_ORDER_TYPE direction)
   {
      // Convert ENUM_ORDER_TYPE to simple integer direction
      int signalDirection = (direction == ORDER_TYPE_BUY) ? 1 : -1;
      
      // Get correlation score
      double correlationScore = CheckCorrelation(symbol, signalDirection);
      
      // If correlation score is negative, it means the signal conflicts with
      // multiple major market correlations
      if(correlationScore < -0.3)
      {
         Print("Signal rejected due to negative correlation with major markets");
         return false;
      }
      
      return true;
   }
   
   // Filter signal by supply/demand zones
   bool FilterSignalBySupplyDemandZones(string symbol, ENUM_TIMEFRAMES timeframe, 
                                       ENUM_ORDER_TYPE direction, double price)
   {
      // Convert ENUM_ORDER_TYPE to simple integer direction
      int signalDirection = (direction == ORDER_TYPE_BUY) ? 1 : -1;
      
      bool passes = CheckSupplyDemandZones(symbol, timeframe, signalDirection, price);
      
      if(!passes)
      {
         Print("Signal rejected due to conflict with supply/demand zones");
         return false;
      }
      
      return true;
   }
   
   // Get the last calculated signal confidence
   double GetSignalConfidence()
   {
      return m_lastSignalConfidence;
   }
   
   // Get the last calculated signal reliability
   double GetSignalReliability()
   {
      return m_lastSignalReliability;
   }
   
   // Get the last calculated market suitability
   double GetMarketSuitability()
   {
      return m_lastMarketSuitability;
   }
   
   // Get the current market condition
   bool GetMarketCondition(string symbol, ENUM_TIMEFRAMES timeframe, string &condition, double &score)
   {
      if(m_marketState.symbol == symbol && m_marketState.condition != "Unknown")
      {
         condition = m_marketState.condition;
         score = m_marketState.conditionScore;
         return true;
      }
      
      return DetermineMarketCondition(symbol, timeframe, condition, score);
   }
   
   // Wrapper for price movement prediction
   bool GetPriceMovementPrediction(string symbol, ENUM_TIMEFRAMES timeframe, 
                            double &upProbability, double &downProbability)
   {
      // Call the void function and return a boolean success indicator
      // This avoids the function signature conflict
      PredictPriceMovement(symbol, timeframe, upProbability, downProbability);
      return true;
   }
   
   // Record signal result for improving AI
   void RecordSignalResult(bool success)
   {
      m_totalSignals++;
      if(success)
         m_successfulSignals++;
   }
};