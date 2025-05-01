//+------------------------------------------------------------------+
//|                                               SignalGenerator.mqh |
//|                        Copyright 2023, Your Company               |
//|                                       https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include "Constants.mqh"
#include "Configuration.mqh"
#include "IndicatorProcessor.mqh"
#include "AISignalAnalyzer.mqh"
#include "MarketSentimentAnalyzer.mqh"

//+------------------------------------------------------------------+
//| Class to generate trading signals                                 |
//+------------------------------------------------------------------+
class SignalGenerator
{
private:
   Configuration* m_config;
   IndicatorProcessor* m_indicatorProcessor;
   AISignalAnalyzer* m_aiAnalyzer;          // AI-powered signal analyzer
   MarketSentimentAnalyzer* m_sentimentAnalyzer;  // Market sentiment analyzer
   
   // AI-enhanced signal analysis
   bool AnalyzeWithAI(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_ORDER_TYPE direction, double &aiStrength);
   bool AnalyzeMarketSentiment(string symbol, string &sentimentSummary, bool &sentimentSupportsSignal);
   
   // Calculate signal strength (1-10)
   int CalculateSignalStrength(ENUM_SIGNAL_DIRECTION direction, string symbol, ENUM_TIMEFRAMES timeframe)
   {
      if(direction == SIGNAL_NEUTRAL) return 0;
      
      int strength = 0;
      int confirmedIndicators = 0;
      
      // Check MA Cross
      if(m_config.GetUseMACross())
      {
         ENUM_SIGNAL_DIRECTION maSignal = m_indicatorProcessor.GetMACrossSignal();
         if(maSignal == direction) 
         {
            strength += 2;
            confirmedIndicators++;
         }
         else if(maSignal != SIGNAL_NEUTRAL) 
         {
            strength -= 1;
         }
      }
      
      // Check RSI
      if(m_config.GetUseRSI())
      {
         ENUM_SIGNAL_DIRECTION rsiSignal = m_indicatorProcessor.GetRSISignal();
         if(rsiSignal == direction) 
         {
            strength += 2;
            confirmedIndicators++;
         }
         else if(rsiSignal != SIGNAL_NEUTRAL) 
         {
            strength -= 1;
         }
         
         // Extra points for extreme RSI values
         double rsiValue = m_indicatorProcessor.GetRSIValue();
         if(direction == SIGNAL_BUY && rsiValue < 30) strength += 1;
         else if(direction == SIGNAL_SELL && rsiValue > 70) strength += 1;
      }
      
      // Check MACD
      if(m_config.GetUseMACD())
      {
         ENUM_SIGNAL_DIRECTION macdSignal = m_indicatorProcessor.GetMACDSignal();
         if(macdSignal == direction) 
         {
            strength += 2;
            confirmedIndicators++;
         }
         else if(macdSignal != SIGNAL_NEUTRAL) 
         {
            strength -= 1;
         }
      }
      
      // Check Stochastic
      if(m_config.GetUseStochastic())
      {
         ENUM_SIGNAL_DIRECTION stochSignal = m_indicatorProcessor.GetStochasticSignal();
         if(stochSignal == direction) 
         {
            strength += 2;
            confirmedIndicators++;
         }
         else if(stochSignal != SIGNAL_NEUTRAL) 
         {
            strength -= 1;
         }
      }
      
      // Check Bollinger Bands
      if(m_config.GetUseBollingerBands())
      {
         ENUM_SIGNAL_DIRECTION bbSignal = m_indicatorProcessor.GetBollingerBandsSignal(symbol, timeframe);
         if(bbSignal == direction) 
         {
            strength += 2;
            confirmedIndicators++;
         }
         else if(bbSignal != SIGNAL_NEUTRAL) 
         {
            strength -= 1;
         }
      }
      
      // Check ADX
      if(m_config.GetUseADX())
      {
         ENUM_SIGNAL_DIRECTION adxSignal = m_indicatorProcessor.GetADXSignal();
         if(adxSignal == direction) 
         {
            strength += 2;
            confirmedIndicators++;
         }
         else if(adxSignal != SIGNAL_NEUTRAL) 
         {
            strength -= 1;
         }
         
         // Extra points for strong trend
         double adxValue = m_indicatorProcessor.GetADXValue();
         if(adxValue > 30) strength += 1;
         if(adxValue > 50) strength += 1;
      }
      
      // Check Price Action
      if(m_config.GetUsePriceAction())
      {
         ENUM_SIGNAL_DIRECTION paSignal = m_indicatorProcessor.GetPriceActionSignal(symbol, timeframe);
         if(paSignal == direction) 
         {
            strength += 3; // Price action has more weight
            confirmedIndicators++;
         }
         else if(paSignal != SIGNAL_NEUTRAL) 
         {
            strength -= 2;
         }
      }
      
      // Bonus points for multiple confirmations
      if(confirmedIndicators >= 3) strength += 2;
      if(confirmedIndicators >= 4) strength += 1;
      
      // Ensure strength is within 1-10 range
      strength = MathMax(1, MathMin(10, strength));
      
      return strength;
   }
   
   // Generate signal reason description
   string GenerateSignalReason(ENUM_SIGNAL_DIRECTION direction, string symbol, ENUM_TIMEFRAMES timeframe)
   {
      string reason = "";
      
      // Add indicators that confirmed the signal
      if(m_config.GetUseMACross() && m_indicatorProcessor.GetMACrossSignal() == direction)
      {
         reason += (reason == "" ? "" : " + ") + "MA Cross";
      }
      
      if(m_config.GetUseRSI() && m_indicatorProcessor.GetRSISignal() == direction)
      {
         string rsiState = "";
         double rsiValue = m_indicatorProcessor.GetRSIValue();
         
         if(direction == SIGNAL_BUY)
            rsiState = "Oversold (" + DoubleToString(rsiValue, 1) + ")";
         else
            rsiState = "Overbought (" + DoubleToString(rsiValue, 1) + ")";
            
         reason += (reason == "" ? "" : " + ") + "RSI " + rsiState;
      }
      
      if(m_config.GetUseMACD() && m_indicatorProcessor.GetMACDSignal() == direction)
      {
         reason += (reason == "" ? "" : " + ") + "MACD Cross";
      }
      
      if(m_config.GetUseStochastic() && m_indicatorProcessor.GetStochasticSignal() == direction)
      {
         reason += (reason == "" ? "" : " + ") + "Stochastic Cross";
      }
      
      if(m_config.GetUseBollingerBands() && m_indicatorProcessor.GetBollingerBandsSignal(symbol, timeframe) == direction)
      {
         reason += (reason == "" ? "" : " + ") + "Bollinger Band " + (direction == SIGNAL_BUY ? "Bounce" : "Break");
      }
      
      if(m_config.GetUseADX() && m_indicatorProcessor.GetADXSignal() == direction)
      {
         double adxValue = m_indicatorProcessor.GetADXValue();
         reason += (reason == "" ? "" : " + ") + "ADX Trend (" + DoubleToString(adxValue, 1) + ")";
      }
      
      if(m_config.GetUsePriceAction() && m_indicatorProcessor.GetPriceActionSignal(symbol, timeframe) == direction)
      {
         string pattern = m_indicatorProcessor.GetPriceActionPatternName(symbol, timeframe);
         if(pattern != "")
            reason += (reason == "" ? "" : " + ") + pattern + " Pattern";
      }
      
      if(reason == "")
         reason = "Multiple indicator confluence";
         
      return reason;
   }

public:
   // Constructor
   SignalGenerator()
   {
      m_config = NULL;
      m_indicatorProcessor = NULL;
      m_aiAnalyzer = NULL;
      m_sentimentAnalyzer = NULL;
   }
   
   // Destructor
   ~SignalGenerator()
   {
      // Clean up AI components
      if(m_aiAnalyzer != NULL)
      {
         delete m_aiAnalyzer;
         m_aiAnalyzer = NULL;
      }
      
      if(m_sentimentAnalyzer != NULL)
      {
         delete m_sentimentAnalyzer;
         m_sentimentAnalyzer = NULL;
      }
   }
   
   // Initialize the signal generator
   bool Initialize(Configuration* config, IndicatorProcessor* indicatorProcessor)
   {
      if(config == NULL || indicatorProcessor == NULL) return false;
      
      m_config = config;
      m_indicatorProcessor = indicatorProcessor;
      
      // Initialize AI components
      m_aiAnalyzer = new AISignalAnalyzer();
      if(m_aiAnalyzer == NULL || !m_aiAnalyzer.Initialize(config, indicatorProcessor))
      {
         Print("Failed to initialize AI Signal Analyzer");
         return false;
      }
      
      m_sentimentAnalyzer = new MarketSentimentAnalyzer();
      if(m_sentimentAnalyzer == NULL || !m_sentimentAnalyzer.Initialize(config))
      {
         Print("Failed to initialize Market Sentiment Analyzer");
         return false;
      }
      
      return true;
   }
   
   // Generate signal for a symbol
   bool GenerateSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      // Default values
      signal.direction = SIGNAL_NEUTRAL;
      signal.strength = 0;
      signal.reason = "";
      signal.time = TimeCurrent();
      signal.executeSignal = false;
      
      ENUM_STRATEGY_PRESET preset = m_config.GetStrategyPreset();
      
      // Generate signal based on the selected preset
      switch(preset)
      {
         case STRATEGY_SCALPING:
            return GenerateScalpingSignal(symbol, timeframe, signal);
            
         case STRATEGY_SWING_TRADING:
            return GenerateSwingTradingSignal(symbol, timeframe, signal);
            
         case STRATEGY_TREND_FOLLOWING:
            return GenerateTrendFollowingSignal(symbol, timeframe, signal);
            
         case STRATEGY_REVERSAL:
            return GenerateReversalSignal(symbol, timeframe, signal);
            
         default:
            return GenerateCustomSignal(symbol, timeframe, signal);
      }
   }
   
   // Generate AI-enhanced signal for a symbol
   bool GenerateAIEnhancedSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      // Default values
      signal.direction = SIGNAL_NEUTRAL;
      signal.strength = 0;
      signal.reason = "";
      signal.time = TimeCurrent();
      signal.executeSignal = false;
      
      // First, generate a traditional signal
      if(!GenerateSignal(symbol, timeframe, signal))
         return false;
         
      // If traditional signal generation failed, we have nothing to enhance
      if(signal.direction == SIGNAL_NEUTRAL)
         return false;
         
      // Convert our signal direction to MQL order type for AI analysis
      ENUM_ORDER_TYPE orderType = (signal.direction == SIGNAL_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      
      // Perform AI analysis
      double aiStrength = 0.0;
      bool aiSupportsSignal = AnalyzeWithAI(symbol, timeframe, orderType, aiStrength);
      
      // Check if AI rejects the signal
      if(!aiSupportsSignal)
      {
         // AI has rejected the signal
         Print("AI analysis rejected the signal for ", symbol);
         signal.direction = SIGNAL_NEUTRAL;
         return false;
      }
      
      // Perform sentiment analysis
      string sentimentSummary = "";
      bool sentimentSupportsSignal = true;
      if(AnalyzeMarketSentiment(symbol, sentimentSummary, sentimentSupportsSignal))
      {
         // Add sentiment info to the signal reason
         signal.reason += " [" + sentimentSummary + "]";
      }
      
      // Check if sentiment is strongly against the signal
      if(!sentimentSupportsSignal)
      {
         // Lower the signal strength but don't reject it completely
         // Sentiment is just one factor among many
         signal.strength = MathMax(1, signal.strength - 2);
      }
      
      // Blend the traditional signal strength with the AI strength
      // 60% weight to AI, 40% to traditional indicators
      signal.strength = MathRound(signal.strength * 0.4 + aiStrength * 0.6);
      
      // Ensure strength is within 1-10
      signal.strength = MathMax(1, MathMin(10, signal.strength));
      
      // Add AI insights to the signal reason
      signal.reason += " (AI Confidence: " + DoubleToString(m_aiAnalyzer.GetSignalConfidence() * 10, 1) + "/10)";
      
      return true;
   }
   
   // Generate Scalping strategy signal
   bool GenerateScalpingSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      // For scalping we prioritize MA cross with RSI and Stochastic confirmation
      
      // First check MA cross as primary signal
      ENUM_SIGNAL_DIRECTION maSignal = m_indicatorProcessor.GetMACrossSignal();
      if(maSignal == SIGNAL_NEUTRAL) return false;
      
      // Now check RSI for confirmation
      ENUM_SIGNAL_DIRECTION rsiSignal = m_indicatorProcessor.GetRSISignal();
      
      // Check Stochastic for confirmation
      ENUM_SIGNAL_DIRECTION stochSignal = m_indicatorProcessor.GetStochasticSignal();
      
      // For a valid scalping signal, we need at least one confirmation
      if(rsiSignal != SIGNAL_NEUTRAL && rsiSignal == maSignal)
      {
         signal.direction = maSignal;
      }
      else if(stochSignal != SIGNAL_NEUTRAL && stochSignal == maSignal)
      {
         signal.direction = maSignal;
      }
      else
      {
         return false;
      }
      
      // Calculate signal strength
      signal.strength = CalculateSignalStrength(signal.direction, symbol, timeframe);
      
      // Generate reason
      signal.reason = GenerateSignalReason(signal.direction, symbol, timeframe);
      
      return true;
   }
   
   // Generate Swing Trading strategy signal
   bool GenerateSwingTradingSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      // For swing trading we prioritize price action, S/R levels, and MACD divergence
      
      // First check price action as primary signal
      ENUM_SIGNAL_DIRECTION paSignal = m_indicatorProcessor.GetPriceActionSignal(symbol, timeframe);
      if(paSignal == SIGNAL_NEUTRAL) return false;
      
      // Now check MACD for confirmation
      ENUM_SIGNAL_DIRECTION macdSignal = m_indicatorProcessor.GetMACDSignal();
      
      // For a valid swing trading signal, we prioritize price action with MACD confirmation
      signal.direction = paSignal;
      
      // Calculate signal strength
      signal.strength = CalculateSignalStrength(signal.direction, symbol, timeframe);
      
      // Generate reason
      signal.reason = GenerateSignalReason(signal.direction, symbol, timeframe);
      
      // Give bonus points for MACD confirmation
      if(macdSignal == paSignal)
      {
         signal.strength = MathMin(10, signal.strength + 2);
      }
      
      return true;
   }
   
   // Generate Trend Following strategy signal
   bool GenerateTrendFollowingSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      // For trend following we use MA cross + ADX + RSI
      
      // First check MA cross as primary signal
      ENUM_SIGNAL_DIRECTION maSignal = m_indicatorProcessor.GetMACrossSignal();
      if(maSignal == SIGNAL_NEUTRAL) return false;
      
      // Check ADX for strong trend
      double adxValue = m_indicatorProcessor.GetADXValue();
      if(adxValue < m_config.GetADXThreshold()) return false;
      
      // Get ADX directional signal
      ENUM_SIGNAL_DIRECTION adxSignal = m_indicatorProcessor.GetADXSignal();
      
      // Now check RSI for confirmation or filter out bad signals
      ENUM_SIGNAL_DIRECTION rsiSignal = m_indicatorProcessor.GetRSISignal();
      double rsiValue = m_indicatorProcessor.GetRSIValue();
      
      // For a valid trend following signal
      signal.direction = maSignal;
      
      // Calculate signal strength
      signal.strength = CalculateSignalStrength(signal.direction, symbol, timeframe);
      
      // Generate reason
      signal.reason = GenerateSignalReason(signal.direction, symbol, timeframe);
      
      // Filter out signals that go against the trend or are in extreme RSI areas
      if(adxSignal != SIGNAL_NEUTRAL && adxSignal != maSignal)
      {
         return false;
      }
      
      if(maSignal == SIGNAL_BUY && rsiValue > 70)
      {
         return false;
      }
      
      if(maSignal == SIGNAL_SELL && rsiValue < 30)
      {
         return false;
      }
      
      return true;
   }
   
   // Generate Reversal strategy signal
   bool GenerateReversalSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      // For reversal we use engulfing patterns + RSI divergence + Bollinger Band
      
      // First check price action as primary signal
      ENUM_SIGNAL_DIRECTION paSignal = m_indicatorProcessor.GetPriceActionSignal(symbol, timeframe);
      if(paSignal == SIGNAL_NEUTRAL) return false;
      
      // Check RSI for confirmation
      ENUM_SIGNAL_DIRECTION rsiSignal = m_indicatorProcessor.GetRSISignal();
      double rsiValue = m_indicatorProcessor.GetRSIValue();
      
      // For a valid reversal signal, we need RSI confirmation
      if(paSignal == SIGNAL_BUY && rsiValue >= 50)
      {
         return false; // Not oversold enough for reversal
      }
      
      if(paSignal == SIGNAL_SELL && rsiValue <= 50)
      {
         return false; // Not overbought enough for reversal
      }
      
      // Check Bollinger Bands
      ENUM_SIGNAL_DIRECTION bbSignal = m_indicatorProcessor.GetBollingerBandsSignal(symbol, timeframe);
      
      // For a stronger reversal signal, Bollinger Band should confirm
      if(bbSignal != SIGNAL_NEUTRAL && bbSignal != paSignal)
      {
         return false;
      }
      
      // Set signal direction
      signal.direction = paSignal;
      
      // Calculate signal strength
      signal.strength = CalculateSignalStrength(signal.direction, symbol, timeframe);
      
      // Generate reason
      signal.reason = GenerateSignalReason(signal.direction, symbol, timeframe);
      
      return true;
   }
   
   // Generate Custom strategy signal
   bool GenerateCustomSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      // For custom strategy, we use all enabled indicators with equal weight
      
      int buySignals = 0;
      int sellSignals = 0;
      int totalIndicators = 0;
      
      // Check MA Cross
      if(m_config.GetUseMACross())
      {
         totalIndicators++;
         ENUM_SIGNAL_DIRECTION maSignal = m_indicatorProcessor.GetMACrossSignal();
         if(maSignal == SIGNAL_BUY) buySignals++;
         else if(maSignal == SIGNAL_SELL) sellSignals++;
      }
      
      // Check RSI
      if(m_config.GetUseRSI())
      {
         totalIndicators++;
         ENUM_SIGNAL_DIRECTION rsiSignal = m_indicatorProcessor.GetRSISignal();
         if(rsiSignal == SIGNAL_BUY) buySignals++;
         else if(rsiSignal == SIGNAL_SELL) sellSignals++;
      }
      
      // Check MACD
      if(m_config.GetUseMACD())
      {
         totalIndicators++;
         ENUM_SIGNAL_DIRECTION macdSignal = m_indicatorProcessor.GetMACDSignal();
         if(macdSignal == SIGNAL_BUY) buySignals++;
         else if(macdSignal == SIGNAL_SELL) sellSignals++;
      }
      
      // Check Stochastic
      if(m_config.GetUseStochastic())
      {
         totalIndicators++;
         ENUM_SIGNAL_DIRECTION stochSignal = m_indicatorProcessor.GetStochasticSignal();
         if(stochSignal == SIGNAL_BUY) buySignals++;
         else if(stochSignal == SIGNAL_SELL) sellSignals++;
      }
      
      // Check Bollinger Bands
      if(m_config.GetUseBollingerBands())
      {
         totalIndicators++;
         ENUM_SIGNAL_DIRECTION bbSignal = m_indicatorProcessor.GetBollingerBandsSignal(symbol, timeframe);
         if(bbSignal == SIGNAL_BUY) buySignals++;
         else if(bbSignal == SIGNAL_SELL) sellSignals++;
      }
      
      // Check ADX
      if(m_config.GetUseADX())
      {
         totalIndicators++;
         ENUM_SIGNAL_DIRECTION adxSignal = m_indicatorProcessor.GetADXSignal();
         if(adxSignal == SIGNAL_BUY) buySignals++;
         else if(adxSignal == SIGNAL_SELL) sellSignals++;
      }
      
      // Check Price Action
      if(m_config.GetUsePriceAction())
      {
         totalIndicators++;
         ENUM_SIGNAL_DIRECTION paSignal = m_indicatorProcessor.GetPriceActionSignal(symbol, timeframe);
         if(paSignal == SIGNAL_BUY) buySignals++;
         else if(paSignal == SIGNAL_SELL) sellSignals++;
      }
      
      // For a valid custom signal, we need at least 50% confirmation
      int requiredSignals = MathCeil(totalIndicators * 0.5);
      
      if(buySignals >= requiredSignals && buySignals > sellSignals)
      {
         signal.direction = SIGNAL_BUY;
      }
      else if(sellSignals >= requiredSignals && sellSignals > buySignals)
      {
         signal.direction = SIGNAL_SELL;
      }
      else
      {
         return false;
      }
      
      // Calculate signal strength
      signal.strength = CalculateSignalStrength(signal.direction, symbol, timeframe);
      
      // Generate reason
      signal.reason = GenerateSignalReason(signal.direction, symbol, timeframe);
      
      return true;
   }
   
//+------------------------------------------------------------------+
//| Analyze signal with AI                                           |
//+------------------------------------------------------------------+
bool SignalGenerator::AnalyzeWithAI(string symbol, ENUM_TIMEFRAMES timeframe, ENUM_ORDER_TYPE direction, double &aiStrength)
{
   if(m_aiAnalyzer == NULL)
      return false;
      
   // Use the AI analyzer to evaluate the signal
   if(!m_aiAnalyzer.AnalyzeSignal(symbol, timeframe, direction, aiStrength))
      return false;
      
   // Verify that signal passes all advanced filters
   bool passesFilters = true;
   
   // Check market volatility - reject signals during extreme volatility
   passesFilters = passesFilters && m_aiAnalyzer.FilterSignalByMarketVolatility(symbol, timeframe);
   
   // Check trend strength - reject signals that go against the trend
   passesFilters = passesFilters && m_aiAnalyzer.FilterSignalByTrendStrength(symbol, timeframe, direction);
   
   // Check correlated markets - reject signals that conflict with correlations
   passesFilters = passesFilters && m_aiAnalyzer.FilterSignalByCorrelation(symbol, direction);
   
   // Check price in relation to supply/demand zones
   double entryPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);
   if(direction == ORDER_TYPE_SELL)
      entryPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
      
   passesFilters = passesFilters && m_aiAnalyzer.FilterSignalBySupplyDemandZones(symbol, timeframe, direction, entryPrice);
   
   // Get AI metrics for logging
   double signalConfidence = m_aiAnalyzer.GetSignalConfidence();
   double signalReliability = m_aiAnalyzer.GetSignalReliability();
   double marketSuitability = m_aiAnalyzer.GetMarketSuitability();
   
   // Print AI analysis results for debugging
   Print("AI Analysis for ", symbol, " ", EnumToString(direction), ":");
   Print("  Signal Strength: ", DoubleToString(aiStrength, 2));
   Print("  Confidence: ", DoubleToString(signalConfidence, 2));
   Print("  Reliability: ", DoubleToString(signalReliability, 2));
   Print("  Market Suitability: ", DoubleToString(marketSuitability, 2));
   Print("  Passes All Filters: ", passesFilters ? "Yes" : "No");
   
   // Analyze the current market condition
   string marketCondition;
   double marketScore;
   if(m_aiAnalyzer.GetMarketCondition(symbol, timeframe, marketCondition, marketScore))
   {
      Print("  Market Condition: ", marketCondition, " (", DoubleToString(marketScore, 2), ")");
   }
   
   // Predict the price movement probability
   double upProbability = 0.0, downProbability = 0.0;
   if(m_aiAnalyzer.GetPriceMovementPrediction(symbol, timeframe, upProbability, downProbability))
   {
      Print("  Price Movement Prediction: Up ", DoubleToString(upProbability*100, 1), 
            "%, Down ", DoubleToString(downProbability*100, 1), "%");
   }
   
   return passesFilters;
}

//+------------------------------------------------------------------+
//| Analyze market sentiment                                          |
//+------------------------------------------------------------------+
bool SignalGenerator::AnalyzeMarketSentiment(string symbol, string &sentimentSummary, bool &sentimentSupportsSignal)
{
   if(m_sentimentAnalyzer == NULL)
      return false;
      
   // Get sentiment summary
   sentimentSummary = m_sentimentAnalyzer.GetMarketSentimentSummary(symbol);
   
   // Get retail sentiment
   double retailBullish = 0.0, retailBearish = 0.0;
   m_sentimentAnalyzer.GetRetailSentiment(symbol, retailBullish, retailBearish);
   
   // Get combined market sentiment
   double bullishScore = 0.0, bearishScore = 0.0;
   m_sentimentAnalyzer.GetCombinedSentiment(symbol, bullishScore, bearishScore);
   
   // Check contrarian signals
   double contraryStrength = 0.0;
   bool isBullishContrary = false;
   bool hasContrarySignal = m_sentimentAnalyzer.GetContrarySignal(symbol, contraryStrength, isBullishContrary);
   
   // Check for extreme sentiment
   bool isBullishExtreme = false, isBearishExtreme = false;
   m_sentimentAnalyzer.IsSentimentExtreme(symbol, isBullishExtreme, isBearishExtreme);
   
   // Check for sentiment shifts
   bool isShifting = false, isShiftingBullish = false;
   m_sentimentAnalyzer.DetectSentimentShift(symbol, isShifting, isShiftingBullish);
   
   // Check retail crowding
   bool isCrowded = false, isBullishCrowded = false;
   m_sentimentAnalyzer.IsRetailCrowded(symbol, isCrowded, isBullishCrowded);
   
   // Print sentiment analysis for debugging
   Print("Market Sentiment Analysis for ", symbol, ":");
   Print("  Retail Sentiment: Bullish ", DoubleToString(retailBullish, 1), 
         "%, Bearish ", DoubleToString(retailBearish, 1), "%");
   Print("  Combined Sentiment: Bullish Score ", DoubleToString(bullishScore*100, 1), 
         "%, Bearish Score ", DoubleToString(bearishScore*100, 1), "%");
   
   if(hasContrarySignal && contraryStrength > 0.3)
   {
      Print("  Contrary Signal: ", isBullishContrary ? "Bullish" : "Bearish", 
            " (Strength: ", DoubleToString(contraryStrength, 2), ")");
   }
   
   if(isBullishExtreme || isBearishExtreme)
   {
      Print("  Extreme Sentiment: ", isBullishExtreme ? "Bullish" : "Bearish");
   }
   
   if(isShifting)
   {
      Print("  Sentiment Shifting: ", isShiftingBullish ? "Bullish" : "Bearish");
   }
   
   if(isCrowded)
   {
      Print("  Retail Positioning Crowded: ", isBullishCrowded ? "Bullish" : "Bearish");
   }
   
   // Determine if sentiment supports a bullish signal
   bool supportsBullish = (bullishScore > bearishScore) ||            // Overall sentiment is bullish
                         (isCrowded && !isBullishCrowded) ||          // Bearish crowded trade (contrarian bullish)
                         (hasContrarySignal && isBullishContrary) ||  // Contrarian bullish signal
                         (isShifting && isShiftingBullish);           // Sentiment shifting bullish
   
   // Determine if sentiment supports a bearish signal                     
   bool supportsBearish = (bearishScore > bullishScore) ||            // Overall sentiment is bearish
                          (isCrowded && isBullishCrowded) ||          // Bullish crowded trade (contrarian bearish)
                          (hasContrarySignal && !isBullishContrary) || // Contrarian bearish signal
                          (isShifting && !isShiftingBullish);          // Sentiment shifting bearish
                          
   Print("  Sentiment supports Bullish: ", supportsBullish ? "Yes" : "No");
   Print("  Sentiment supports Bearish: ", supportsBearish ? "Yes" : "No");
   
   sentimentSupportsSignal = true; // Default to true if we can't determine
   
   return true;
}
};
