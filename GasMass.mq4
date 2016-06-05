//+------------------------------------------------------------------+
//|                                                      GasMass.mq4 |
//|                           Copyright 2016, DeepSky Software Corp. |
//|                                  https://www.deepsky.com/gasmass |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, DeepSky Software Corp."
#property link      "https://www.deepsky.com/gasmass"
#property version   "1.00"
#property description "√азћасс - советник, позвол€ющий контролировать рыночно-нейтральную группу ордеров"
#property strict
//--- input parameters
input int      InitTimerPeriodSec=100;       // переодичность обработки скрипта (сек)
input string   TimeForSmsStr="11:30,17:00";  // график отправки смс
input string   PrefixForSmsStr="[FxPro]:";   // префикс дл€ смс

//---- global vars
      int      TimeForSmsArr [][2];          // [временна€ точка][часы,минуты]
      datetime PrevTimeSmsSend;           // предыдущий момент отправки смс
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- init array
   string result[];
   int k = StringSplit(TimeForSmsStr,StringGetCharacter(",",0),result);
   if(k > 0) {
      ArrayResize(TimeForSmsArr,k);
      for(int i = 0; i < k; ++i) {
         string t[];
         int j = StringSplit(result[i],StringGetCharacter(":",0),t);
         if(j == 2) {
            TimeForSmsArr[i][0] = StrToInteger(t[0]);
            if(TimeForSmsArr[i][0]<0 || TimeForSmsArr[i][0]>24) return(INIT_PARAMETERS_INCORRECT);
            TimeForSmsArr[i][1] = StrToInteger(t[1]);
            if(TimeForSmsArr[i][1]<0 || TimeForSmsArr[i][1]>60) return(INIT_PARAMETERS_INCORRECT);
         } else return(INIT_PARAMETERS_INCORRECT);
      }
   } else return(INIT_PARAMETERS_INCORRECT);
   
//--- create timer
   EventSetTimer(InitTimerPeriodSec);
      
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
//---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   static ulong SmsNum = 0;
//---
   for(int i = 0; i < ArrayRange(TimeForSmsArr,0); ++i) {
      datetime TimePoint = StrToTime((string)TimeForSmsArr[i][0]+":"+(string)TimeForSmsArr[i][1]);
      if((PrevTimeSmsSend < TimePoint) && (TimePoint <= TimeCurrent())) {
         PrevTimeSmsSend = TimeCurrent();
         string strPositions = "";
         for(int pos = 0; pos < OrdersTotal(); ++pos) {
            if(OrderSelect(pos, SELECT_BY_POS, MODE_TRADES) == false) continue;
            MqlTick tTick;
            SymbolInfoTick(OrderSymbol(),tTick);
            strPositions += "("+OrderSymbol()+" "+(OrderType()==OP_BUY?"buy ":"")+(OrderType()==OP_SELL?"sell ":"")+
            (string)OrderLots()+" "+(string)OrderOpenPrice()+"->"+
            (OrderType()==OP_BUY?(string)tTick.bid:"")+(OrderType()==OP_SELL?(string)tTick.ask:"")+
            +"="+(string)NormalizeDouble(OrderProfit()-OrderCommission()-OrderSwap(),2)+" sw:"+
            (OrderType()==OP_BUY?(string)SymbolInfoDouble(OrderSymbol(),SYMBOL_SWAP_LONG):"")+
            (OrderType()==OP_SELL?(string)SymbolInfoDouble(OrderSymbol(),SYMBOL_SWAP_SHORT):"")+
            SwapMode(OrderSymbol(), SymbolInfoInteger(OrderSymbol(),SYMBOL_SWAP_MODE))+")";
         }
         SendMail("mail #" + (string)(++SmsNum)," "+(string)TimeForSmsArr[i][0]+":"+(string)TimeForSmsArr[i][1]+" - "+
            PrefixForSmsStr+" Equity/Margin: "+
            (string)AccountEquity()+" / "+(string)AccountMargin()+" "+AccountCurrency()+" "+strPositions);
      }
   }
  }
//+------------------------------------------------------------------+
//| Swap mode function                                               |
//+------------------------------------------------------------------+
string SwapMode(string os,long sm)
  {
   switch((int)sm) {
      case 0: // in points
      return "pt";
      case 1: // in the symbol base currency
      return SymbolInfoString(os, SYMBOL_CURRENCY_BASE);
      case 2: // by interest
      return "%";
      case 3: // in the margin currency
      return SymbolInfoString(os, SYMBOL_CURRENCY_MARGIN);
      default:
      return "";
   }
  }
//+------------------------------------------------------------------+