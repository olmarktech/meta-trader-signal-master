//+------------------------------------------------------------------+
//|                                                MT5_Signal_Bot.mq5 |
//|                        Copyright 2023, Your Company               |
//|                                       https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property description "MT5 Trading Signals Bot"
#property strict

// Include necessary files
#include <SignalBot/Constants.mqh>
#include <SignalBot/Configuration.mqh>
#include <SignalBot/IndicatorProcessor.mqh>
#include <SignalBot/SignalGenerator.mqh>
#include <SignalBot/SignalGenerator_AI.mqh>
#include <SignalBot/AISignalAnalyzer.mqh>
#include <SignalBot/MarketSentimentAnalyzer.mqh>
#include <SignalBot/RiskManager.mqh>
#include <SignalBot/Notifier.mqh>
#include <SignalBot/UIManager.mqh>
#include <SignalBot/Strategy.mqh>
#include <SignalBot/Backtester.mqh>
#include <SignalBot/Utils.mqh>
#include <SignalBot/NewsFilter.mqh>
#include <SignalBot/APIServer.mqh>  // Add APIServer include

// Global variables
Configuration config;
IndicatorProcessor indicatorProcessor;
SignalGenerator_AI signalGenerator;  // Using AI-enhanced signal generator
RiskManager riskManager;
Notifier notifier;
UIManager uiManager;
NewsFilter newsFilter;
Backtester backtester;
SignalBotAPI apiServer;           // Add API server instance

// Input parameters
input string GeneralSettings = "=== General Settings ==="; // General Settings
input bool EnableBacktesting = false; // Enable Backtesting Mode
input ENUM_TIMEFRAMES TimeFrame = PERIOD_H1; // Main Timeframe
input string TradingSymbols = "EURUSD,GBPUSD,USDJPY,AUDUSD"; // Trading Symbols (comma separated)
input bool AutoDetectVolatilePairs = false; // Auto-detect Volatile Pairs
input int MaxDailyTrades = 5; // Maximum Daily Trades

input string RiskSettings = "=== Risk Management Settings ==="; // Risk Settings
input double LotSize = 0.01; // Fixed Lot Size
input bool UsePercentRisk = false; // Use Percentage Risk
input double RiskPercent = 1.0; // Risk Percent of Balance (if above is true)
input double StopLossPips = 50; // Stop Loss in Pips
input double TakeProfitPips = 100; // Take Profit in Pips
input bool UseTrailingStop = false; // Use Trailing Stop
input double TrailingStopPips = 20; // Trailing Stop in Pips
input double RiskRewardRatio = 2.0; // Risk-Reward Ratio

input string SignalSettings = "=== Signal Settings ==="; // Signal Settings
input int MinimumSignalStrength = 3; // Minimum Signal Strength (1-10)
input bool EnableNewsFilter = true; // Enable News Filter
input ENUM_NEWS_IMPORTANCE MinNewsImportance = NEWS_IMPORTANCE_MEDIUM; // Minimum News Importance to Filter

input string AISettings = "=== AI Analysis Settings ==="; // AI Settings
input bool EnableAIAnalysis = true; // Enable AI-Enhanced Signal Analysis
input bool EnableSentimentAnalysis = true; // Enable Market Sentiment Analysis

input string StrategyPresets = "=== Strategy Presets ==="; // Strategy Presets
input ENUM_STRATEGY_PRESET StrategyPreset = STRATEGY_TREND_FOLLOWING; // Strategy Preset
input bool CustomizeStrategy = false; // Customize Strategy Indicators

input string IndicatorSettings = "=== Indicator Settings (if Customize Strategy) ==="; // Indicator Settings
input bool UseMACross = true; // Use Moving Average Cross
input bool UseRSI = true; // Use RSI
input bool UseMACD = true; // Use MACD
input bool UseStochastic = false; // Use Stochastic Oscillator
input bool UseBollingerBands = false; // Use Bollinger Bands
input bool UseADX = true; // Use ADX
input bool UseATR = true; // Use ATR for Dynamic SL/TP
input bool UseFibonacci = false; // Use Fibonacci Retracement
input bool UsePriceAction = true; // Use Price Action Patterns

input string NotificationSettings = "=== Notification Settings ==="; // Notification Settings
input bool EnableMT5Alerts = true; // Enable MT5 Alerts
input bool EnableEmailAlerts = false; // Enable Email Alerts
input bool EnableTelegramAlerts = false; // Enable Telegram Alerts
input string TelegramBotToken = ""; // Telegram Bot Token
input string TelegramChatID = ""; // Telegram Chat ID

input string DashboardSettings = "=== Dashboard Settings ==="; // Dashboard Settings
input bool ShowDashboard = true; // Show Dashboard
input int DashboardX = 20; // Dashboard X Position
input int DashboardY = 20; // Dashboard Y Position
input int DashboardFontSize = 10; // Dashboard Font Size

input string APISettings = "=== Remote API Settings ==="; // API Settings
input bool EnableRemoteAPI = true; // Enable Remote API
input int APIPort = 5555; // API Port
input int APIUpdateInterval = 5; // API Update Interval (seconds)

// Global variables for state management
int totalSignals = 0;
int totalTrades = 0;
datetime lastCalculationTime = 0;
bool isInitialized = false;
string activeSymbols[];
int activeSymbolsCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("MT5 Trading Signals Bot - Initializing...");
   
   // Initialize configuration
   if(!config.Initialize())
   {
      Print("Failed to initialize configuration. Exiting...");
      return INIT_FAILED;
   }
   
   // Load settings from inputs to config
   LoadConfigFromInputs();
   
   // Initialize components
   if(!InitializeComponents())
   {
      Print("Failed to initialize components. Exiting...");
      return INIT_FAILED;
   }
   
   // Parse symbols
   ParseSymbols();
   
   // Initialize UI
   if(ShowDashboard)
   {
      uiManager.CreateDashboard(DashboardX, DashboardY, DashboardFontSize);
   }
   
   // Initialize API server
   if(EnableRemoteAPI)
   {
      if(!apiServer.Initialize(APIPort))
      {
         Print("Warning: Failed to initialize API server: ", apiServer.GetLastError());
         // Continue even if API server fails to initialize
      }
      else
      {
         Print("API server initialized on port ", APIPort);
         
         // Set up timer for API processing
         EventSetTimer(APIUpdateInterval);
      }
   }
   
   Print("MT5 Trading Signals Bot - Initialized successfully");
   isInitialized = true;
   
   // Start backtesting if enabled
   if(EnableBacktesting)
   {
      backtester.Start();
   }
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Clean up resources
   if(ShowDashboard)
   {
      uiManager.DestroyDashboard();
   }
   
   // Shut down API server
   if(EnableRemoteAPI && apiServer.IsInitialized())
   {
      // Stop the timer
      EventKillTimer();
      
      // Shutdown the API server
      apiServer.Shutdown();
      Print("API server shut down");
   }
   
   Print("MT5 Trading Signals Bot - Deinitialized");
}

//+------------------------------------------------------------------+
//| Timer function                                                    |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Process API server requests
   if(EnableRemoteAPI && apiServer.IsInitialized())
   {
      apiServer.ProcessRequests();
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!isInitialized) return;
   
   // Skip if less than X seconds passed since last calculation
   datetime currentTime = TimeCurrent();
   if(currentTime - lastCalculationTime < 5) return; // 5 seconds interval
   
   lastCalculationTime = currentTime;
   
   // In backtesting mode, let the backtester handle everything
   if(EnableBacktesting)
   {
      backtester.ProcessTick();
      return;
   }
   
   // Process each active symbol
   for(int i = 0; i < activeSymbolsCount; i++)
   {
      string symbol = activeSymbols[i];
      ProcessSymbol(symbol);
   }
   
   // Update dashboard
   if(ShowDashboard)
   {
      uiManager.UpdateDashboard();
   }
}

//+------------------------------------------------------------------+
//| Process a specific symbol                                        |
//+------------------------------------------------------------------+
void ProcessSymbol(string symbol)
{
   // Check if there's a high-impact news event
   if(EnableNewsFilter && newsFilter.IsHighImpactNewsTime(symbol))
   {
      Print("Skipping ", symbol, " analysis due to high-impact news event");
      return;
   }
   
   // Process indicators
   if(!indicatorProcessor.ProcessIndicators(symbol, TimeFrame))
   {
      Print("Failed to process indicators for ", symbol);
      return;
   }
   
   // Generate signals
   SignalInfo signal;
   bool signalGenerated = false;
   
   // If AI Analysis is enabled, use the AI-enhanced signal generation
   if(EnableAIAnalysis)
   {
      signalGenerated = signalGenerator.GenerateAIEnhancedSignal(symbol, TimeFrame, signal);
      if(signalGenerated)
      {
         Print("AI-enhanced signal generated for ", symbol);
      }
   }
   else
   {
      // Otherwise use traditional signal generation
      signalGenerated = signalGenerator.GenerateSignal(symbol, TimeFrame, signal);
   }
   
   if(!signalGenerated)
   {
      Print("No signal generated for ", symbol);
      return;
   }
   
   // Check signal strength
   if(signal.strength < MinimumSignalStrength)
   {
      Print("Signal strength too low for ", symbol, ": ", signal.strength);
      return;
   }
   
   // Check daily trade limit
   if(totalTrades >= MaxDailyTrades)
   {
      Print("Daily trade limit reached");
      return;
   }
   
   // Calculate risk parameters
   TradeParameters tradeParams;
   if(!riskManager.CalculateTradeParameters(symbol, signal.direction, tradeParams))
   {
      Print("Failed to calculate risk parameters for ", symbol);
      return;
   }
   
   // Send notifications
   notifier.SendSignalAlert(symbol, signal, tradeParams);
   
   // Update stats
   totalSignals++;
   if(signal.executeSignal) totalTrades++;
   
   // Add to dashboard
   uiManager.AddSignalToDashboard(symbol, signal, tradeParams);
}

//+------------------------------------------------------------------+
//| Load configuration from input parameters                         |
//+------------------------------------------------------------------+
void LoadConfigFromInputs()
{
   // General settings
   config.SetTimeFrame(TimeFrame);
   config.SetMaxDailyTrades(MaxDailyTrades);
   config.SetAutoDetectVolatilePairs(AutoDetectVolatilePairs);
   
   // Risk settings
   config.SetLotSize(LotSize);
   config.SetUsePercentRisk(UsePercentRisk);
   config.SetRiskPercent(RiskPercent);
   config.SetStopLossPips(StopLossPips);
   config.SetTakeProfitPips(TakeProfitPips);
   config.SetUseTrailingStop(UseTrailingStop);
   config.SetTrailingStopPips(TrailingStopPips);
   config.SetRiskRewardRatio(RiskRewardRatio);
   
   // Signal settings
   config.SetMinimumSignalStrength(MinimumSignalStrength);
   config.SetEnableNewsFilter(EnableNewsFilter);
   config.SetMinNewsImportance(MinNewsImportance);
   config.SetEnableAIAnalysis(EnableAIAnalysis);
   config.SetEnableSentimentAnalysis(EnableSentimentAnalysis);
   
   // Strategy preset
   config.SetStrategyPreset(StrategyPreset);
   config.SetCustomizeStrategy(CustomizeStrategy);
   
   // Indicator settings
   config.SetUseMACross(UseMACross);
   config.SetUseRSI(UseRSI);
   config.SetUseMACD(UseMACD);
   config.SetUseStochastic(UseStochastic);
   config.SetUseBollingerBands(UseBollingerBands);
   config.SetUseADX(UseADX);
   config.SetUseATR(UseATR);
   config.SetUseFibonacci(UseFibonacci);
   config.SetUsePriceAction(UsePriceAction);
   
   // Notification settings
   config.SetEnableMT5Alerts(EnableMT5Alerts);
   config.SetEnableEmailAlerts(EnableEmailAlerts);
   config.SetEnableTelegramAlerts(EnableTelegramAlerts);
   config.SetTelegramBotToken(TelegramBotToken);
   config.SetTelegramChatID(TelegramChatID);
}

//+------------------------------------------------------------------+
//| Initialize all components                                        |
//+------------------------------------------------------------------+
bool InitializeComponents()
{
   if(!indicatorProcessor.Initialize(&config))
   {
      Print("Failed to initialize indicator processor");
      return false;
   }
   
   if(!signalGenerator.Initialize(&config, &indicatorProcessor))
   {
      Print("Failed to initialize signal generator");
      return false;
   }
   
   if(!riskManager.Initialize(&config))
   {
      Print("Failed to initialize risk manager");
      return false;
   }
   
   if(!notifier.Initialize(&config))
   {
      Print("Failed to initialize notifier");
      return false;
   }
   
   if(ShowDashboard)
   {
      if(!uiManager.Initialize(&config))
      {
         Print("Failed to initialize UI manager");
         return false;
      }
   }
   
   if(EnableNewsFilter)
   {
      if(!newsFilter.Initialize(&config))
      {
         Print("Failed to initialize news filter");
         return false;
      }
   }
   
   if(EnableBacktesting)
   {
      if(!backtester.Initialize(&config, &signalGenerator, &riskManager))
      {
         Print("Failed to initialize backtester");
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Parse symbols from input string                                  |
//+------------------------------------------------------------------+
void ParseSymbols()
{
   string symbolArray[];
   int count = StringSplit(TradingSymbols, ',', symbolArray);
   
   if(count == 0)
   {
      activeSymbols[0] = Symbol();
      activeSymbolsCount = 1;
   }
   else
   {
      activeSymbolsCount = count;
      ArrayResize(activeSymbols, count);
      
      for(int i = 0; i < count; i++)
      {
         activeSymbols[i] = StringTrimRight(StringTrimLeft(symbolArray[i]));
      }
   }
   
   // If auto-detect volatile pairs is enabled, replace with volatile pairs
   if(AutoDetectVolatilePairs)
   {
      string volatilePairs[];
      int volatileCount = Utils::DetectVolatilePairs(volatilePairs);
      
      if(volatileCount > 0)
      {
         activeSymbolsCount = volatileCount;
         ArrayResize(activeSymbols, volatileCount);
         
         for(int i = 0; i < volatileCount; i++)
         {
            activeSymbols[i] = volatilePairs[i];
         }
      }
   }
   
   // Print active symbols
   string symbolsList = "";
   for(int i = 0; i < activeSymbolsCount; i++)
   {
      symbolsList += (i > 0 ? ", " : "") + activeSymbols[i];
   }
   
   Print("Active trading symbols: ", symbolsList);
}
