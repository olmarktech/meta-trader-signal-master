//+------------------------------------------------------------------+
//|                                               Configuration.mqh |
//|                        Copyright 2023, Your Company               |
//|                                       https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include "Constants.mqh"

//+------------------------------------------------------------------+
//| Configuration class to manage all settings                        |
//+------------------------------------------------------------------+
class Configuration
{
private:
   // General settings
   ENUM_TIMEFRAMES m_timeframe;
   int m_maxDailyTrades;
   bool m_autoDetectVolatilePairs;
   
   // Risk settings
   double m_lotSize;
   bool m_usePercentRisk;
   double m_riskPercent;
   double m_stopLossPips;
   double m_takeProfitPips;
   bool m_useTrailingStop;
   double m_trailingStopPips;
   double m_riskRewardRatio;
   
   // Signal settings
   int m_minimumSignalStrength;
   bool m_enableNewsFilter;
   ENUM_NEWS_IMPORTANCE m_minNewsImportance;
   bool m_enableAIAnalysis;
   bool m_enableSentimentAnalysis;
   
   // Strategy preset
   ENUM_STRATEGY_PRESET m_strategyPreset;
   bool m_customizeStrategy;
   
   // Indicator settings
   bool m_useMACross;
   bool m_useRSI;
   bool m_useMACD;
   bool m_useStochastic;
   bool m_useBollingerBands;
   bool m_useADX;
   bool m_useATR;
   bool m_useFibonacci;
   bool m_usePriceAction;
   
   // Notification settings
   bool m_enableMT5Alerts;
   bool m_enableEmailAlerts;
   bool m_enableTelegramAlerts;
   string m_telegramBotToken;
   string m_telegramChatID;
   
   // Indicator parameters
   int m_fastMA;
   int m_slowMA;
   ENUM_MA_METHOD m_maMethod;
   ENUM_APPLIED_PRICE m_maAppliedPrice;
   
   int m_rsiPeriod;
   int m_rsiOverbought;
   int m_rsiOversold;
   
   int m_macdFast;
   int m_macdSlow;
   int m_macdSignal;
   
   int m_stochKPeriod;
   int m_stochDPeriod;
   int m_stochSlowing;
   
   int m_bbPeriod;
   double m_bbDeviation;
   
   int m_adxPeriod;
   int m_adxThreshold;
   
   int m_atrPeriod;
   
public:
   // Constructor
   Configuration()
   {
      // Set default values
      SetDefaults();
   }
   
   // Initialize the configuration
   bool Initialize()
   {
      return true;
   }
   
   // Set default values based on strategy preset
   void SetDefaults()
   {
      // General settings
      m_timeframe = PERIOD_H1;
      m_maxDailyTrades = 5;
      m_autoDetectVolatilePairs = false;
      
      // Risk settings
      m_lotSize = 0.01;
      m_usePercentRisk = false;
      m_riskPercent = 1.0;
      m_stopLossPips = 50;
      m_takeProfitPips = 100;
      m_useTrailingStop = false;
      m_trailingStopPips = 20;
      m_riskRewardRatio = 2.0;
      
      // Signal settings
      m_minimumSignalStrength = 3;
      m_enableNewsFilter = true;
      m_minNewsImportance = NEWS_IMPORTANCE_MEDIUM;
      m_enableAIAnalysis = true;
      m_enableSentimentAnalysis = true;
      
      // Strategy preset
      m_strategyPreset = STRATEGY_TREND_FOLLOWING;
      m_customizeStrategy = false;
      
      // Indicator settings - defaults
      m_useMACross = true;
      m_useRSI = true;
      m_useMACD = true;
      m_useStochastic = false;
      m_useBollingerBands = false;
      m_useADX = true;
      m_useATR = true;
      m_useFibonacci = false;
      m_usePriceAction = true;
      
      // Notification settings
      m_enableMT5Alerts = true;
      m_enableEmailAlerts = false;
      m_enableTelegramAlerts = false;
      m_telegramBotToken = "";
      m_telegramChatID = "";
      
      // Set indicator parameters based on default strategy
      SetIndicatorParametersByStrategy(m_strategyPreset);
   }
   
   // Set indicator parameters based on strategy preset
   void SetIndicatorParametersByStrategy(ENUM_STRATEGY_PRESET preset)
   {
      switch(preset)
      {
         case STRATEGY_SCALPING:
            m_timeframe = PERIOD_M5;
            m_fastMA = 5;
            m_slowMA = 10;
            m_maMethod = MODE_EMA;
            m_maAppliedPrice = PRICE_CLOSE;
            
            m_rsiPeriod = 7;
            m_rsiOverbought = 70;
            m_rsiOversold = 30;
            
            m_stochKPeriod = 5;
            m_stochDPeriod = 3;
            m_stochSlowing = 3;
            
            m_useMACross = true;
            m_useRSI = true;
            m_useMACD = false;
            m_useStochastic = true;
            m_useBollingerBands = false;
            m_useADX = false;
            m_useATR = true;
            m_useFibonacci = false;
            m_usePriceAction = false;
            break;
            
         case STRATEGY_SWING_TRADING:
            m_timeframe = PERIOD_H4;
            m_fastMA = 21;
            m_slowMA = 50;
            m_maMethod = MODE_SMA;
            m_maAppliedPrice = PRICE_CLOSE;
            
            m_macdFast = 12;
            m_macdSlow = 26;
            m_macdSignal = 9;
            
            m_useMACross = false;
            m_useRSI = false;
            m_useMACD = true;
            m_useStochastic = false;
            m_useBollingerBands = false;
            m_useADX = false;
            m_useATR = true;
            m_useFibonacci = true;
            m_usePriceAction = true;
            break;
            
         case STRATEGY_TREND_FOLLOWING:
            m_timeframe = PERIOD_H1;
            m_fastMA = 20;
            m_slowMA = 50;
            m_maMethod = MODE_EMA;
            m_maAppliedPrice = PRICE_CLOSE;
            
            m_rsiPeriod = 14;
            m_rsiOverbought = 70;
            m_rsiOversold = 30;
            
            m_adxPeriod = 14;
            m_adxThreshold = 25;
            
            m_useMACross = true;
            m_useRSI = true;
            m_useMACD = false;
            m_useStochastic = false;
            m_useBollingerBands = false;
            m_useADX = true;
            m_useATR = true;
            m_useFibonacci = false;
            m_usePriceAction = false;
            break;
            
         case STRATEGY_REVERSAL:
            m_timeframe = PERIOD_H1;
            m_rsiPeriod = 14;
            m_rsiOverbought = 70;
            m_rsiOversold = 30;
            
            m_bbPeriod = 20;
            m_bbDeviation = 2.0;
            
            m_useMACross = false;
            m_useRSI = true;
            m_useMACD = false;
            m_useStochastic = false;
            m_useBollingerBands = true;
            m_useADX = false;
            m_useATR = true;
            m_useFibonacci = false;
            m_usePriceAction = true;
            break;
      }
   }
   
   // Getters and Setters for all configuration parameters
   // General settings
   ENUM_TIMEFRAMES GetTimeFrame() { return m_timeframe; }
   void SetTimeFrame(ENUM_TIMEFRAMES timeframe) { m_timeframe = timeframe; }
   
   int GetMaxDailyTrades() { return m_maxDailyTrades; }
   void SetMaxDailyTrades(int maxTrades) { m_maxDailyTrades = maxTrades; }
   
   bool GetAutoDetectVolatilePairs() { return m_autoDetectVolatilePairs; }
   void SetAutoDetectVolatilePairs(bool autoDetect) { m_autoDetectVolatilePairs = autoDetect; }
   
   // Risk settings
   double GetLotSize() { return m_lotSize; }
   void SetLotSize(double lotSize) { m_lotSize = lotSize; }
   
   bool GetUsePercentRisk() { return m_usePercentRisk; }
   void SetUsePercentRisk(bool usePercent) { m_usePercentRisk = usePercent; }
   
   double GetRiskPercent() { return m_riskPercent; }
   void SetRiskPercent(double percent) { m_riskPercent = percent; }
   
   double GetStopLossPips() { return m_stopLossPips; }
   void SetStopLossPips(double pips) { m_stopLossPips = pips; }
   
   double GetTakeProfitPips() { return m_takeProfitPips; }
   void SetTakeProfitPips(double pips) { m_takeProfitPips = pips; }
   
   bool GetUseTrailingStop() { return m_useTrailingStop; }
   void SetUseTrailingStop(bool useTrailing) { m_useTrailingStop = useTrailing; }
   
   double GetTrailingStopPips() { return m_trailingStopPips; }
   void SetTrailingStopPips(double pips) { m_trailingStopPips = pips; }
   
   double GetRiskRewardRatio() { return m_riskRewardRatio; }
   void SetRiskRewardRatio(double ratio) { m_riskRewardRatio = ratio; }
   
   // Signal settings
   int GetMinimumSignalStrength() { return m_minimumSignalStrength; }
   void SetMinimumSignalStrength(int strength) { m_minimumSignalStrength = strength; }
   
   bool GetEnableNewsFilter() { return m_enableNewsFilter; }
   void SetEnableNewsFilter(bool enable) { m_enableNewsFilter = enable; }
   
   ENUM_NEWS_IMPORTANCE GetMinNewsImportance() { return m_minNewsImportance; }
   void SetMinNewsImportance(ENUM_NEWS_IMPORTANCE importance) { m_minNewsImportance = importance; }
   
   bool GetEnableAIAnalysis() { return m_enableAIAnalysis; }
   void SetEnableAIAnalysis(bool enable) { m_enableAIAnalysis = enable; }
   
   bool GetEnableSentimentAnalysis() { return m_enableSentimentAnalysis; }
   void SetEnableSentimentAnalysis(bool enable) { m_enableSentimentAnalysis = enable; }
   
   // Strategy preset
   ENUM_STRATEGY_PRESET GetStrategyPreset() { return m_strategyPreset; }
   void SetStrategyPreset(ENUM_STRATEGY_PRESET preset) 
   { 
      m_strategyPreset = preset; 
      if(!m_customizeStrategy)
      {
         SetIndicatorParametersByStrategy(preset);
      }
   }
   
   bool GetCustomizeStrategy() { return m_customizeStrategy; }
   void SetCustomizeStrategy(bool customize) { m_customizeStrategy = customize; }
   
   // Indicator settings
   bool GetUseMACross() { return m_useMACross; }
   void SetUseMACross(bool use) { m_useMACross = use; }
   
   bool GetUseRSI() { return m_useRSI; }
   void SetUseRSI(bool use) { m_useRSI = use; }
   
   bool GetUseMACD() { return m_useMACD; }
   void SetUseMACD(bool use) { m_useMACD = use; }
   
   bool GetUseStochastic() { return m_useStochastic; }
   void SetUseStochastic(bool use) { m_useStochastic = use; }
   
   bool GetUseBollingerBands() { return m_useBollingerBands; }
   void SetUseBollingerBands(bool use) { m_useBollingerBands = use; }
   
   bool GetUseADX() { return m_useADX; }
   void SetUseADX(bool use) { m_useADX = use; }
   
   bool GetUseATR() { return m_useATR; }
   void SetUseATR(bool use) { m_useATR = use; }
   
   bool GetUseFibonacci() { return m_useFibonacci; }
   void SetUseFibonacci(bool use) { m_useFibonacci = use; }
   
   bool GetUsePriceAction() { return m_usePriceAction; }
   void SetUsePriceAction(bool use) { m_usePriceAction = use; }
   
   // Notification settings
   bool GetEnableMT5Alerts() { return m_enableMT5Alerts; }
   void SetEnableMT5Alerts(bool enable) { m_enableMT5Alerts = enable; }
   
   bool GetEnableEmailAlerts() { return m_enableEmailAlerts; }
   void SetEnableEmailAlerts(bool enable) { m_enableEmailAlerts = enable; }
   
   bool GetEnableTelegramAlerts() { return m_enableTelegramAlerts; }
   void SetEnableTelegramAlerts(bool enable) { m_enableTelegramAlerts = enable; }
   
   string GetTelegramBotToken() { return m_telegramBotToken; }
   void SetTelegramBotToken(string token) { m_telegramBotToken = token; }
   
   string GetTelegramChatID() { return m_telegramChatID; }
   void SetTelegramChatID(string chatID) { m_telegramChatID = chatID; }
   
   // Indicator parameters
   int GetFastMA() { return m_fastMA; }
   int GetSlowMA() { return m_slowMA; }
   ENUM_MA_METHOD GetMAMethod() { return m_maMethod; }
   ENUM_APPLIED_PRICE GetMAAppliedPrice() { return m_maAppliedPrice; }
   
   int GetRSIPeriod() { return m_rsiPeriod; }
   int GetRSIOverbought() { return m_rsiOverbought; }
   int GetRSIOversold() { return m_rsiOversold; }
   
   int GetMACDFast() { return m_macdFast; }
   int GetMACDSlow() { return m_macdSlow; }
   int GetMACDSignal() { return m_macdSignal; }
   
   int GetStochKPeriod() { return m_stochKPeriod; }
   int GetStochDPeriod() { return m_stochDPeriod; }
   int GetStochSlowing() { return m_stochSlowing; }
   
   int GetBBPeriod() { return m_bbPeriod; }
   double GetBBDeviation() { return m_bbDeviation; }
   
   int GetADXPeriod() { return m_adxPeriod; }
   int GetADXThreshold() { return m_adxThreshold; }
   
   int GetATRPeriod() { return m_atrPeriod; }
};
