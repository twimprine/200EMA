//+------------------------------------------------------------------+
//|                                                       200EMA.mq4 |
//|                                                  Thomas Wimprine |
//|                                    http://www.thomaswimprine.com |
//+------------------------------------------------------------------+
#property copyright "Thomas Wimprine"
#property link      "http://www.thomaswimprine.com"
#property version   "1.00"
#property strict

bool troubleshoot = false;
string templateFileName = "Standard Template.tpl";
//int lotMultiplyer = MathFloor(AccountEquity() / 100);
int order = 0;
int fastEMAPeriod = 9;
int slowEMAPeriod = 20;
int atrDays = 20 ;
int absoluteMaxOrders = 10;

double MAXORDERS_TOTAL = 0;
double MAXORDERS_CURRENCY = 1;

int initialDay = 1;
int prevDay = initialDay + 1;

int sellPeriod = PERIOD_W1;
int buyPeriod = PERIOD_H1;

//double numberLots = (MarketInfo(Symbol(),MODE_MINLOT)) * 1;

double slPoints = 150;
double maxSpread = 0.01;

int additionalOrderSpread = 300;

double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
double pipValue = Point*(tickValue/tickSize);



double numberLots() {
   double lotMultiplyer = (AccountFreeMargin() * .01);
   return (MarketInfo(Symbol(),MODE_MINLOT)) * MathMax((MathRound(lotMultiplyer)-1),1);
}

double calcSpread() {
   return NormalizeDouble((Ask - Bid), Digits);
}


int CheckOpenOrders() {
   int openOrders = 0;
   for (int i = 0; i < OrdersTotal(); i++) {
      order = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
      if (OrderSymbol() == Symbol()) {
         openOrders++;
      }
   }
   return(openOrders);
}

double avgAskBid(){
   return NormalizeDouble((Ask + Bid) / 2,Digits);
}

double calcSL() {
   double SL = 9999999999990;
   if (OrderType() == OP_BUY) {
      if (Bid > (OrderOpenPrice() + NormalizeDouble(10*slPoints*Point, Digits))) {
         //Print("SL: ", OrderOpenPrice() + (Bid - OrderOpenPrice())/2);
         SL = (Bid - ((Bid - OrderOpenPrice())*.25));
         return MathMax(SL, OrderStopLoss());
      } 
      else if (Bid > (OrderOpenPrice() + NormalizeDouble(5*slPoints*Point, Digits))) {
         //Print("SL: ", OrderOpenPrice() + (Bid - OrderOpenPrice())/2);
         SL = (Bid - ((Bid - OrderOpenPrice())*.5));
         return MathMax(SL, OrderStopLoss());
      }
      else if (Bid > (OrderOpenPrice() + NormalizeDouble(slPoints*Point, Digits))) {
         //Print("SL: ", OrderOpenPrice() + (Bid - OrderOpenPrice())/2);
         SL = (Bid - ((Bid - OrderOpenPrice())*.75));
         return MathMax(SL, OrderStopLoss());
      }
   } else if (OrderType() == OP_SELL) {
      double currSL = OrderStopLoss();
      if (currSL == 0) {
         currSL = 9999999999;
      }
      if (Ask < (OrderOpenPrice() - NormalizeDouble(10*slPoints*Point,Digits))) {
         //Alert("Trying to set Sell SL!: 25%");
         SL = (Ask + ((OrderOpenPrice() - Ask)*.25));
         //Alert("Setting SL: ", MathMin(SL, OrderStopLoss()));
         return MathMin(SL, currSL);
      }
      else if (Ask < (OrderOpenPrice() - NormalizeDouble(5*slPoints*Point,Digits))) {
         //Alert("Trying to set Sell SL!: 50%");
         SL = (Ask + ((OrderOpenPrice() - Ask)*.5));
         //Alert("Setting SL: ", MathMin(SL, OrderStopLoss()));
         return MathMin(SL, currSL);
      } 
      else if (Ask < (OrderOpenPrice() - NormalizeDouble(slPoints*Point,Digits))) {
         //Alert("Trying to set Sell SL!: 75%");
         SL = (Ask + ((OrderOpenPrice() - Ask)*.75));
         //Alert("Setting SL: ", MathMin(SL, OrderStopLoss()));
         return MathMin(SL, currSL);
      } 
   }
   return OrderStopLoss();
}

double calcLots(int orderType) {
   if(!AccountFreeMarginCheck(Symbol(),orderType,numberLots())) {
      calcLots(orderType, 1);
   } else  {
      return numberLots();
   }
   return numberLots();
}


double calcLots(int orderType, int lots) {
   if(!AccountFreeMarginCheck(Symbol(),OP_BUY,NormalizeDouble(lots,Digits))) {
      calcLots(orderType,  1);
   } else  {
      return lots;
   }
   return numberLots();
}

void buyOrder() {
      double ATR = iATR(Symbol(),0,atrDays,0);
      //Alert("Buy Order ", Symbol());
      order = OrderSend(Symbol(),OP_BUY,numberLots(),avgAskBid(),3,NULL,NULL,"200EMA Buy",0,0,Green);
      if (order > 0) {
         Alert("Buy Order: ",order);
      } else if (GetLastError() == 134){
         Print("Not enough Money");
      } else {
         Alert("Error: ", GetLastError());
      }
}

void sellOrder() {
      double ATR = iATR(Symbol(),0,atrDays,0);
      //Alert("Sell Order ", Symbol());
      order = OrderSend(Symbol(),OP_SELL,numberLots(),avgAskBid(),3,NULL,NULL,"200EMA Short",0,0,Green);
      if (order > 0) {
         Alert("Short Order: ",order);
      } else if (GetLastError() == 134){
         Print("Not enough Money");
      } else {
         Alert("Error: ", GetLastError());
      }
}

int setSL() {

   double SL = calcSL();
   //double ATR = iATR(Symbol(),0,atrDays,0);
   
   //Print("setSL SL: ",SL);
   if (OrderStopLoss() != SL) {
      return order = OrderModify(OrderTicket(),NULL,SL,OrderTakeProfit(),NULL,Yellow);
   }
   return 0;
}



int closeOrder(int orderNum, string symbol) {
      //Print("200 EMA slope is: ", slope(symbol), " - Closing Trade");
      Print("Order Open: ",OrderOpenPrice());
      Print("Current Ask: ",Ask);
      //Alert("Closing");
      Comment("pipValue: ", pipValue);
      if (!OrderClose(OrderTicket(),OrderLots(),Ask,0,Red)) {
         Alert("Could not close order: ",OrderTicket());
         return GetLastError();
      }
      Sleep(3600000 * 8);
      return 0;
}


//void buyMaint(string symbol, double atr, int orderNum, int orderType) {
void buyMaint() {
   bool  orderClose = false;
   //double ATR = iATR(Symbol(),0,atrDays,0);
   
   double SlowEMA = iMA(NULL,sellPeriod,slowEMAPeriod,0,MODE_EMA,PRICE_CLOSE,0);
   double FastEMA = iMA(NULL,sellPeriod,fastEMAPeriod,0,MODE_EMA,PRICE_CLOSE,0);
   
   // Set SL
   //Print("Calling setSL Long");
   //Print("ATR: ",ATR);
   setSL(); 
   
   if (troubleshoot == true) {
      Print("FastEMA: ", FastEMA);
      Print("SlowEMA: ", SlowEMA);
   }
   
   // Did we slip below to 200 somehow?
   //if (Bid <= iMA(Symbol(), 0, 200, 0, MODE_EMA,PRICE_CLOSE,0)) {
   //   closeOrder = true;
   //}
   if (FastEMA < SlowEMA) {
      orderClose = true;
      
      //(prevFastEMA > prevSlowEMA)
      //&& (FastEMA < SlowEMA)
   }
   
   // Determine if we are Bull or Bear
   //if (slope(Symbol()) <= 0) { // Slope of 200 EMA is 0 or negative close trade
   //   closeOrder = true;
   //}   
   
   if (orderClose == true) {
      Print("Closing Order: ", OrderTicket());
      closeOrder(OrderTicket(), Symbol());
   }
   
}


//void sellMaint(string symbol, double atr, int orderNum, int orderType) {
void sellMaint() {
   bool closeOrder = false;
   //double ATR = iATR(Symbol(),0,atrDays,0);
   double SlowEMA = iMA(NULL,sellPeriod,slowEMAPeriod,0,MODE_EMA,PRICE_CLOSE,0);
   double FastEMA = iMA(NULL,sellPeriod,fastEMAPeriod,0,MODE_EMA,PRICE_CLOSE,0);


   if (troubleshoot == true) {
      Print("FastEMA: ", FastEMA);
      Print("SlowEMA: ", SlowEMA);
   }


   setSL(); 
   
   //if (Ask >= iMA(Symbol(), 0, slowEMAPeriod, 0, MODE_EMA,PRICE_CLOSE,0)) {
   //   closeOrder = true;
   //}
   
   if (FastEMA > SlowEMA) {
      closeOrder = true;
   }
   // Slope of 200 EMA is 0 or nega tive close trade
   //if (slope(Symbol()) >= 0) {
   //  closeOrder = true;
   //}
     
   if (closeOrder == true) {
      Print("Closing Order: ", OrderTicket());
      closeOrder(OrderTicket(), Symbol());
   }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);
   
   //int symbolCount = SymbolsTotal(true);
   //Print("There are ",symbolCount, " charts to open.");
   //for(int i = 1;i <= symbolCount; i++) {
   //   ChartOpen(SymbolName(i,true),PERIOD_D1);
   //   ChartApplyTemplate(0,templateFileName);
   //}
   //ChartApplyTemplate(0,templateFileName);
   // Make sure we are on the daily charts
   //ChartSetSymbolPeriod(NULL,Symbol(),PERIOD_W1);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   
   MAXORDERS_TOTAL = MathMin(MathRound(AccountEquity() / (80)) - 1, absoluteMaxOrders);
   int symbolOrderCount = 0;
  
   double SlowEMA = iMA(NULL,buyPeriod,slowEMAPeriod,0,MODE_EMA,PRICE_CLOSE,initialDay);
   double prevSlowEMA = iMA(NULL,buyPeriod,slowEMAPeriod,0,MODE_EMA,PRICE_CLOSE,prevDay);
   double FastEMA = iMA(NULL,buyPeriod,fastEMAPeriod,0,MODE_EMA,PRICE_CLOSE,initialDay);
   double prevFastEMA = iMA(NULL,buyPeriod,fastEMAPeriod,0,MODE_EMA,PRICE_CLOSE,prevDay);
   //double ATR = iATR(Symbol(),0,atrDays,0);
   
   double longerTrend = iMA(NULL,sellPeriod,fastEMAPeriod,0,MODE_EMA,PRICE_CLOSE,initialDay) -
      iMA(NULL,sellPeriod,slowEMAPeriod,0,MODE_EMA,PRICE_CLOSE,slowEMAPeriod);
   
   for (int i = 0; i < OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if (OrderSymbol() == Symbol()) {
            symbolOrderCount++;
         }
      }
   }
     
  string trendStr;
  if (longerTrend > 0) {
   trendStr = "Positive";
  } else if (longerTrend < 0) {
   trendStr = "Negative";
  } else {
   trendStr = "NFC Check your code!";
  }
   
   if (  
      (OrdersTotal() <= MAXORDERS_TOTAL) 
      && (symbolOrderCount < MAXORDERS_CURRENCY)
      && (calcSpread() < maxSpread)
      && (prevFastEMA < prevSlowEMA)
      && (FastEMA > SlowEMA)
      && (longerTrend > 0)
      
      ) {
      Print("BuyOrder");
      //Comment("Buy Order");
      buyOrder();
   } else if (
      (OrdersTotal() <= MAXORDERS_TOTAL) 
      && (symbolOrderCount < MAXORDERS_CURRENCY)
      && (calcSpread() < maxSpread)
      && (prevFastEMA > prevSlowEMA)
      && (FastEMA < SlowEMA)
      && (longerTrend < 0)
      
      ) {
      Print("Sell Order");
      //Comment("Sell Order");
      sellOrder();
   } 

  
  for (int i = 0; i < OrdersTotal(); i++) {
   if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderSymbol() == Symbol()) {
         Comment("Order Profit: $", OrderProfit(),  " Spread: ", calcSpread(), " pipValue: ", pipValue,
            "\nWeekly Trend: ", trendStr, "\npip/$: ", (1/pipValue),
            "\nSell SL: ", (OrderOpenPrice() - NormalizeDouble(slPoints*Point,Digits)));
         if (OrderType() == 0) {
            buyMaint();
         } else if (OrderType() == 1) {
            sellMaint();
         }
      }
   }
  }   
  
  
 }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   
  }
//+------------------------------------------------------------------+
