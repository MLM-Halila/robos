//+------------------------------------------------------------------+
//|                                        Tradestars                |
//|                                        mario@mobios.com.br       |
//+------------------------------------------------------------------+
#property strict
#property copyright "Tradestars"
#property link      "https://www.mql5.com"
#property description "EuroBot"

#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Generic\HashMap.mqh>
#include <MovingAverages.mqh>
#include <Trade\DealInfo.mqh>
CDealInfo      m_deal;
CPositionInfo  m_position;              // trade position object



CTrade          m_trade;
#import "TelegramService.ex5"
int SendMessage(string const token, string chatId,string text);
#import


sinput string   Robo = "EuroBot";
sinput string Versao ="2.28";                  //
input group " "
input group "PARAMETROS"
input double          INISALDO            = 100;   // Saldo Base
input int             Pontos_Reabre_OP_em_loss      = 30;     // Pontos para reentrada de operação
input int             Pontos_Tot_Fecha    = 50;     // Pontos para fechar todas as posições
input int             Max_oper            = 9;     // Máximo de operações simultâneas
input double          LOTE               = 0.02;   // Lote base (inicial)
input group " "
input group "HORARIOS PARA OPERACAO "
input group "POR DIA DA SEMANA "
input group "(formato HHMM - 0000 a 2400)"
input int             InpSeg_In            = 0000;   // SEGUNDA - Início
input int             InpSeg_Fi            = 2400;   // SEGUNDA - Fim
input int             InpTer_In            = 0000;   // TERÇA - Início
input int             InpTer_Fi            = 2400;   // TERÇA - Fim
input int             InpQua_In            = 0000;   // QUARTA - Início
input int             InpQua_Fi            = 2400;   // QUARTA - Fim
input int             InpQui_In            = 0000;   // QUINTA - Início
input int             InpQui_Fi            = 2400;   // QUINTA - Fim
input int             InpSex_In            = 0000;   // SEXTA - Início
input int             InpSex_Fi            = 2400;   // SEXTA - Fim
input int             InpSab_In            = 0000;   // SÁBADO - Início
input int             InpSab_Fi            = 2400;   // SÁBADO - Fim
input int             InpDom_In            = 0000;   // DOMINGO - Início
input int             InpDom_Fi            = 2400;   // DOMINGO - Fim
input group " "
input group "NOTIFICACOES TELEGRAM"
input string InpToken="1617382308:AAEmQf9aWNwVrjnbdCY0Ni8bvkBc3E6VBVI";//Token do bot que esta no nosso grupo
input string GroupChatId="-564508963";
input bool            TEL                  = false;  // Enviar mensagens via Telegram
input int             SEGS                 = 3600;     // Tempo entre mensagens (segundos)
input string          VER                  = "EB";   // Prefixo da mensagem Telegram

input group " "
input group "PROVISORIOS"

//input
bool            TSP                 = true;   // Usa SPREAD nos cálculos de pontos
input
double FATOR                      = 1.8;   // Fator prox oper
input
double             Fator_Reabre_OP_em_Gain      = 0.3;     // Pontos para reentrada gain
input
double             width      = 0;     // Largura linha Bollinger (pontos)
input
double             Perda_Maxima      = 0;     // Perda maxima para expertremove
//input
int SEQ_CANDLES=0;
int SEQ_CANDLES_COM_OP=0;
struct SDaySchedule
  {
   int               start;
   int               end;
  };
SDaySchedule schedule[7];
datetime INItempo[10];
double SALDO_Inicial = 0;
double SALDO_Anterior = 0;
double SALDOINI = 0;
double INVERSO_SALDOINI = 0;
double CLote = 0;
int NWOP = 0;
int SeqOPer1 = 0;
int SeqOPer2 = 0;
double ponto      = 0;
double tick_size  = 0;
double tick_value = 0;
double valor_do_ponto = 0;
double ValPonto = 0;
int O_magic_number;
double SPREAD;
int C_V;
ENUM_ORDER_TYPE_FILLING filling_type = ORDER_FILLING_IOC;
double          PropLote            = 0.05;   // Percentual do lote em relação ao saldo
string WHY;
//teste
int O1 = 0;
int O2 = 0;
int M1 = 0;
int M2 = 0;
int F1 = 0;
int F2 = 0;
double MAIORSDO = 0;
//+------------------------------------------------------------------+
//| Função de inicialização                                          |
//+------------------------------------------------------------------+
int OnInit()
  {
   O_magic_number = MathRand();
   SALDO_Inicial = 0;
   SALDO_Anterior = 0;
   SALDOINI = INISALDO;
   SALDO_Rev();
   TelMsg();
   double s = SALDO_Corrigido();
//   Print ("X saldo init ",s);
   PropLote = LOTE * 100 / s;
   double CCCC = NormalizeDouble(LOTE,2);
   CLote = LOTE_Prop();
   ponto      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   valor_do_ponto = tick_value * (ponto / tick_size);
   ValPonto = valor_do_ponto * CLote;
   schedule[1].start = InpSeg_In;
   schedule[1].end = InpSeg_Fi;
   schedule[2].start = InpTer_In;
   schedule[2].end = InpTer_Fi;
   schedule[3].start = InpQua_In;
   schedule[3].end = InpQua_Fi;
   schedule[4].start = InpQui_In;
   schedule[4].end = InpQui_Fi;
   schedule[5].start = InpSex_In;
   schedule[5].end = InpSex_Fi;
   schedule[6].start = InpSab_In;
   schedule[6].end = InpSab_Fi;
   schedule[0].start = InpDom_In;
   schedule[0].end = InpDom_Fi;
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
   double seg = SALDO_Corrigido(); // Teste para remove
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   bool NewCandle = TemosNewCandle();
   if(NewCandle)
     {
      SEQ_CANDLES++;
      if(IsWithinOperatingHours())
        {
         if(CountSeconds(SEGS, 1) == true)
           {
            TelMsg();
           }
         bool dls = ObjectDelete(0, "L1");
         ponto      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
         tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
         valor_do_ponto = tick_value * (ponto / tick_size);
         double s = SALDO_Corrigido();
         CLote = LOTE_Prop();
         int OO = Orders_ON();
         NWOP = CheckBollingerSignal(Symbol(), PERIOD_CURRENT, 20, 2);
         if(NWOP > 0)
           {
            int OO = Orders_by_OP(NWOP);
//            Print("X OO o ",NWOP," q ",OO," m ",Max_oper);
            if(OO <= Max_oper)
              {
               if(NWOP == 1)
                 {
                  D_linVER("L1", SymbolInfoDouble(Symbol(),SYMBOL_ASK), TimeCurrent(),clrLime, 2);
                  O1++;
                 }
               if(NWOP == 2)
                 {
                  D_linVER("L1", SymbolInfoDouble(Symbol(),SYMBOL_ASK), TimeCurrent(),clrRed, 2);
                  O2++;
                 }
               WHY = "NOVA";
               ORDER(NWOP, CLote);
              }
           }
         else
           {
            OPs_Negativas(1);
            OPs_Negativas(2);
            OPs_Positivas(1);
            OPs_Positivas(2);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Sinais com base nas Bandas de Bollinger                          |
//+------------------------------------------------------------------+
int CheckBollingerSignal(string symbol, ENUM_TIMEFRAMES timeframe, int period, double deviation)
  {
// Verifica se os dados estão disponíveis
   if(!SymbolInfoInteger(symbol, SYMBOL_SELECT))
      SymbolSelect(symbol, true);

   if(Bars(symbol, timeframe) < period + 2)
      return 0;

// Calcula as bandas
   double middle[], upper[], lower[];
   int boll_handle = iBands(symbol, timeframe, period, 1, deviation, PRICE_CLOSE);

   if(boll_handle == INVALID_HANDLE)
      return 0;
   if(!ChartIndicatorAdd(0, 0, boll_handle))
     {
      //      Print("Erro ao exibir o indicador no gráfico");
     }
// Copia os valores das bandas
   if(CopyBuffer(boll_handle, 0, 0, 2, middle) < 0 ||
      CopyBuffer(boll_handle, 1, 0, 2, upper) < 0 ||
      CopyBuffer(boll_handle, 2, 0, 2, lower) < 0)
     {
      return 0;
     }

   double price_prev = iClose(symbol, timeframe, 1);
   /*
      D_linHOR("HH", upper[1], TimeCurrent(), clrBlueViolet, 1);
      D_linHOR("MM", middle[1], TimeCurrent(), clrBlueViolet, 1);
      D_linHOR("LL", lower[1], TimeCurrent(), clrBlueViolet, 1);
      Print("X Prices ",price_prev," ",upper[1]," ",lower[1]);
   */
   double Mwidth = valor_do_ponto * CLote * width;
   if(price_prev > (upper[1]-Mwidth))
      return 2;

   if(price_prev < (lower[1]+Mwidth))
      return 1;
   return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ORDER(int E_op, double E_lote)
  {
   if((SEQ_CANDLES < 2) ||
      (SEQ_CANDLES > (SEQ_CANDLES_COM_OP + 2)))
     {
      MqlTradeRequest   requisicao = {};    // requisição
      MqlTradeResult    resposta = {};      // resposta
      ZeroMemory(requisicao);
      ZeroMemory(resposta);
      double open_price;
      double Valloss;
      double Valgain;
      double LotSize;
      SPREAD = 0;
      if(TSP)
        {
         SPREAD = SymbolInfoDouble(Symbol(),SYMBOL_ASK) - SymbolInfoDouble(Symbol(),SYMBOL_BID);
        }
      Valloss = 0;
      Valgain = 0;
      LotSize = E_lote;
      C_V = E_op;
      if(C_V == 1)
        {
         open_price=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         requisicao.type = ORDER_TYPE_BUY;
        }
      else
        {
         open_price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         requisicao.type = ORDER_TYPE_SELL;
        }
      string c;
      if(C_V == 1)
        {
         SeqOPer1++;
         c=IntegerToString(SeqOPer1);
        }
      else
        {
         SeqOPer2++;
         c=IntegerToString(SeqOPer2);
        }
//      Print("----------------------------------------->",WHY," ",SEQ_CANDLES," ",E_op," ",E_lote," ",SeqOPer1," ",SeqOPer2);
      requisicao.comment = c;
      requisicao.action       = TRADE_ACTION_DEAL;                            // Executa ordem a mercado
      requisicao.magic        = O_magic_number;                               // Nº mágico da ordem
      requisicao.symbol       = _Symbol;                                      // Simbolo do SYMB
      requisicao.price        = NormalizeDouble(open_price,_Digits);            // Preço OPER
      requisicao.sl           = NormalizeDouble(Valloss,_Digits);             // Preço Stop Loss
      requisicao.tp           = NormalizeDouble(Valgain,_Digits);             // Alvo de Ganho - Take Profit
      requisicao.volume       = NormalizeDouble(LotSize, 2);                  // Nº de Lotes
      requisicao.deviation    = 0;                                            // Desvio Permitido do preço
      requisicao.type_filling = filling_type;                                 // Tipo de Preenchimento da ordem
      Place_Order(C_V, requisicao);
      SEQ_CANDLES_COM_OP = SEQ_CANDLES;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Place_Order(int OP, MqlTradeRequest &requisicao)
  {
   int erro = 0;

   MqlTradeCheckResult checkResult;
   MqlTradeResult resposta;
   if(OrderCheck(requisicao, checkResult))
     {
      if(OrderSend(requisicao,resposta))
        {
         if(resposta.retcode == 10008 || resposta.retcode == 10009)
           {
            // Print("X SEQ O ",SeqOPer1," ",SeqOPer2);
            double vptos = valor_do_ponto * requisicao.volume;
            //            D_linHOR("s",(requisicao.price+vptos+SPREAD),TimeCurrent(), clrTurquoise, 1);
            //            D_linHOR("i",(requisicao.price-vptos-SPREAD),TimeCurrent(), clrTurquoise, 1);
           }
         else
           {
            Print("Erro 2 ao enviar Ordem ", resposta.request_id," do tipo ", requisicao.type, ". Erro = ", erro, " C_V ",C_V);
            ResetLastError();
           }
        }
      else
        {
         erro = GetLastError();
         Print("Erro 3 ao enviar Ordem ", resposta.request_id," do tipo ", requisicao.type, ". Erro = ", erro, " C_V ",C_V);
         ResetLastError();
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
   DASHBOARD((SALDO_Atual-SALDO_Inicial));
   if(TEL == true)
     {
      Print(Telegram_Message);
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
   double var = NormalizeDouble(res,2);
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
void D_linVER(string nome, double PrecolinVER, datetime dt, color cor = clrBlueViolet, int wid = 1)
  {
   ObjectCreate(0,nome,OBJ_VLINE,0,dt,PrecolinVER);
   ObjectSetInteger(0,nome,OBJPROP_COLOR, cor);
   ObjectSetInteger(0,nome,OBJPROP_STYLE, STYLE_DASHDOT);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH, wid);
   ObjectSetInteger(0,nome,OBJPROP_BACK, false);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0,nome,OBJPROP_SELECTED, false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN, true);
   ObjectSetInteger(0,nome,OBJPROP_ZORDER, 0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void D_linHOR(string nome, double PrecolinHOR, datetime dt, color cor = clrBlueViolet, int wid = 1)
  {
   ObjectCreate(0,nome,OBJ_HLINE,0,dt,PrecolinHOR);
   ObjectSetInteger(0,nome,OBJPROP_COLOR, cor);
   ObjectSetInteger(0,nome,OBJPROP_STYLE, STYLE_DASHDOT);
   ObjectSetInteger(0,nome,OBJPROP_WIDTH, wid);
   ObjectSetInteger(0,nome,OBJPROP_BACK, false);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0,nome,OBJPROP_SELECTED, false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN, true);
   ObjectSetInteger(0,nome,OBJPROP_ZORDER, 0);
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
void SALDO_Rev()
  {
   INVERSO_SALDOINI = 0;
   SALDOINI = INISALDO;
   if(SALDOINI > 0)
     {
      INVERSO_SALDOINI = AccountInfoDouble(ACCOUNT_EQUITY) - SALDOINI;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SALDO_Corrigido()
  {
   double N;
   N = AccountInfoDouble(ACCOUNT_EQUITY) - INVERSO_SALDOINI;
   if((Perda_Maxima > 0) && (N < -Perda_Maxima))
     {
      Close_all_Orders(1);
      Close_all_Orders(2);
      ExpertRemove();
     }
   return N;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Orders_ON()
  {
   int orders_count = PositionsTotal();
   if(orders_count > 0)
     {
      //      Print("X orders_count ",orders_count);
      OPs_total_pontos_fecha(1);
      OPs_total_pontos_fecha(2);
     }
   orders_count = PositionsTotal();
   return (orders_count);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OPs_Negativas(int OPtipo)
  {
//   Print("X OPs_Negativas", OPtipo," ",SeqOPer1," ",SeqOPer2);
   ulong posTicket;
   bool posSelected;
   SPREAD = 0;
   if(TSP)
     {
      SPREAD = SymbolInfoDouble(Symbol(),SYMBOL_ASK) - SymbolInfoDouble(Symbol(),SYMBOL_BID);
     }
   for(int i = 0; i < PositionsTotal(); i++)
     {
      posTicket = PositionGetTicket(i);
      posSelected = m_position.SelectByTicket(posTicket);
      if(posTicket>0 && posSelected)
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == O_magic_number)
           {
            ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            int OP = 0;
            if(tipo == POSITION_TYPE_BUY)
              {
               OP = 1;
              }
            else
               if(tipo == POSITION_TYPE_SELL)
                 {
                  OP = 2;
                 }
            /*
                        Print("POSITION_VOLUME ",PositionGetDouble(POSITION_VOLUME));
                        Print("POSITION_PRICE_OPEN ",PositionGetDouble(POSITION_PRICE_OPEN));
                        Print("POSITION_SL ",PositionGetDouble(POSITION_SL));
                        Print("POSITION_TP ",PositionGetDouble(POSITION_TP));
                        Print("POSITION_PRICE_CURRENT ",PositionGetDouble(POSITION_PRICE_CURRENT));
                        Print("POSITION_SWAP ",PositionGetDouble(POSITION_SWAP));
                        Print("POSITION_PROFIT ",PositionGetDouble(POSITION_PROFIT));
            */
            if(OP == OPtipo)
              {
               string c = PositionGetString(POSITION_COMMENT);
               long Sl = StringToInteger(c);
               int Sq = (int)Sl;
               //               Print("X LOOP - ",OP," sq ",Sq," ",SeqOPer1," ",SeqOPer2);
               if(((OP == 1) && (Sq == SeqOPer1)) || ((OP == 2) && (Sq == SeqOPer2)))
                 {
                  //                  Print("X TEM1 - ",OP," sq ",Sq," ",SeqOPer1," ",SeqOPer2);
                  ValPonto = valor_do_ponto * PositionGetDouble(POSITION_VOLUME);
                  /*
                                          Print("POSITION_VOLUME ",PositionGetDouble(POSITION_VOLUME));
                                          Print("POSITION_PRICE_OPEN ",PositionGetDouble(POSITION_PRICE_OPEN));
                                          Print("POSITION_PRICE_CURRENT ",PositionGetDouble(POSITION_PRICE_CURRENT));
                                          Print("POSITION_PROFIT ",PositionGetDouble(POSITION_PROFIT));
                                          Print("Calc ",PositionGetDouble(POSITION_PRICE_CURRENT)-PositionGetDouble(POSITION_PRICE_OPEN));
                  */
                  double RES=PositionGetDouble(POSITION_PRICE_CURRENT)-PositionGetDouble(POSITION_PRICE_OPEN);
                  if(OPtipo == 2)
                    {
                     RES = RES * -1;
                    };
                  RES = RES - SPREAD;
                  double EMpontos = RES / ValPonto;
                  //                  Print("Em pontos ",EMpontos," ",RES," ",ValPonto);
                  if(EMpontos < -Pontos_Reabre_OP_em_loss)
                    {
                     double CCCC = LOTE_Prop();
                     // Print("X MAR ",SeqOPer1," ",SeqOPer2);
                     double l = (PositionGetDouble(POSITION_VOLUME)+(FATOR*CCCC));
//                     Print(" LOTE = ",l," Va ",PositionGetDouble(POSITION_VOLUME)," F ",FATOR," * C ",CCCC);
                     WHY = "OUTRA Loss "+DoubleToString(l,2);
                     ORDER(OP, l);
                     if(OP == 1)
                       {
                        M1++;
                       }
                     else
                       {
                        M2++;
                       }
                     //Print("OUTRA Loss ",EMpontos," ",OP," ",CLote," L ",l);
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OPs_Positivas(int OPtipo)
  {
//   Print("X OPs_Positivas", OPtipo," ",SeqOPer1," ",SeqOPer2);
   ulong posTicket;
   bool posSelected;
   SPREAD = 0;
   if(TSP)
     {
      SPREAD = SymbolInfoDouble(Symbol(),SYMBOL_ASK) - SymbolInfoDouble(Symbol(),SYMBOL_BID);
     }
   for(int i = 0; i < PositionsTotal(); i++)
     {
      posTicket = PositionGetTicket(i);
      posSelected = m_position.SelectByTicket(posTicket);
      if(posTicket>0 && posSelected)
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == O_magic_number)
           {
            ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            int OP = 0;
            if(tipo == POSITION_TYPE_BUY)
              {
               OP = 1;
              }
            else
               if(tipo == POSITION_TYPE_SELL)
                 {
                  OP = 2;
                 }
            /*
                        Print("POSITION_VOLUME ",PositionGetDouble(POSITION_VOLUME));
                        Print("POSITION_PRICE_OPEN ",PositionGetDouble(POSITION_PRICE_OPEN));
                        Print("POSITION_SL ",PositionGetDouble(POSITION_SL));
                        Print("POSITION_TP ",PositionGetDouble(POSITION_TP));
                        Print("POSITION_PRICE_CURRENT ",PositionGetDouble(POSITION_PRICE_CURRENT));
                        Print("POSITION_SWAP ",PositionGetDouble(POSITION_SWAP));
                        Print("POSITION_PROFIT ",PositionGetDouble(POSITION_PROFIT));
            */
            if(OP == OPtipo)
              {
               string c = PositionGetString(POSITION_COMMENT);
               long Sl = StringToInteger(c);
               int Sq = (int)Sl;
               ValPonto = valor_do_ponto * PositionGetDouble(POSITION_VOLUME);
               /*
                                       Print("POSITION_VOLUME ",PositionGetDouble(POSITION_VOLUME));
                                       Print("POSITION_PRICE_OPEN ",PositionGetDouble(POSITION_PRICE_OPEN));
                                       Print("POSITION_PRICE_CURRENT ",PositionGetDouble(POSITION_PRICE_CURRENT));
                                       Print("POSITION_PROFIT ",PositionGetDouble(POSITION_PROFIT));
                                       Print("Calc ",PositionGetDouble(POSITION_PRICE_CURRENT)-PositionGetDouble(POSITION_PRICE_OPEN));
               */
               double RES=PositionGetDouble(POSITION_PRICE_CURRENT)-PositionGetDouble(POSITION_PRICE_OPEN);
               if(OPtipo == 2)
                 {
                  RES = RES * -1;
                 };
               RES = RES - SPREAD;
               double EMpontos = RES / ValPonto;
               //                  Print("X +++ Em pontos ",EMpontos," ",RES," ",ValPonto);
               if(EMpontos > (Pontos_Reabre_OP_em_loss * Fator_Reabre_OP_em_Gain))
                 {
                  double CCCC = LOTE_Prop();
                  double l = (PositionGetDouble(POSITION_VOLUME)+(FATOR*CCCC));
//                  Print(" LOTE = ",l," Va ",PositionGetDouble(POSITION_VOLUME)," F ",FATOR," * C ",CCCC);
                  WHY = "OUTRA Gain "+DoubleToString(l,2);
                  ORDER(OP, l);
                  if(OP == 1)
                    {
                     M1++;
                    }
                  else
                    {
                     M2++;
                    }
                  //Print("OUTRA Gain",EMpontos," ",OP," ",CLote," L ",l);
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OPs_total_pontos_fecha(int OPtipo)
  {
   double TOT_pontos = 0;
   ulong posTicket;
   bool posSelected;
   SPREAD = 0;
   if(TSP)
     {
      SPREAD = SymbolInfoDouble(Symbol(),SYMBOL_ASK) - SymbolInfoDouble(Symbol(),SYMBOL_BID);
     }
   for(int i = 0; i < PositionsTotal(); i++)
     {
      posTicket = PositionGetTicket(i);
      posSelected = m_position.SelectByTicket(posTicket);
      if(posTicket>0 && posSelected)
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == O_magic_number)
           {
            /*
                        Print("POSITION_VOLUME ",PositionGetDouble(POSITION_VOLUME));
                        Print("POSITION_PRICE_OPEN ",PositionGetDouble(POSITION_PRICE_OPEN));
                        Print("POSITION_SL ",PositionGetDouble(POSITION_SL));
                        Print("POSITION_TP ",PositionGetDouble(POSITION_TP));
                        Print("POSITION_PRICE_CURRENT ",PositionGetDouble(POSITION_PRICE_CURRENT));
                        Print("POSITION_SWAP ",PositionGetDouble(POSITION_SWAP));
                        Print("POSITION_PROFIT ",PositionGetDouble(POSITION_PROFIT));
            */
            ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            int OP = 0;
            if(tipo == POSITION_TYPE_BUY)
              {
               OP = 1;
              }
            else
               if(tipo == POSITION_TYPE_SELL)
                 {
                  OP = 2;
                 }
            if(OP == OPtipo)
              {
               ValPonto = valor_do_ponto * PositionGetDouble(POSITION_VOLUME);
               double RES=PositionGetDouble(POSITION_PRICE_CURRENT)-PositionGetDouble(POSITION_PRICE_OPEN);
               if(OPtipo == 2)
                 {
                  RES = RES * -1;
                 };
               RES = RES - SPREAD;
               double EMpontos = RES / ValPonto;
               TOT_pontos = TOT_pontos + EMpontos;
               //               Print("X PONTOS AC  O ",OPtipo," S ",SeqOPer1,SeqOPer2," t ",TOT_pontos," E ",EMpontos," = ",RES," / ",ValPonto,
               //                     " = p ",valor_do_ponto," * v ",PositionGetDouble(POSITION_VOLUME));
              }
           }
        }
     }
//Print("X PONTOS TT  O ",OPtipo," S ",SeqOPer1,SeqOPer2," t ",TOT_pontos," P ",Pontos_Tot_Fecha);
   if(TOT_pontos > Pontos_Tot_Fecha)
     {
      Close_all_Orders(OPtipo);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Orders_by_OP(int OPtipo)
  {
   int QO = 0;
   double TOT_pontos = 0;
   ulong posTicket;
   bool posSelected;
   SPREAD = 0;
   if(TSP)
     {
      SPREAD = SymbolInfoDouble(Symbol(),SYMBOL_ASK) - SymbolInfoDouble(Symbol(),SYMBOL_BID);
     }
   for(int i = 0; i < PositionsTotal(); i++)
     {
      posTicket = PositionGetTicket(i);
      posSelected = m_position.SelectByTicket(posTicket);
      if(posTicket>0 && posSelected)
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == O_magic_number)
           {
            ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            int OP = 0;
            if(tipo == POSITION_TYPE_BUY)
              {
               OP = 1;
              }
            else
               if(tipo == POSITION_TYPE_SELL)
                 {
                  OP = 2;
                 }
            if(OP == OPtipo)
              {
               QO++;
              }
           }
        }
     }
   return QO;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Close_all_Orders(int OPtipo)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong posTicket = PositionGetTicket(i);

      if(posTicket > 0)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Symbol() == _Symbol && m_position.Magic() == O_magic_number)
              {
               ENUM_POSITION_TYPE tipo = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               int OP = 0;
               if(tipo == POSITION_TYPE_BUY)
                 {
                  OP = 1;
                 }
               else
                  if(tipo == POSITION_TYPE_SELL)
                    {
                     OP = 2;
                    }
               if(OP == OPtipo)
                 {
                  if(OP == 1)
                    {
                     F1++;
                    }
                  else
                    {
                     F2++;
                    }

                  if(!m_trade.PositionClose(posTicket))
                    {
                     Print("Erro ao fechar posição ", posTicket, " | Código: ", GetLastError());
                    }
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsWithinOperatingHours()
  {
   MqlDateTime dt;
   TimeCurrent(dt); // Obtém a hora atual do servidor

// Converte a hora atual para o formato HHMM
   int currentTimeHHMM = (dt.hour * 100) + dt.min;

// Pega o horário configurado para o dia da semana atual (dt.day_of_week)
   int day = dt.day_of_week;

// Se início e fim forem 0, assumimos que não opera no dia
   if(schedule[day].start == 0 && schedule[day].end == 0)
      return false;

//   Print("auto  ",currentTimeHHMM," >= ",schedule[day].start," < ",schedule[day].end,(currentTimeHHMM >= schedule[day].start && currentTimeHHMM < schedule[day].end));
   return (currentTimeHHMM >= schedule[day].start && currentTimeHHMM < schedule[day].end);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LOTE_Prop()
  {
   double CCCC = NormalizeDouble(LOTE,2);
   double s = SALDO_Corrigido();
   CCCC = MathAbs(NormalizeDouble((PropLote * s / 100),2));
   return CCCC;
  }
//+------------------------------------------------------------------+
