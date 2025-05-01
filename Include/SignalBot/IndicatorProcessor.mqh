//+------------------------------------------------------------------+
//|                                            IndicatorProcessor.mqh |
//|                        Copyright 2023, Your Company               |
//|                                       https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include "Constants.mqh"
#include "Configuration.mqh"

//+------------------------------------------------------------------+
//| Class to process indicator values                                 |
//+------------------------------------------------------------------+
class IndicatorProcessor
{
private:
   Configuration* m_config;
   
   // Indicator handles
   int m_maFastHandle;
   int m_maSlowHandle;
   int m_rsiHandle;
   int m_macdHandle;
   int m_stochHandle;
   int m_bbHandle;
   int m_adxHandle;
   int m_atrHandle;
   
   // Indicator buffers
   double m_maFastBuffer[];
   double m_maSlowBuffer[];
   double m_rsiBuffer[];
   double m_macdMainBuffer[];
   double m_macdSignalBuffer[];
   double m_stochMainBuffer[];
   double m_stochSignalBuffer[];
   double m_bbUpperBuffer[];
   double m_bbMiddleBuffer[];
   double m_bbLowerBuffer[];
   double m_adxMainBuffer[];
   double m_adxPlusDIBuffer[];
   double m_adxMinusDIBuffer[];
   double m_atrBuffer[];
   
   // Price action patterns cache
   ENUM_PRICE_ACTION_PATTERN m_lastPattern;
   datetime m_lastPatternTime;
   string m_lastSymbol;
   
   // Initialize indicator handles
   bool InitializeHandles(string symbol, ENUM_TIMEFRAMES timeframe)
   {
      bool success = true;
      
      // Initialize Moving Averages if needed
      if(m_config.GetUseMACross())
      {
         m_maFastHandle = iMA(symbol, timeframe, m_config.GetFastMA(), 0, m_config.GetMAMethod(), 
                             m_config.GetMAAppliedPrice());
         m_maSlowHandle = iMA(symbol, timeframe, m_config.GetSlowMA(), 0, m_config.GetMAMethod(), 
                             m_config.GetMAAppliedPrice());
         
         if(m_maFastHandle == INVALID_HANDLE || m_maSlowHandle == INVALID_HANDLE)
         {
            Print("Failed to create MA handles for " + symbol);
            success = false;
         }
      }
      
      // Initialize RSI if needed
      if(m_config.GetUseRSI())
      {
         m_rsiHandle = iRSI(symbol, timeframe, m_config.GetRSIPeriod(), PRICE_CLOSE);
         
         if(m_rsiHandle == INVALID_HANDLE)
         {
            Print("Failed to create RSI handle for " + symbol);
            success = false;
         }
      }
      
      // Initialize MACD if needed
      if(m_config.GetUseMACD())
      {
         m_macdHandle = iMACD(symbol, timeframe, m_config.GetMACDFast(), m_config.GetMACDSlow(), 
                             m_config.GetMACDSignal(), PRICE_CLOSE);
         
         if(m_macdHandle == INVALID_HANDLE)
         {
            Print("Failed to create MACD handle for " + symbol);
            success = false;
         }
      }
      
      // Initialize Stochastic if needed
      if(m_config.GetUseStochastic())
      {
         m_stochHandle = iStochastic(symbol, timeframe, m_config.GetStochKPeriod(), 
                                   m_config.GetStochDPeriod(), m_config.GetStochSlowing(), 
                                   MODE_SMA, STO_LOWHIGH);
         
         if(m_stochHandle == INVALID_HANDLE)
         {
            Print("Failed to create Stochastic handle for " + symbol);
            success = false;
         }
      }
      
      // Initialize Bollinger Bands if needed
      if(m_config.GetUseBollingerBands())
      {
         m_bbHandle = iBands(symbol, timeframe, m_config.GetBBPeriod(), 0, 
                           m_config.GetBBDeviation(), PRICE_CLOSE);
         
         if(m_bbHandle == INVALID_HANDLE)
         {
            Print("Failed to create Bollinger Bands handle for " + symbol);
            success = false;
         }
      }
      
      // Initialize ADX if needed
      if(m_config.GetUseADX())
      {
         m_adxHandle = iADX(symbol, timeframe, m_config.GetADXPeriod());
         
         if(m_adxHandle == INVALID_HANDLE)
         {
            Print("Failed to create ADX handle for " + symbol);
            success = false;
         }
      }
      
      // Initialize ATR if needed
      if(m_config.GetUseATR())
      {
         m_atrHandle = iATR(symbol, timeframe, m_config.GetATRPeriod());
         
         if(m_atrHandle == INVALID_HANDLE)
         {
            Print("Failed to create ATR handle for " + symbol);
            success = false;
         }
      }
      
      return success;
   }
   
   // Copy indicator data to buffers
   bool CopyIndicatorData(string symbol, ENUM_TIMEFRAMES timeframe, int bars)
   {
      if(bars <= 0) return false;
      
      bool success = true;
      
      // Copy MA data if needed
      if(m_config.GetUseMACross())
      {
         if(CopyBuffer(m_maFastHandle, 0, 0, bars, m_maFastBuffer) <= 0)
         {
            Print("Failed to copy fast MA data for " + symbol);
            success = false;
         }
         
         if(CopyBuffer(m_maSlowHandle, 0, 0, bars, m_maSlowBuffer) <= 0)
         {
            Print("Failed to copy slow MA data for " + symbol);
            success = false;
         }
      }
      
      // Copy RSI data if needed
      if(m_config.GetUseRSI())
      {
         if(CopyBuffer(m_rsiHandle, 0, 0, bars, m_rsiBuffer) <= 0)
         {
            Print("Failed to copy RSI data for " + symbol);
            success = false;
         }
      }
      
      // Copy MACD data if needed
      if(m_config.GetUseMACD())
      {
         if(CopyBuffer(m_macdHandle, 0, 0, bars, m_macdMainBuffer) <= 0)
         {
            Print("Failed to copy MACD main data for " + symbol);
            success = false;
         }
         
         if(CopyBuffer(m_macdHandle, 1, 0, bars, m_macdSignalBuffer) <= 0)
         {
            Print("Failed to copy MACD signal data for " + symbol);
            success = false;
         }
      }
      
      // Copy Stochastic data if needed
      if(m_config.GetUseStochastic())
      {
         if(CopyBuffer(m_stochHandle, 0, 0, bars, m_stochMainBuffer) <= 0)
         {
            Print("Failed to copy Stochastic main data for " + symbol);
            success = false;
         }
         
         if(CopyBuffer(m_stochHandle, 1, 0, bars, m_stochSignalBuffer) <= 0)
         {
            Print("Failed to copy Stochastic signal data for " + symbol);
            success = false;
         }
      }
      
      // Copy Bollinger Bands data if needed
      if(m_config.GetUseBollingerBands())
      {
         if(CopyBuffer(m_bbHandle, 0, 0, bars, m_bbMiddleBuffer) <= 0)
         {
            Print("Failed to copy BB middle data for " + symbol);
            success = false;
         }
         
         if(CopyBuffer(m_bbHandle, 1, 0, bars, m_bbUpperBuffer) <= 0)
         {
            Print("Failed to copy BB upper data for " + symbol);
            success = false;
         }
         
         if(CopyBuffer(m_bbHandle, 2, 0, bars, m_bbLowerBuffer) <= 0)
         {
            Print("Failed to copy BB lower data for " + symbol);
            success = false;
         }
      }
      
      // Copy ADX data if needed
      if(m_config.GetUseADX())
      {
         if(CopyBuffer(m_adxHandle, 0, 0, bars, m_adxMainBuffer) <= 0)
         {
            Print("Failed to copy ADX main data for " + symbol);
            success = false;
         }
         
         if(CopyBuffer(m_adxHandle, 1, 0, bars, m_adxPlusDIBuffer) <= 0)
         {
            Print("Failed to copy ADX +DI data for " + symbol);
            success = false;
         }
         
         if(CopyBuffer(m_adxHandle, 2, 0, bars, m_adxMinusDIBuffer) <= 0)
         {
            Print("Failed to copy ADX -DI data for " + symbol);
            success = false;
         }
      }
      
      // Copy ATR data if needed
      if(m_config.GetUseATR())
      {
         if(CopyBuffer(m_atrHandle, 0, 0, bars, m_atrBuffer) <= 0)
         {
            Print("Failed to copy ATR data for " + symbol);
            success = false;
         }
      }
      
      return success;
   }
   
   // Detect price action patterns
   ENUM_PRICE_ACTION_PATTERN DetectPriceActionPattern(string symbol, ENUM_TIMEFRAMES timeframe)
   {
      if(!m_config.GetUsePriceAction()) return PATTERN_NONE;
      
      // If already calculated for this symbol and time, return cached result
      datetime currentTime = iTime(symbol, timeframe, 0);
      if(m_lastSymbol == symbol && m_lastPatternTime == currentTime && m_lastPattern != PATTERN_NONE)
      {
         return m_lastPattern;
      }
      
      m_lastSymbol = symbol;
      m_lastPatternTime = currentTime;
      
      // Get candle data
      double open[3], high[3], low[3], close[3];
      for(int i = 0; i < 3; i++)
      {
         open[i] = iOpen(symbol, timeframe, i);
         high[i] = iHigh(symbol, timeframe, i);
         low[i] = iLow(symbol, timeframe, i);
         close[i] = iClose(symbol, timeframe, i);
      }
      
      // Check for bullish engulfing
      if(close[1] < open[1] && close[0] > open[0] && open[0] < open[1] && close[0] > close[1])
      {
         m_lastPattern = PATTERN_BULLISH_ENGULFING;
         return PATTERN_BULLISH_ENGULFING;
      }
      
      // Check for bearish engulfing
      if(close[1] > open[1] && close[0] < open[0] && open[0] > open[1] && close[0] < close[1])
      {
         m_lastPattern = PATTERN_BEARISH_ENGULFING;
         return PATTERN_BEARISH_ENGULFING;
      }
      
      // Check for hammer (bullish)
      if(close[0] > open[0] && // Bullish candle
         (high[0] - close[0]) < (open[0] - low[0]) * 0.3 && // Small upper shadow
         (open[0] - low[0]) > (close[0] - open[0]) * 2) // Long lower shadow
      {
         m_lastPattern = PATTERN_HAMMER;
         return PATTERN_HAMMER;
      }
      
      // Check for shooting star (bearish)
      if(close[0] < open[0] && // Bearish candle
         (high[0] - open[0]) > (close[0] - low[0]) * 2 && // Long upper shadow
         (close[0] - low[0]) < (open[0] - close[0]) * 0.3) // Small lower shadow
      {
         m_lastPattern = PATTERN_SHOOTING_STAR;
         return PATTERN_SHOOTING_STAR;
      }
      
      // Check for pin bar
      double body = MathAbs(close[0] - open[0]);
      double totalRange = high[0] - low[0];
      double upperShadow = high[0] - MathMax(open[0], close[0]);
      double lowerShadow = MathMin(open[0], close[0]) - low[0];
      
      if(body < totalRange * 0.2 && // Small body
         ((upperShadow > body * 2 && lowerShadow < body) || // Upper pin
         (lowerShadow > body * 2 && upperShadow < body))) // Lower pin
      {
         m_lastPattern = PATTERN_PINBAR;
         return PATTERN_PINBAR;
      }
      
      // Check for doji
      if(MathAbs(open[0] - close[0]) < (high[0] - low[0]) * 0.1)
      {
         m_lastPattern = PATTERN_DOJI;
         return PATTERN_DOJI;
      }
      
      m_lastPattern = PATTERN_NONE;
      return PATTERN_NONE;
   }

public:
   // Constructor
   IndicatorProcessor()
   {
      m_config = NULL;
      m_lastPattern = PATTERN_NONE;
      m_lastPatternTime = 0;
      m_lastSymbol = "";
   }
   
   // Initialize the processor
   bool Initialize(Configuration* config)
   {
      if(config == NULL) return false;
      
      m_config = config;
      return true;
   }
   
   // Process all indicators for a symbol
   bool ProcessIndicators(string symbol, ENUM_TIMEFRAMES timeframe)
   {
      // Initialize handles if not done yet or symbol changed
      if(m_lastSymbol != symbol)
      {
         if(!InitializeHandles(symbol, timeframe))
         {
            Print("Failed to initialize indicator handles for " + symbol);
            return false;
         }
      }
      
      // Copy indicator data
      if(!CopyIndicatorData(symbol, timeframe, 100))
      {
         Print("Failed to copy indicator data for " + symbol);
         return false;
      }
      
      // Cache the current symbol
      m_lastSymbol = symbol;
      
      return true;
   }
   
   // Get Moving Average Cross signal
   ENUM_SIGNAL_DIRECTION GetMACrossSignal()
   {
      if(!m_config.GetUseMACross()) return SIGNAL_NEUTRAL;
      
      // Check if fast MA crossed above slow MA
      if(m_maFastBuffer[1] <= m_maSlowBuffer[1] && m_maFastBuffer[0] > m_maSlowBuffer[0])
      {
         return SIGNAL_BUY;
      }
      // Check if fast MA crossed below slow MA
      else if(m_maFastBuffer[1] >= m_maSlowBuffer[1] && m_maFastBuffer[0] < m_maSlowBuffer[0])
      {
         return SIGNAL_SELL;
      }
      
      return SIGNAL_NEUTRAL;
   }
   
   // Get RSI signal
   ENUM_SIGNAL_DIRECTION GetRSISignal()
   {
      if(!m_config.GetUseRSI()) return SIGNAL_NEUTRAL;
      
      int overbought = m_config.GetRSIOverbought();
      int oversold = m_config.GetRSIOversold();
      
      // Check if RSI crossed above oversold level
      if(m_rsiBuffer[1] <= oversold && m_rsiBuffer[0] > oversold)
      {
         return SIGNAL_BUY;
      }
      // Check if RSI crossed below overbought level
      else if(m_rsiBuffer[1] >= overbought && m_rsiBuffer[0] < overbought)
      {
         return SIGNAL_SELL;
      }
      
      return SIGNAL_NEUTRAL;
   }
   
   // Get MACD signal
   ENUM_SIGNAL_DIRECTION GetMACDSignal()
   {
      if(!m_config.GetUseMACD()) return SIGNAL_NEUTRAL;
      
      // Check if MACD crossed above signal line
      if(m_macdMainBuffer[1] <= m_macdSignalBuffer[1] && m_macdMainBuffer[0] > m_macdSignalBuffer[0])
      {
         return SIGNAL_BUY;
      }
      // Check if MACD crossed below signal line
      else if(m_macdMainBuffer[1] >= m_macdSignalBuffer[1] && m_macdMainBuffer[0] < m_macdSignalBuffer[0])
      {
         return SIGNAL_SELL;
      }
      
      return SIGNAL_NEUTRAL;
   }
   
   // Get Stochastic signal
   ENUM_SIGNAL_DIRECTION GetStochasticSignal()
   {
      if(!m_config.GetUseStochastic()) return SIGNAL_NEUTRAL;
      
      // Check if %K crossed above %D in oversold region
      if(m_stochMainBuffer[1] <= m_stochSignalBuffer[1] && m_stochMainBuffer[0] > m_stochSignalBuffer[0] && 
         m_stochMainBuffer[0] < 30)
      {
         return SIGNAL_BUY;
      }
      // Check if %K crossed below %D in overbought region
      else if(m_stochMainBuffer[1] >= m_stochSignalBuffer[1] && m_stochMainBuffer[0] < m_stochSignalBuffer[0] && 
              m_stochMainBuffer[0] > 70)
      {
         return SIGNAL_SELL;
      }
      
      return SIGNAL_NEUTRAL;
   }
   
   // Get Bollinger Bands signal
   ENUM_SIGNAL_DIRECTION GetBollingerBandsSignal(string symbol, ENUM_TIMEFRAMES timeframe)
   {
      if(!m_config.GetUseBollingerBands()) return SIGNAL_NEUTRAL;
      
      double close = iClose(symbol, timeframe, 0);
      double prev_close = iClose(symbol, timeframe, 1);
      
      // Price crossed above lower band
      if(prev_close <= m_bbLowerBuffer[1] && close > m_bbLowerBuffer[0])
      {
         return SIGNAL_BUY;
      }
      // Price crossed below upper band
      else if(prev_close >= m_bbUpperBuffer[1] && close < m_bbUpperBuffer[0])
      {
         return SIGNAL_SELL;
      }
      
      return SIGNAL_NEUTRAL;
   }
   
   // Get ADX signal
   ENUM_SIGNAL_DIRECTION GetADXSignal()
   {
      if(!m_config.GetUseADX()) return SIGNAL_NEUTRAL;
      
      int threshold = m_config.GetADXThreshold();
      
      // ADX above threshold and +DI crossed above -DI
      if(m_adxMainBuffer[0] > threshold && 
         m_adxPlusDIBuffer[1] <= m_adxMinusDIBuffer[1] && 
         m_adxPlusDIBuffer[0] > m_adxMinusDIBuffer[0])
      {
         return SIGNAL_BUY;
      }
      // ADX above threshold and +DI crossed below -DI
      else if(m_adxMainBuffer[0] > threshold && 
              m_adxPlusDIBuffer[1] >= m_adxMinusDIBuffer[1] && 
              m_adxPlusDIBuffer[0] < m_adxMinusDIBuffer[0])
      {
         return SIGNAL_SELL;
      }
      
      return SIGNAL_NEUTRAL;
   }
   
   // Get Price Action signal
   ENUM_SIGNAL_DIRECTION GetPriceActionSignal(string symbol, ENUM_TIMEFRAMES timeframe)
   {
      if(!m_config.GetUsePriceAction()) return SIGNAL_NEUTRAL;
      
      ENUM_PRICE_ACTION_PATTERN pattern = DetectPriceActionPattern(symbol, timeframe);
      
      switch(pattern)
      {
         case PATTERN_BULLISH_ENGULFING:
         case PATTERN_HAMMER:
            return SIGNAL_BUY;
            
         case PATTERN_BEARISH_ENGULFING:
         case PATTERN_SHOOTING_STAR:
            return SIGNAL_SELL;
            
         default:
            return SIGNAL_NEUTRAL;
      }
   }
   
   // Get ATR value
   double GetATR()
   {
      if(!m_config.GetUseATR()) return 0;
      
      return m_atrBuffer[0];
   }
   
   // Get RSI value
   double GetRSIValue()
   {
      if(!m_config.GetUseRSI()) return 0;
      
      return m_rsiBuffer[0];
   }
   
   // Get ADX value
   double GetADXValue()
   {
      if(!m_config.GetUseADX()) return 0;
      
      return m_adxMainBuffer[0];
   }
   
   // Get price action pattern name
   string GetPriceActionPatternName(string symbol, ENUM_TIMEFRAMES timeframe)
   {
      ENUM_PRICE_ACTION_PATTERN pattern = DetectPriceActionPattern(symbol, timeframe);
      
      switch(pattern)
      {
         case PATTERN_BULLISH_ENGULFING: return "Bullish Engulfing";
         case PATTERN_BEARISH_ENGULFING: return "Bearish Engulfing";
         case PATTERN_HAMMER: return "Hammer";
         case PATTERN_SHOOTING_STAR: return "Shooting Star";
         case PATTERN_DOJI: return "Doji";
         case PATTERN_PINBAR: return "Pin Bar";
         default: return "";
      }
   }
};
