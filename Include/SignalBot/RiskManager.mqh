//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                        Copyright 2023, Your Company               |
//|                                       https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include "Constants.mqh"
#include "Configuration.mqh"
#include "Utils.mqh"

//+------------------------------------------------------------------+
//| Class to manage risk for trades                                   |
//+------------------------------------------------------------------+
class RiskManager
{
private:
   Configuration* m_config;
   
   // Calculate pips to price for a symbol
   double PipsToPrice(string symbol, double pips)
   {
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double multiplier = (digits == 3 || digits == 5) ? 10 : 1;
      
      return pips * point * multiplier;
   }
   
   // Calculate optimal lot size based on risk settings
   double CalculateLotSize(string symbol, double riskAmount, double stopLossPips)
   {
      if(stopLossPips <= 0) return 0.01; // Minimum lot size if no SL
      
      double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double pointValue = tickValue / tickSize;
      
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double multiplier = (digits == 3 || digits == 5) ? 10 : 1;
      
      double pipValue = pointValue * multiplier;
      double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
      double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
      
      // Calculate lot size based on risk amount and stop loss
      double optimalLot = riskAmount / (stopLossPips * pipValue);
      
      // Round to nearest lot step
      optimalLot = MathRound(optimalLot / lotStep) * lotStep;
      
      // Ensure within min/max limits
      optimalLot = MathMax(minLot, MathMin(maxLot, optimalLot));
      
      return optimalLot;
   }

public:
   // Constructor
   RiskManager()
   {
      m_config = NULL;
   }
   
   // Initialize the risk manager
   bool Initialize(Configuration* config)
   {
      if(config == NULL) return false;
      
      m_config = config;
      return true;
   }
   
   // Calculate trade parameters for a signal
   bool CalculateTradeParameters(string symbol, ENUM_SIGNAL_DIRECTION direction, TradeParameters &params)
   {
      if(direction == SIGNAL_NEUTRAL) return false;
      
      // Get current prices
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      
      // Set entry price based on direction
      params.entryPrice = (direction == SIGNAL_BUY) ? ask : bid;
      
      // Calculate stop loss and take profit pips
      double stopLossPips = m_config.GetStopLossPips();
      double takeProfitPips = m_config.GetTakeProfitPips();
      
      // Use ATR for dynamic SL/TP if enabled
      if(m_config.GetUseATR())
      {
         // This requires the indicator processor to provide ATR value
         // For now, we'll use a simple multiplier of the base values
         stopLossPips *= 1.0; // This would be replaced by ATR multiplier logic
         takeProfitPips *= 1.0; // This would be replaced by ATR multiplier logic
      }
      
      // Apply risk-reward ratio if set
      double rrRatio = m_config.GetRiskRewardRatio();
      if(rrRatio > 0)
      {
         takeProfitPips = stopLossPips * rrRatio;
      }
      
      // Convert pips to price
      double stopLossPrice = (direction == SIGNAL_BUY) 
         ? params.entryPrice - PipsToPrice(symbol, stopLossPips)
         : params.entryPrice + PipsToPrice(symbol, stopLossPips);
         
      double takeProfitPrice = (direction == SIGNAL_BUY)
         ? params.entryPrice + PipsToPrice(symbol, takeProfitPips)
         : params.entryPrice - PipsToPrice(symbol, takeProfitPips);
      
      params.stopLoss = stopLossPrice;
      params.takeProfit = takeProfitPrice;
      params.stopLossPips = (int)stopLossPips;
      params.takeProfitPips = (int)takeProfitPips;
      
      // Set trailing stop parameters
      params.useTrailingStop = m_config.GetUseTrailingStop();
      params.trailingStopPips = (int)m_config.GetTrailingStopPips();
      
      // Calculate lot size
      if(m_config.GetUsePercentRisk())
      {
         // Calculate lot size based on account balance and risk percentage
         double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         double riskAmount = accountBalance * m_config.GetRiskPercent() / 100.0;
         params.lotSize = CalculateLotSize(symbol, riskAmount, stopLossPips);
      }
      else
      {
         // Use fixed lot size
         params.lotSize = m_config.GetLotSize();
      }
      
      return true;
   }
   
   // Validate trading hours and session
   bool IsValidTradingTime()
   {
      // This can be expanded based on requirements
      // For now, we'll just allow trading at all times
      return true;
   }
   
   // Check if a trading day is valid (no weekends, holidays)
   bool IsValidTradingDay()
   {
      // Check for weekends
      datetime currentTime = TimeCurrent();
      MqlDateTime time_struct;
      TimeToStruct(currentTime, time_struct);
      int dayOfWeek = time_struct.day_of_week;
      
      if(dayOfWeek == 0 || dayOfWeek == 6) // Sunday or Saturday
      {
         return false;
      }
      
      // Could add holiday checking here
      
      return true;
   }
   
   // Check daily trade limit
   bool IsWithinDailyTradeLimit(int currentTrades)
   {
      return currentTrades < m_config.GetMaxDailyTrades();
   }
};
