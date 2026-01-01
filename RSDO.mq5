//+------------------------------------------------------------------+
//|                                        Tradestars                |
//|                                        mario@mobios.com.br       |
//+------------------------------------------------------------------+
#property strict
#property copyright "Tradestars"
#property link      "https://www.mql5.com"
#property description "RMG02"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Generic\HashMap.mqh>
#include <MovingAverages.mqh>
#include <Trade\DealInfo.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDealInfo      m_deal;                       // object of CDealInfo class
#import "TelegramService.ex5"
int SendMessage(string const token, string chatId,string text);
#import
input string InpToken="1617382308:AAEmQf9aWNwVrjnbdCY0Ni8bvkBc3E6VBVI";//Token do bot que esta no nosso grupo
input string GroupChatId="-564508963";
input string VER="SD1";                  // VERSAO
input int SEGS = 3600; // Tempo (SEGUNDOS)
input bool TEL = true; // MSG telegram
datetime INItempo[10];
double SALDO_Inicial = 0;
double SALDO_Anterior = 0;
//+------------------------------------------------------------------+
//| Função de inicialização                                          |
//+------------------------------------------------------------------+
int OnInit()
  {
   SALDO_Inicial = 0;
   SALDO_Anterior = 0;
   TelMsg();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Função de desinicialização                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Função principal de execução                                     |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(CountSeconds(SEGS, 1) == true)
     {
      TelMsg();
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   bool NewCandle = TemosNewCandle();
   if(NewCandle)
     {
      if(CountSeconds(SEGS, 1) == true)
        {
         TelMsg();
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TemosNewCandle()
  {
   static datetime last_time=0;
   datetime lastbar_time= (datetime) SeriesInfoInteger(Symbol(),Period(),SERIES_LASTBAR_DATE);
   if(last_time==0)
     {
      last_time=lastbar_time;
      return(false);
     }
   if(last_time!=lastbar_time)
     {
      last_time=lastbar_time;
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TelMsg()
  {

   long NConta = (AccountInfoInteger(ACCOUNT_LOGIN));
   string XConta = DoubleToString(NConta,0);
   double SALDO_Atual = SALDO_Corrigido();
//   Print(SALDO_Anterior," ",SALDO_Atual);
   if(SALDO_Inicial == 0)
     {
      SALDO_Inicial = SALDO_Atual;
     }
   if(SALDO_Anterior == 0)
     {
      SALDO_Anterior = SALDO_Atual;
     }
   string Telegram_Message=
      VER+" "+
      XConta+
//      " L "+DoubleToString((SALDO_Atual-SALDO_Anterior),2)+
      "  "+DoubleToString((SALDO_Atual-SALDO_Inicial),2);
   Print(Telegram_Message);
   DASHBOARD((SALDO_Atual-SALDO_Inicial));
   if(TEL == true)
     {
      SendMessage(InpToken, GroupChatId, Telegram_Message);
     }
   SALDO_Anterior = SALDO_Atual;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DASHBOARD(double res)
  {
   string label_name="Sit";
   double var = DoubleToString(res,2);
   ObjectCreate(0,label_name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,label_name,OBJPROP_XDISTANCE,300);
   ObjectSetInteger(0,label_name,OBJPROP_YDISTANCE,20);
   ObjectSetInteger(0,label_name,OBJPROP_COLOR,clrWhite);
   string tmpmsg = DoubleToString(var,2);
   ObjectSetString(0,label_name,OBJPROP_TEXT,tmpmsg);
   ObjectSetString(0,label_name,OBJPROP_FONT,"arial");
   ObjectSetInteger(0,label_name,OBJPROP_FONTSIZE,30);
   ObjectSetDouble(0,label_name,OBJPROP_ANGLE,0);
   ObjectSetInteger(0,label_name,OBJPROP_SELECTABLE,false);
   ChartRedraw(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CountSeconds(int seg, int quem)
  {
   if(quem < 10)
     {
      datetime agora = TimeCurrent();
      if(INItempo[quem] == 0)
        {
         INItempo[quem] = agora;
         return false;
        }
      if((agora - INItempo[quem]) >= seg)
        {
         INItempo[quem] = agora;
         return true;
        }
      return false;
     }
   else
     {
      return false;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SALDO_Corrigido()
  {
   double N;
   N =AccountInfoDouble(ACCOUNT_EQUITY);
   return N;
  }
//+------------------------------------------------------------------+
