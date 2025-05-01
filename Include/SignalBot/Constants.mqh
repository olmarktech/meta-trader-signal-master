//+------------------------------------------------------------------+
//|                                                    Constants.mqh |
//|                        Copyright 2023, Your Company               |
//|                                       https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

// Strategy presets
enum ENUM_STRATEGY_PRESET
{
   STRATEGY_SCALPING,       // Scalping (M1/M5 with fast MA, RSI & Stochastic)
   STRATEGY_SWING_TRADING,  // Swing Trading (Price action, S/R, MACD divergence)
   STRATEGY_TREND_FOLLOWING, // Trend Following (MA cross + ADX + RSI)
   STRATEGY_REVERSAL        // Reversal (Engulfing + RSI divergence + BB)
};

// Signal direction
enum ENUM_SIGNAL_DIRECTION
{
   SIGNAL_NEUTRAL = 0,      // Neutral (No signal)
   SIGNAL_BUY = 1,          // Buy signal
   SIGNAL_SELL = -1         // Sell signal
};

// News importance levels
enum ENUM_NEWS_IMPORTANCE
{
   NEWS_IMPORTANCE_LOW = 1,    // Low impact news
   NEWS_IMPORTANCE_MEDIUM = 2, // Medium impact news
   NEWS_IMPORTANCE_HIGH = 3    // High impact news
};

// AI-powered price prediction
struct PricePrediction
{
   double upProbability;    // Probability of price going up (0-1)
   double downProbability;  // Probability of price going down (0-1)
   
   // Constructor
   PricePrediction()
   {
      upProbability = 0.5;
      downProbability = 0.5;
   }
};

// Market sentiment data
struct SentimentData
{
   // Retail sentiment
   double retailBullishPercent;
   double retailBearishPercent;
   
   // Institutional sentiment
   double institutionalBullishPercent;
   double institutionalBearishPercent;
   
   // Overall sentiment
   double overallBullishScore;
   double overallBearishScore;
   
   // Sentiment state flags
   bool isBullishExtreme;
   bool isBearishExtreme;
   bool isShifting;
   bool isShiftingBullish;
   
   // Retail crowding
   bool isRetailCrowded;
   bool isRetailCrowdedBullish;
   
   // Contrarian signals
   bool hasContrarySignal;
   bool isContraryBullish;
   double contraryStrength;
   
   // Signal modification flags
   bool sentimentConflict;
   bool contraryConfirmation;
   
   // Summary
   string summary;
   
   // Constructor
   SentimentData()
   {
      retailBullishPercent = 50.0;
      retailBearishPercent = 50.0;
      institutionalBullishPercent = 50.0;
      institutionalBearishPercent = 50.0;
      overallBullishScore = 0.5;
      overallBearishScore = 0.5;
      
      isBullishExtreme = false;
      isBearishExtreme = false;
      isShifting = false;
      isShiftingBullish = false;
      
      isRetailCrowded = false;
      isRetailCrowdedBullish = false;
      
      hasContrarySignal = false;
      isContraryBullish = false;
      contraryStrength = 0.0;
      
      sentimentConflict = false;
      contraryConfirmation = false;
      
      summary = "Neutral";
   }
};

// Signal info structure
struct SignalInfo
{
   ENUM_SIGNAL_DIRECTION direction;  // Signal direction
   int strength;                      // Signal strength (1-10)
   string reason;                     // Reason for the signal
   datetime time;                     // Signal generation time
   bool executeSignal;                // Whether to auto-execute the trade
   
   // AI-enhanced signal properties
   double aiStrength;                // AI-calculated signal strength (0-10)
   double signalConfidence;          // Confidence in the signal (0-1)
   double signalReliability;         // Historical reliability of similar signals (0-1)
   double marketSuitability;         // Suitability of current market for this signal (0-1)
   string marketCondition;           // Current market condition (e.g., "Strong Uptrend")
   double marketConditionScore;      // Score of the market condition (0-1)
   
   // Advanced analytical data
   PricePrediction pricePrediction;  // AI-powered price prediction
   SentimentData sentimentData;      // Market sentiment data
   
   // Constructor
   SignalInfo()
   {
      direction = SIGNAL_NEUTRAL;
      strength = 0;
      reason = "";
      time = 0;
      executeSignal = false;
      
      aiStrength = 0.0;
      signalConfidence = 0.0;
      signalReliability = 0.0;
      marketSuitability = 0.0;
      marketCondition = "";
      marketConditionScore = 0.0;
   }
};

// Trade parameters structure
struct TradeParameters
{
   double lotSize;           // Calculated lot size
   double entryPrice;        // Entry price
   double stopLoss;          // Stop loss price
   double takeProfit;        // Take profit price
   int stopLossPips;         // Stop loss in pips
   int takeProfitPips;       // Take profit in pips
   bool useTrailingStop;     // Whether to use trailing stop
   int trailingStopPips;     // Trailing stop in pips
   
   // Constructor
   TradeParameters()
   {
      lotSize = 0.01;
      entryPrice = 0.0;
      stopLoss = 0.0;
      takeProfit = 0.0;
      stopLossPips = 0;
      takeProfitPips = 0;
      useTrailingStop = false;
      trailingStopPips = 0;
   }
};

// Price action patterns
enum ENUM_PRICE_ACTION_PATTERN
{
   PATTERN_NONE = 0,           // No pattern
   PATTERN_BULLISH_ENGULFING,  // Bullish engulfing
   PATTERN_BEARISH_ENGULFING,  // Bearish engulfing
   PATTERN_HAMMER,             // Hammer
   PATTERN_SHOOTING_STAR,      // Shooting star
   PATTERN_DOJI,               // Doji
   PATTERN_MORNING_STAR,       // Morning star
   PATTERN_EVENING_STAR,       // Evening star
   PATTERN_PIERCING_LINE,      // Piercing line
   PATTERN_DARK_CLOUD_COVER,   // Dark cloud cover
   PATTERN_BULLISH_HARAMI,     // Bullish harami
   PATTERN_BEARISH_HARAMI,     // Bearish harami
   PATTERN_PINBAR                // Pin bar
};

// Dashboard colors
#define COLOR_BACKGROUND    clrBlack
#define COLOR_TEXT          clrWhite
#define COLOR_HEADER        clrGray
#define COLOR_BUY_SIGNAL    clrLime
#define COLOR_SELL_SIGNAL   clrRed
#define COLOR_NEUTRAL       clrYellow
