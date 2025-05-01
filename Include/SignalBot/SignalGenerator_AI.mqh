//+------------------------------------------------------------------+
//|                                        SignalGenerator_AI.mqh |
//|                          Copyright 2025, Signal Bot            |
//|                                                                |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Signal Bot"
#property link      ""
#property version   "1.00"
#property strict

#include "Constants.mqh"
#include "Configuration.mqh"
#include "SignalGenerator.mqh"
#include "AISignalAnalyzer.mqh"
#include "MarketSentimentAnalyzer.mqh"

//+------------------------------------------------------------------+
//| Class to extend SignalGenerator with AI capabilities              |
//+------------------------------------------------------------------+
class SignalGenerator_AI : public SignalGenerator
{
private:
   AISignalAnalyzer* m_aiAnalyzer;
   MarketSentimentAnalyzer* m_sentimentAnalyzer;
   bool m_aiInitialized;
   bool m_sentimentInitialized;
   
   // Apply AI analysis to the signal
   bool EnhanceSignalWithAI(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      if(!m_aiInitialized || m_aiAnalyzer == NULL)
         return false;
         
      // Analyze signal with AI
      double aiStrength = 0.0;
      if(!m_aiAnalyzer.AnalyzeSignal(symbol, timeframe, signal.direction == SIGNAL_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, aiStrength))
      {
         Print("AI signal analysis failed for ", symbol);
         return false;
      }
      
      // Apply AI signal strength (0-10 scale)
      signal.aiStrength = aiStrength;
      
      // Apply filters based on market volatility
      if(!m_aiAnalyzer.FilterSignalByMarketVolatility(symbol, timeframe))
      {
         Print("Signal rejected by AI volatility filter for ", symbol);
         return false;
      }
      
      // Apply filters based on trend strength
      if(!m_aiAnalyzer.FilterSignalByTrendStrength(symbol, timeframe, 
            signal.direction == SIGNAL_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL))
      {
         Print("Signal rejected by AI trend filter for ", symbol);
         return false;
      }
      
      // Apply filters based on supply/demand zones
      double currentPrice = SymbolInfoDouble(symbol, SYMBOL_BID);
      if(!m_aiAnalyzer.FilterSignalBySupplyDemandZones(symbol, timeframe, 
            signal.direction == SIGNAL_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
            currentPrice))
      {
         Print("Signal rejected by AI supply/demand filter for ", symbol);
         return false;
      }
      
      // Adjust signal strength based on AI analysis
      // The final strength is a weighted combination of traditional and AI strength
      signal.strength = (signal.strength * 0.6) + (aiStrength * 0.4);
      
      // Get additional confidence metrics
      signal.signalConfidence = m_aiAnalyzer.GetSignalConfidence();
      signal.signalReliability = m_aiAnalyzer.GetSignalReliability();
      signal.marketSuitability = m_aiAnalyzer.GetMarketSuitability();
      
      // Get market condition
      string marketCondition = "";
      double conditionScore = 0.0;
      if(m_aiAnalyzer.GetMarketCondition(symbol, timeframe, marketCondition, conditionScore))
      {
         signal.marketCondition = marketCondition;
         signal.marketConditionScore = conditionScore;
      }
      
      // Make signal prediction
      double upProb = 0.0, downProb = 0.0;
      if(m_aiAnalyzer.GetPriceMovementPrediction(symbol, timeframe, upProb, downProb))
      {
         signal.pricePrediction.upProbability = upProb;
         signal.pricePrediction.downProbability = downProb;
      }
      
      return true;
   }
   
   // Apply market sentiment analysis to the signal
   bool EnhanceSignalWithSentiment(string symbol, SignalInfo &signal)
   {
      if(!m_sentimentInitialized || m_sentimentAnalyzer == NULL)
         return true; // Not a critical component, can continue without it
      
      // Get retail sentiment
      double retailBullish = 0.0, retailBearish = 0.0;
      if(m_sentimentAnalyzer.GetRetailSentiment(symbol, retailBullish, retailBearish))
      {
         signal.sentimentData.retailBullishPercent = retailBullish;
         signal.sentimentData.retailBearishPercent = retailBearish;
      }
      
      // Get institutional sentiment
      double instBullish = 0.0, instBearish = 0.0;
      if(m_sentimentAnalyzer.GetInstitutionalSentiment(symbol, instBullish, instBearish))
      {
         signal.sentimentData.institutionalBullishPercent = instBullish;
         signal.sentimentData.institutionalBearishPercent = instBearish;
      }
      
      // Get combined sentiment
      double combinedBullish = 0.0, combinedBearish = 0.0;
      if(m_sentimentAnalyzer.GetCombinedSentiment(symbol, combinedBullish, combinedBearish))
      {
         signal.sentimentData.overallBullishScore = combinedBullish;
         signal.sentimentData.overallBearishScore = combinedBearish;
      }
      
      // Check for extreme sentiment
      bool isBullishExtreme = false, isBearishExtreme = false;
      if(m_sentimentAnalyzer.IsSentimentExtreme(symbol, isBullishExtreme, isBearishExtreme))
      {
         signal.sentimentData.isBullishExtreme = isBullishExtreme;
         signal.sentimentData.isBearishExtreme = isBearishExtreme;
      }
      
      // Check for sentiment shifts
      bool isShifting = false, isShiftingBullish = false;
      if(m_sentimentAnalyzer.DetectSentimentShift(symbol, isShifting, isShiftingBullish))
      {
         signal.sentimentData.isShifting = isShifting;
         signal.sentimentData.isShiftingBullish = isShiftingBullish;
      }
      
      // Check for retail crowding
      bool isCrowded = false, isBullishCrowded = false;
      if(m_sentimentAnalyzer.IsRetailCrowded(symbol, isCrowded, isBullishCrowded))
      {
         signal.sentimentData.isRetailCrowded = isCrowded;
         signal.sentimentData.isRetailCrowdedBullish = isBullishCrowded;
      }
      
      // Get contrarian signal
      double contraryStrength = 0.0;
      bool isContraryBullish = false;
      if(m_sentimentAnalyzer.GetContrarySignal(symbol, contraryStrength, isContraryBullish))
      {
         signal.sentimentData.hasContrarySignal = true;
         signal.sentimentData.isContraryBullish = isContraryBullish;
         signal.sentimentData.contraryStrength = contraryStrength;
      }
      
      // Get sentiment summary
      signal.sentimentData.summary = m_sentimentAnalyzer.GetMarketSentimentSummary(symbol);
      
      // If sentiment is extremely against our signal direction, reduce the signal strength
      if((signal.direction == SIGNAL_BUY && isBearishExtreme) || 
         (signal.direction == SIGNAL_SELL && isBullishExtreme))
      {
         signal.strength *= 0.7; // Reduce signal strength by 30%
         signal.sentimentData.sentimentConflict = true;
      }
      
      // If there's a very strong contrarian signal aligned with our direction, boost the signal
      if((signal.direction == SIGNAL_BUY && isContraryBullish && contraryStrength > 0.7) ||
         (signal.direction == SIGNAL_SELL && !isContraryBullish && contraryStrength > 0.7))
      {
         signal.strength *= 1.3; // Boost signal strength by 30%
         signal.sentimentData.contraryConfirmation = true;
      }
      
      return true;
   }
   
public:
   // Constructor
   SignalGenerator_AI() : SignalGenerator()
   {
      m_aiAnalyzer = NULL;
      m_sentimentAnalyzer = NULL;
      m_aiInitialized = false;
      m_sentimentInitialized = false;
   }
   
   // Destructor
   ~SignalGenerator_AI()
   {
      if(m_aiAnalyzer != NULL)
         delete m_aiAnalyzer;
         
      if(m_sentimentAnalyzer != NULL)
         delete m_sentimentAnalyzer;
   }
   
   // Initialize with configuration
   bool Initialize(Configuration* config, IndicatorProcessor* indicatorProcessor)
   {
      // Initialize base SignalGenerator first
      if(!SignalGenerator::Initialize(config, indicatorProcessor))
         return false;
      
      // Create and initialize AI analyzer if enabled
      if(config.GetEnableAIAnalysis())
      {
         m_aiAnalyzer = new AISignalAnalyzer();
         m_aiInitialized = m_aiAnalyzer.Initialize(config, indicatorProcessor);
         
         if(!m_aiInitialized)
         {
            Print("Failed to initialize AI Signal Analyzer");
            return false;
         }
      }
      
      // Create and initialize sentiment analyzer if enabled
      if(config.GetEnableSentimentAnalysis())
      {
         m_sentimentAnalyzer = new MarketSentimentAnalyzer();
         m_sentimentInitialized = m_sentimentAnalyzer.Initialize(config);
         
         if(!m_sentimentInitialized)
         {
            Print("Failed to initialize Market Sentiment Analyzer");
            // Not critical, can continue
         }
      }
      
      return true;
   }
   
   // Generate an AI-enhanced signal
   bool GenerateAIEnhancedSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      // First, generate a base signal using the traditional method
      if(!SignalGenerator::GenerateSignal(symbol, timeframe, signal))
         return false;
      
      // If AI analysis is enabled and initialized, enhance the signal
      if(m_config.GetEnableAIAnalysis() && m_aiInitialized)
      {
         if(!EnhanceSignalWithAI(symbol, timeframe, signal))
            return false;
      }
      
      // If sentiment analysis is enabled and initialized, enhance with sentiment
      if(m_config.GetEnableSentimentAnalysis() && m_sentimentInitialized)
      {
         EnhanceSignalWithSentiment(symbol, signal);
      }
      
      return true;
   }
};