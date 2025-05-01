//+------------------------------------------------------------------+
//|                                                   Backtester.mqh |
//|                        Copyright 2023, Your Company               |
//|                                       https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"
#property strict

#include "Constants.mqh"
#include "Configuration.mqh"
#include "SignalGenerator.mqh"
#include "RiskManager.mqh"

// Trade result structure for backtesting
struct TradeResult
{
   datetime openTime;     // Trade open time
   datetime closeTime;    // Trade close time
   double openPrice;      // Open price
   double closePrice;     // Close price
   double stopLoss;       // Stop loss price
   double takeProfit;     // Take profit price
   double lotSize;        // Lot size
   ENUM_SIGNAL_DIRECTION direction; // Trade direction
   double profit;         // Profit in currency
   double pips;           // Profit in pips
   string symbol;         // Symbol traded
   string reason;         // Entry reason
   bool hitSL;            // Whether hit stop loss
   bool hitTP;            // Whether hit take profit
   bool trailing;         // Whether trailing stop was triggered
};

//+------------------------------------------------------------------+
//| Class to backtest strategies on historical data                   |
//+------------------------------------------------------------------+
class Backtester
{
private:
   Configuration* m_config;
   SignalGenerator* m_signalGenerator;
   RiskManager* m_riskManager;
   
   // Backtesting parameters
   datetime m_startDate;
   datetime m_endDate;
   double m_startBalance;
   double m_currentBalance;
   double m_maxDrawdown;
   double m_maxDrawdownPct;
   double m_peakBalance;
   double m_profitFactor;
   int m_totalTrades;
   int m_winningTrades;
   int m_losingTrades;
   double m_grossProfit;
   double m_grossLoss;
   double m_winRate;
   double m_avgWin;
   double m_avgLoss;
   
   // Array of trade results
   TradeResult m_trades[];
   
   // Array of equity points for chart
   datetime m_equityTimes[];
   double m_equityValues[];
   
   // Current open trades for backtest
   TradeResult m_openTrades[];
   int m_openTradesCount;
   
   // Initialize the backtesting parameters
   void InitializeParameters()
   {
      m_startDate = D'2022.01.01 00:00';
      m_endDate = TimeCurrent();
      m_startBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      m_currentBalance = m_startBalance;
      m_maxDrawdown = 0;
      m_maxDrawdownPct = 0;
      m_peakBalance = m_startBalance;
      m_profitFactor = 0;
      m_totalTrades = 0;
      m_winningTrades = 0;
      m_losingTrades = 0;
      m_grossProfit = 0;
      m_grossLoss = 0;
      m_winRate = 0;
      m_avgWin = 0;
      m_avgLoss = 0;
      
      m_openTradesCount = 0;
      
      // Clear arrays
      ArrayFree(m_trades);
      ArrayFree(m_equityTimes);
      ArrayFree(m_equityValues);
      ArrayFree(m_openTrades);
   }
   
   // Calculate pip value based on symbol
   double CalculatePipValue(string symbol, double lots)
   {
      double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double pipSize = (digits == 3 || digits == 5) ? point * 10 : point;
      
      return lots * (tickValue / tickSize) * (pipSize / point);
   }
   
   // Calculate profit in pips for a trade
   double CalculateProfitInPips(string symbol, ENUM_SIGNAL_DIRECTION direction, double openPrice, double closePrice)
   {
      double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
      int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
      double multiplier = (digits == 3 || digits == 5) ? 10 : 1;
      double pipSize = point * multiplier;
      
      if(direction == SIGNAL_BUY)
      {
         return (closePrice - openPrice) / pipSize;
      }
      else
      {
         return (openPrice - closePrice) / pipSize;
      }
   }
   
   // Process an open trade to see if it hit SL/TP or should be closed
   bool ProcessOpenTrade(int index, datetime currentTime, string symbol)
   {
      if(index < 0 || index >= m_openTradesCount) return false;
      
      TradeResult* trade = &m_openTrades[index];
      
      // Get high and low since trade open
      double highSinceOpen = 0;
      double lowSinceOpen = 0;
      
      // Get chart data from trade open time to current time
      int bars = Bars(symbol, m_config.GetTimeFrame(), trade.openTime, currentTime);
      if(bars <= 0) return false;
      
      highSinceOpen = iHigh(symbol, m_config.GetTimeFrame(), iHighest(symbol, m_config.GetTimeFrame(), MODE_HIGH, bars, 0));
      lowSinceOpen = iLow(symbol, m_config.GetTimeFrame(), iLowest(symbol, m_config.GetTimeFrame(), MODE_LOW, bars, 0));
      
      // Check for stop loss hit
      if((trade.direction == SIGNAL_BUY && lowSinceOpen <= trade.stopLoss) ||
         (trade.direction == SIGNAL_SELL && highSinceOpen >= trade.stopLoss))
      {
         // SL hit - close the trade at SL price
         trade.closeTime = currentTime;
         trade.closePrice = trade.stopLoss;
         trade.hitSL = true;
         trade.hitTP = false;
         trade.trailing = false;
         
         // Calculate profit
         trade.pips = CalculateProfitInPips(symbol, trade.direction, trade.openPrice, trade.closePrice);
         double pipValue = CalculatePipValue(symbol, trade.lotSize);
         trade.profit = trade.pips * pipValue;
         
         // Update balance and statistics
         m_currentBalance += trade.profit;
         
         // Add to completed trades
         AddCompletedTrade(*trade);
         
         return true;
      }
      
      // Check for take profit hit
      if((trade.direction == SIGNAL_BUY && highSinceOpen >= trade.takeProfit) ||
         (trade.direction == SIGNAL_SELL && lowSinceOpen <= trade.takeProfit))
      {
         // TP hit - close the trade at TP price
         trade.closeTime = currentTime;
         trade.closePrice = trade.takeProfit;
         trade.hitSL = false;
         trade.hitTP = true;
         trade.trailing = false;
         
         // Calculate profit
         trade.pips = CalculateProfitInPips(symbol, trade.direction, trade.openPrice, trade.closePrice);
         double pipValue = CalculatePipValue(symbol, trade.lotSize);
         trade.profit = trade.pips * pipValue;
         
         // Update balance and statistics
         m_currentBalance += trade.profit;
         
         // Add to completed trades
         AddCompletedTrade(*trade);
         
         return true;
      }
      
      // Check for trailing stop if enabled
      if(m_config.GetUseTrailingStop())
      {
         double trailingPoints = m_config.GetTrailingStopPips() * SymbolInfoDouble(symbol, SYMBOL_POINT) * 
                              ((int)SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 3 || (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS) == 5 ? 10 : 1);
         
         if(trade.direction == SIGNAL_BUY && highSinceOpen > trade.openPrice)
         {
            double newStopLoss = highSinceOpen - trailingPoints;
            if(newStopLoss > trade.stopLoss)
            {
               trade.stopLoss = newStopLoss;
               trade.trailing = true;
            }
         }
         else if(trade.direction == SIGNAL_SELL && lowSinceOpen < trade.openPrice)
         {
            double newStopLoss = lowSinceOpen + trailingPoints;
            if(newStopLoss < trade.stopLoss)
            {
               trade.stopLoss = newStopLoss;
               trade.trailing = true;
            }
         }
      }
      
      return false;
   }
   
   // Add a completed trade to the results array and update statistics
   void AddCompletedTrade(TradeResult &trade)
   {
      // Add to trades array
      int size = ArraySize(m_trades);
      ArrayResize(m_trades, size + 1);
      m_trades[size] = trade;
      
      // Update statistics
      m_totalTrades++;
      
      if(trade.profit > 0)
      {
         m_winningTrades++;
         m_grossProfit += trade.profit;
      }
      else
      {
         m_losingTrades++;
         m_grossLoss += MathAbs(trade.profit);
      }
      
      // Update peak balance and drawdown
      if(m_currentBalance > m_peakBalance)
      {
         m_peakBalance = m_currentBalance;
      }
      else
      {
         double drawdown = m_peakBalance - m_currentBalance;
         double drawdownPct = drawdown / m_peakBalance * 100.0;
         
         if(drawdownPct > m_maxDrawdownPct)
         {
            m_maxDrawdown = drawdown;
            m_maxDrawdownPct = drawdownPct;
         }
      }
      
      // Update equity chart
      int eqSize = ArraySize(m_equityTimes);
      ArrayResize(m_equityTimes, eqSize + 1);
      ArrayResize(m_equityValues, eqSize + 1);
      m_equityTimes[eqSize] = trade.closeTime;
      m_equityValues[eqSize] = m_currentBalance;
      
      // Calculate performance metrics
      CalculatePerformanceMetrics();
   }
   
   // Calculate performance metrics
   void CalculatePerformanceMetrics()
   {
      if(m_totalTrades > 0)
      {
         m_winRate = (double)m_winningTrades / m_totalTrades * 100.0;
         
         if(m_winningTrades > 0)
            m_avgWin = m_grossProfit / m_winningTrades;
            
         if(m_losingTrades > 0)
            m_avgLoss = m_grossLoss / m_losingTrades;
            
         if(m_grossLoss > 0)
            m_profitFactor = m_grossProfit / m_grossLoss;
      }
   }
   
   // Display backtest results
   void DisplayResults()
   {
      Print("===== BACKTEST RESULTS =====");
      Print("Start Balance: ", DoubleToString(m_startBalance, 2));
      Print("End Balance: ", DoubleToString(m_currentBalance, 2));
      Print("Net Profit: ", DoubleToString(m_currentBalance - m_startBalance, 2), 
            " (", DoubleToString((m_currentBalance - m_startBalance) / m_startBalance * 100.0, 2), "%)");
      Print("Maximum Drawdown: ", DoubleToString(m_maxDrawdown, 2), 
            " (", DoubleToString(m_maxDrawdownPct, 2), "%)");
      Print("Profit Factor: ", DoubleToString(m_profitFactor, 2));
      Print("Total Trades: ", m_totalTrades);
      Print("Winning Trades: ", m_winningTrades, " (", DoubleToString(m_winRate, 2), "%)");
      Print("Losing Trades: ", m_losingTrades);
      Print("Average Win: ", DoubleToString(m_avgWin, 2));
      Print("Average Loss: ", DoubleToString(m_avgLoss, 2));
      Print("=============================");
   }
   
   // Create equity chart
   void CreateEquityChart()
   {
      // Create chart object if it doesn't exist
      string chartName = "BacktestEquityChart";
      
      if(ObjectFind(0, chartName) < 0)
      {
         ObjectCreate(0, chartName, OBJ_BITMAP_LABEL, 0, 0, 0);
      }
      
      // Create the chart image (this is a simplified version)
      // In a real implementation, you would create a bitmap here
      
      // For now, just display the equity points as lines
      for(int i = 1; i < ArraySize(m_equityTimes); i++)
      {
         string lineName = "EquityLine" + IntegerToString(i);
         
         if(ObjectFind(0, lineName) < 0)
         {
            ObjectCreate(0, lineName, OBJ_TREND, 0, m_equityTimes[i-1], m_equityValues[i-1], 
                        m_equityTimes[i], m_equityValues[i]);
         }
         else
         {
            ObjectMove(0, lineName, 0, m_equityTimes[i-1], m_equityValues[i-1]);
            ObjectMove(0, lineName, 1, m_equityTimes[i], m_equityValues[i]);
         }
         
         ObjectSetInteger(0, lineName, OBJPROP_COLOR, clrGreen);
         ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, lineName, OBJPROP_RAY_RIGHT, false);
      }
   }

public:
   // Constructor
   Backtester()
   {
      m_config = NULL;
      m_signalGenerator = NULL;
      m_riskManager = NULL;
      m_openTradesCount = 0;
   }
   
   // Initialize the backtester
   bool Initialize(Configuration* config, SignalGenerator* signalGenerator, RiskManager* riskManager)
   {
      if(config == NULL || signalGenerator == NULL || riskManager == NULL) return false;
      
      m_config = config;
      m_signalGenerator = signalGenerator;
      m_riskManager = riskManager;
      
      InitializeParameters();
      
      return true;
   }
   
   // Start the backtest
   bool Start()
   {
      Print("Starting backtest...");
      
      // Get symbols to test
      string symbols[];
      string symbolsStr = "EURUSD,GBPUSD,USDJPY,AUDUSD"; // Default symbols - ideally from config
      int symbolCount = StringSplit(symbolsStr, ',', symbols);
      
      if(symbolCount == 0)
      {
         Print("No symbols specified for backtesting");
         return false;
      }
      
      // Set up initial parameters
      InitializeParameters();
      
      // Loop through each bar from start to end date
      datetime currentTime = m_startDate;
      
      while(currentTime <= m_endDate)
      {
         // Process each symbol
         for(int s = 0; s < symbolCount; s++)
         {
            string symbol = symbols[s];
            
            // Check if symbol exists
            if(!SymbolSelect(symbol, true))
            {
               Print("Symbol not found: ", symbol);
               continue;
            }
            
            // Process any open trades for this symbol
            for(int i = m_openTradesCount - 1; i >= 0; i--)
            {
               if(m_openTrades[i].symbol == symbol)
               {
                  bool closed = ProcessOpenTrade(i, currentTime, symbol);
                  
                  if(closed)
                  {
                     // Remove from open trades
                     for(int j = i; j < m_openTradesCount - 1; j++)
                     {
                        m_openTrades[j] = m_openTrades[j+1];
                     }
                     m_openTradesCount--;
                  }
               }
            }
            
            // Generate signals for this symbol
            SignalInfo signal;
            if(m_signalGenerator.GenerateSignal(symbol, m_config.GetTimeFrame(), signal))
            {
               if(signal.strength >= m_config.GetMinimumSignalStrength())
               {
                  // Calculate trade parameters
                  TradeParameters params;
                  if(m_riskManager.CalculateTradeParameters(symbol, signal.direction, params))
                  {
                     // Open a new trade
                     TradeResult newTrade;
                     newTrade.openTime = currentTime;
                     newTrade.closeTime = 0;
                     newTrade.openPrice = params.entryPrice;
                     newTrade.closePrice = 0;
                     newTrade.stopLoss = params.stopLoss;
                     newTrade.takeProfit = params.takeProfit;
                     newTrade.lotSize = params.lotSize;
                     newTrade.direction = signal.direction;
                     newTrade.profit = 0;
                     newTrade.pips = 0;
                     newTrade.symbol = symbol;
                     newTrade.reason = signal.reason;
                     newTrade.hitSL = false;
                     newTrade.hitTP = false;
                     newTrade.trailing = false;
                     
                     // Add to open trades
                     ArrayResize(m_openTrades, m_openTradesCount + 1);
                     m_openTrades[m_openTradesCount] = newTrade;
                     m_openTradesCount++;
                  }
               }
            }
         }
         
         // Move to next bar
         currentTime = iTime(symbols[0], m_config.GetTimeFrame(), iBarShift(symbols[0], m_config.GetTimeFrame(), currentTime) - 1);
         
         // If we reached the end of data
         if(currentTime == 0) break;
      }
      
      // Close any remaining open trades at current market price
      for(int i = 0; i < m_openTradesCount; i++)
      {
         TradeResult* trade = &m_openTrades[i];
         trade.closeTime = m_endDate;
         
         // Get closing price
         if(trade.direction == SIGNAL_BUY)
         {
            trade.closePrice = SymbolInfoDouble(trade.symbol, SYMBOL_BID);
         }
         else
         {
            trade.closePrice = SymbolInfoDouble(trade.symbol, SYMBOL_ASK);
         }
         
         // Calculate profit
         trade.pips = CalculateProfitInPips(trade.symbol, trade.direction, trade.openPrice, trade.closePrice);
         double pipValue = CalculatePipValue(trade.symbol, trade.lotSize);
         trade.profit = trade.pips * pipValue;
         
         // Update balance
         m_currentBalance += trade.profit;
         
         // Add to completed trades
         AddCompletedTrade(*trade);
      }
      
      // Reset open trades
      m_openTradesCount = 0;
      ArrayFree(m_openTrades);
      
      // Display results
      DisplayResults();
      
      // Create equity chart
      CreateEquityChart();
      
      Print("Backtest completed");
      return true;
   }
   
   // Process a new tick during backtesting
   void ProcessTick()
   {
      // This would be called during live backtesting
      // Not fully implemented for this simplified version
   }
   
   // Get backtest results
   bool GetResults(int &totalTrades, double &profitFactor, double &winRate, double &maxDrawdownPct)
   {
      totalTrades = m_totalTrades;
      profitFactor = m_profitFactor;
      winRate = m_winRate;
      maxDrawdownPct = m_maxDrawdownPct;
      
      return true;
   }
   
   // Export results to CSV file
   bool ExportToCSV(string filename)
   {
      // Open file for writing
      int handle = FileOpen(filename, FILE_WRITE|FILE_CSV);
      if(handle == INVALID_HANDLE)
      {
         Print("Failed to open file for writing: ", filename, ", error: ", GetLastError());
         return false;
      }
      
      // Write header
      FileWrite(handle, "Symbol", "Direction", "Open Time", "Close Time", "Open Price", "Close Price", 
               "Stop Loss", "Take Profit", "Lot Size", "Profit", "Pips", "Reason", "Hit SL", "Hit TP", "Trailing");
               
      // Write trades
      for(int i = 0; i < ArraySize(m_trades); i++)
      {
         FileWrite(handle, m_trades[i].symbol, 
                  m_trades[i].direction == SIGNAL_BUY ? "BUY" : "SELL", 
                  TimeToString(m_trades[i].openTime, TIME_DATE|TIME_MINUTES), 
                  TimeToString(m_trades[i].closeTime, TIME_DATE|TIME_MINUTES), 
                  DoubleToString(m_trades[i].openPrice, SymbolInfoInteger(m_trades[i].symbol, SYMBOL_DIGITS)), 
                  DoubleToString(m_trades[i].closePrice, SymbolInfoInteger(m_trades[i].symbol, SYMBOL_DIGITS)), 
                  DoubleToString(m_trades[i].stopLoss, SymbolInfoInteger(m_trades[i].symbol, SYMBOL_DIGITS)), 
                  DoubleToString(m_trades[i].takeProfit, SymbolInfoInteger(m_trades[i].symbol, SYMBOL_DIGITS)), 
                  DoubleToString(m_trades[i].lotSize, 2), 
                  DoubleToString(m_trades[i].profit, 2), 
                  DoubleToString(m_trades[i].pips, 1), 
                  m_trades[i].reason, 
                  m_trades[i].hitSL ? "Yes" : "No", 
                  m_trades[i].hitTP ? "Yes" : "No", 
                  m_trades[i].trailing ? "Yes" : "No");
      }
      
      // Write summary
      FileWrite(handle, "");
      FileWrite(handle, "Summary");
      FileWrite(handle, "Start Balance", DoubleToString(m_startBalance, 2));
      FileWrite(handle, "End Balance", DoubleToString(m_currentBalance, 2));
      FileWrite(handle, "Net Profit", DoubleToString(m_currentBalance - m_startBalance, 2));
      FileWrite(handle, "Net Profit %", DoubleToString((m_currentBalance - m_startBalance) / m_startBalance * 100.0, 2));
      FileWrite(handle, "Maximum Drawdown", DoubleToString(m_maxDrawdown, 2));
      FileWrite(handle, "Maximum Drawdown %", DoubleToString(m_maxDrawdownPct, 2));
      FileWrite(handle, "Profit Factor", DoubleToString(m_profitFactor, 2));
      FileWrite(handle, "Total Trades", IntegerToString(m_totalTrades));
      FileWrite(handle, "Winning Trades", IntegerToString(m_winningTrades));
      FileWrite(handle, "Win Rate %", DoubleToString(m_winRate, 2));
      FileWrite(handle, "Losing Trades", IntegerToString(m_losingTrades));
      FileWrite(handle, "Average Win", DoubleToString(m_avgWin, 2));
      FileWrite(handle, "Average Loss", DoubleToString(m_avgLoss, 2));
      
      // Close file
      FileClose(handle);
      
      Print("Backtest results exported to: ", filename);
      return true;
   }
   
   // Set backtest date range
   void SetDateRange(datetime startDate, datetime endDate)
   {
      m_startDate = startDate;
      m_endDate = endDate;
   }
   
   // Set initial balance for backtest
   void SetInitialBalance(double balance)
   {
      m_startBalance = balance;
      m_currentBalance = balance;
      m_peakBalance = balance;
   }
};
