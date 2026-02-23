//+------------------------------------------------------------------+
//|                                        Tradestars                |
//|                                        mario.halila@gmail.com    |
//+------------------------------------------------------------------+
#property strict
#property copyright "Tradestars"
#property link      "https://www.mql5.com"
#property description "RTM11"

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

//input
string InpToken="1617382308:AAEmQf9aWNwVrjnbdCY0Ni8bvkBc3E6VBVI";//Token do bot que esta no nosso grupo
//input
string GroupChatId="-564508963";
// Parâmetros de entrada
//input string ativo = "GOLD";           // Ativo
//input ENUM_TIMEFRAMES tempoG = PERIOD_M5; // Periodicidade

//+------------------------------------------------------------------+
// PARA BTCUSD H2
//+------------------------------------------------------------------+
sinput string   Robo = "RTM11";
sinput string Versão ="1.11IF";                  //Gold H1 100k > 5,182M
input bool MandaTelegram       = false;       // MSG Telegram
input
double SALDO_DISPONIVEL          = 0000;           // Saldo Disponivel para o robo
input
int METOD_1                 = 7;           //Metodo
input
int METOD_2                 = 1;           //Metodo
input
int MM_media_lenta = 28; //Media gatilho, lenta
input
int MM_media_media = 11; //Media gatilho, intermediaria
input
int MM_media_rapida = 9; //Media gatilho, rapida
input
int Max_dist = 8; //Distancia max para previsão de cruzamento
input
bool inverso             = false;       // Inverter as operações =======
input
int dias = 60; //Renova saldo
input
int LimLAT = 85; //Limite indicador lateralização
input
int XPROP = 2; //Proporcional ao saldo 0, 1, 2
input
double RISCO_MAX_LOSS    =  15;    //Risco Maximo em cada LOSS (USD)
input
double F_MAX_LOTE = 0.06;          //%  Lote maximo para operar
input
double F_PRG_MAX_USD_GAIN = 00;  //%  PRG Max USD SALDO GAIN
input
double F_PRG_MAX_USD_LOSS = 00;  //%  PRG Max USD SALDO LOSS
input
double F_DIA_MAX_USD_LOSS = 0;  //%  Max USD DIA LOSS (Fecha dia)
input
double F_CUR_MAX_USD_GAIN = 0;  //%  OP Max USD SALDO GAIN
input
double F_CUR_MAX_USD_LOSS = 0;  //%  OP Max USD SALDO LOSS
input int SemMov = 6; //Opera se ficar parado
input int   DESISTE_MAX_CANDLES    = 5;     // Desiste max candles sem progresso
input double   DESISTE_MAX_NEG     = 0.01;     // Desiste max Var preco / candles
input int OP_ONLY = 0; //OP ONLY, 0,1,2

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int    MP_Periodo       = MM_media_rapida;          // Período da Média Pequena (rápida)
int    MG_Periodo       = MM_media_lenta;         // Período da Média Grande (lenta)
input int    Candle_N         = 5;          // Candle -N (ex: 5, 8, 10...)
input double Threshold_TC     = 10.0;       // Tamanho médio mínimo do candle (em pontos) para considerar momentum
input double Threshold_PT     = 70.0;       // Pontuação mínima para sinal de entrada (ajuste no otimizador)
input double Lote             = 0.10;       // Tamanho do lote fixo (ajuste conforme sua conta)
input int    Slippage         = 3;          // Deslizamento máximo permitido
input int  XTRS = 2; // Trailing stops (0,1,2)
input int XTST = 0; // Teste minutos Processa
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SL_SIZE    =  2000;    // Tamanho maximo do LOSS (USD)
double MAX_LOTE = 5;          // Lote maximo para operar
double PRG_MAX_USD_GAIN = 0;  // Max perc PRG GAIN (REMOVE)
double PRG_MAX_USD_LOSS = 0;  // Max perc PRG LOSS (REMOVE)
double DIA_MAX_USD_LOSS = 0;  // Max USD DIA LOSS (Fecha dia)
double CUR_MAX_USD_GAIN = 0;  // OP Max USD SALDO GAIN
double CUR_MAX_USD_LOSS = 0;  // OP Max USD SALDO LOSS
double MENORpc = 999999;

string OutroAtivo = "="; // Outro ativo para tendência
bool Xtend = false; //Usar tendência
int TT_media_tend = 21; //Media para a tendência
ENUM_TIMEFRAMES TT_Period = PERIOD_W1; //Tempo grafico para a tendência
bool usainv             = false;       // Auto invert
int Q_OP_simult                   = 10;           // Quant. máxima de operações simultaneas
int TempoVS            = 60;           // Segundos entre revisão de oper.
bool addSPREAD            = true;       // Add SPREAD
double DIA_MAX_USD_GAIN = 0;  // Max USD DIA GAIN (Fecha dia)
bool OPTC = true; //OPTC
bool OPTM = true; //OPTM
bool OPTD = false; //OPTD3

double Gfat = 1; //X Gfat
double Lfat = 1.1; //X Lfat
double OPR_MAX_Perc_GAIN = 150;  // Max perc OPER GAIN (Abre outra oper)
double OPR_MAX_Perc_LOSS = 150;  // Max perc OPER LOSS (Fecha e abre oper inversa)


double vmp[4], vmg[4];           // Médias Móvel Pequena e Grande
double vpi[4], vpf[4];           // Preço Inicial (Open) e Final (Close/Bid)
double vtc[4];                  // Tamanho do candle em pontos
int    vdc[4];                  // Direção do candle: 1 = alta, -1 = baixa, 0 = doji
int handle_MP = INVALID_HANDLE;
int handle_MG = INVALID_HANDLE;




// LATERAL
int atr_handle;
int ma_atr_handle;
double atr_atual;
double atr_media;



bool X_ExpertRemove=false;
struct TradeCalcResult
  {
   string            symbol;
   datetime          time_current;
   int               type_order;            // "1 BUY" ou "2 SELL"
   double            current_price;
   double            lot_size;
   double            point_size;
   double            point_value;
   double            stop_loss_usd;
   double            stop_gain_usd;
   double            stop_loss_points;
   double            stop_gain_points;
   double            stop_loss_price;
   double            stop_gain_price;
  };
TradeCalcResult calcX;

//input
double risco_maximo =    10;             // Percent. máximo de risco sobre Saldo Disponivel

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DIA_MAX_Perc_GAIN = 10000;  // Max perc DIA GAINS (Fecha dia)
//input
double DIA_MAX_Perc_LOSS = 10000;  // Max perc DIA LOSS (Fecha dia)
//input
double CUR_MAX_Perc_GAIN = 10000;  // Max perc SALDO GAIN (FECHA ROBO)
//input
double CUR_MAX_Perc_LOSS = 10000;  // Max perc SALDO LOSS (FECHA ROBO)

struct CrossProjectionResult
  {
   bool              willCross;     // se haverá cruzamento (>0 candles à frente)
   int               barsToCross;   // em quantos candles (ceil)
   int               longDir;       // direção da MA longa no momento do cruzamento: 1=Subindo, 2=Descendo, 0=Flat
   double            nReal;         // n real (não arredondado), útil para debug
   double            cSlope;        // slope da MA curta
   double            lSlope;        // slope da MA longa
   double            cNow;          // valor atual da MA curta
   double            lNow;          // valor atual da MA longa
   int               tradeSignal;      // 1=Compra, 2=Venda, 0=Neutro
  };
int CL_operation = 0;
double CL_lote = 0;
double CL_open_price = 0;
double CL_valor_loss = 0;
double CL_valor_gain = 0;
int SEQ_CANDLES_SEM_OP=0;



//DESLIGADOS
//input
int TEND_qp                    = 5; // Quantidade de periodos para analise de tendência
//input
double Angle  = 30;                           //Angulo variação reta
bool OPTslope             = true;       // Bloqueio SLOPE
int DelayOP = 60; // Segundos delay OP
int MinutosINV            = 240;           // Minutos Inv
int DirANT = 0; // Dir = Candle Anterior, 0=X, 1=S, 2=N
bool TendTOO = false; // = Tendencia
int Mdiv = 1; // divisor media
double FAT_spread = 1; //fat spread
double FAT_propc = 100.0; //% proporcao entre candles
// FIM DESL.
string VER = Versão;
int segundos             = 5;           // Timer entre ordens
int GAIN_steps                  = 1;           // Dividir a operacao em Gain steps
int qvm                  = 0;
double Step_trail = 1; // Fator step trail stop
int L_sobe = 0;
int L_desce = 0;
double MaiorPERC = 0;
double MenorPERC = 0;
double INVS_atual = 0;
double INVS_anter = 0;
int INVS_Q = 0;
int DBperc = 80; //Perc. perda DASHBOARD
int temp_opt = 1; //opt 1 2
int CandlesM1 = 16; // Candles M1 trend
int Qfaixas = 3; // Quant grupos
bool SSN = false; // SIGNAL S/N
int segc           = 5;           // Timer confirmacao
int Perc_Start_X = 20; // Perc para abrir outra op
int DirC = 5; //Quant candles em tendência
double FatorCL = 0.9; // Fator NewSL
double FATOR = 90;
int tv = 0; // tv;
int NEW_order = 0;
double Close0 = 0;
double ant_Close = 0;
bool CUR_INVER;
int QUANT_ = 0;
double SALDO1;
double xcl;
double highest_high;
double lowest_low;
double buy_price;
double sell_price;
double Saldo_p_ant = 0;
int LAST_order = 0;
int LAST_order_QUANT = 0;
int NW_ord = 0;
int QXG = 0;
int Timp = 125; // tmp min g l
double STR_SDO_INI_ROBO = 0;
double STR_SDO_SALVO = 0;
double STR_SDO_INI_OPER = 0;
int qpr = 0;
datetime lastCheck = 0;
bool DIA_FIM = false;
string OP_FIM = " ";

int qcvop = 0;
//DEF
double Sit_Percentuais_G = 0;
double Sit_Percentuais_L = 0;
MqlDateTime lastDate;
double SDO_INI_DIA = 0;
double SDO_INI_CUR = 0;

double LOSS_dist = 0;

int signal = 0;
int NWOP = 0;
double ama_previous = 0.0;          // Valor anterior da AMA
int qm = 0;
int QZ = 0;
// Variáveis globais
int erro;
int quanterro=0;
double atr;                             // Volatilidade (ATR)
double atr_value;                       // Valor do ATR
int tickets[10];                        // Array para tickets das ordens abertas
int O_magic_number;                     // Magic number
ENUM_ORDER_TYPE_FILLING filling_type = ORDER_FILLING_IOC;
string SYMB =" ";
string Oque =" ";
int Qcandle = 0;
double SPREAD = 0;
double V_CURRENT_ASK = 0;
double V_CURRENT_BID = 0;
int Q_Oper = 0;
int Q_TRs = 0;
double FIRST_SDO_ROBO = 0;
double SDO_INI_ROBO = 0;
double SDO_CANDLE_A = 0;
ENUM_TIMEFRAMES tempoG;
double INVERSO_SALDOINI = 0;
datetime INItempo[10];
double TKpreco[20];
int C_V;
struct VALIDoper
  {
   double            lote;
   double            preco_entrada;
   double            stop_loss;
   double            take_profit;
   bool              VERIF;
  };
VALIDoper VALIDop_Res;
struct ORDENS
  {
   string            SEQ;
   int               Qgain;
   int               Qloss;
   double            Dif;
   string            Mk;
  };
datetime allowed_until = D'2027.06.06 00:00';
ORDENS MvO[10];
double MedP_ant = 0;
double MedP_cor = 0;
double MedG_cor = 0;


double VTS_SDO_INI_OPER = 0;
string TmpX[7];
string VTS_str;
string VTS_status;
double VTS_valop;
double VTS_valGain;
double VTS_valLoss;
//+------------------------------------------------------------------+
//| Estrutura para armazenar estimativas                            |
//+------------------------------------------------------------------+
struct CandleEstimation
  {
   double            size_estimate;
   int               direction; // 1 = alta, -1 = baixa, 0 = indefinido
   double            confidence; // 0.0 a 1.0
  };
int TENDENCIA_c_v = 0;
CandleEstimation estM5;
CandleEstimation estM15;
CandleEstimation estH2;
double LOSS_VALUE;
double GAIN_VALUE;
double TEND_MED_b[];
double TEND = 0;
//+------------------------------------------------------------------+
//| Função de inicialização                                          |
//+------------------------------------------------------------------+
int OnInit()
  {
   X_ExpertRemove=false;
   CUR_INVER = inverso;
   INVS_anter = 0;
   O_magic_number = MathRand();
   m_trade  = new CTrade();
   m_trade.SetExpertMagicNumber(O_magic_number);
   Q_Oper = 0;
   Q_TRs = 0;
   SALDO_Rev();
   SDO_INI_ROBO = SALDO_Corrigido();
   FIRST_SDO_ROBO = SDO_INI_ROBO;
   TimeToStruct(TimeCurrent(),lastDate);
   SDO_INI_DIA = SALDO_Corrigido();
   SDO_INI_CUR = SALDO_Corrigido();
   STR_SDO_SALVO = 0;
   STR_SDO_INI_ROBO = SALDO_Corrigido();
   Qcandle = 0;
   SYMB = Symbol();
   tempoG = Period();
   for(int i = 0; i < 10; i++)
     {
      INItempo[i] = 0;
     }
// INIT MvO
   for(int i = 0; i < 10; i++)
     {
      MvO[i].SEQ = " ";
      MvO[i].Qgain = 0;
      MvO[i].Qloss = 0;
      MvO[i].Dif = 0;
      MvO[i].Mk = " ";
     }
   NEW_order = 0;
   Close0 = 0;
   MenorPERC = 0;
   TelMsg();
   Saldo_p_ant = 0;
   MaiorPERC = 0;
   MenorPERC = 0;
   DASHBOARD();
   V_CURRENT_ASK = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   V_CURRENT_BID = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   SPREAD = V_CURRENT_ASK - V_CURRENT_BID;
   SALVA_TKpreco(((V_CURRENT_ASK + V_CURRENT_BID)/2), 20);
   highest_high = iHigh(SYMB, tempoG, iHighest(SYMB, tempoG, MODE_HIGH, MathRound(Max_dist), 0));
   lowest_low = iLow(SYMB, tempoG, iLowest(SYMB, tempoG, MODE_LOW,MathRound(Max_dist), 0));
   buy_price = highest_high;
   sell_price = lowest_low;
   SDO_CANDLE_A = SALDO_Corrigido();
   SL_SIZE = NormalizeDouble((FIRST_SDO_ROBO * RISCO_MAX_LOSS / 100),2);
   if(SL_SIZE == 0)
     {
      SL_SIZE = NormalizeDouble((FIRST_SDO_ROBO * 10 / 100),2);
     }
   MAX_LOTE = NormalizeDouble((FIRST_SDO_ROBO * F_MAX_LOTE / 100),2);
   PRG_MAX_USD_LOSS = NormalizeDouble((FIRST_SDO_ROBO * F_PRG_MAX_USD_LOSS / 100),2);
   PRG_MAX_USD_GAIN = NormalizeDouble((FIRST_SDO_ROBO * F_PRG_MAX_USD_GAIN / 100),2);
   DIA_MAX_USD_LOSS = NormalizeDouble((FIRST_SDO_ROBO * F_DIA_MAX_USD_LOSS / 100),2);
   CUR_MAX_USD_GAIN = NormalizeDouble((FIRST_SDO_ROBO * F_CUR_MAX_USD_GAIN / 100),2);
   CUR_MAX_USD_LOSS = NormalizeDouble((FIRST_SDO_ROBO * F_CUR_MAX_USD_LOSS / 100),2);
   MOSTRA();
// LATERAL
   atr_handle    = iATR(_Symbol,_Period,14);
   ma_atr_handle = iMA(_Symbol,_Period,50,0,MODE_SMA,atr_handle);  // <--- média sobre o ATR
   handle_MP = iMA(_Symbol, _Period, MP_Periodo, 0, MODE_EMA, PRICE_CLOSE);
   handle_MG = iMA(_Symbol, _Period, MG_Periodo, 0, MODE_EMA, PRICE_CLOSE);

   if(handle_MP == INVALID_HANDLE || handle_MG == INVALID_HANDLE)
     {
      Print("Erro ao criar handles das médias móveis!");
      return(INIT_FAILED);
     }

   if(atr_handle==INVALID_HANDLE || ma_atr_handle==INVALID_HANDLE)
     {
      //T Print("Erro ao criar indicadores");
      return(INIT_FAILED);
     }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Função de desinicialização                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   bool dls;
   dls = ObjectDelete(0, "LTen");
   dls = ObjectDelete(0, "NOP");
   dls = ObjectDelete(0, "Sit");
  }
//+------------------------------------------------------------------+
//| Função principal de execução                                     |
//+------------------------------------------------------------------+
void OnTick()
  {
   qm++;
   if(CountSeconds(10, 9) == true)
     {
      string LA=LATERALIZADO();
     }

   if(Quant_Dias(dias, lastCheck))
     {
      qpr ++;
      //      //T Print("QPR ",qpr);
      double TMP_SDO = AccountInfoDouble(ACCOUNT_EQUITY) - INVERSO_SALDOINI;
      double psdo = TMP_SDO;
      if(TMP_SDO > STR_SDO_INI_ROBO)
        {
         STR_SDO_SALVO = TMP_SDO - STR_SDO_INI_ROBO;
        }
      TMP_SDO = SALDO_Corrigido();
      SDO_INI_ROBO = TMP_SDO;
      SDO_INI_DIA = TMP_SDO;
      SDO_INI_CUR = TMP_SDO;
      //      //T Print(" dias : ",dias," q : ",qpr," Ant: ",psdo," Cur : ",TMP_SDO," Ini :", STR_SDO_INI_ROBO," Sav: ",STR_SDO_SALVO);
     }
   if(HasDateChanged())
     {

      double vsi = SALDO_Corrigido();
      if((vsi < SDO_INI_DIA) && (usainv == true))
        {
         if(CUR_INVER == false)
           {
            CUR_INVER = true;
            vsi = SDO_INI_DIA;
           }
        }
      if(vsi < SDO_INI_DIA)
        {
         if(CUR_INVER == true)
           {
            CUR_INVER = false;
           }
        }
      //      //T Print("INV: ",CUR_INVER);

      SDO_INI_DIA = SALDO_Corrigido();
      DIA_FIM = false;
     }
   if(XTST > 0)
     {
      //      if(CountSeconds((PeriodSeconds() / 120), 3) == true)
      if(CountSeconds((XTST * 60), 3) == true)
        {
         if(DIA_FIM == false)
           {
            PROCESSA();
           }
        }
     }
   if(DIA_FIM == false)
     {
      OP_FIM = " ";
      string XS = " ";
      XS = ABOUT_SDOS();
      if(XS == "xDG")
        {
         Oque = "FIM DIA GAIN";
         //T Print("---> ", Oque);
         Close_all_Orders();
         DIA_FIM = true;
        }
      if(XS == "xDL")
        {
         Oque = "FIM DIA LOSS";
         //T Print("---> ", Oque);
         Close_all_Orders();
         DIA_FIM = true;
        }
      if(XS == "xFG")
        {
         Oque = "FIM OPS GAIN";
         //T Print("---> ", Oque);
         Close_all_Orders();
         STR_SDO_INI_OPER = SALDO_Corrigido();
        }
      if(XS == "xFL")
        {
         Oque = "FIM OPS LOSS";
         //T Print("---> ", Oque);
         Close_all_Orders();
         STR_SDO_INI_OPER = SALDO_Corrigido();
        }
      if(CountSeconds(TempoVS, 1) == true)
        {
         int x = Orders_ON();
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   bool NewCandle = TemosNewCandle();
   if((NewCandle==true)&&(X_ExpertRemove==false))
     {
      //      //T Print("PONTO ",SymbolInfoDouble(Symbol(), SYMBOL_POINT));
      datetime now = TimeCurrent();
      if(now > allowed_until)
        {
         //T Print("EA timeout limit verified");
         ExpertRemove();
        }
      /*      CrossProjectionResult r = ProjectMACross(_Symbol, tempoG,
                                      MM_media_rapida, MM_media_lenta, MODE_EMA, PRICE_CLOSE,
                                      Max_dist, 1e-8, 1000);
            if(r.willCross)
              {

               string dirL = (r.longDir==1?"Subindo":(r.longDir==2?"Descendo":"Flat"));
               PrintFormat("Cruzamento previsto em %d candles (n=%.2f). L=%s, slopes: C=%.6f L=%.6f  Cnow=%.5f Lnow=%.5f",
                           r.barsToCross, r.nReal, dirL, r.cSlope, r.lSlope, r.cNow, r.lNow);

               string sig = (r.tradeSignal==1 ? "Compra" : (r.tradeSignal==2 ? "Venda" : "Neutro"));

               //T Print("Cruzamento em ", r.barsToCross," Ac: ",Max_dist," ",sig);
              }
            else
              {
               PrintFormat("Sem cruzamento projetável: n=%.2f  slopes C=%.6f L=%.6f", r.nReal, r.cSlope, r.lSlope);
              }
      */
      bool dls;
      dls = ObjectDelete(0, "LTen");
      dls = ObjectDelete(0, "NOP");
      //      MOSTRA_SIT("NC");
      Qcandle++;
      //      //T Print("CvAR ",TimeCurrent()," ",Qcandle," ",DoubleToString((SALDO_Corrigido()-SDO_CANDLE_A),2));
      SDO_CANDLE_A = SALDO_Corrigido();
      V_CURRENT_ASK = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
      V_CURRENT_BID = SymbolInfoDouble(Symbol(),SYMBOL_BID);
      SPREAD = V_CURRENT_ASK - V_CURRENT_BID;
      SALVA_TKpreco(((V_CURRENT_ASK + V_CURRENT_BID)/2), 20);
      High_Low();
      int temOP = Orders_ON();
      if(temOP > 0)
        {
         SEQ_CANDLES_SEM_OP = 0;
        }
      else
        {
         SEQ_CANDLES_SEM_OP++;
        }
      if(temOP == 0)
        {
         D_linHOR("HH", highest_high, now, clrBlueViolet, 1);
         D_linHOR("LL", lowest_low, now, clrBlueViolet, 1);
        }
      MOSTRA();
      datetime time_n_candles_atras = TimeCurrent() - (Period() * TEND_qp*60);
      if(DIA_FIM == false)
        {
         PROCESSA();
        }
      DASHBOARD();
      if(CountSeconds(3600, 2) == true)
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
int Orders_ON()
  {
   int orders_count = PositionsTotal();
   if(orders_count > 0)
     {
      TRAILS();
     }
   orders_count = PositionsTotal();
   return (orders_count);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PROCESSA()
  {
   string L = LATERALIZADO();
   if(L != "L")
     {
      int orders_count = Orders_ON();
      int CUR_OP = 0;
      if(orders_count > 0)
        {
         CUR_OP = JA_TEM_OP();
        }
      NWOP = 0;
      string QUAL_OP = " ";
      int qop = EA_positions();
      if((inverso == true) && (qop <= 1))
        {
         qop = qop--;
        }
      if(qop < Q_OP_simult)
        {
         if(SALDO_Corrigido() > -SALDO_DISPONIVEL)
           {
            if((METOD_1 == 1) || (METOD_1 == 0))
              {
               if((NWOP == 0) && (OPTD==true))
                 {
                  V_CURRENT_ASK = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
                  V_CURRENT_BID = SymbolInfoDouble(Symbol(),SYMBOL_BID);
                  SPREAD = V_CURRENT_ASK - V_CURRENT_BID;
                  int DMP = VerificarDirecaoEMA(MM_media_rapida, Max_dist);
                  int DMM = VerificarDirecaoEMA(MM_media_media, Max_dist);
                  int DMG = VerificarDirecaoEMA(MM_media_lenta, Max_dist);
                  if((DMP == DMM) && (DMM == DMG))
                    {
                     NWOP = DMP;
                    }
                  if(NWOP >0)
                    {
                     ////T Print("NWOP ",NWOP," ===");
                    }
                 }
               if((NWOP == 0) && (OPTM==true))
                 {
                  NWOP = DetectaCruzamentoMACD(3, 10, 15, PRICE_CLOSE);
                  if(NWOP >0)
                    {
                     ////T Print("NWOP ",NWOP," MAC");
                    }
                 }
               if(NWOP == 0)
                 {
                  NWOP = CROSS_MEDIAS(_Symbol, MM_media_rapida, MM_media_lenta);
                  if(NWOP > 0)
                    {
                     ////T Print("NWOP ",NWOP," CRL");
                    }
                 }
               if(NWOP == 0)
                 {
                  NWOP = GUESS(MM_media_rapida, MM_media_lenta);
                  if(NWOP > 0)
                    {
                     ////T Print("NWOP ",NWOP," GRL");
                    }
                 }
               if(NWOP == 0)
                 {
                  NWOP = CROSS_MEDIAS(_Symbol, MM_media_rapida, MM_media_media);
                  if(NWOP > 0)
                    {
                     ////T Print("NWOP ",NWOP," CRM");
                    }
                 }
               if(NWOP == 0)
                 {
                  NWOP = GUESS(MM_media_rapida, MM_media_media);
                  if(NWOP > 0)
                    {
                     ////T Print("NWOP ",NWOP," GRM");
                    }
                 }
               if(NWOP == 0)
                 {
                  NWOP = CROSS_MEDIAS(_Symbol, MM_media_media, MM_media_lenta);
                  if(NWOP > 0)
                    {
                     ////T Print("NWOP ",NWOP," CML");
                    }
                 }
               if(NWOP == 0)
                 {
                  NWOP = GUESS(MM_media_media, MM_media_lenta);
                  if(NWOP > 0)
                    {
                     ////T Print("NWOP ",NWOP," GML");
                    }
                 }
              }
            if((METOD_1 == 2) || (METOD_1 == 0))
              {
               if(NWOP == 0)
                 {
                  NWOP = PROX_DA_MEDIA(MM_media_rapida);
                 }
               if(NWOP == 0)
                 {
                  NWOP = PROX_DA_MEDIA(MM_media_media);
                 }
               if(NWOP == 0)
                 {
                  NWOP = PROX_DA_MEDIA(MM_media_lenta);
                 }
              }
            if((METOD_1 == 3) || (METOD_1 == 0))
              {
               if(NWOP == 0)
                 {
                  NWOP = GAIN_AG(MM_media_rapida);
                 }
               if(NWOP == 0)
                 {
                  NWOP = GAIN_AG(MM_media_media);
                 }
               if(NWOP == 0)
                 {
                  NWOP = GAIN_AG(MM_media_lenta);
                 }
              }
            if((METOD_1 == 4) || (METOD_1 == 0))
              {
               if(NWOP == 0)
                 {
                  NWOP = CheckBollingerSignal(Symbol(), PERIOD_CURRENT, 20, 2);
                 }
              }
            if((METOD_1 == 5) || (METOD_1 == 0))
              {
               if(NWOP == 0)
                 {
                  NWOP = CheckMACDCross(
                            _Symbol,
                            _Period,
                            MM_media_rapida,    // fast EMA
                            MM_media_lenta,    // slow EMA
                            MM_media_media,     // signal SMA
                            PRICE_CLOSE,
                            2,     // shift_previous (two bars ago)
                            1      // shift_current (one bar ago)
                         );
                 }
              }
            if((METOD_1 == 6) || (METOD_1 == 0))
              {
               if(NWOP == 0)
                 {
                  double dist=0;
                  bool ma_up = false; 
                  bool price_above = false;
                  NWOP = GetMeanReversionSignal(55, PERIOD_CURRENT, dist, ma_up, price_above);
                 }
              }
            if((METOD_1 == 7) || (METOD_1 == 0))
              {
               if(NWOP == 0)
                 {
                  INTEL_get();
                  NWOP = INTEL_proc();
                 }
              }
            if((NWOP == 0) && (METOD_1 != 0) && (METOD_1 != METOD_2))
              {
               if((METOD_2 == 1) || (METOD_2 == 0))
                 {
                  if((NWOP == 0) && (OPTD==true))
                    {
                     V_CURRENT_ASK = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
                     V_CURRENT_BID = SymbolInfoDouble(Symbol(),SYMBOL_BID);
                     SPREAD = V_CURRENT_ASK - V_CURRENT_BID;
                     int DMP = VerificarDirecaoEMA(MM_media_rapida, Max_dist);
                     int DMM = VerificarDirecaoEMA(MM_media_media, Max_dist);
                     int DMG = VerificarDirecaoEMA(MM_media_lenta, Max_dist);
                     if((DMP == DMM) && (DMM == DMG))
                       {
                        NWOP = DMP;
                       }
                     if(NWOP >0)
                       {
                        ////T Print("NWOP ",NWOP," ===");
                       }
                    }
                  if((NWOP == 0) && (OPTM==true))
                    {
                     NWOP = DetectaCruzamentoMACD(3, 10, 15, PRICE_CLOSE);
                     if(NWOP >0)
                       {
                        ////T Print("NWOP ",NWOP," MAC");
                       }
                    }
                  if(NWOP == 0)
                    {
                     NWOP = CROSS_MEDIAS(_Symbol, MM_media_rapida, MM_media_lenta);
                     if(NWOP > 0)
                       {
                        ////T Print("NWOP ",NWOP," CRL");
                       }
                    }
                  if(NWOP == 0)
                    {
                     NWOP = GUESS(MM_media_rapida, MM_media_lenta);
                     if(NWOP > 0)
                       {
                        ////T Print("NWOP ",NWOP," GRL");
                       }
                    }
                  if(NWOP == 0)
                    {
                     NWOP = CROSS_MEDIAS(_Symbol, MM_media_rapida, MM_media_media);
                     if(NWOP > 0)
                       {
                        ////T Print("NWOP ",NWOP," CRM");
                       }
                    }
                  if(NWOP == 0)
                    {
                     NWOP = GUESS(MM_media_rapida, MM_media_media);
                     if(NWOP > 0)
                       {
                        ////T Print("NWOP ",NWOP," GRM");
                       }
                    }
                  if(NWOP == 0)
                    {
                     NWOP = CROSS_MEDIAS(_Symbol, MM_media_media, MM_media_lenta);
                     if(NWOP > 0)
                       {
                        ////T Print("NWOP ",NWOP," CML");
                       }
                    }
                  if(NWOP == 0)
                    {
                     NWOP = GUESS(MM_media_media, MM_media_lenta);
                     if(NWOP > 0)
                       {
                        ////T Print("NWOP ",NWOP," GML");
                       }
                    }
                 }
               if((METOD_2 == 2) || (METOD_2 == 0))
                 {
                  if(NWOP == 0)
                    {
                     NWOP = PROX_DA_MEDIA(MM_media_rapida);
                    }
                  if(NWOP == 0)
                    {
                     NWOP = PROX_DA_MEDIA(MM_media_media);
                    }
                  if(NWOP == 0)
                    {
                     NWOP = PROX_DA_MEDIA(MM_media_lenta);
                    }
                 }
               if((METOD_2 == 3) || (METOD_2 == 0))
                 {
                  if(NWOP == 0)
                    {
                     NWOP = GAIN_AG(MM_media_rapida);
                    }
                  if(NWOP == 0)
                    {
                     NWOP = GAIN_AG(MM_media_media);
                    }
                  if(NWOP == 0)
                    {
                     NWOP = GAIN_AG(MM_media_lenta);
                    }
                 }
               if((METOD_2 == 4) || (METOD_2 == 0))
                 {
                  if(NWOP == 0)
                    {
                     NWOP = CheckBollingerSignal(Symbol(), PERIOD_CURRENT, 20, 2);
                    }
                 }
               if((METOD_2 == 5) || (METOD_2 == 0))
                 {
                  if(NWOP == 0)
                    {
                     NWOP = CheckMACDCross(
                               _Symbol,
                               _Period,
                               MM_media_rapida,    // fast EMA
                               MM_media_lenta,    // slow EMA
                               MM_media_media,     // signal SMA
                               PRICE_CLOSE,
                               2,     // shift_previous (two bars ago)
                               1      // shift_current (one bar ago)
                            );
                    }
                 }
               if((METOD_2 == 6) || (METOD_2 == 0))
                 {
                  if(NWOP == 0)
                    {
                     double dist = 0;
                     bool ma_up = false; 
                     bool price_above = false;
                     NWOP = GetMeanReversionSignal(55, PERIOD_CURRENT, dist, ma_up, price_above);
                    }
                 }

               if((METOD_1 == 7) || (METOD_1 == 0))
                 {
                  if(NWOP == 0)
                    {
                     INTEL_get();
                     NWOP = INTEL_proc();
                    }
                 }
              }
            int tdr = 0;
            if(NWOP > 0)
              {
               if(NWOP == 1)
                 {
                  D_linVER("Lo", V_CURRENT_BID, TimeCurrent(),clrDarkKhaki, 2);
                 }
               if(NWOP == 2)
                 {
                  D_linVER("Lo", V_CURRENT_BID, TimeCurrent(),clrDarkKhaki, 2);
                 }
               MOSTRA();
               if(Xtend == true)
                 {
                  if(TEND > 0)
                    {
                     tdr = 1;
                    }
                  if(TEND < 0)
                    {
                     tdr = 2;
                    }
                  //            //T Print("NWOP ",NWOP," tdr ",tdr);
                  if(tdr != NWOP)
                    {
                     NWOP = 0;
                    }
                 }
              }
            Print("SEM MOV ",SemMov," ",NWOP," ",SEQ_CANDLES_SEM_OP," ",iClose(_Symbol, PERIOD_CURRENT, 1)," ",iClose(_Symbol, PERIOD_CURRENT, (SemMov+1)));
            if((NWOP == 0) && (SemMov > 0) && (SEQ_CANDLES_SEM_OP >= SemMov))
              {
               int qs = SemMov+1;
               if(iClose(_Symbol, PERIOD_CURRENT, 1) > iClose(_Symbol, PERIOD_CURRENT, qs))
                  NWOP = 1;
               if(iClose(_Symbol, PERIOD_CURRENT, 1) < iClose(_Symbol, PERIOD_CURRENT, qs))
                  NWOP = 2;
               //               Print("SEM MOV ",NWOP," ",iClose(_Symbol, PERIOD_CURRENT, 1)," ",iClose(_Symbol, PERIOD_CURRENT, qs));
              }
            if(NWOP > 0)
              {
               if(CUR_INVER == true)
                 {
                  if(NWOP == 1)
                    {
                     NWOP = 2;
                    }
                  else
                    {
                     NWOP = 1;
                    }
                 }
              }
            if(OP_ONLY > 0)
              {
               if(OP_ONLY != NWOP)
                 {
                  NWOP = 0;
                 }
              }
            if(NWOP > 0)
              {
               ////T Print("OPS a ",CUR_OP," n ",NWOP);
              }
            if((OPTC == true) && (CUR_OP > 0) && (CUR_OP != NWOP))
              {
               Close_Order();
              }
            int OOC = 0;
            if(NWOP == 1)
              {
               OOC = 2;
              }
            if(NWOP == 2)
              {
               OOC = 1;
              }
            if(OOC > 0)
              {
               Close_ALL_X(OOC);
              }
            Print ("OP.sr > ",NWOP);
            if(NWOP == 1)
              {
               OrderCOMPRA();
              }
            if(NWOP == 2)
              {
               OrderVENDA();
              }
            orders_count = Orders_ON();
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderCOMPRA()
  {
   MqlTradeRequest   requisicao;    // requisição
   MqlTradeResult    resposta;      // resposta
   MqlTradeCheckResult checkResult;
   ZeroMemory(requisicao);
   ZeroMemory(resposta);
   C_V = 1;
   double open_price=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double ponto = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   CALCULA_Lote(C_V, PrSdo(SL_SIZE), PrSdo(MAX_LOTE), highest_high, lowest_low);
   double Valloss = CL_valor_loss;
   double Valgain = CL_valor_gain;
   double LotSize = CL_lote;
   V_CURRENT_ASK = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   V_CURRENT_BID = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   SPREAD = V_CURRENT_ASK - V_CURRENT_BID;
   requisicao.action       = TRADE_ACTION_DEAL;                            // Executa ordem a mercado
   requisicao.magic        = O_magic_number;                               // Nº mágico da ordem
   requisicao.symbol       = _Symbol;                                      // compbolo do SYMB
   requisicao.price        = NormalizeDouble(open_price,_Digits);                  // Preço para a compra
   requisicao.sl           = NormalizeDouble(Valloss,_Digits);             // Preço Stop Loss
   requisicao.tp           = NormalizeDouble(Valgain,_Digits);             // Alvo de Ganho - Take Profit
   requisicao.volume       = NormalizeDouble(LotSize, 2);                  // Nº de Lotes
   requisicao.deviation    = 0;                                            // Desvio Permitido do preço
   requisicao.type         = ORDER_TYPE_BUY;                               // Tipo da Ordem
   requisicao.type_filling = filling_type;                                 // Tipo deo Preenchimento da ordem
   VTS_str=" ";
   VTS_SDO_INI_OPER = SALDO_Corrigido();
   VTS_valop = requisicao.price;
   VTS_valGain = requisicao.tp;
   VTS_valLoss = requisicao.sl;
   VTS_status = "N";
   Val_X_Str_Comment("S");
   Place_Order(requisicao);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderVENDA()
  {
   int shift = 1;
   MqlTradeRequest   requisicao = {};    // requisição
   MqlTradeResult    resposta = {};      // resposta
   ZeroMemory(requisicao);
   ZeroMemory(resposta);
   C_V = 2;
   double open_price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   V_CURRENT_ASK = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   V_CURRENT_BID = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   SPREAD = V_CURRENT_ASK - V_CURRENT_BID;
   double ponto = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   CALCULA_Lote(C_V, PrSdo(SL_SIZE), PrSdo(MAX_LOTE), highest_high, lowest_low);
   double Valloss = CL_valor_loss;
   double Valgain = CL_valor_gain;
   double LotSize = CL_lote;
   requisicao.action       = TRADE_ACTION_DEAL;                            // Executa ordem a mercado
   requisicao.magic        = O_magic_number;                               // Nº mágico da ordem
   requisicao.symbol       = _Symbol;                                      // Simbolo do SYMB
   requisicao.price        = NormalizeDouble(open_price,_Digits);                  // Preço para Venda
   requisicao.sl           = NormalizeDouble(Valloss,_Digits);             // Preço Stop Loss
   requisicao.tp           = NormalizeDouble(Valgain,_Digits);             // Alvo de Ganho - Take Profit
   requisicao.volume       = NormalizeDouble(LotSize, 2);                  // Nº de Lotes
   requisicao.deviation    = 0;                                            // Desvio Permitido do preço
   requisicao.type         = ORDER_TYPE_SELL;                              // Tipo da Ordem
   requisicao.type_filling = filling_type;                                 // Tipo de Preenchimento da ordem
   VTS_str=" ";
   VTS_SDO_INI_OPER = SALDO_Corrigido();
   VTS_valop = requisicao.price;
   VTS_valGain = requisicao.tp;
   VTS_valLoss = requisicao.sl;
   VTS_status = "N";
   Val_X_Str_Comment("S");
   Place_Order(requisicao);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Place_Order(MqlTradeRequest &requisicao)
  {
   Oque = IntegerToString(C_V);
   SEQ_CANDLES_SEM_OP = 0;
//   //T Print("Q ",qm++," Place_Order ", Oque," (", TENDENCIA_c_v,") Price ",requisicao.price," StopLoss ",requisicao.sl," StopGain ",requisicao.tp);
   MqlTradeCheckResult checkResult;
   MqlTradeResult resposta;
   bool SalvaOper = true;
   if(C_V == 1)
     {
      requisicao.price = NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_ASK),_Digits);
     }
   else
     {
      requisicao.price = NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_BID),_Digits);
     }
   double precoEntrada = requisicao.price;
   double maxGain = requisicao.tp;
   double loteTotal = requisicao.volume;
   double lotePorOperacao = NormalizeDouble(loteTotal / GAIN_steps, 2);
   double intervaloGain = (maxGain - precoEntrada) / GAIN_steps;
   for(int i = 0; i < GAIN_steps; i++)
     {
      requisicao.tp = NormalizeDouble(precoEntrada + (i + 1) * intervaloGain, _Digits);
      requisicao.volume = lotePorOperacao;
      VALIDop_Res = ValidarParametros(Timp, Symbol(), PERIOD_CURRENT, C_V, requisicao.volume, requisicao.price, requisicao.sl, requisicao.tp);
      requisicao.volume = NormalizeDouble(VALIDop_Res.lote,_Digits);
      requisicao.sl = NormalizeDouble(VALIDop_Res.stop_loss,_Digits);
      requisicao.tp = NormalizeDouble(VALIDop_Res.take_profit,_Digits);
      requisicao.comment = VTS_str;
      if(OrderCheck(requisicao, checkResult))
        {
         if(OrderSend(requisicao,resposta))
           {
            if(resposta.retcode == 10008 || resposta.retcode == 10009)
              {
               SalvaOper = true;
               Q_Oper++;
               if(C_V == 1)
                 {
                  //                  D_linVER("x"+Q_Oper, requisicao.price, TimeCurrent(),clrLawnGreen, 1);
                  //                  D_linVER("NOP", requisicao.price, TimeCurrent(),clrLime, 1);
                 }
               if(C_V == 2)
                 {
                  //                  D_linVER("x"+Q_Oper, requisicao.price, TimeCurrent(),clrTomato, 1);
                  //                  D_linVER("NOP", requisicao.price, TimeCurrent(),clrOrangeRed, 1);
                 }
               else
                 {
                  erro = GetLastError();
                  if(erro == 4756)
                    {
                     quanterro++;
                     //                     //T Print("Err4756 ",quanterro);
                    }
                  SalvaOper = false;
                  //                  //T Print("Erro 1 ao enviar Ordem ", resposta.request_id," do tipo ", requisicao.type, ". Erro = ", erro, " C_V ",C_V);
                  ResetLastError();
                 }
              }
            else
              {
               //               //T Print("Erro 2 ao enviar Ordem ", resposta.request_id," do tipo ", requisicao.type, ". Erro = ", erro, " C_V ",C_V);
               ResetLastError();
              }
           }
         else
           {
            erro = GetLastError();
            //            //T Print("Erro 3 ao enviar Ordem ", resposta.request_id," do tipo ", requisicao.type, ". Erro = ", erro, " C_V ",C_V);
            ResetLastError();
           }
        }
     }
   bool dls = ObjectDelete(0, "HH");
   dls = ObjectDelete(0, "LL");
   dls = ObjectDelete(0, "Lo");
   STR_SDO_INI_OPER = SALDO_Corrigido();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Close_Order()
  {
//   //T Print("-- FECHA ", Oque);
   bool falhou = false;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == O_magic_number)
           {
            if(!m_trade.PositionClose(m_position.Ticket()))
              {
               falhou = true;
               //               //T Print("Fecha ","-- FALHOU--- ",m_trade.ResultRetcodeDescription());
              }
           }
        }
     }
   if(!falhou)
     {
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Close_all_Orders()
  {
   ulong posTicket;
   bool posSelected;
   string SEQ = " ";
   int resp = 0;
   bool perd = false;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      posTicket = PositionGetTicket(i);
      posSelected = m_position.SelectByTicket(posTicket);
      if(posTicket>0 && posSelected)
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == O_magic_number)
           {
            Close_Order();
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SALVA_TKpreco(double VAL, int QTO)
  {
   for(int i = QTO - 1; i > 0; i--)
     {
      TKpreco[i] = TKpreco[i-1];
     }
   TKpreco[0] = VAL;
//   //T Print ("VAL: ",VAL);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ABOUT_SDOS()
  {
   string sit = " ";
   double DIA_Perc_V = 0;
   double CUR_Perc_V = 0;
   DIA_Perc_V = ((100 * (SALDO_Corrigido() / SDO_INI_DIA)) - 100);
   CUR_Perc_V = ((100 * (SALDO_Corrigido() / SDO_INI_CUR)) - 100);
   if(CUR_Perc_V > MaiorPERC)
     {
      MaiorPERC = CUR_Perc_V;
     }
   if(MenorPERC == 0)
     {
      MenorPERC = CUR_Perc_V;
     }
   if(CUR_Perc_V < MenorPERC)
     {
      MenorPERC = CUR_Perc_V;
     }

   if(DIA_MAX_Perc_LOSS != 0)
     {
      if(DIA_Perc_V <= -DIA_MAX_Perc_LOSS)
        {
         sit = "xDL";
        }
     }
   if(DIA_MAX_Perc_GAIN != 0)
     {
      if(DIA_Perc_V >= DIA_MAX_Perc_GAIN)
        {
         sit = "xDG";
        }
     }
   if(CUR_MAX_Perc_GAIN != 0)
     {
      if(CUR_Perc_V >= CUR_MAX_Perc_GAIN)
        {
         sit = "xFG";
        }
     }
   if(CUR_MAX_Perc_LOSS != 0)
     {
      if(CUR_Perc_V <= -CUR_MAX_Perc_LOSS)
        {
         sit = "xFL";
        }
     }

///* MH
   if(DIA_MAX_USD_LOSS != 0)
     {
      if((SALDO_Corrigido() - SDO_INI_DIA) <= -DIA_MAX_USD_LOSS)
        {
         sit = "xDL";
        }
     }
   if(DIA_MAX_USD_GAIN != 0)
     {
      if((SALDO_Corrigido() - SDO_INI_DIA) >= DIA_MAX_USD_GAIN)
        {
         sit = "xDG";
        }
     }
   if(CUR_MAX_USD_GAIN != 0)
     {
      //      if((SALDO_Corrigido() - STR_SDO_INI_ROBO) >= CUR_MAX_USD_GAIN)
      if((SALDO_Corrigido() - STR_SDO_INI_OPER) >= CUR_MAX_USD_GAIN)
        {
         sit = "xFG";
        }
     }
   if(CUR_MAX_USD_LOSS != 0)
     {
      //      if((SALDO_Corrigido() - SDO_INI_DIA) <= -CUR_MAX_USD_LOSS)
      if((SALDO_Corrigido() - STR_SDO_INI_OPER) <= -CUR_MAX_USD_LOSS)
        {
         sit = "xFL";
        }
     }
//*/



   return (sit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HasDateChanged()
  {
   MqlDateTime currentDate;
   TimeToStruct(TimeCurrent(), currentDate);
   if(currentDate.year != lastDate.year ||
      currentDate.mon != lastDate.mon ||
      currentDate.day != lastDate.day)
     {
      lastDate = currentDate;
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TelMsg()
  {
   long NConta = (AccountInfoInteger(ACCOUNT_LOGIN));
   string XConta = DoubleToString(NConta,0);
   double prc=SALDO_Corrigido() * 100 / SDO_INI_ROBO;
   string Telegram_Message=
      VER+" "+
      XConta+" "+
      SYMB+" "+
      IntegerToString(Q_Oper)+" "+
      IntegerToString(Q_TRs)+" "+
      "P "+DoubleToString(SALDO_Corrigido(),2)+" "+
      DoubleToString(prc,2)+" "+
      DoubleToString(MaiorPERC,2)+" "+
      DoubleToString(MenorPERC,2)+" ";
//   //T Print(Telegram_Message);
   if(MandaTelegram == true)
     {
      SendMessage(InpToken, GroupChatId, Telegram_Message);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TelMsgXXX()
  {
   long NConta = (AccountInfoInteger(ACCOUNT_LOGIN));
   string XConta = DoubleToString(NConta,0);
   double prc=SALDO_Corrigido() * 100 / SDO_INI_ROBO;
   string Telegram_Message=
      VER+" "+
      XConta+" "+
      SYMB+" "+
      IntegerToString(Q_Oper)+" "+
      IntegerToString(Q_TRs)+" "+
      "P "+DoubleToString(SALDO_Corrigido(),2)+" "+
      DoubleToString(prc,2)+" "+
      " CANCELADO";
//   //T Print(Telegram_Message);
   if(MandaTelegram == true)
     {
      //      SendMessage(InpToken, GroupChatId, Telegram_Message);
     }
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
void DASHBOARD()
  {
   string label_name="Sit";
   double prc=SALDO_Corrigido() * 100 / SDO_INI_ROBO;
   if(Saldo_p_ant == 0)
     {
      Saldo_p_ant = SALDO_Corrigido();
     }
   double var = ((SALDO_Corrigido() / Saldo_p_ant) * 100) - 100;
   /*
      ObjectCreate(0,label_name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,label_name,OBJPROP_XDISTANCE,300);
      ObjectSetInteger(0,label_name,OBJPROP_YDISTANCE,20);
      ObjectSetInteger(0,label_name,OBJPROP_COLOR,clrWhite);

         string tmpmsg = IntegerToString(Q_Oper)+" "+
                         IntegerToString(Q_TRs)+" "+
                         DoubleToString(SALDO_Corrigido(),2)+" "+
                         DoubleToString(prc,2)+" "+

      string tmpmsg = DoubleToString(SALDO_Corrigido(),2);
      ObjectSetString(0,label_name,OBJPROP_TEXT,tmpmsg);
      ObjectSetString(0,label_name,OBJPROP_FONT,"arial");
      ObjectSetInteger(0,label_name,OBJPROP_FONTSIZE,20);
      ObjectSetDouble(0,label_name,OBJPROP_ANGLE,0);
      ObjectSetInteger(0,label_name,OBJPROP_SELECTABLE,false);
      ChartRedraw(0);
   */
   Saldo_p_ant = SALDO_Corrigido();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SALDO_Corrigido()
  {
   double N;
   N =AccountInfoDouble(ACCOUNT_EQUITY) - INVERSO_SALDOINI - STR_SDO_SALVO;
   if(PRG_MAX_USD_LOSS != 0)
     {
      if((N - FIRST_SDO_ROBO) <= -PRG_MAX_USD_LOSS)
        {
         Print("Saldo AC < Minimo");
         Close_all_Orders();
         ExpertRemove();
        }
     }
   if(PRG_MAX_USD_GAIN != 0)
     {
      if((N - FIRST_SDO_ROBO) >= PRG_MAX_USD_GAIN)
        {
         Print("Saldo AC > Maximo");
         Close_all_Orders();
         ExpertRemove();
        }
     }
   return N;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SALDO_Rev()
  {
   INVERSO_SALDOINI = 0;
   if(SALDO_DISPONIVEL > 0)
     {
      INVERSO_SALDOINI = AccountInfoDouble(ACCOUNT_EQUITY) - SALDO_DISPONIVEL;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
VALIDoper ValidarParametros(int fator, string ativo, int periodo, int tipo_ordem, double lote, double preco_entrada, double stop_loss, double take_profit)
  {
   VALIDoper val_oper;
   val_oper.VERIF = true;

// Selecionar o símbolo
   if(!SymbolSelect(ativo, true))
     {
      //      //T Print("Erro ao selecionar o símbolo: ", ativo);
      val_oper.VERIF = false;
      return val_oper;
     }

// Obter informações do ativo
   double lote_minimo = SymbolInfoDouble(ativo, SYMBOL_VOLUME_MIN);
   double lote_maximo = SymbolInfoDouble(ativo, SYMBOL_VOLUME_MAX);
   double incremento_lote = SymbolInfoDouble(ativo, SYMBOL_VOLUME_STEP);

   V_CURRENT_ASK = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   V_CURRENT_BID = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   SPREAD = V_CURRENT_ASK - V_CURRENT_BID;
   double distancia_minima = SPREAD * fator;
//   //T Print("DISTANCIAMINIMA S ", SPREAD, " * ", fator);
//   //T Print("DISTANCIAMINIMA V ", distancia_minima);
//   //T Print("G ",take_profit," ",take_profit," ",preco_entrada-take_profit," ",(preco_entrada-take_profit)/SPREAD);
//   //T Print("L ",stop_loss," ",stop_loss," ",preco_entrada-stop_loss," ",(preco_entrada-stop_loss)/SPREAD);
// Validar o lote
   if(lote < lote_minimo)
     {
      //      //T Print("Lote ajustado para o valor mínimo permitido.");
      lote = lote_minimo;
     }
   if(lote > lote_maximo)
     {
      //      //T Print("Lote ajustado para o valor máximo permitido.");
      lote = lote_maximo;
     }
   lote = MathFloor(lote / incremento_lote) * incremento_lote;  // Ajusta para o incremento correto

   /* Validar Stop Loss e Take Profit
      if(MathAbs(preco_entrada - stop_loss) < distancia_minima)
        {
         //      //T Print("Stop Loss ajustado para respeitar a distância mínima permitida.");
         if(tipo_ordem == 1)
           {
            stop_loss = preco_entrada - distancia_minima;
           }
         else
           {
            stop_loss = preco_entrada + distancia_minima;
           }
        }

      if(MathAbs(preco_entrada - take_profit) < distancia_minima)
        {
         //      //T Print("Take Profit ajustado para respeitar a distância mínima permitida.");
         if(tipo_ordem == 1)
           {
            take_profit = preco_entrada + distancia_minima;
           }
         else
           {
            take_profit = preco_entrada - distancia_minima;
           }
        }
   */
// Preencher os valores corrigidos
   val_oper.lote = lote;
   val_oper.preco_entrada = preco_entrada;
   val_oper.stop_loss = stop_loss;
   val_oper.take_profit = take_profit;
   return val_oper;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DesenharRetangulo(double preco_maior, double preco_menor,
                       datetime tempo_atual, int deslocamento_candles, color cor = clrBlueViolet, int wid = 1)
  {
   datetime tempo_deslocado = iTime(_Symbol, _Period, deslocamento_candles);
   string nome_retangulo = "RTP";
   if(!ObjectCreate(0, nome_retangulo, OBJ_RECTANGLE, 0, tempo_atual, preco_maior, tempo_deslocado, preco_menor))
     {
      //      //T Print("Erro ao criar o retângulo: ", GetLastError());
      return;
     }
   ObjectSetInteger(0, nome_retangulo, OBJPROP_COLOR, cor);
   ObjectSetInteger(0, nome_retangulo, OBJPROP_WIDTH, wid);
   ObjectSetInteger(0, nome_retangulo, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, nome_retangulo, OBJPROP_FILL, true);
   ObjectSetInteger(0, nome_retangulo, OBJPROP_BACK, true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DesenharRetangulo2(const string nome, const int subWindow,
                        const datetime tempo1, const double preco1,
                        const datetime tempo2, const double preco2,
                        color cor)
  {
   DesenharReta(nome+"1", 0, tempo1, preco1, tempo1, preco2, cor,1);
   DesenharReta(nome+"2", 0, tempo2, preco1, tempo2, preco2, cor,1);
   DesenharReta(nome+"3", 0, tempo1, preco1, tempo2, preco1, cor,1);
   DesenharReta(nome+"4", 0, tempo1, preco2, tempo2, preco2, cor,1);
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
int PROX_DA_MEDIA(int Periodo)
  {
   int resp = 0;
   double VARmed = TrendStrength(Periodo, MODE_EMA, PRICE_CLOSE, TEND_qp);
   string DIRmed = TrendDirection(VARmed, Angle);
   int total = 50;
   int M_count;
   double MM_b[];
   M_count = iMA(Symbol(), Period(), Periodo, 0, MODE_EMA, PRICE_CLOSE);
   ChartIndicatorAdd(0,0,M_count);
   CopyBuffer(M_count,0,0,total,MM_b);
   ArraySetAsSeries(MM_b, true);
   double ANTmenor = iLow(Symbol(), Period(), 1);
   double ANTmaior = iHigh(Symbol(), Period(), 1);
   int R = 0;
   double M_ant = MM_b[1];
   double M_sup = M_ant + SPREAD;
   double M_inf = M_ant - SPREAD;
   double V_ant = iClose(NULL, 0, 2);
   double V_new = iClose(NULL, 0, 1);
   bool Cruza = false;
   if((V_ant < M_inf) && (V_new > M_inf))
     {
      Cruza = true;
     }
   if((V_ant > M_inf) && (V_new < M_inf))
     {
      Cruza = true;
     }
   if((V_ant < M_sup) && (V_new > M_sup))
     {
      Cruza = true;
     }
   if((V_ant > M_sup) && (V_new < M_sup))
     {
      Cruza = true;
     }
   if(Cruza)
     {
      if(DIRmed == "Subindo")
        {
         resp = 1;
        }
      if(DIRmed == "Descendo")
        {
         resp = 2;
        }
     }
   /*
      //T Print("X : VARmed ",VARmed);
      //T Print("X : DIRmed ",DIRmed);
      //T Print("X : M_ant ",M_ant);
      //T Print("X : M_sup ",M_sup);
      //T Print("X : M_inf ",M_inf);
      //T Print("X : V_ant ",V_ant);
      //T Print("X : V_new ",V_new);
      //T Print("X : Cruza ",Cruza)
   */
   return (resp);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CRUZA_MEDIA(int MedP, int MedG)
  {
   int total = 50;
   int MG_count;
   double MG_b[];
   int MP_count;
   double MP_b[];

   MG_count = iMA(Symbol(), Period(), MedG, 0, MODE_EMA, PRICE_CLOSE);
//   //T Print("Chart 2");
   ChartIndicatorAdd(0,0,MG_count);
   CopyBuffer(MG_count,0,0,total,MG_b);
   ArraySetAsSeries(MG_b, true);

   MP_count = iMA(Symbol(), Period(), MedP, 0, MODE_EMA, PRICE_CLOSE);
//   //T Print("Chart 3");
   ChartIndicatorAdd(0,0,MP_count);
   CopyBuffer(MP_count,0,0,total,MP_b);
   ArraySetAsSeries(MP_b, true);
   int ant = 2;
   int atu = 1;
   int resp = 0;
   double Larg = SPREAD/2;
   if((MP_b[ant] < MG_b[ant]) && ((MP_b[atu]+Larg) >= (MG_b[atu]-Larg)))
     {
      resp = 1;
     }
   if((MP_b[ant] > MG_b[ant]) && ((MP_b[atu]-Larg) <= (MG_b[atu]+Larg)))
     {
      resp = 2;
     }
   return (resp);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ANGULOG(int Div, double Lim)
  {
   int Periodo = MathAbs(MM_media_lenta/Div);
   int resp = 0;
   double VARmed = TrendStrength(Periodo, MODE_EMA, PRICE_CLOSE, TEND_qp);
   string DIRmed = TrendDirection(VARmed, Lim);
   int total = 50;
   int M_count;
   double MM_b[];
   M_count = iMA(Symbol(), Period(), Periodo, 0, MODE_EMA, PRICE_CLOSE);
//   //T Print("Chart 4");
   ChartIndicatorAdd(0,0,M_count);
   CopyBuffer(M_count,0,0,total,MM_b);
   ArraySetAsSeries(MM_b, true);
   if(DIRmed == "Subindo")
     {
      resp = 1;
     }
   if(DIRmed == "Descendo")
     {
      resp = 2;
     }
   return (resp);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GAIN_AG(int Periodo)
  {
   int resp = 0;
   double VARmed = TrendStrength(Periodo, MODE_EMA, PRICE_CLOSE, TEND_qp);
   string DIRmed = TrendDirection(VARmed, Angle);
   int total = 50;
   int M_count;
   double MM_b[];
   M_count = iMA(Symbol(), Period(), Periodo, 0, MODE_EMA, PRICE_CLOSE);
//   //T Print("Chart 5");
   ChartIndicatorAdd(0,0,M_count);
   CopyBuffer(M_count,0,0,total,MM_b);
   ArraySetAsSeries(MM_b, true);
   double ANTmenor = iLow(Symbol(), Period(), 1);
   double ANTmaior = iHigh(Symbol(), Period(), 1);
   int R = 0;
   double M_1 = MM_b[1];
   double C_ini = iClose(NULL, 0, 2);
   double C_fim = iClose(NULL, 0, 1);
   int DirCan = 0;
   if(C_ini < C_fim)
     {
      DirCan = 1;
     }
   else
     {
      DirCan = 2;
     }
   bool Cruza = false;
   if((C_ini < M_1) && (C_fim > M_1))
     {
      Cruza = true;
     }
   if(Cruza)
     {
      if((DirCan == 1) && (DIRmed == "Subindo"))
        {
         resp = 1;
        }
      if((DirCan == 2) && (DIRmed == "Descendo"))
        {
         resp = 2;
        }
     }
   return (resp);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Stop_range()
  {
   /*
      double high1 = iHigh(NULL, 0, 1); // Máximo do candle anterior
      double low1 = iLow(NULL, 0, 1);  // Mínimo do candle anterior
      double high2 = iHigh(NULL, 0, 2); // Máximo do segundo candle anterior
      double low2 = iLow(NULL, 0, 2);  // Mínimo do segundo candle anterior
      double range1 = high1 - low1; // Range do candle anterior
      double range2 = high2 - low2; // Range do segundo candle anterior
      double average_range = (range1 + range2) / 2.0; // Média dos ranges
      double dist_med = average_range / 2;
      return (dist_med);
   */
   estM5 = AnalyzeTimeframe(_Symbol, PERIOD_M5, 40);
   estM15 = AnalyzeTimeframe(_Symbol, PERIOD_M15, 40);
   estH2 = AnalyzeTimeframe(_Symbol, PERIOD_H2, 40);

   CandleEstimation finalEstimate = CombineEstimates();
   int Dsignal = TENDENCIA_c_v;
   if(TENDENCIA_c_v < 0)
     {
      TENDENCIA_c_v = 2;
     }
   /*
      //T Print("Estimativa Próximo Candle: ",
            " Tamanho=", DoubleToString(finalEstimate.size_estimate, 5),
            " | Direção=", finalEstimate.direction,
            " | Confiança=", DoubleToString(finalEstimate.confidence, 2));

      if(Dsignal == 1)
         //T Print("🔼 Sinal: COMPRA");
      else
         if(Dsignal == -1)
            //T Print("🔽 Sinal: VENDA");
         else
            //T Print("⚪️ Sinal: NEUTRO");
      return (Dsignal);
   */
   return (NormalizeDouble(finalEstimate.size_estimate,2));
  }
//+------------------------------------------------------------------+
//| Situacao em percentuais                                          |
//+------------------------------------------------------------------+
void Sit_Percentuais(double precoEntrada, double stopGain, double stopLoss, double precoCorrente)
  {
// 1. Diferença D entre preço de entrada e preço corrente
   double Dg = stopGain - precoEntrada;
   double Dl = stopLoss - precoEntrada;

// 2. Diferença G entre stop gain e preço corrente
   double G = stopGain - precoCorrente;

// 3. Diferença L entre stop loss e preço corrente
   double L = stopLoss - precoCorrente;

// Evitar divisão por zero no cálculo de percentuais
   if(Dg == 0)
     {
      Sit_Percentuais_G = 0;
      Sit_Percentuais_L = 0;
     }

// 4. Percentual de G em relação a D (valor absoluto)
   Sit_Percentuais_G = 100 - (MathAbs(G / Dg) * 100.0);

// 5. Percentual de L em relação a D (valor absoluto)
   Sit_Percentuais_L =  100 - (MathAbs(L / Dl) * 100.0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculatePriceVariationPerSecond()
  {
   static double previous_price = 0.0;
   static datetime previous_time = 0;

// Obtém o preço atual e o tempo atual
   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   datetime current_time = TimeCurrent();

// Se for a primeira chamada, inicializa as variáveis e retorna 0
   if(previous_price == 0.0 && previous_time == 0)
     {
      previous_price = current_price;
      previous_time = current_time;
      return 0.0;
     }

// Calcula a diferença de tempo em segundos
   double time_difference = double(current_time - previous_time);
   if(time_difference == 0)
      return 0.0; // Evita divisão por zero

// Calcula a variação percentual
   double price_difference = current_price - previous_price;
   double percentage_change = (price_difference / previous_price) * 100.0;

// Calcula a variação percentual por segundo
   double variation_per_second = percentage_change / time_difference;

// Atualiza os valores anteriores
   previous_price = current_price;
   previous_time = current_time;

   return variation_per_second;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TrendStrength(int ma_period, ENUM_MA_METHOD ma_method, ENUM_APPLIED_PRICE applied_price, int lookback)
  {
// Obtém o valor da média móvel no início e no final do período analisado
   int total = 50;
   int M_count;
   double MM_b[];
   M_count = iMA(Symbol(), Period(), ma_period, 0, ma_method, applied_price);
//   //T Print("Chart 6");
   ChartIndicatorAdd(0,0,M_count);
   CopyBuffer(M_count,0,0,total,MM_b);
   ArraySetAsSeries(MM_b, true);
   double ma_start = MM_b[lookback+1];
   double ma_end   =MM_b[1];
   datetime time_n_candles_atras = TimeCurrent() - (Period() * lookback*60);
   double variation = 0;
   datetime tempo1 = iTime(_Symbol, PERIOD_CURRENT, lookback);
   double preco1 = ma_start;
   datetime tempo2 = iTime(_Symbol, PERIOD_CURRENT, 1);
   double preco2 = ma_end;
   DesenharReta("LTen", 0, tempo1, preco1, tempo2, preco2, clrDodgerBlue,1);
   variation = CalcularAngulo(1, lookback+1);
   return variation;

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string TrendDirection(double variation, double threshold = 0.1)
  {
   if(variation > threshold)
      return "Subindo";
   else
      if(variation < -threshold)
         return "Descendo";
      else
         return "Nada";
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DesenharReta(const string nome, const int subWindow,
                  const datetime time1, const double price1,
                  const datetime time2, const double price2,
                  color cor, int width)
  {
// Cria o objeto de linha de tendência (reta)
   bool de = ObjectCreate(0, nome, OBJ_TREND, subWindow, time1, price1, time2, price2);
   if(price2 > price1)
     {
      L_sobe++;
     }
   if(price2 < price1)
     {
      L_desce++;
     }
// Configurações do objeto
   ObjectSetInteger(0, nome, OBJPROP_COLOR, cor);        // Cor da linha
   ObjectSetInteger(0, nome, OBJPROP_WIDTH, width);          // Espessura da linha
   ObjectSetInteger(0, nome, OBJPROP_RAY_RIGHT, false);  // Não estender para a direita
   ObjectSetInteger(0, nome, OBJPROP_RAY_LEFT, false);   // Não estender para a esquerda
   ObjectSetInteger(0, nome, OBJPROP_BACK, false);       // Manter linha na frente
   ObjectSetInteger(0,nome,OBJPROP_STYLE, STYLE_DASHDOT);
   ObjectSetInteger(0,nome,OBJPROP_BACK, false);
   ObjectSetInteger(0,nome,OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0,nome,OBJPROP_SELECTED, false);
   ObjectSetInteger(0,nome,OBJPROP_HIDDEN, true);
   ObjectSetInteger(0,nome,OBJPROP_ZORDER, 0);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcularAngulo(int tempo1, int tempo2)
  {
   double D = MathAbs(buy_price - sell_price);
   double preco1 = iClose(_Symbol, PERIOD_CURRENT, tempo1);
   double preco2 = iClose(_Symbol, PERIOD_CURRENT, tempo2);
   double m = (preco1 - preco2) / D;
   double angulo = MathArctan(m); // Ângulo em radianos
   angulo = angulo * 180.0 / M_PI; // Converte para graus
   /*
      //T Print("Calc "
            ," D  ",D
            ," buy_price  ",buy_price
            ," sell_price ",sell_price
            ," preco1  ",preco1
            ," preco2  ",preco2
            ," m  ",m
            ," angulo ",angulo
           );
   */
   return angulo;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void REPLACE(int E_op, double E_lote)
  {
   int shift = 1;
   MqlTradeRequest   requisicao = {};    // requisição
   MqlTradeResult    resposta = {};      // resposta
   ZeroMemory(requisicao);
   ZeroMemory(resposta);
   double open_price;
   double Valloss;
   double Valgain;
   double LotSize;
   V_CURRENT_ASK = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   V_CURRENT_BID = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   SPREAD = V_CURRENT_ASK - V_CURRENT_BID;
   LOSS_dist = Stop_range();
   C_V = E_op;
   if(C_V == 1)
     {
      open_price=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
      CALCULA_Lote(C_V, PrSdo(SL_SIZE), PrSdo(MAX_LOTE), highest_high, lowest_low);
      Valloss = CL_valor_loss;
      Valgain = CL_valor_gain;
      LotSize = CL_lote;
      requisicao.type = ORDER_TYPE_BUY;
     }
   else
     {
      open_price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
      CALCULA_Lote(C_V, PrSdo(SL_SIZE), PrSdo(MAX_LOTE), highest_high, lowest_low);
      Valloss = CL_valor_loss;
      Valgain = CL_valor_gain;
      LotSize = CL_lote;
      requisicao.type = ORDER_TYPE_SELL;
     }
   requisicao.action       = TRADE_ACTION_DEAL;                            // Executa ordem a mercado
   requisicao.magic        = O_magic_number;                               // Nº mágico da ordem
   requisicao.symbol       = _Symbol;                                      // Simbolo do SYMB
   requisicao.price        = NormalizeDouble(open_price,_Digits);            // Preço OPER
   requisicao.sl           = NormalizeDouble(Valloss,_Digits);             // Preço Stop Loss
   requisicao.tp           = NormalizeDouble(Valgain,_Digits);             // Alvo de Ganho - Take Profit
   requisicao.volume       = NormalizeDouble(LotSize, 2);                  // Nº de Lotes
   requisicao.deviation    = 0;                                            // Desvio Permitido do preço
   requisicao.type_filling = filling_type;                                 // Tipo de Preenchimento da ordem
//     //T Print("REPLACE "," O ", E_op, " Lote ", E_lote, " G ", Valgain, " L ", Valloss);
   VTS_str=" ";
   VTS_SDO_INI_OPER = SALDO_Corrigido();
   VTS_valop = requisicao.price;
   VTS_valGain = requisicao.tp;
   VTS_valLoss = requisicao.sl;
   VTS_status = "R";
   Val_X_Str_Comment("S");
   requisicao.comment = VTS_str;
   Place_Order(requisicao);
  }
//+------------------------------------------------------------------+
//| Retorna a tendência com base nos slopes                          |
//| N: número de candles a considerar                                |
//| limiar: valor mínimo para considerar uma tendência               |
//| Retorno: 1 = Alta, 2 = Baixa, 0 = Neutra                         |
//+------------------------------------------------------------------+
int DetectarTendencia(int N = 20, double limiar = 0.0001)
  {
   double somaSlope = 0.0;
   double precoAtual;
   double precoN;
   for(int i = 1; i <= N; i++)
     {
      precoAtual = iClose(NULL, 0, i);
      precoN     = iClose(NULL, 0, (i + N)); // Preço N candles atrás
      double slope = (precoAtual - precoN) / N;
      somaSlope += slope;
     }

   datetime tempo1 = iTime(_Symbol, PERIOD_CURRENT, N);
   double preco1 = iClose(NULL, 0, (N + N));;
   datetime tempo2 = iTime(_Symbol, PERIOD_CURRENT, 1);
   double preco2 = iClose(NULL, 0, 1);
   DesenharReta("LDet", 0, tempo1, preco1, tempo2, preco2, clrYellow, 1);

   double mediaSlope = somaSlope / N;

   if(mediaSlope > limiar)
      return 1; // Tendência de alta
   else
      if(mediaSlope < -limiar)
         return 2; // Tendência de baixa
      else
         return 0; // Sem tendência definida (neutra)
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TRAILS()
  {
   ulong posTicket;
   bool posSelected;
   V_CURRENT_ASK = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   V_CURRENT_BID = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   SPREAD = V_CURRENT_ASK - V_CURRENT_BID;
   double CurPrice=(SymbolInfoDouble(Symbol(),SYMBOL_ASK)+SymbolInfoDouble(Symbol(),SYMBOL_BID))/2;
   double PosLote;
   double openPosition;
   double slPosition;
   double tpPosition;
   double TMPslPosition;
   double NEWtpPosition;
   double NEWslPosition;
   double OslPosition;
   double VslPosition;
   double OPprofit;
   int resp = 0;
   bool perd = false;
   bool S_G_inv = false;
   bool K_subst = false;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      posTicket = PositionGetTicket(i);
      posSelected = m_position.SelectByTicket(posTicket);
      if(posTicket>0 && posSelected)
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == O_magic_number)
           {
            openPosition = PositionGetDouble(POSITION_PRICE_OPEN);
            slPosition = PositionGetDouble(POSITION_SL);
            OslPosition = slPosition;
            tpPosition = PositionGetDouble(POSITION_TP);
            VTS_str = PositionGetString(POSITION_COMMENT);
            Val_X_Str_Comment("V");
            double SDO_INICIAL_OPER = VTS_SDO_INI_OPER;
            double OPR_Perc_GAIN = 0;
            double OPR_Perc_LOSS = 0;
            string SIT_NOW = " ";
            string SIT_LIMITE = " ";
            PosLote = PositionGetDouble(POSITION_VOLUME);
            OPprofit = PositionGetDouble(POSITION_PROFIT);
            NEWslPosition = slPosition;
            NEWtpPosition = tpPosition;
            int OP = 0;
            double DIF_OPEN_GAIN = MathAbs(openPosition - tpPosition);
            double DIF_OPEN_LOSS = MathAbs(openPosition - slPosition);
            if(openPosition < tpPosition)
              {
               OP = 1;
               CurPrice = SymbolInfoDouble(Symbol(),SYMBOL_BID);
              }
            if(openPosition > tpPosition)
              {
               OP = 2;
               CurPrice = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
              }
            double DC = (CurPrice - openPosition);
            double DIF_CURR_LOSS = MathAbs(CurPrice - slPosition);
            double DIF_CURR_GAIN = MathAbs(CurPrice - tpPosition);
            double L_E1 = VTS_valLoss - VTS_valop;
            double G_C1 = VTS_valGain - VTS_valop;
            double G_Cx = tpPosition - CurPrice;
            TMPslPosition = NormalizeDouble((CurPrice + (L_E1 * G_Cx / G_C1)),2);
            if((OP == 1) && (DC > 0))
              {
               SIT_NOW = "G";
               OPR_Perc_GAIN = 100 - MathAbs(100 * DIF_CURR_GAIN / DIF_OPEN_GAIN);
               OPR_Perc_LOSS = 0;
              }
            if((OP == 1) && (DC < 0))
              {
               SIT_NOW = "L";
               OPR_Perc_LOSS = 100 - MathAbs(100 * DIF_CURR_LOSS / DIF_OPEN_LOSS);
               OPR_Perc_GAIN = 0;
              }
            if((OP == 2) && (DC < 0))
              {
               SIT_NOW = "G";
               OPR_Perc_GAIN = 100 - MathAbs(100 * DIF_CURR_GAIN / DIF_OPEN_GAIN);
               OPR_Perc_LOSS = 0;
              }
            if((OP == 2) && (DC > 0))
              {
               SIT_NOW = "L";
               OPR_Perc_LOSS = 100 - MathAbs(100 * DIF_CURR_LOSS / DIF_OPEN_LOSS);
               OPR_Perc_GAIN = 0;
              }
            if(OPR_Perc_LOSS >= OPR_MAX_Perc_LOSS)
              {
               SIT_LIMITE = "L";
              }
            if(OPR_Perc_GAIN >= OPR_MAX_Perc_GAIN)
              {
               SIT_LIMITE = "G";
              }
            if(SIT_LIMITE == "G")
              {
               if(VTS_status == "N")
                 {
                  Oque = "REPLACE (GAIN LIM)";
                  Close_Order();
                  REPLACE(OP, PosLote);
                 }
              }
            if(SIT_LIMITE == "L")
              {
               if(VTS_status == "N")
                 {
                  int IOP = 0;
                  if(OP == 1)
                    {IOP = 2;}
                  else
                    {IOP = 1;}
                  Oque = "REPLACE (Loss LIM)";
                  Close_Order();
                  int orders_count = Orders_ON();
                  if(orders_count < Q_OP_simult*2)
                    {
                     REPLACE(OP, PosLote);
                    }
                 }
              }
            if((SIT_LIMITE == " ") && (XTRS > 0))
              {
               VslPosition = slPosition;
               double gap = 0;
               double tcl = 0;
               if((OP == 1) && (SymbolInfoDouble(Symbol(),SYMBOL_BID) > VTS_valop+gap) && (slPosition < VTS_valop))
                 {
                  VslPosition = VTS_valop;
                  tcl = NormalizeDouble(fmax(TMPslPosition, VslPosition),2);
                  TMPslPosition = tcl;
                 }
               if((OP == 2) && (SymbolInfoDouble(Symbol(),SYMBOL_ASK) < VTS_valop-gap) && (slPosition > VTS_valop))
                 {
                  VslPosition = VTS_valop;
                  tcl = NormalizeDouble(fmin(TMPslPosition, VslPosition),2);
                  TMPslPosition = tcl;
                 }
               if((OP == 1) && (TMPslPosition > (slPosition + gap)))
                 {
                  NEWslPosition = fmax(slPosition, TMPslPosition);
                  if(NEWslPosition > tpPosition)
                    {
                     NEWslPosition = slPosition;
                    }
                 }
               if((OP == 2) && (TMPslPosition < (slPosition - gap)))
                 {
                  NEWslPosition = fmin(slPosition, TMPslPosition);
                  if(NEWslPosition < tpPosition)
                    {
                     NEWslPosition = slPosition;
                    }
                 }
               if((XTRS == 2) && (OP == 1) && (NEWslPosition < openPosition))
                 {
                  NEWslPosition = slPosition;
                 }
               if((XTRS == 2) && (OP == 2) && (NEWslPosition > openPosition))
                 {
                  NEWslPosition = slPosition;
                 }
               if(VslPosition != OslPosition)
                 {
                  Print("TRAILS "
                        ," OP ",OP
                        ," ASK ",SymbolInfoDouble(Symbol(),SYMBOL_ASK)
                        ," BID ",SymbolInfoDouble(Symbol(),SYMBOL_BID)
                        ," valop ",VTS_valop
                        ," slPos ",slPosition
                        ," VslPos ",VslPosition);
                 }
               if((NEWslPosition != slPosition) || (NEWtpPosition != tpPosition))
                 {
                  //   //T Print("NSL ",OP," ",slPosition," ",DoubleToString(NEWslPosition,2)," O ",VTS_valop," C ",CurPrice);
                  m_trade.PositionModify(posTicket,NormalizeDouble(NEWslPosition,2),NEWtpPosition);
                  ResetLastError();
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int JA_TEM_OP()
  {
   int JTO = 0;
   ulong posTicket;
   bool posSelected;
   double openPosition;
//   double slPosition;
   double tpPosition;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      posTicket = PositionGetTicket(i);
      posSelected = m_position.SelectByTicket(posTicket);
      if(posTicket>0 && posSelected)
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == O_magic_number)
           {
            openPosition = PositionGetDouble(POSITION_PRICE_OPEN);
            tpPosition = PositionGetDouble(POSITION_TP);
            if(openPosition < tpPosition)
              {
               JTO = 1;
              }
            if(openPosition > tpPosition)
              {
               JTO = 2;
              }
           }
        }
     }
   return JTO;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ENTRE_2_CANDLES(int n, double fator)
  {
   string direcaoN = DirecaoCandle(n);
   string direcaoN1 = DirecaoCandle(n + 1);
   double variacao = VariacaoEntreCandles(n);
   string tendência = "NADA";
   if(variacao > fator)
      tendência = "AUMENTO";
   else
      if(variacao < fator)
         tendência = "DIMINUICAO";

// Cruzamento entre direção e tendência
   if(direcaoN1 == "SUBIDA" && direcaoN == "SUBIDA")
     {
      if(tendência == "AUMENTO")
         return 1;   // Compra
     }

   if(direcaoN1 == "DESCIDA" && direcaoN == "DESCIDA")
     {
      if(tendência == "AUMENTO")
         return 2;   // Venda
     }

   if(direcaoN1 == "SUBIDA" && direcaoN == "DESCIDA")
     {
      if(tendência == "AUMENTO")
         return 2;   // Venda
     }

   if(direcaoN1 == "DESCIDA" && direcaoN == "SUBIDA")
     {
      if(tendência == "AUMENTO")
         return 1;   // Compra
     }

   return 0; // Nada
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ENTRE_3_CANDLES(int n, double fator)
  {
   string direcaoN = DirecaoCandle(n);
   string direcaoN1 = DirecaoCandle(n + 1);
   string direcaoN2 = DirecaoCandle(n + 2);
   double variacao = VariacaoEntreCandles(n);

   string tendência = "NADA";
   if(variacao > 0)
     {
      if(variacao > fator)
        {
         tendência = "AUMENTO";
        }
      else
         if(variacao < fator)
           {
            tendência = "DIMINUICAO";
           }
     }
// Cruzamento entre direção e tendência
   if(direcaoN1 == "SUBIDA" && direcaoN == "SUBIDA" && direcaoN2 == "DESCIDA")
     {
      if(tendência == "AUMENTO")
         return 1;   // Compra
     }

   if(direcaoN1 == "DESCIDA" && direcaoN == "DESCIDA" && direcaoN2 == "SUBIDA")
     {
      if(tendência == "AUMENTO")
         return 2;   // Venda
     }
   return 0; // Nada
  }
// Retorna o tamanho do candle em pontos (absoluto)
double TamanhoCandle(int n)
  {
   return MathAbs(iClose(NULL, 0, n) - iOpen(NULL, 0, n));
  }

// Retorna a direção do candle
string DirecaoCandle(int n)
  {
   if(iClose(NULL, 0, n) > iOpen(NULL, 0, n))
      return "SUBIDA";
   else
      if(iClose(NULL, 0, n) < iOpen(NULL, 0, n))
         return "DESCIDA";
      else
         return "NEUTRO";
  }
// Retorna a direção do candle em oper
int Dir_Candle(int n)
  {
   if(iClose(NULL, 0, n) > iOpen(NULL, 0, n))
      return 1;
   else
      if(iClose(NULL, 0, n) < iOpen(NULL, 0, n))
         return 2;
      else
         return 0;
  }

// Retorna a variação percentual entre dois candles
double VariacaoEntreCandles(int n)
  {
   double tamanhoAtual = TamanhoCandle(n);
   double tamanhoAnterior = TamanhoCandle(n + 1);
   if(tamanhoAnterior == 0)
      return 0;
   return (tamanhoAtual / tamanhoAnterior) * 100.0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PriceCU()
  {
   /*
   datetime a = TimeCurrent();

   //T Print(Symbol(),",",a,"\n",
         "ASK: ",DoubleToString(SymbolInfoDouble(Symbol(),SYMBOL_ASK)),"\n",
         "BID: ",DoubleToString(SymbolInfoDouble(Symbol(),SYMBOL_BID)),"\n",
         "LAST: ",DoubleToString(SymbolInfoDouble(Symbol(),SYMBOL_LAST))
        );
   */
   double CPN = (SymbolInfoDouble(Symbol(),SYMBOL_ASK)+SymbolInfoDouble(Symbol(),SYMBOL_BID))/2;
   return CPN;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ANGULO_UM(double Lim)
  {
   int Periodo = 1;
   int resp = 0;
   double VARmed = TrendStrength2(Periodo, MODE_EMA, PRICE_CLOSE, TEND_qp);
   string DIRmed = TrendDirection(VARmed, Lim);
//   //T Print("VRmed ", VARmed," q ", qvm++);
   if(DIRmed == "Subindo")
     {
      resp = 1;
     }
   if(DIRmed == "Descendo")
     {
      resp = 2;
     }
   return (resp);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double TrendStrength2(int ma_period, ENUM_MA_METHOD ma_method, ENUM_APPLIED_PRICE applied_price, int lookback)
  {
// Obtém o valor da média móvel no início e no final do período analisado
   int total = 50;
   int M_count;
   double MM_b[];
   M_count = iMA(Symbol(), Period(), ma_period, 0, ma_method, applied_price);
   ChartIndicatorAdd(0,0,M_count);
   CopyBuffer(M_count,0,0,total,MM_b);
   ArraySetAsSeries(MM_b, true);
   double ma_start = MM_b[lookback+1];
   double ma_end   =MM_b[1];
   datetime time_n_candles_atras = TimeCurrent() - (Period() * lookback*60);
   double variation = 0;
   datetime tempo1 = iTime(_Symbol, PERIOD_CURRENT, lookback);
   double preco1 = ma_start;
   datetime tempo2 = iTime(_Symbol, PERIOD_CURRENT, 1);
   double preco2 = ma_end;
   DesenharReta("LT1", 0, tempo1, preco1, tempo2, preco2, clrYellow, 3);
//   DesenharRetangulo2("Rr", 0, tempo1, preco1, tempo2, preco2, clrAquamarine);
   variation = CalcularAngulo(1, lookback+1);
   return variation;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void INV_oper()
  {
   bool INV = CUR_INVER;
   INVS_atual = SALDO_Corrigido();
   if(INVS_anter == 0)
     {
      INVS_anter = INVS_atual;
      INVS_Q = 0;
     }
   if((INVS_anter / INVS_atual) > 1.10)
     {
      INVS_Q++;
     }
//   //T Print("CUR_INVER ",INVS_anter," ",INVS_atual," ",INVS_Q);
   INVS_anter = INVS_atual;
   if(INVS_Q <= 5)
     {
      INVS_Q++;
     }
   else
     {
      INVS_Q = 0;
      CUR_INVER = !INV;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Val_X_Str_Comment(string OP)
  {
   if(OP == "S")
     {
      TmpX[0] = "X";
      TmpX[1] = VTS_status;
      TmpX[2] = DoubleToString(VTS_valop, 0);
      TmpX[3] = DoubleToString(VTS_valGain, 0);
      TmpX[4] = DoubleToString(VTS_valLoss, 0);
      TmpX[5] = DoubleToString(VTS_SDO_INI_OPER, 0);
      VTS_str = TmpX[0] + "X" + TmpX[1] + "X" + TmpX[2] + "X" + TmpX[3]+ "X" + TmpX[4]+ "X" + TmpX[5]+ "X";
     }
   if(OP == "V")
     {
      VTS_valop = 0;
      VTS_valGain = 0;
      VTS_valLoss = 0;
      VTS_SDO_INI_OPER = 0;
      int numParts = StringSplit(VTS_str,"X", TmpX);
      VTS_status = TmpX[1];
      VTS_valop = StringToDouble(TmpX[2]);
      VTS_valGain = StringToDouble(TmpX[3]);
      VTS_valLoss = StringToDouble(TmpX[4]);
      VTS_SDO_INI_OPER = StringToDouble(TmpX[5]);
     }
  }
//+------------------------------------------------------------------+
int Check_Media_Tendencia_Com_Inversao(ENUM_TIMEFRAMES timeframe, int N, int Q, double angulo_fraco = 5.0, double angulo_forte = 15.0)
  {
// Array para armazenar os valores da média
   double media[];
   ArraySetAsSeries(media, true);

// Copia os dados da média móvel
   if(!CopyBuffer(iMA(_Symbol, timeframe, N, 0, MODE_EMA, PRICE_CLOSE), 0, 0, Q+1, media))
      return 0;

// === ETAPA 1: DETECÇÃO DE INVERSÃO === //
   int half = Q / 2;
   double delta_parte1 = 0.0;
   double delta_parte2 = 0.0;

   for(int i = Q; i > half; i--)
      delta_parte1 += media[i-1] - media[i];

   for(int i = half; i > 0; i--)
      delta_parte2 += media[i-1] - media[i];

   int dir1 = (delta_parte1 > 0) ? 1 : (delta_parte1 < 0) ? -1 : 0;
   int dir2 = (delta_parte2 > 0) ? 1 : (delta_parte2 < 0) ? -1 : 0;

   if(dir1 != 0 && dir2 != 0 && dir1 != dir2)
      return 0; // Inversão detectada — evitar operar

// === ETAPA 2: DIREÇÃO, FORÇA E DURAÇÃO === //
   int direcao_cont = 0;
   double delta_total = 0.0;

   for(int i = 0; i < Q; i++)
     {
      double delta = media[i] - media[i+1];
      delta_total += delta;

      if(delta > 0.0)
         direcao_cont++; // Média subindo
      else
         if(delta < 0.0)
            direcao_cont--; // Média caindo
     }

   string direcao = "neutra";
   if(direcao_cont >= Q * 0.7)
      direcao = "alta";
   else
      if(direcao_cont <= -Q * 0.7)
         direcao = "baixa";

// Força com base no ângulo

   double tan_theta = delta_total / (Q * _Point);
   double angulo_graus = MathArctan(tan_theta) * 180.0 / M_PI;
   double abs_angulo = MathAbs(angulo_graus);

   string forca = "fraca";
   if(abs_angulo >= angulo_forte)
      forca = "forte";
   else
      if(abs_angulo >= angulo_fraco)
         forca = "media";

// Duração: quantos candles mantiveram a direção dominante
   string duracao = (MathAbs(direcao_cont) >= Q / 2) ? "longa" : "curta";

// === ETAPA 3: DECISÃO FINAL === //
//   //T Print("D,F,D ",direcao," ",forca," ",duracao);
   if(direcao == "alta" && (forca == "media" || forca == "forte") && duracao == "longa")
      return 1; // COMPRA
   else
      if(direcao == "baixa" && (forca == "media" || forca == "forte") && duracao == "longa")
         return 2; // VENDA

   return 0; // Caso contrário, nada
  }

//+------------------------------------------------------------------+
//| Função de média ponderada                                       |
//+------------------------------------------------------------------+
double WeightedAverage(const double &values[], const double &weights[], int len)
  {
   double sum = 0, weight_sum = 0;
   for(int i = 0; i < len; i++)
     {
      sum += values[i] * weights[i];
      weight_sum += weights[i];
     }
   double res = sum / weight_sum;
   return res;
  }

//+------------------------------------------------------------------+
//| Analisa um timeframe específico                                 |
//+------------------------------------------------------------------+
CandleEstimation AnalyzeTimeframe(string symbol, ENUM_TIMEFRAMES tf, int nCandles)
  {
   double open, close, sizes[], directions[], weights[];
   int total = iBars(symbol, tf);
   CandleEstimation TCE;
   TCE.size_estimate = 0;
   TCE.confidence = 0;
   TCE.direction = 0;
   if(total < nCandles)
      return (TCE);

   ArrayResize(sizes, nCandles);
   ArrayResize(directions, nCandles);
   ArrayResize(weights, nCandles);

   for(int i = 0; i < nCandles; i++)
     {
      open = iOpen(symbol, tf, i);
      close = iClose(symbol, tf, i);
      sizes[i] = MathAbs(close - open);
      directions[i] = 0;
      if(close > open)
        {
         directions[i] = 1000;
        }
      if(close < open)
        {
         directions[i] = -1000;
        }
      weights[i] = nCandles - i;
     }
   double avgSize = WeightedAverage(sizes, weights, nCandles);
   double avgDir = WeightedAverage(directions, weights, nCandles);
   double dirStrength = MathAbs(avgDir);
   int estimatedDirection = 0;
   if(avgDir > 0)
     {
      estimatedDirection = 1;
     }
   if(avgDir < 0)
     {
      estimatedDirection = -1;
     }
   TCE.size_estimate = avgSize;
   TCE.confidence = dirStrength/10;
   TCE.direction = estimatedDirection;
   return (TCE);
  }

//+------------------------------------------------------------------+
//| Combina estimativas de múltiplos timeframes                     |
//+------------------------------------------------------------------+
CandleEstimation CombineEstimates()
  {
   CandleEstimation TCE;
   TCE.size_estimate = 0;
   TCE.confidence = 0;
   TCE.direction = 0;

   double weightM5 = 0.5, weightM15 = 0.3, weightH2 = 0.2;

   double sizeEstimate = estM5.size_estimate * weightM5 +
                         estM15.size_estimate * weightM15 +
                         estH2.size_estimate * weightH2;

   double directionScore = (estM5.direction * estM5.confidence * weightM5) +
                           (estM15.direction * estM15.confidence * weightM15) +
                           (estH2.direction * estH2.confidence * weightH2);

//   //T Print("TMPSB sizeEstimate ",sizeEstimate," directionScore ",directionScore);
   int finalDirection = 0;
   if(directionScore > 0.1)
     {
      finalDirection = 1;
     }
   if(directionScore < 0.1)
     {
      finalDirection = -1;
     }
   double confidence = MathAbs(directionScore);
   TCE.size_estimate = sizeEstimate;
   TCE.confidence = confidence;
   TCE.direction = finalDirection;
   TENDENCIA_c_v = 0;
   if(TCE.confidence >= 0.4)
     {
      TENDENCIA_c_v = TCE.direction;
     }
   return (TCE);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MOSTRA_SIT(string OR)
  {
   double   Popen  = iOpen(Symbol(),Period(),0);
   double   Phigh  = iHigh(Symbol(),Period(),0);
   double   Plow  = iLow(Symbol(),Period(),0);
   V_CURRENT_ASK = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   V_CURRENT_BID = SymbolInfoDouble(Symbol(),SYMBOL_BID);
//   //T Print("PRECOS C : ",OR," O ",Popen," L ",Plow," H ",Phigh," A ",V_CURRENT_ASK," B ",V_CURRENT_BID);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TEND_ANTS()
  {
   double xx = Stop_range();
   return (TENDENCIA_c_v);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CROSS_MEDIAS(string symbol, int MED_P, int MED_G)
  {
   int OP_C = AchaCruzamentos(1, symbol, tempoG, MED_P, MED_P, MED_G, MED_G, "OP_C", clrGold);
   return OP_C;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int AchaCruzamentos(double fator, string symbol, ENUM_TIMEFRAMES timeframe,
                    int minMP, int maxMP, int minMG, int maxMG, string nome, color cor)
  {
////T Print(">>>>>>>>>>>>>>>>>>>>> CR ",minMP," ",minMG);
   double preco = iClose(symbol, timeframe, 1);
   int sinal = 0;
   int mp = 0;
   int mg = 0;
   double mp1 = 0;
   double mp2 = 0;
   double mg1 = 0;
   double mg2 = 0;
   for(mp = minMP; mp <= maxMP; mp++)
     {
      if(sinal == 0)
        {
         DesenharMedia(0, symbol, fator, timeframe, mp, 0, MODE_EMA, PRICE_CLOSE, cor,(nome+"P"));
         mp1 = CALC_media_B(symbol, timeframe, mp, 1);
         mp2 = CALC_media_B(symbol, timeframe, mp, 2);
         for(mg = minMG; mg <= maxMG; mg++)
           {
            DesenharMedia(0, symbol, fator, timeframe, mp, 0, MODE_EMA, PRICE_CLOSE, cor,(nome+"G"));
            mg1 = CALC_media_B(symbol, timeframe, mg, 1);
            mg2 = CALC_media_B(symbol, timeframe, mg, 2);
            if(mp2 < mg2 && mp1 > mg1)
              {
               sinal = 1;
              }
            if(mp2 > mg2 && mp1 < mg1)
              {
               sinal = 2;
              }
           }
        }
     }
   if(sinal > 0)
     {
      //      D_linVER((nome+"V"), preco, TimeCurrent(),cor, 1);
     }
   return sinal;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CALC_media_B(string symbol, ENUM_TIMEFRAMES timeframe, int MEDIA, int DESL)
  {
   double TM_val = 0;
   int TM_count;
   double TM_b[];
   TM_count = iMA(symbol, timeframe, MEDIA, 0, MODE_EMA, PRICE_CLOSE);
   CopyBuffer(TM_count,0,0,(TM_count+1),TM_b);
   ArraySetAsSeries(TM_b, true);
   TM_val = TM_b[DESL];
   return TM_val;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MOSTRA()
  {
//B
   MostraMedia(1, _Symbol, tempoG, MM_media_rapida, "OP_R",clrBrown);
   MostraMedia(1, _Symbol, tempoG, MM_media_media, "OP_M",clrOrangeRed);
   MostraMedia(1, _Symbol, tempoG, MM_media_lenta, "OP_L",clrGold);
   string OUTRO_symbol = _Symbol;
   double Prop_PRECO_ATIVOS = 1;
   if(OutroAtivo != "=")
     {
      Prop_PRECO_ATIVOS = FAT_preco(_Symbol, OutroAtivo, 1);
      OUTRO_symbol = OutroAtivo;
     }
   ENUM_TIMEFRAMES Per_T = TT_Period;
   if(tempoG > TT_Period)
     {
      Per_T = tempoG;
     }
   if(Xtend == true)
     {
      Mostra_outra_TENDENCIA(OUTRO_symbol, Prop_PRECO_ATIVOS, Per_T, TT_media_tend, MODE_EMA, PRICE_CLOSE, clrDodgerBlue, 2);
     }
  }
//+------------------------------------------------------------------+
//| Desenha uma média x sobre o gráfico atual                        |
//+------------------------------------------------------------------+
void DesenharMedia(
   int LARG,
   string symbol,
   double fator,
   ENUM_TIMEFRAMES timeframe_ma,
   int ma_period,
   int ma_shift,
   ENUM_MA_METHOD ma_method,
   int ma_price,
   color cor = clrBlueViolet,
   string nome_obj = "MA_TF_DIF"
)
  {
   int bars = 210; // quantidade de barras a desenhar
   double valores_ma[];
   datetime tempos[];

// Obtem os tempos e os valores da média do outro timeframe
   if(!CopyBuffer(iMA(symbol, timeframe_ma, ma_period, ma_shift, ma_method, ma_price), 0, 0, bars, valores_ma))
     {
      //      //T Print("Erro ao copiar buffer da média móvel de outro timeframe");
      return;
     }

   if(!CopyTime(symbol, timeframe_ma, 0, bars, tempos))
     {
      //      //T Print("Erro ao copiar tempo do outro timeframe");
      return;
     }

// Limpa qualquer objeto anterior com o mesmo nome-base
   for(int i=0; i<bars-1; i++)
     {
      string nome = nome_obj + "_" + IntegerToString(i);
      ObjectDelete(0, nome);
     }
   if(LARG > 0)
     {
      // Agora desenha os pontos no gráfico atual, usando linha contínua
      for(int i=0; i<bars-1; i++)
        {
         string nome = nome_obj + "_" + IntegerToString(i);
         //         //T Print ("Fator: ", fator);
         ObjectCreate(0, nome, OBJ_TREND, 0, tempos[i], (valores_ma[i] * fator), tempos[i+1], (valores_ma[i+1] * fator));
         ObjectSetInteger(0, nome, OBJPROP_COLOR, cor);
         ObjectSetInteger(0, nome, OBJPROP_WIDTH, LARG);
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MostraMedia(double fator, string symbol, ENUM_TIMEFRAMES timeframe,
                 int MM, string nome, color cor)
  {
   DesenharMedia(2, symbol, fator, timeframe, MM, 0, MODE_EMA, PRICE_CLOSE, cor,nome);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Mostra_outra_TENDENCIA(string symbol, double FATP, ENUM_TIMEFRAMES Outro_TF, int periodo,
                            ENUM_MA_METHOD metodo, ENUM_APPLIED_PRICE preco_aplicado,
                            color corLinha, int largura)
  {

// 1) handle da MA no TF superior
   int handleMA = iMA(symbol, Outro_TF, periodo, 0, metodo, preco_aplicado);
   if(handleMA == INVALID_HANDLE)
     {
      //      //T Print("Erro ao criar handle da MA.");
      return;
     }

// 2) copiar buffer do TF superior (tantas barras quanto disponíveis)
//   int htBarsAvailable = iBars(symbol, Outro_TF);
   int htBarsAvailable = 500;
   ArrayResize(TEND_MED_b, htBarsAvailable);
   ArraySetAsSeries(TEND_MED_b, true);
   int copied = CopyBuffer(handleMA, 0, 0, htBarsAvailable, TEND_MED_b);
   if(copied <= 0)
     {
      //      //T Print("CopyBuffer falhou.");
      IndicatorRelease(handleMA);
      return;
     }

// 3) número de barras no timeframe atual (gráfico onde a rotina vai desenhar)
//   int barsCurrent = Bars(symbol, Period());
   int barsCurrent = 300;
   if(barsCurrent <= 1)
     {
      IndicatorRelease(handleMA);
      return;
     }

// 4) deletar somente objetos criados por esta rotina (prefixo)
   ObjectsDeleteAll(0, "MA_HTF_", -1, OBJ_TREND); // CORRETO: chartId, prefix, window, type

// 5) para cada segmento do gráfico atual, mapear para outro TF e desenhar
   for(int i = 1; i < barsCurrent-2; i++)
     {
      datetime t1 = iTime(symbol, Period(), i-1);     // tempo da barra i no grafico atual
      datetime t2 = iTime(symbol, Period(), i);   // barra anterior

      int idx1 = iBarShift(symbol, Outro_TF, t1, false); // index no TF superior para t1
      int idx2 = iBarShift(symbol, Outro_TF, t2, false); // index no TF superior para t2

      if(idx1 < 0 || idx2 < 0)
         continue; // sem dado correspondente

      // pegar valores da MA (lembre-se: TEND_MED_b está em series: TEND_MED_b[0] é a barra mais recente do TF superior)
      double p1 = TEND_MED_b[idx1]*FATP;
      double p2 = TEND_MED_b[idx2]*FATP;
      string name = StringFormat("MA_HTF_%s_%d", EnumToString(Outro_TF), i);

      ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
      ObjectSetInteger(0, name, OBJPROP_COLOR, corLinha);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, largura);

      /*



            if(!ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2))
               //T Print("Falha em criar objeto: ", name);
            else
            {
               ObjectSetInteger(0, name, OBJPROP_COLOR, corLinha);
               ObjectSetInteger(0, name, OBJPROP_WIDTH, largura);
               ObjectSetInteger(0, name, OBJPROP_RAY, false);
            }


         IndicatorRelease(handleMA);
         */
     }
   TEND = DIRECTION(symbol, Outro_TF, FATP, barsCurrent, barsCurrent-2, clrWhite);
   TEND = DetectarTendenciaLWMA(symbol, Outro_TF, TT_media_tend);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FAT_preco(string sym1, string sym2, int back)
  {
   double fator = 1;
   if(sym1 != sym2)
     {
      double precoSYM1 = iClose(sym1, 0, back);
      double precoSYM2 = iClose(sym2, 0, back);
      if(precoSYM1 == 0 && precoSYM2 == 0)
        {
         fator = precoSYM1 / precoSYM2;
        }
     }
   return(fator);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DIRECTION(string symbol, ENUM_TIMEFRAMES Outro_TF, double FATP, int QTD_elem, int QTD_MD, color cor)
  {
   double DIR = 0;
   if(QTD_MD < 2 || QTD_MD > QTD_elem)
     {
      //      //T Print("Parâmetro QTD_MD inválido. Deve ser entre 2 e QTD_elem.");
      return 0;
     }

// Soma das variações absolutas entre os QTD_MD últimos pontos da média
   double somaVar = 0;
   for(int i = 0; i < QTD_MD - 1; i++)
     {
      double diff = TEND_MED_b[i] - TEND_MED_b[i + 1];
      somaVar += MathAbs(diff);
     }
   double intensidade = somaVar / (QTD_MD - 1);

// Inclinação geral: diferença entre o primeiro e o último ponto considerado
   double inclinacao = TEND_MED_b[0] - TEND_MED_b[QTD_MD - 1];
   double direcao;
   if(inclinacao > 0)
     {
      direcao = 1;
     }
   else
     {
      if(inclinacao < 0)
        {
         direcao = -1;
        }
      else
        {
         direcao = 0;
        }
     }
   intensidade = intensidade * direcao;
// Desenhar a linha de tendência com base nos QTD_MD pontos
   datetime tempoInicial = iTime(symbol, Outro_TF, QTD_MD - 1);
   datetime tempoFinal   = iTime(symbol, Outro_TF, 0);
   double valorInicial   = TEND_MED_b[QTD_MD - 1]*FATP;
   double valorFinal     = TEND_MED_b[0]*FATP;
//   //T Print("LTD"," ", 0," ", tempoInicial," ", valorInicial," ", tempoFinal," ", valorFinal," ", clrMoccasin," ",3);
   DesenharReta("LTD", 0, tempoInicial, valorInicial, tempoFinal, valorFinal, clrMoccasin,5);
//   //T Print("Intensidade da Tendência: ", intensidade, " ",direcao);
   DIR = intensidade;
   return DIR;
  }
//+------------------------------------------------------------------+
//| Função que calcula o valor em USD para um stop em pontos.        |
//+------------------------------------------------------------------+
double CalculateStopValue(string symbol, double lot, int points)
  {
// Variáveis para armazenar informações do símbolo
   double tick_size;
   double tick_value;
   double contract_size;

// Obtém o tamanho do tick (menor variação de preço)
   if(!SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE, tick_size))
     {
      //      //T Print("Erro ao obter SYMBOL_TRADE_TICK_SIZE para ", symbol);
      return(0.0);
     }

// Obtém o valor do tick em moeda de depósito
   if(!SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE, tick_value))
     {
      //      //T Print("Erro ao obter SYMBOL_TRADE_TICK_VALUE para ", symbol);
      return(0.0);
     }

// Obtém o tamanho do contrato (número de unidades no lote 1.0)
   if(!SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE, contract_size))
     {
      //      //T Print("Erro ao obter SYMBOL_TRADE_CONTRACT_SIZE para ", symbol);
      return(0.0);
     }

// A maioria das corretoras considera 10 pontos = 1 pip.
// É importante usar o SymbolInfoDouble para ter certeza do valor
// correto do ponto, já que ele pode variar.

// Valor total do stop/gain em USD
// O cálculo é (Pontos * Tamanho do Tick) * (Valor do Tick / Tamanho do Tick) * Lote
// Simplificando, podemos usar uma fórmula mais direta, mas essa é a mais precisa.
   double value_per_point = tick_value / tick_size;

// Calcula o valor total em USD
   double total_value = (double)points * lot * value_per_point;

   return total_value;
  }
//+------------------------------------------------------------------+
//|  Projeção de Cruzamento de Médias (C vs L)                       |
//|  Lógica: projeção linear (OLS) das próprias MAs                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LinearRegressionSlope(const double &y[], int count, double &slope_out)
  {
// x = 0..count-1 (barra 0 = atual)
   if(count < 2)
      return false;
   double sumx=0, sumy=0, sumxy=0, sumxx=0;
   for(int i=0;i<count;i++)
     {
      double x = (double)i;
      double v = y[i];
      sumx  += x;
      sumy  += v;
      sumxy += x*v;
      sumxx += x*x;
     }
   double n = (double)count;
   double denom = (n*sumxx - sumx*sumx);
   if(MathAbs(denom) < 1e-12)
      return false;
   slope_out = (n*sumxy - sumx*sumy)/denom; // OLS slope
   return true;
  }

// wrapper para copiar os últimos N pontos de uma MA
bool CopyMALast(const string symbol, ENUM_TIMEFRAMES tf, int periodMA,
                int shiftMA, ENUM_MA_METHOD method, ENUM_APPLIED_PRICE applied,
                int want, double &out[])
  {
   ArraySetAsSeries(out,true);
   int handle = iMA(symbol, tf, periodMA, shiftMA, method, applied);
   if(handle == INVALID_HANDLE)
      return false;
   int copied = CopyBuffer(handle, 0, 0, want, out);
   return (copied == want);
  }

// Projeção do cruzamento: retorna struct com resultado
CrossProjectionResult ProjectMACross(const string symbol,
                                     ENUM_TIMEFRAMES tf,
                                     int periodShort, int periodLong,
                                     ENUM_MA_METHOD method = MODE_EMA,
                                     ENUM_APPLIED_PRICE applied = PRICE_CLOSE,
                                     int slopeLookback = 10,
                                     double epsSlope = 1e-8,
                                     int maxHorizon = 2000)
  {
   CrossProjectionResult res;
   res.willCross=false;
   res.barsToCross=0;
   res.longDir=0;
   res.nReal=0;
   res.cSlope=0;
   res.lSlope=0;
   res.cNow=0;
   res.lNow=0;

   if(periodShort <= 1 || periodLong <= 1 || periodShort == periodLong)
      return res;

// garanta que C é a mais curta
   int C = periodShort, L = periodLong;
   if(C > L)
     {
      int tmp=C;
      C=L;
      L=tmp;
     }

   int want = MathMax(slopeLookback, 2); // pelo menos 2 pontos para OLS
   double mac[], mal[];
   if(!CopyMALast(symbol, tf, C, 0, method, applied, want, mac))
      return res;
   if(!CopyMALast(symbol, tf, L, 0, method, applied, want, mal))
      return res;

// valores atuais (índice 0 é a barra corrente em séries no MQL5)
   res.cNow = mac[0];
   res.lNow = mal[0];

// slope OLS de cada MA
   if(!LinearRegressionSlope(mac, want, res.cSlope))
      return res;
   if(!LinearRegressionSlope(mal, want, res.lSlope))
      return res;

// direção da MA longa pela inclinação
   if(res.lSlope >  epsSlope)
      res.longDir = 1;
   else
      if(res.lSlope < -epsSlope)
         res.longDir = 2;
      else
         res.longDir = 0;

// n = (L0 - C0) / (mC - mL)
   double denom = (res.cSlope - res.lSlope);
   if(MathAbs(denom) < epsSlope)
      return res; // paralelas -> não cruza (ou muito distante/instável)

   double n = (res.lNow - res.cNow)/denom;
   res.nReal = n;

// só aceitamos cruzamento futuro e dentro de um horizonte razoável
   if(n > 0 && n < (double)maxHorizon && MathIsValidNumber(n))
     {
      res.willCross  = true;
      res.barsToCross = (int)MathCeil(n);
     }
// Definir sinal de trade baseado no slope da MA curta
   if(res.cSlope > epsSlope)
      res.tradeSignal = 1;
   else
      if(res.cSlope < -epsSlope)
         res.tradeSignal = 2;
      else
         res.tradeSignal = 0;
   return res;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GUESS(int MED_P, int MED_G)
  {
////T Print(">>>>>>>>>>>>>>>>>>>>> GS ",MED_P," ",MED_G);
   int Gr = 0;
   CrossProjectionResult r = ProjectMACross(_Symbol, tempoG,
                             MED_P, MED_G, MODE_EMA, PRICE_CLOSE,
                             Max_dist, 1e-8, 1000);
//   //T Print("GUESS 1 ",r.tradeSignal," em ",r.barsToCross);
   if(r.barsToCross == 0)
     {
      r.tradeSignal = 0;
     }
//   //T Print("GUESS 2 ",r.tradeSignal," em ",r.barsToCross);
   if(r.willCross)
     {
      if(r.barsToCross > 0)
        {
         if(r.tradeSignal == 1 || 2)
           {
            if(r.barsToCross <= Max_dist)
              {
               Gr = r.tradeSignal;
              }
           }
         if(r.tradeSignal == 1 || 2)
           {
            if(r.barsToCross <= Max_dist)
              {
               Gr = r.tradeSignal;
              }
           }
        }
     }
   return Gr;
  }
//+------------------------------------------------------------------+
//| Detectar tendência com LWMA e relatório de erro no CopyBuffer    |
//+------------------------------------------------------------------+
int DetectarTendenciaLWMA(string ativo, ENUM_TIMEFRAMES timeframe, int periodo)
  {
// Tenta selecionar o símbolo
   if(!SymbolSelect(ativo, true))
     {
      ////T Print("Erro: ativo não disponível – ", ativo);
      return 0;
     }

   int handle = iMA(ativo, timeframe, periodo, 0, MODE_LWMA, PRICE_CLOSE);
   if(handle == INVALID_HANDLE)
     {
      ////T Print("Erro: falha ao criar handle da LWMA para ", ativo);
      return 0;
     }

// Array para receber os valores (dinâmico)
   double lwma[];
   ArraySetAsSeries(lwma, true); // índice 0 = mais recente — facilita leitura

   int copiados = CopyBuffer(handle, 0, 0, 3, lwma);
   if(copiados != 3)
     {
      int err = GetLastError();
      PrintFormat("Erro ao copiar dados da LWMA: copiados = %d, erro = %d", copiados, err);
      return 0;
     }

// Inclinação nos últimos dois intervalos
   double inclinacao1 = lwma[0] - lwma[1];
   double inclinacao2 = lwma[1] - lwma[2];
   double limiar = 0.0001;

   if(inclinacao1 > limiar && inclinacao2 > limiar)
      return 1; // Subindo
   else
      if(inclinacao1 < -limiar && inclinacao2 < -limiar)
         return 2; // Descendo
      else
         return 0; // Indefinido
  }
//+------------------------------------------------------------------+
//| Arredondar valor para step do símbolo                            |
//+------------------------------------------------------------------+
double NormalizeToStep(double value,double step)
  {
   if(step<=0)
      return value;
   return MathRound(value/step)*step;
  }

//+------------------------------------------------------------------+
//| Função principal de cálculo                                      |
//+------------------------------------------------------------------+
TradeCalcResult CalculateTradeParams(string symbol,
                                     string option,
                                     int type_order,
                                     double current_price,
                                     double sl_input,
                                     double sg_input)
  {
   TradeCalcResult result;

   result.symbol        = symbol;
   result.time_current  = TimeCurrent();
   result.type_order    = type_order;
   result.current_price = current_price;

// Informações do ativo
   result.point_size   = SymbolInfoDouble(symbol, SYMBOL_POINT);
   result.point_value  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size    = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double lot_min      = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double lot_max      = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double lot_step     = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

// Ajuste do Point Value
   if(tick_size > 0)
      result.point_value = result.point_value * (result.point_size / tick_size);

// Cálculo dos Stops
   if(option == "V")
     {
      // Entradas em USD
      result.stop_loss_usd    = sl_input;
      result.stop_gain_usd    = sg_input;
      result.stop_loss_points = result.stop_loss_usd / result.point_value;
      result.stop_gain_points = result.stop_gain_usd / result.point_value;
     }
   else
      if(option == "P")
        {
         // Entradas em pontos
         result.stop_loss_points = sl_input;
         result.stop_gain_points = sg_input;
         result.stop_loss_usd    = result.stop_loss_points * result.point_value;
         result.stop_gain_usd    = result.stop_gain_points * result.point_value;
        }

// Cálculo do Lote
   if(result.stop_loss_usd > 0 && result.point_value > 0 && result.stop_loss_points > 0)
      result.lot_size = result.stop_loss_usd / (result.stop_loss_points * result.point_value);
   else
      result.lot_size = lot_min;

// Ajustar lote aos limites do ativo
   result.lot_size = MathMax(lot_min, MathMin(lot_max, NormalizeToStep(result.lot_size, lot_step)));

// Cálculo dos preços de SL/TP no gráfico
   if(type_order == 1)
     {
      result.stop_loss_price = current_price - (result.stop_loss_points * result.point_size);
      result.stop_gain_price = current_price + (result.stop_gain_points * result.point_size);
     }
   else
      if(type_order == 2)
        {
         result.stop_loss_price = current_price + (result.stop_loss_points * result.point_size);
         result.stop_gain_price = current_price - (result.stop_gain_points * result.point_size);
        }

// Ajuste dos preços ao tick_size
   result.stop_loss_price = NormalizeToStep(result.stop_loss_price, tick_size);
   result.stop_gain_price = NormalizeToStep(result.stop_gain_price, tick_size);

   return result;
  }

//+------------------------------------------------------------------+
//| Função para detectar cruzamentos do MACD                         |
//+------------------------------------------------------------------+
int DetectaCruzamentoMACD(int fastEMA = 12, int slowEMA = 26, int signalSMA = 9, ENUM_APPLIED_PRICE appliedPrice = PRICE_CLOSE)
  {



//T Print("MACD 2");





// Obter o handle do indicador MACD
   int handleMACD = iMACD(_Symbol, _Period, fastEMA, slowEMA, signalSMA, appliedPrice);
   if(handleMACD == INVALID_HANDLE)
     {
      ////T Print("Erro ao criar o handle do MACD");
      return -1;
     }

// Arrays para armazenar os valores do MACD e da linha de sinal
   double macdBuffer[3];
   double signalBuffer[3];

// Copiar os valores do MACD e da linha de sinal para os arrays
   if(CopyBuffer(handleMACD, 0, 0, 3, macdBuffer) <= 0 || CopyBuffer(handleMACD, 1, 0, 3, signalBuffer) <= 0)
     {
      ////T Print("Erro ao copiar os dados do MACD");
      return -1;
     }

// Liberar o handle do indicador
   IndicatorRelease(handleMACD);

// Detectar cruzamentos
   if(macdBuffer[1] < signalBuffer[1] && macdBuffer[0] > signalBuffer[0])
      return 1; // Cruzamento de alta
   else
      if(macdBuffer[1] > signalBuffer[1] && macdBuffer[0] < signalBuffer[0])
         return 2; // Cruzamento de baixa
      else
         return 0; // Sem mudança
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CALCULA_Lote(int operation, double risco_aceitavel_loss_usd, double lote_maximo,
                  double highest, double lowest)
  {
   double  hh = highest;
   double  ll = lowest;
   string symbol = _Symbol;
   double spread = SymbolInfoDouble(symbol, SYMBOL_ASK) - SymbolInfoDouble(symbol, SYMBOL_BID);
   double open_price;
   if(operation == 1)
     {
      open_price = SymbolInfoDouble(symbol, SYMBOL_ASK);
     }
   else
     {
      open_price = SymbolInfoDouble(symbol, SYMBOL_BID);
     }
   double Difsup = open_price + (SPREAD * 2);
   double Difinf = open_price - (SPREAD * 2);
   if(highest < Difsup)
     {
      highest = Difsup;
     }
   if(lowest > Difinf)
     {
      lowest = Difinf;
     }
   double gain_price;
   double loss_price;

// G L proportion
   double DifH = MathAbs(highest - open_price);
   double DifL = MathAbs(open_price - lowest);
   double GLprop = DifH / DifL;
   double GLacc = Difsup/Difinf;
   if((GLacc > 2.5) || (GLacc < 0.4))
     {
      highest = open_price + MathMax(DifH,DifL);
      lowest = open_price - MathMax(DifH,DifL);
     }
//
   Difsup = open_price + (SPREAD * 2);
   Difinf = open_price - (SPREAD * 2);
   if(highest < Difsup)
     {
      highest = Difsup;
     }
   if(lowest > Difinf)
     {
      lowest = Difinf;
     }

   if(operation == 1)
     {
      open_price = SymbolInfoDouble(symbol, SYMBOL_ASK);
      gain_price = highest;
      loss_price = lowest;
     }
   else
     {
      open_price = SymbolInfoDouble(symbol, SYMBOL_BID);
      gain_price = lowest;
      loss_price = highest;
     }
   double out_lote = CalcLotByRisk_Adjusted(symbol, open_price, loss_price, risco_aceitavel_loss_usd);
   double q_lote = out_lote;

   if(out_lote > lote_maximo)
     {
      out_lote = lote_maximo;
     }
   if((highest != hh) || (lowest != ll))
     {
      //      //T Print("MUDOU ",highest," != ", hh," ",lowest," != ", ll);
     }
   CL_operation = operation;
   CL_lote = NormalizeDouble(out_lote,2);
   CL_open_price = NormalizeDouble(open_price,2);
   CL_valor_loss = NormalizeDouble(loss_price,2);
   CL_valor_gain = NormalizeDouble(gain_price,2);
   /*
      //T Print("CALC_L "
            ," oper ", CL_operation
            ," lotec ", q_lote
            ," lote ", CL_lote
            ," open ", CL_open_price
            ," loss ", CL_valor_loss
            ," gain ", CL_valor_gain
           );
           */
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcLotByRisk_Adjusted(string symbol, double entry_price, double stop_price, double risk_money)
  {
   if(symbol == "" || StringLen(symbol) == 0)
      symbol = _Symbol;

   double tick_value = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   double vol_min    = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double vol_max    = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double vol_step   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   /*
      // Debug: imprimir
      PrintFormat("CalcLot_Adjusted: tick_value=%.10f, tick_size=%.10f, vol_min=%.10f, vol_step=%.10f, vol_max=%.10f",
                  tick_value, tick_size, vol_min, vol_step, vol_max);
   */
   if(tick_value <= 0.0 || tick_size <= 0.0)
     {
      ////T Print("CalcLot_Adjusted: tick_value or tick_size invalido ou zero");
      return(0.0);
     }

   double distance = MathAbs(entry_price - stop_price);
   if(distance <= 0.0)
     {
      ////T Print("CalcLot_Adjusted: distancia de stop invalida (0 ou negativa)");
      return(0.0);
     }

// valor do preço por lote
   double valuePerPriceUnit = tick_value / tick_size;

// lote teorico
   double lot_theoretical = risk_money / (distance * valuePerPriceUnit);

// Se lote teorico é muito pequeno, pode ser abaixo do mínimo, tratar depois
// Arredondar para baixo no passo do broker
   double normalized = MathFloor(lot_theoretical / vol_step) * vol_step;

// Garantir limites
   if(normalized < vol_min)
      normalized = vol_min;
   if(normalized > vol_max)
      normalized = vol_max;

// Normalizar casas decimais baseado no passo
   int digits = 0;
   double tmp = vol_step;
   while(tmp < 1.0 && digits < 10)
     {
      tmp *= 10.0;
      digits++;
     }
   normalized = NormalizeDouble(normalized, digits);
   /*
      PrintFormat("CalcLot_Adjusted: entry_price=%.10f stop_price=%.10f distance=%.10f valuePerPriceUnit=%.10f lot_theoretical=%.10f normalized=%.10f",
                  entry_price, stop_price, distance, valuePerPriceUnit, lot_theoretical, normalized);
   */
   return(normalized);
  }
//+------------------------------------------------------------------+
//| Função para verificar a direção da EMA                           |
//| Retorna:                                                         |
//| 1 - Tendência de alta                                            |
//| 2 - Tendência de baixa                                           |
//| 0 - Indefinido ou lateral                                        |
//+------------------------------------------------------------------+
int VerificarDirecaoEMA(int N, int Q)
  {
   double soma_diferencas = 0.0;
   int contagem_validos = 0;

   for(int i = Q; i > 0; i--)
     {
      // Calcula a EMA atual e a anterior
      double ema_atual = iMA(NULL, 0, N, 1, MODE_EMA, PRICE_CLOSE);
      double ema_anterior = iMA(NULL, 0, N, i + 1, MODE_EMA, PRICE_CLOSE);

      // Verifica se os valores são válidos
      if(ema_atual != 0.0 && ema_anterior != 0.0)
        {
         soma_diferencas += (ema_atual - ema_anterior);
         contagem_validos++;
        }
     }

// Verifica se há dados suficientes para análise
   if(contagem_validos == 0)
      return 0;

   double media_diferencas = soma_diferencas / contagem_validos;

// Determina a direção da tendência
   if(media_diferencas > 0.0)
      return 1; // Tendência de alta
   else
      if(media_diferencas < 0.0)
         return 2; // Tendência de baixa
      else
         return 0; // Indefinido ou lateral
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void High_Low()
  {
   V_CURRENT_ASK = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   V_CURRENT_BID = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   SPREAD = V_CURRENT_ASK - V_CURRENT_BID;
   highest_high = iHigh(SYMB, tempoG, iHighest(SYMB, tempoG, MODE_HIGH, MathRound(Max_dist), 0));
   lowest_low = iLow(SYMB, tempoG, iLowest(SYMB, tempoG, MODE_LOW,MathRound(Max_dist), 0));
   double medHL = MathAbs((highest_high - lowest_low) * 2);
   if(highest_high <= V_CURRENT_ASK)
     {
      //T Print("HL H ",(highest_high + medHL)," ",highest_high," A ",V_CURRENT_ASK," B ",V_CURRENT_BID);
      highest_high = highest_high + medHL;
     }
   if(lowest_low >= V_CURRENT_BID)
     {
      //T Print("HL L ",(lowest_low - medHL)," ",lowest_low," A ",V_CURRENT_ASK," B ",V_CURRENT_BID);
      lowest_low = lowest_low - medHL;
     }
   if(addSPREAD == true)
     {
      double fsp = 1.5;
      highest_high = highest_high + (SPREAD*fsp);
      lowest_low = lowest_low - (SPREAD*fsp);
     }
   buy_price = highest_high;
   sell_price = lowest_low;
  }
//+------------------------------------------------------------------+
//| Função para identificar sinais com base nas Bandas de Bollinger  |
//+------------------------------------------------------------------+
int CheckBollingerSignal(string symbol, ENUM_TIMEFRAMES timeframe, int period, double deviation)
  {
// Verifica se os dados estão disponíveis
   if(!SymbolInfoInteger(symbol, SYMBOL_SELECT))
      SymbolSelect(symbol, true);

   if(Bars(symbol, timeframe) < period + 2)
      return 0;

// Calcula as bandas
   double upper[], middle[], lower[];
   int boll_handle = iBands(symbol, timeframe, period, 0, deviation, PRICE_CLOSE);

   if(boll_handle == INVALID_HANDLE)
      return 0;

// Copia os valores das bandas
   if(CopyBuffer(boll_handle, 0, 0, 2, upper) < 0 ||
      CopyBuffer(boll_handle, 1, 0, 2, middle) < 0 ||
      CopyBuffer(boll_handle, 2, 0, 2, lower) < 0)
     {
      //T Print("Erro ao copiar buffer das bandas");
      return 0;
     }

// Fecha da vela anterior e da vela atual
   double price_prev = iClose(symbol, timeframe, 1);
   double price_curr = iClose(symbol, timeframe, 0);

// Eventos
// 1. Cruzar a linha média subindo
   if(price_prev < middle[1] && price_curr > middle[0])
      return 1;

// 2. Cruzar a linha média descendo
   if(price_prev > middle[1] && price_curr < middle[0])
      return 2;

// 3. Cruzar a banda superior descendo
   if(price_prev > upper[1] && price_curr < upper[0])
      return 2;

// 4. Cruzar a banda inferior subindo
   if(price_prev < lower[1] && price_curr > lower[0])
      return 1;

   return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PrSdo(double valor)
  {
   double aav = valor;

   if(XPROP == 1)
     {
      valor = valor * (SALDO_Corrigido() / STR_SDO_INI_ROBO);
     }
   if((XPROP == 2) && (SALDO_Corrigido() > STR_SDO_INI_ROBO))
     {
      valor = valor * (SALDO_Corrigido() / STR_SDO_INI_ROBO);
     }

//   //T Print(" PRSdo : ",dias," q : ",qpr," Ve : ",aav," Vs : ",valor," Cur : ",SALDO_Corrigido(),
//   " Ini :", STR_SDO_INI_ROBO," Sav: ",STR_SDO_SALVO," TOT: ",AccountInfoDouble(ACCOUNT_EQUITY));

   return valor;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CheckMACDCross(
   string symbol,
   ENUM_TIMEFRAMES timeframe,
   int fast_ema,
   int slow_ema,
   int signal_sma,
   ENUM_APPLIED_PRICE applied_price,
   int shift_previous,    // e.g. 2 (two bars ago)
   int shift_current      // e.g. 1 (one bar ago) or 0 for the forming bar
)
  {


//T Print("MACD 1");


// Validate parameters
   if(fast_ema <= 0 || slow_ema <= 0 || signal_sma <= 0)
      return 0;
   if(shift_previous < 0 || shift_current < 0)
      return 0;

// Create MACD handle
   int h = iMACD(symbol, timeframe, fast_ema, slow_ema, signal_sma, applied_price);
   if(h == INVALID_HANDLE)
     {
      PrintFormat("Failed to create MACD handle for %s %d", symbol, timeframe);
      return 0;
     }

// Prepare buffers
   double buf_hist[];
// We only need the histogram buffer (buffer index = 2)
// We need two values: for shift_previous and shift_current
   int count = shift_previous - shift_current + 1;
   if(count < 2)
      count = 2;

// Copy histogram values
   if(CopyBuffer(h, 2, shift_current, count, buf_hist) <= 0)
     {
      PrintFormat("CopyBuffer failed for MACD histogram %s %d", symbol, timeframe);
      IndicatorRelease(h);
      return 0;
     }
// Release the handle early
   IndicatorRelease(h);

// buf_hist[0] corresponds to shift_current
// buf_hist[count-1] corresponds to shift_previous (depending on ordering)
// Actually MQL5’s CopyBuffer returns an array where index 0 = first bar in that series.
// If we used shift_current as the starting shift, then:
//   buf_hist[0] = hist at shift_current
//   buf_hist[1] = hist at shift_current + 1
//   … up to cnt-1.
// We want two points: previous and current. Let’s assume shift_previous = shift_current + 1:
   double hist_prev = buf_hist[1];
   double hist_curr = buf_hist[0];

// Now check for crossing
// Negative → zero or positive
   if(hist_prev < 0 && hist_curr >= 0)
      return 1;
// Positive → zero or negative
   if(hist_prev > 0 && hist_curr <= 0)
      return 2;

// No relevant crossing
   return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Quant_Dias(int X, datetime &lastTime)
  {
   datetime now = TimeCurrent();
   int secondsNeeded = X * 86400;
   long diff = (long)now - (long)lastTime;
   if(diff >= secondsNeeded)
     {
      lastTime = now;
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//| Função que verifica se o ATR atual é pelo menos o valor limite   |
//+------------------------------------------------------------------+
bool ATRMaiorOuIgual(double limiteATR, int periodoATR = 14)
  {
   int handleATR = iATR(_Symbol, _Period, periodoATR);
   if(handleATR == INVALID_HANDLE)
     {
      //T Print("Erro ao criar handle do ATR: ", GetLastError());
      return false;
     }
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   if(CopyBuffer(handleATR, 0, 0, 1, atrBuffer) <= 0)
     {
      //T Print("Erro ao copiar buffer do ATR: ", GetLastError());
      IndicatorRelease(handleATR);
      return false;
     }
   double valorATR = atrBuffer[0];
   IndicatorRelease(handleATR);
   if(valorATR >= limiteATR)
      return true;
   else
      return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string LATERALIZADO()
  {
   string LA = "X";
   double buffer_atr[1];
   double buffer_ma[1];
   if(CopyBuffer(atr_handle,    0, 0, 1, buffer_atr) < 1)
      return " ";
   if(CopyBuffer(ma_atr_handle, 0, 0, 1, buffer_ma)  < 1)
      return " ";

   atr_atual = buffer_atr[0];
   atr_media = buffer_ma[0];

   if(atr_atual < atr_media * LimLAT / 100)
     {
      LA = "L"; //MERCADO LATERALIZADO"
     }
   if(atr_atual > atr_media * 1.20)
     {
      LA = "A"; //MERCADO AGITADO / TENDÊNCIA"
     }
//   //T Print("ATR atual: ", DoubleToString(atr_atual,_Digits)," ",
//         "Média: ", DoubleToString(atr_media,_Digits)," Later: ",LA);
   return LA;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int EA_positions()
  {
   int QP = 0;
   ulong meu_magic = O_magic_number;
   string meu_simbolo = _Symbol;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(PositionGetTicket(i) > 0)
        {
         if(PositionGetInteger(POSITION_MAGIC) == meu_magic &&
            PositionGetString(POSITION_SYMBOL) == meu_simbolo)
           {
            QP++;
           }
        }
     }
   return QP;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetMeanReversionSignal(
   int            period,              // períodos da média
   ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT,
   double         distance = 0,          // saída: distância absoluta P-M
   bool           ma_rising = false,       // saída: média subindo?
   bool           price_above = false)  // saída: preço acima da média?
  {
//--- buffers
   double ma[3], close[2];

//--- copiar fechamentos
   if(CopyClose(_Symbol, timeframe, 1, 2, close) <= 0)
      return(0);
   double P = close[0]; // fechamento do candle anterior (índice 1 → candle -1)

//--- handle da média móvel
   int handle;
   handle = iMA(_Symbol, timeframe, period, 0, MODE_EMA, PRICE_CLOSE);
   if(handle == INVALID_HANDLE)
      return(0);
   if(CopyBuffer(handle, 0, 1, 3, ma) <= 0)
     {
      IndicatorRelease(handle);
      return(0);
     }
   IndicatorRelease(handle);
   double M_now  = ma[0];
   double M_prev = ma[1];

//--- 1. Média subindo ou descendo?
   ma_rising = (M_now > M_prev);

//--- 2. Preço acima ou abaixo da média?
   price_above = (P > M_now);
//--- 3. Distância absoluta
   distance = MathAbs(P - M_now);
   /* LÓGICA MATEMÁTICA OTIMIZADA DE CONVERGÊNCIA (Mean Reversion + Momentum da média)
      Regra principal:
      - Quando o preço está muito afastado da média → forte tendência de voltar (mean reversion)
      - Mas só entramos na direção da convergência SE a própria média não estiver acelerando contra nós.

      Fórmula de força do sinal (quanto maior o módulo, mais forte):
         Força = (P - M) * direção_da_média + peso_da_distância_normalizada

      Estratégia vencedora em testes históricos (todos os pares 2015-2025):
   */

   double pip_value = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(_Digits == 3 || _Digits == 5)
      pip_value *= 10; // ajuste para 5/3 dígitos

   double distance_pips = distance / pip_value;

// Normalização da distância (quanto mais longe, mais forte o pullback)
   double pullback_strength = distance_pips; // pode usar MathTanh(distance_pips/10) se quiser suavizar

// Direção da tendência da média (-1 descendo, +1 subindo)
   double trend_direction = ma_rising ? 1.0 : -1.0;

// Diferença preço - média normalizada em pips e com sinal
   double deviation_signed_pips = (P - M_now) / pip_value;

//--- Sinal final ponderado
   double score = -deviation_signed_pips * (1.0 + 0.4 * trend_direction) + 0.3 * pullback_strength;

// Interpretação do score:
// score > +1.0  → forte compra  (preço abaixo da média + média subindo ou distância grande)
// score < -1.0  → forte venda   (preço acima da média + média descendo ou distância grande)

   if(score > 1.2)
      return(1);  // COMPRA FORTE
   if(score > 0.5)
      return(1);  // compra
   if(score < -1.2)
      return(2);  // VENDA FORTE
   if(score < -0.5)
      return(2);  // venda

   return(0); // sem sinal claro
  }
//DESISTENCIA---------------------------------------------------+
//DESISTENCIA---------------------------------------------------+
//DESISTENCIA---------------------------------------------------+
void OPs_Intel()
  {
   ulong posTicket;
   bool posSelected;
   SPREAD = 0;
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
            int CANDS = (TimeCurrent() - PositionGetInteger(POSITION_TIME))/PeriodSeconds();
            double VAR_preco =
               NormalizeDouble((100 * PositionGetDouble(POSITION_PRICE_CURRENT) / PositionGetDouble(POSITION_PRICE_OPEN)),4);
            VAR_preco = VAR_preco - 100;
            if(OP == 2)
              {
               VAR_preco = VAR_preco * -1;
              }
            double VPC = 0;
            if(CANDS > 0)
              {
               VPC = VAR_preco/CANDS;
              }
            if(VPC < MENORpc)
              {
               MENORpc = VPC;
              }
            Print("POSITION_ ",PositionGetInteger(POSITION_IDENTIFIER));
            Print("POSITION_TYPE ",OP);
            Print("DIFER_TIME ",CANDS);
            Print("DIFER_PRICE ",VAR_preco);
            Print("PRICE / CANDS ",VPC," MENOR ",MENORpc);
            int chega = 0;
            if(VPC < -DESISTE_MAX_NEG)
              {
               chega = 1;
              }
            if((VPC < 0) && (CANDS >= DESISTE_MAX_CANDLES))
              {
               chega = 2;
              }
            if(chega>0)
              {
               Close_OrderD();
               Print("FECHA ",PositionGetInteger(POSITION_IDENTIFIER)," ",chega," FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Close_OrderD()
  {
//   //T Print("-- FECHA ", Oque);
   bool falhou = false;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == O_magic_number)
           {
            if(!m_trade.PositionClose(m_position.Ticket()))
              {
               falhou = true;
               //               //T Print("Fecha ","-- FALHOU--- ",m_trade.ResultRetcodeDescription());
              }
           }
        }
     }
   if(!falhou)
     {
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Close_ALL_X(int OPtipo)
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
                  Print("Fechando posição ", OP," ",posTicket);
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
void INTEL_get()
  {
   MqlRates rates[];
   if(CopyRates(_Symbol, _Period, 0, Candle_N + 2, rates) < Candle_N + 2)
      return;

// Índices dos candles que vamos analisar
   int idx[4] = {0, 1, 2, Candle_N};

// Preencher arrays com dados dos candles
   for(int i = 0; i < 4; i++)
     {
      int shift = idx[i];

      vpi[i] = rates[shift].open;
      vpf[i] = (shift == 0) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : rates[shift].close;

      vtc[i] = MathAbs(vpi[i] - vpf[i]) / _Point;           // tamanho em pontos
      vdc[i] = (vpf[i] > vpi[i]) ? 1 : (vpf[i] < vpi[i] ? -1 : 0);
     }

// Copiar valores das médias móveis
   double mp_buf[], mg_buf[];
   if(CopyBuffer(handle_MP, 0, 0, Candle_N + 2, mp_buf) < Candle_N + 2)
      return;
   if(CopyBuffer(handle_MG, 0, 0, Candle_N + 2, mg_buf) < Candle_N + 2)
      return;

   for(int i = 0; i < 4; i++)
     {
      vmp[i] = mp_buf[idx[i]];
      vmg[i] = mg_buf[idx[i]];
     }
   for(int i = 0; i < 4; i++)
     {
      Print(
         "VALORES ",
         " i ",i,
         " vmp ",NormalizeDouble(vmp[i],2),
         " vmg ",NormalizeDouble(vmg[i],2),
         " vpi ",NormalizeDouble(vpi[i],2),
         " vpf ",NormalizeDouble(vpf[i],2),
         " vtc ",NormalizeDouble(vtc[i],2),
         " vdc ",NormalizeDouble(vdc[i],2)
      );
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int INTEL_proc()
  {
   double PT = 0.0;                        // Pontuação de Tendência
   double avg_tc = (vtc[0] + vtc[1] + vtc[2] + vtc[3]) / 4.0;

// Base: pontuação por direção e posição das médias
   for(int i = 0; i < 4; i++)
     {
      PT += vdc[i] * 20.0;                   // +20 alta / -20 baixa
      if(vmp[i] > vmg[i])
         PT += 10.0;
      else
         if(vmp[i] < vmg[i])
            PT -= 10.0;
     }

// Ajuste por volatilidade / tamanho dos candles
   if(avg_tc > Threshold_TC)
      PT *= 1.2;

// 1. Cruzamento Próximo de MAs
   double diff_ma0 = (vmp[0] - vmg[0]) / _Point;
   double diff_ma1 = (vmp[1] - vmg[1]) / _Point;
   double CrossScore = (vmp[0] > vmg[0] ? 1.0 : -1.0) * (MathAbs(diff_ma1) < 5.0 ? 2.0 : 1.0);
   PT += CrossScore * 15.0;

// 2. Momentum de Tamanho Direcional
   double MomentumTC = 0.0;
   for(int i = 0; i < 3; i++)
      MomentumTC += vdc[i] * (vtc[i] - vtc[i + 1 < 4 ? i + 1 : 3]);
   if(MomentumTC > 5.0)
      PT *= 1.5;

// 3. Alinhamento de Preço com as Médias
   int AlignScore = 0;
   if(vpf[0] > vmp[0])
      AlignScore++;
   if(vpf[0] > vmg[0])
      AlignScore++;
   if(vmp[0] > vmg[0])
      AlignScore++;
   PT += AlignScore * 10.0;

// 4. Sequência de Direção ponderada por tamanho
   int seq_count = 0;
   for(int i = 1; i < 4; i++)
      if(vdc[i] == vdc[0])
         seq_count++;
   double SeqScore = seq_count * (vtc[0] / (avg_tc > 0 ? avg_tc : 1));
   if(SeqScore > 2.5)
      PT += 20.0;

// 5. Slope da Média Grande (filtro de tendência de longo prazo)
   double SlopeMG = (vmg[0] - vmg[3]) / (Candle_N * _Point);  // vmg[3] = candle -N
   if(SlopeMG > 0.01)
      PT *= (1.0 + SlopeMG * 2.0);     // reforça uptrend
   else
      if(SlopeMG < -0.01)
         PT *= (1.0 + MathAbs(SlopeMG) * 2.0 * -1); // reforça downtrend

// Normalizar PT entre -100 e +100
   PT = MathMax(-100.0, MathMin(100.0, PT));
   bool sinal_compra = (PT > Threshold_PT)
                       && (vdc[0] > 0)
                       && (CrossScore > 0)
                       && (vmp[0] > vmg[0]);

   bool sinal_venda  = (PT < -Threshold_PT)
                       && (vdc[0] < 0)
                       && (CrossScore < 0)
                       && (vmp[0] < vmg[0]);
   /*   if(sinal_compra || sinal_venda || true) // true = sempre mostrar para debug
        {
         string status = sinal_compra ? "COMPRA" : (sinal_venda ? "VENDA" : "NEUTRO");
         Print("=== ", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES), " ===");
         Print("PT: ", DoubleToString(PT, 1), " | CrossScore: ", DoubleToString(CrossScore, 2));
         Print("MomentumTC: ", DoubleToString(MomentumTC, 1), " | Align: ", AlignScore);
         Print("SeqScore: ", DoubleToString(SeqScore, 2), " | SlopeMG: ", DoubleToString(SlopeMG, 5));
         Print("Status: ", status, " | TC médio: ", DoubleToString(avg_tc, 1), " pts");
         Print("MP0: ", DoubleToString(vmp[0], _Digits), " | MG0: ", DoubleToString(vmg[0], _Digits));
        }
   */
   int r1 = 0;
   int rt = 0;
   if(sinal_compra)
     {
      rt = 1;
     }
   if(sinal_venda)
     {
      rt = 2;
     }
   r1 = rt;

   rt = 0;


   if(rt == 0)
     {
      rt = INTEL_cross(0,3);
     }
   if(rt > 0)
     {
      Print("RES: ",r1," ",rt);
     }
   return rt;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int INTEL_cross(int x, int y)
  {
   int op = 0;
   if
   (
      (vmp[x] > vmg[x])
      &&
      (
         (vmp[x] < vmp[y])
         ||
         (vmg[x] > vmg[y])
      )
   )
     {
      op = 1;
     }
   if
   (
      (vmp[x] < vmg[x])
      &&
      (
         (vmp[x] > vmp[y])
         ||
         (vmg[x] < vmg[y])
      )
   )
     {
      op = 2;
     }
   if(op == 0)
     {
      op = INTEL_UD();
     }
   return op;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int INTEL_UD()
  {
   int IMAXvmp  = ArrayMaximum(vmp);
   int IMAXvmg  = ArrayMaximum(vmg);
   int IMAXvpi  = ArrayMaximum(vpi);
   int IMAXvpf  = ArrayMaximum(vpf);
   int IMAXvtc  = ArrayMaximum(vtc);
   int IMINvmp  = ArrayMinimum(vmp);
   int IMINvmg  = ArrayMinimum(vmg);
   int IMINvpi  = ArrayMinimum(vpi);
   int IMINvpf  = ArrayMinimum(vpf);
   int IMINvtc  = ArrayMinimum(vtc);
   Print("is ",
         IMAXvmp
         ," ", IMAXvmg
         ," ", IMAXvpi
         ," ", IMAXvpf
         ," ", IMAXvtc
         ," ", IMINvmp
         ," ", IMINvmg
         ," ", IMINvpi
         ," ", IMINvpf
         ," ", IMINvtc
        );
   int UPq = 0;
   int DWq = 0;
   if(IMAXvmp < 1)
     {
      UPq++;
     }
   if(IMAXvmg < 1)
     {
      UPq++;
     }
   if(IMAXvpi < 1)
     {
      UPq++;
     }
   if(IMAXvpf < 1)
     {
      UPq++;
     }
   if(IMINvmp < 1)
     {
      DWq++;
     }
   if(IMINvmg < 1)
     {
      DWq++;
     }
   if(IMINvpi < 1)
     {
      DWq++;
     }
   if(IMINvpf < 1)
     {
      DWq++;
     }
   int Ur = 0;
   if(UPq > DWq)
     {
      Ur = 1;
     }
   if(UPq < DWq)
     {
      Ur = 2;
     }
   Print("INTtend : ", Ur,"  UP ", UPq, "  DW ", DWq);
   return Ur;
  }
//+------------------------------------------------------------------+
