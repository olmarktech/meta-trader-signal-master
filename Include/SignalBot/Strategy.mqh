//+------------------------------------------------------------------+
//|                                                     Strategy.mqh |
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
#include "SignalGenerator.mqh"

//+------------------------------------------------------------------+
//| Base class for strategies                                         |
//+------------------------------------------------------------------+
class Strategy
{
protected:
   string m_name;
   string m_description;
   Configuration* m_config;
   IndicatorProcessor* m_indicatorProcessor;
   SignalGenerator* m_signalGenerator;
   
public:
   // Constructor
   Strategy()
   {
      m_name = "Base Strategy";
      m_description = "Base strategy class";
      m_config = NULL;
      m_indicatorProcessor = NULL;
      m_signalGenerator = NULL;
   }
   
   // Virtual destructor
   virtual ~Strategy() {}
   
   // Initialize the strategy
   virtual bool Initialize(Configuration* config, IndicatorProcessor* indicatorProcessor, SignalGenerator* signalGenerator)
   {
      if(config == NULL || indicatorProcessor == NULL || signalGenerator == NULL) return false;
      
      m_config = config;
      m_indicatorProcessor = indicatorProcessor;
      m_signalGenerator = signalGenerator;
      return true;
   }
   
   // Generate signal - to be overridden by derived classes
   virtual bool GenerateSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      return false;
   }
   
   // Load strategy settings from file
   virtual bool LoadSettings(string filename)
   {
      return false;
   }
   
   // Save strategy settings to file
   virtual bool SaveSettings(string filename)
   {
      return false;
   }
   
   // Get strategy name
   string GetName()
   {
      return m_name;
   }
   
   // Get strategy description
   string GetDescription()
   {
      return m_description;
   }
};

//+------------------------------------------------------------------+
//| Scalping strategy class                                           |
//+------------------------------------------------------------------+
class ScalpingStrategy : public Strategy
{
public:
   // Constructor
   ScalpingStrategy()
   {
      m_name = "Scalping Strategy";
      m_description = "Fast strategy for M1/M5 timeframes with quick entries and exits";
   }
   
   // Initialize with scalping-specific settings
   bool Initialize(Configuration* config, IndicatorProcessor* indicatorProcessor, SignalGenerator* signalGenerator)
   {
      if(!Strategy::Initialize(config, indicatorProcessor, signalGenerator)) return false;
      
      // Set scalping-specific settings when initialized
      // These would override any existing settings
      
      return true;
   }
   
   // Generate signal for scalping strategy
   bool GenerateSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      return m_signalGenerator.GenerateScalpingSignal(symbol, timeframe, signal);
   }
};

//+------------------------------------------------------------------+
//| Swing Trading strategy class                                      |
//+------------------------------------------------------------------+
class SwingTradingStrategy : public Strategy
{
public:
   // Constructor
   SwingTradingStrategy()
   {
      m_name = "Swing Trading Strategy";
      m_description = "Medium-term strategy focused on price action and support/resistance";
   }
   
   // Initialize with swing trading-specific settings
   bool Initialize(Configuration* config, IndicatorProcessor* indicatorProcessor, SignalGenerator* signalGenerator)
   {
      if(!Strategy::Initialize(config, indicatorProcessor, signalGenerator)) return false;
      
      // Set swing trading-specific settings when initialized
      
      return true;
   }
   
   // Generate signal for swing trading strategy
   bool GenerateSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      return m_signalGenerator.GenerateSwingTradingSignal(symbol, timeframe, signal);
   }
};

//+------------------------------------------------------------------+
//| Trend Following strategy class                                    |
//+------------------------------------------------------------------+
class TrendFollowingStrategy : public Strategy
{
public:
   // Constructor
   TrendFollowingStrategy()
   {
      m_name = "Trend Following Strategy";
      m_description = "Strategy focused on identifying and following strong trends";
   }
   
   // Initialize with trend following-specific settings
   bool Initialize(Configuration* config, IndicatorProcessor* indicatorProcessor, SignalGenerator* signalGenerator)
   {
      if(!Strategy::Initialize(config, indicatorProcessor, signalGenerator)) return false;
      
      // Set trend following-specific settings when initialized
      
      return true;
   }
   
   // Generate signal for trend following strategy
   bool GenerateSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      return m_signalGenerator.GenerateTrendFollowingSignal(symbol, timeframe, signal);
   }
};

//+------------------------------------------------------------------+
//| Reversal strategy class                                           |
//+------------------------------------------------------------------+
class ReversalStrategy : public Strategy
{
public:
   // Constructor
   ReversalStrategy()
   {
      m_name = "Reversal Strategy";
      m_description = "Strategy focused on identifying and trading market reversals";
   }
   
   // Initialize with reversal-specific settings
   bool Initialize(Configuration* config, IndicatorProcessor* indicatorProcessor, SignalGenerator* signalGenerator)
   {
      if(!Strategy::Initialize(config, indicatorProcessor, signalGenerator)) return false;
      
      // Set reversal-specific settings when initialized
      
      return true;
   }
   
   // Generate signal for reversal strategy
   bool GenerateSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      return m_signalGenerator.GenerateReversalSignal(symbol, timeframe, signal);
   }
};

//+------------------------------------------------------------------+
//| Custom strategy class                                             |
//+------------------------------------------------------------------+
class CustomStrategy : public Strategy
{
public:
   // Constructor
   CustomStrategy()
   {
      m_name = "Custom Strategy";
      m_description = "User-defined custom strategy with custom indicator settings";
   }
   
   // Generate signal for custom strategy
   bool GenerateSignal(string symbol, ENUM_TIMEFRAMES timeframe, SignalInfo &signal)
   {
      return m_signalGenerator.GenerateCustomSignal(symbol, timeframe, signal);
   }
};

//+------------------------------------------------------------------+
//| Strategy Factory function to create appropriate strategy          |
//+------------------------------------------------------------------+
Strategy* CreateStrategy(ENUM_STRATEGY_PRESET preset)
{
   switch(preset)
   {
      case STRATEGY_SCALPING:
         return new ScalpingStrategy();
         
      case STRATEGY_SWING_TRADING:
         return new SwingTradingStrategy();
         
      case STRATEGY_TREND_FOLLOWING:
         return new TrendFollowingStrategy();
         
      case STRATEGY_REVERSAL:
         return new ReversalStrategy();
         
      default:
         return new CustomStrategy();
   }
}
