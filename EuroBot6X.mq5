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

// 01 a 16 jan, gold, m30, 1865,09 em 37 ops
sinput string   Robo = "EuroBot6x";
sinput string Versao ="2.1X";                  //btc m30
input group " "
input group "PARAMETROS"
input double          INISALDO            = 80;   // Saldo Base
input int             Pontos_Reabre_OP_em_loss      = 15;     // Pontos para reentrada de operação
input int             Pontos_Tot_Fecha    = 40;     // Pontos para fechar todas as posições
input int             Max_oper            = 9;     // Máximo de operações simultâneas
input double          LOTE               = 0.1;   // Lote base (inicial)
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
input int             SEGS                 = 1200;     // Tempo entre mensagens (segundos)
input string          VER                  = "X2";   // Prefixo da mensagem Telegram

input group " "
input group "PROVISORIOS"

//input
bool            TSP                 = true;   // Usa SPREAD nos cálculos de pontos
input
double FATOR                      = 2;   // Fator prox oper
input
double             Fator_Reabre_OP_em_Gain      = 1;     // Pontos para reentrada gain
input
double             width      = 0;     // Largura linha Bollinger (pontos)
input
int             Notick      = 60;     // Tempo para rever ops no tick (Segs)
input
double  Sdo_THRESHOLD = 50;// Max QUEDA SALDO inicial
input
double  Ops_THRESHOLD = 50;// Max QUEDA SALDO operacional
input bool USA_M_menor = false; //Confirma com media timeframe menor
input bool USA_M_maior = false; //Confirma com media timeframe menor
input int Mquant = 50; //Quant medias
input
bool inverso             = false;       // Inverter as operações
input int OP_ONLY = 0; //OP ONLY, 0,1,2
input
int testa             = 0;       // TESTA
input int SemMov = 12; //Opera para não ficar parado

int SegundosAtual;
double             Perda_Maxima      = 0;     // Perda maxima para expertremove
int tendencia_lower = 0;
int tendencia_upper = 0;
int SEQ_CANDLES=0;
int SEQ_CANDLES_SEM_OP=0;
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
double SALDO_1 = 0;
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
double SALDO_DISP = 0;
double          PropLote            = 0.05;   // Percentual do lote em relação ao saldo
string WHY;
bool INV_oper             = false;       // Inverter as operações
bool ABRIUop = false;
//testa
int O1 = 0;
int O2 = 0;
int M1 = 0;
int M2 = 0;
int F1 = 0;
int F2 = 0;
double MAIORSDO = 0;
double maiorjerk = 0;
double menorjerk = 0;
//+------------------------------------------------------------------+
//| Função de inicialização                                          |
//+------------------------------------------------------------------+
int OnInit()
  {
   O_magic_number = MathRand();
   SALDO_Inicial = 0;
   SALDO_Anterior = 0;
   SALDOINI = INISALDO;
   SALDO_DISP = 0;
   SALDO_Rev();
   TelMsg();
   SALDO_1 = SALDO_Corrigido();
   if(SALDOINI == 0)
     {
      SALDOINI = SALDO_1;
     }
   Print("X saldo init ",SALDOINI);
   PropLote = LOTE * 100 / SALDO_1;
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
   SegundosAtual = PeriodSeconds();
   INV_oper = inverso;
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
   if(CountSeconds(30, 3) == true)
     {
      SALDO_DISP = SALDO_Corrigido();
      if(SALDO_DISP < -INISALDO)
        {
         Close_all_Orders(1);
         Close_all_Orders(2);
         ExpertRemove();
        }
     }
   int tempo_prov = SegundosAtual/2;
   if(CountSeconds(tempo_prov, 5) == true)
     {
      double SDO_VAR_INI = CalcularVariacaoSALDOINICIAL(SALDO_Corrigido());
      if(SDO_VAR_INI < -Sdo_THRESHOLD)
        {
         Close_all_Orders(1);
         Close_all_Orders(2);
         ExpertRemove();
        }
      double SDO_VAR = CalcularVariacaoSALDO(SALDO_Corrigido(), tempo_prov);
      if((SDO_VAR < -Ops_THRESHOLD) && (ABRIUop == true))
        {
         ABRIUop = false;
         Close_all_losing_operations(0);
         INV_oper = !INV_oper;
         //         Print("X INV_oper ",INV_oper," IIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIIII");
        }
      ENUM_TIMEFRAMES lower, upper;
      GetAdjacentTimeframes(PERIOD_CURRENT, lower, upper);
      if(USA_M_menor)
        {
         tendencia_lower = EMATrend(21, lower, Mquant);
         if(testa == 2)
           {
            Close_all_losing_operations(tendencia_lower);
           }
        }
      if(USA_M_maior)
        {
         tendencia_upper = EMATrend(21, upper, Mquant);
         if(testa == 2)
           {
            Close_all_losing_operations(tendencia_upper);
           }
        }
     }
   if(Notick > 0)
     {
      if(CountSeconds(Notick, 2) == true)
        {
         Processa();
        }
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   bool NewCandle = TemosNewCandle();
   if(NewCandle)
     {
      if(SALDO_DISP < -INISALDO)
        {
         Close_all_Orders(1);
         Close_all_Orders(2);
         ExpertRemove();
        }
      SEQ_CANDLES++;
      ENUM_TIMEFRAMES lower, upper;
      GetAdjacentTimeframes(PERIOD_CURRENT, lower, upper);
      int LWOP = CheckBollingerSignal(0, Symbol(), lower, 20, 2);
      int GWOP = CheckBollingerSignal(0, Symbol(), upper, 20, 2);
      ChartRedraw();
      Processa();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Processa()
  {
   bool dls = ObjectDelete(0, "L1");
   ponto      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   valor_do_ponto = tick_value * (ponto / tick_size);
   double s = SALDO_Corrigido();
   CLote = LOTE_Prop();
   int OO = Orders_ON();
   if(OO > 0)
     {
      OPs_Negativas(1);
      OPs_Negativas(2);
      OPs_Positivas(1);
      OPs_Positivas(2);
      SEQ_CANDLES_SEM_OP = 0;
     }
   else
     {
      SEQ_CANDLES_SEM_OP++;
     }
   Print ("SEM MOV ",SEQ_CANDLES_SEM_OP); 
   NWOP = CheckBollingerSignal(0, Symbol(), PERIOD_CURRENT, 20, 2);

   if((INV_oper == true) && (NWOP > 0))
     {
      NWOP++;
      if(NWOP == 3)
        {
         NWOP = 1;
        }
     }
   if(OP_ONLY > 0)
     {
      if(OP_ONLY != NWOP)
        {
         NWOP = 0;
        }
     }
   if(testa == 1)
     {
      if(NWOP > 0)
        {
         if(
            ((USA_M_menor) && (NWOP != tendencia_lower))
            ||
            ((USA_M_maior) && (NWOP != tendencia_upper))
         )
           {
            INV_oper = !INV_oper;
            NWOP++;
            if(NWOP == 3)
              {
               NWOP = 1;
              }
            Print("X SIT NWOP ", NWOP, "  TENDs ",tendencia_lower," ",tendencia_upper," I.NOW ",INV_oper);
           }
        }
     }

   if(NWOP > 0)
     {
      int OO = Orders_by_OP(NWOP);
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
         ABRIUop = true;
         ORDER(NWOP, CLote);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OLDProcessa()
  {
   bool dls = ObjectDelete(0, "L1");
   ponto      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   valor_do_ponto = tick_value * (ponto / tick_size);
   double s = SALDO_Corrigido();
   CLote = LOTE_Prop();
   int OO = Orders_ON();
   NWOP = CheckBollingerSignal(0, Symbol(), PERIOD_CURRENT, 20, 2);
   if(NWOP > 0)
     {
      //      Print("X LIMS ",NWOP," ",USA_M_menor," ",tendencia_lower," ",USA_M_maior," ",tendencia_upper);
      if(USA_M_menor && (NWOP == tendencia_lower))
        {
         Print("X LIMS PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP");
         NWOP = 0;
        }
      if(USA_M_maior && (NWOP == tendencia_upper))
        {
         Print("X LIMS GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG");
         NWOP = 0;
        }
     }
   if((INV_oper == true) && (NWOP > 0))
     {
      NWOP++;
      if(NWOP == 3)
        {
         NWOP = 1;
        }
     }
   if(NWOP > 0)
     {
      int OO = Orders_by_OP(NWOP);
      Print("X INVER ",INV_oper," ",NWOP," ",SALDO_Corrigido()," ",OO);
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
         ABRIUop = true;
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
//+------------------------------------------------------------------+
//| Sinais com base nas Bandas de Bollinger                          |
//+------------------------------------------------------------------+
int CheckBollingerSignal(int graf, string symbol, ENUM_TIMEFRAMES timeframe, int period, double deviation)
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
   if(!ChartIndicatorAdd(graf, graf, boll_handle))
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
   if(SEQ_CANDLES_SEM_OP < SemMov)
     {
      return 0;
     }
   int qs = SemMov+1;
   Print ("SEM MOV ",iClose(symbol, timeframe, 1)," ",iClose(symbol, timeframe, qs));
   if(iClose(symbol, timeframe, 1) > iClose(symbol, timeframe, qs))
      return 2;
   if(iClose(symbol, timeframe, 1) < iClose(symbol, timeframe, qs))
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
//| Função para calcular a variação da aceleração do saldo           |
//+------------------------------------------------------------------+
double CalcularVariacaoAceleracao(double saldo_atual, double tempo_decorrido)
  {
// Variáveis estáticas para manter o estado entre chamadas
   static double saldo_anterior = 0.0;
   static double velocidade_anterior = 0.0;
   static double aceleracao_anterior = 0.0;
   static bool inicializado = false;

// Se não inicializado, define os valores iniciais e retorna 0
   if(!inicializado)
     {
      saldo_anterior = saldo_atual;
      inicializado = true;
      return 0.0;
     }

// Evita divisão por zero se tempo_decorrido for zero
   if(tempo_decorrido <= 0.0)
     {
      return 0.0;
     }

// Calcula velocidade atual (variação do saldo por tempo)
   double delta_saldo = saldo_atual - saldo_anterior;
   double velocidade_atual = delta_saldo / tempo_decorrido;

// Calcula aceleração atual (variação da velocidade por tempo)
   double delta_velocidade = velocidade_atual - velocidade_anterior;
   double aceleracao_atual = delta_velocidade / tempo_decorrido;

// Calcula variação da aceleração (jerk)
   double delta_aceleracao = aceleracao_atual - aceleracao_anterior;
   double variacao_aceleracao = delta_aceleracao / tempo_decorrido;

// Atualiza os valores para a próxima chamada
   saldo_anterior = saldo_atual;
   velocidade_anterior = velocidade_atual;
   aceleracao_anterior = aceleracao_atual;
   Print("X JERK ",tempo_decorrido," ",SALDO_Corrigido()," va ",variacao_aceleracao," da ",delta_aceleracao);

   return NormalizeDouble((variacao_aceleracao),8);
  }
//+------------------------------------------------------------------+
//| Função para avaliar a tendência da EMA nos últimos N candles     |
//+------------------------------------------------------------------+
int EMATrend(int ema_period = 20, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, int N = 10)
  {
   if(N <= 1)
      return 0; // N inválido, retorna neutro

// Cria handle para o indicador EMA
   int handle = iMA(_Symbol, timeframe, ema_period, 0, MODE_EMA, PRICE_CLOSE);
   if(handle == INVALID_HANDLE)
     {
      Print("Erro ao criar handle para iMA (EMA)");
      return 0;
     }

// Array para armazenar os valores da EMA
   double ema_values[];
   ArraySetAsSeries(ema_values, true);

// Copia os valores dos últimos N candles fechados (iniciando do bar 1, excluindo o atual)
   if(CopyBuffer(handle, 0, 1, N, ema_values) != N)
     {
      Print("Erro ao copiar buffer da EMA");
      IndicatorRelease(handle);
      return 0;
     }

// Libera o handle (em um EA, faça isso no OnDeinit)
   IndicatorRelease(handle);

// Calcula a inclinação (slope) via regressão linear
   double sum_x = 0.0, sum_y = 0.0, sum_xy = 0.0, sum_x2 = 0.0;
   for(int i = 0; i < N; i++)
     {
      double x = (double)i; // x de 0 (mais antigo) a N-1 (mais recente)
      double y = ema_values[N - 1 - i]; // Inverte para alinhar: antigo primeiro
      sum_x += x;
      sum_y += y;
      sum_xy += x * y;
      sum_x2 += x * x;
     }

   double denominator = (N * sum_x2 - sum_x * sum_x);
   if(denominator == 0.0)
      return 0; // Evita divisão por zero

   double slope = (N * sum_xy - sum_x * sum_y) / denominator;

// Threshold para ignorar ruído (ajuste conforme o símbolo e timeframe, ex: 1e-5 para forex em M30)
   double epsilon = 1e-5;

   if(MathAbs(slope) < epsilon)
      return 0; // Neutra
   else
      if(slope > 0)
         return 1; // Alta
      else
         return 2; // Baixa
  }
//+------------------------------------------------------------------+
//| Função para obter os tempos gráficos adjacentes                  |
//+------------------------------------------------------------------+
void GetAdjacentTimeframes(ENUM_TIMEFRAMES current, ENUM_TIMEFRAMES &lower, ENUM_TIMEFRAMES &upper)
  {
// Array com os tempos gráficos padrão do MT5
   ENUM_TIMEFRAMES tf_list[] =
     {
      PERIOD_M1,
      //PERIOD_M2,
      //PERIOD_M3,
      //PERIOD_M4,
      PERIOD_M5,
      //PERIOD_M6,
      PERIOD_M10,
      //PERIOD_M12,
      PERIOD_M15,
      //PERIOD_M20,
      PERIOD_M30,
      PERIOD_H1,
      PERIOD_H2,
      //PERIOD_H3,
      PERIOD_H4,
      PERIOD_H6,
      PERIOD_H8,
      PERIOD_H12,
      PERIOD_D1,
      PERIOD_W1,
      PERIOD_MN1
     };
   int total = ArraySize(tf_list);
   lower = PERIOD_CURRENT; // Valor padrão caso não encontre inferior
   upper = PERIOD_CURRENT; // Valor padrão caso não encontre superior

   for(int i = 0; i < total; i++)
     {
      if(tf_list[i] == current)
        {
         // Se não for o primeiro da lista, pega o anterior
         if(i > 0)
            lower = tf_list[i-1];

         // Se não for o último da lista, pega o próximo
         if(i < total - 1)
            upper = tf_list[i+1];

         break;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcularVariacaoSALDO(double saldo_atual, double tempo_decorrido)
  {
// Variáveis estáticas para manter o estado entre chamadas
   static double saldo_anterior = 0.0;
   static bool inicializado = false;

// Se não inicializado, define os valores iniciais e retorna 0
   if(!inicializado)
     {
      saldo_anterior = saldo_atual;
      inicializado = true;
      return 0.0;
     }

// Evita divisão por zero se tempo_decorrido for zero
   if(tempo_decorrido <= 0.0)
     {
      return 0.0;
     }
   double delta_saldo = NormalizeDouble(((saldo_atual * 100 / saldo_anterior)-100),2);
   string n = " ";
   if(delta_saldo <0)
     {
      n=" ---------------------";
     }
   Print("X SDO VAR ",delta_saldo," ",saldo_atual," ",saldo_anterior,n);
   saldo_anterior = saldo_atual;
   return NormalizeDouble((delta_saldo),2);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcularVariacaoSALDOINICIAL(double I_SDO_atual)
  {
   static double I_SDO_anterior = 0.0;
   static bool I_inic = false;
   if(!I_inic)
     {
      I_SDO_anterior = SALDO_1;
      I_inic = true;
      return 0.0;
     }
   double delta_saldo = NormalizeDouble(((I_SDO_atual * 100 / I_SDO_anterior)-100),2);
   string n = " ";
   if(delta_saldo <0)
     {
      n=" ---------------------";
     }
   Print("X SDO INI ",delta_saldo," ",I_SDO_atual," ",I_SDO_anterior,n);
   return NormalizeDouble((delta_saldo),2);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Close_all_losing_operations(int Osl)
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
               double CURR =  PositionGetDouble(POSITION_PRICE_CURRENT) - PositionGetDouble(POSITION_PRICE_OPEN);
               int OP = 0;
               if(tipo == POSITION_TYPE_BUY)
                 {
                  OP = 1;
                 }
               if(tipo == POSITION_TYPE_SELL)
                 {
                  OP = 2;
                  CURR = CURR * -1;
                 }
               if((CURR < 0) && (Osl != OP))
                 {
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
