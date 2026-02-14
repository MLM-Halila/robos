//+------------------------------------------------------------------+
//|                                                  TendenciaMA.mq5 |
//|                        Copyright 2025, Seu Nome ou Mario L.      |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Mario L."
#property link      "https://www.mql5.com"
#property version   "1.10"
#property strict
#property description "EA baseado em cruzamento de médias, direção e tamanho de candles"

// =====================================================================
// ===  PARÂMETROS DE ENTRADA (INPUTS)  ================================
// =====================================================================
input int    MP_Periodo       = 9;          // Período da Média Pequena (rápida)
input int    MG_Periodo       = 21;         // Período da Média Grande (lenta)
input int    Candle_N         = 5;          // Candle -N (ex: 5, 8, 10...)
input double Threshold_TC     = 10.0;       // Tamanho médio mínimo do candle (em pontos) para considerar momentum
input double Threshold_PT     = 70.0;       // Pontuação mínima para sinal de entrada (ajuste no otimizador)
input double Lote             = 0.10;       // Tamanho do lote fixo (ajuste conforme sua conta)
input int    MagicNumber      = 202510;     // Número mágico para identificar ordens deste EA
input int    Slippage         = 3;          // Deslizamento máximo permitido


// =====================================================================
// ===  HANDLES DOS INDICADORES  =======================================
// =====================================================================
int handle_MP = INVALID_HANDLE;
int handle_MG = INVALID_HANDLE;


// =====================================================================
// ===  ARRAYS PARA ARMAZENAR OS DADOS DOS 4 CANDLES  ==================
// =====================================================================
double vmp[4], vmg[4];           // Médias Móvel Pequena e Grande
double vpi[4], vpf[4];           // Preço Inicial (Open) e Final (Close/Bid)
double vtc[4];                  // Tamanho do candle em pontos
int    vdc[4];                  // Direção do candle: 1 = alta, -1 = baixa, 0 = doji


// =====================================================================
//| Expert initialization function                                     |
// =====================================================================
int OnInit()
  {
// Criar handles das médias móveis
   handle_MP = iMA(_Symbol, _Period, MP_Periodo, 0, MODE_EMA, PRICE_CLOSE);
   handle_MG = iMA(_Symbol, _Period, MG_Periodo, 0, MODE_EMA, PRICE_CLOSE);

   if(handle_MP == INVALID_HANDLE || handle_MG == INVALID_HANDLE)
     {
      Print("Erro ao criar handles das médias móveis!");
      return(INIT_FAILED);
     }

   Print("EA inicializado com sucesso → MP:", MP_Periodo, " | MG:", MG_Periodo, " | Candle N:", Candle_N);
   return(INIT_SUCCEEDED);
  }


// =====================================================================
//| Expert deinitialization function                                   |
// =====================================================================
void OnDeinit(const int reason)
  {
   if(handle_MP != INVALID_HANDLE)
      IndicatorRelease(handle_MP);
   if(handle_MG != INVALID_HANDLE)
      IndicatorRelease(handle_MG);

   Print("EA finalizado. Motivo: ", reason);
  }


// =====================================================================
//| Expert tick function                                               |
// =====================================================================
void OnTick()
  {

// =================================================================
// 1. COLETA DE DADOS DOS CANDLES E MÉDIAS
// =================================================================
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

// =================================================================
// 2. CÁLCULO DAS MÉTRICAS AVANÇADAS
// =================================================================
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

// =================================================================
// 3. GERAÇÃO DE SINAIS
// =================================================================
   bool sinal_compra = (PT > Threshold_PT)
                       && (vdc[0] > 0)
                       && (CrossScore > 0)
                       && (vmp[0] > vmg[0]);

   bool sinal_venda  = (PT < -Threshold_PT)
                       && (vdc[0] < 0)
                       && (CrossScore < 0)
                       && (vmp[0] < vmg[0]);

// =================================================================
// 4. DEBUG / LOG (remova ou comente em produção)
// =================================================================
   if(sinal_compra || sinal_venda || true) // true = sempre mostrar para debug
     {
      string status = sinal_compra ? "COMPRA" : (sinal_venda ? "VENDA" : "NEUTRO");
      Print("=== ", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES), " ===");
      Print("PT: ", DoubleToString(PT, 1), " | CrossScore: ", DoubleToString(CrossScore, 2));
      Print("MomentumTC: ", DoubleToString(MomentumTC, 1), " | Align: ", AlignScore);
      Print("SeqScore: ", DoubleToString(SeqScore, 2), " | SlopeMG: ", DoubleToString(SlopeMG, 5));
      Print("Status: ", status, " | TC médio: ", DoubleToString(avg_tc, 1), " pts");
      Print("MP0: ", DoubleToString(vmp[0], _Digits), " | MG0: ", DoubleToString(vmg[0], _Digits));
     }

// =================================================================
// 5. ENVIO DE ORDENS (descomente quando for usar em conta real/demo)
// =================================================================
   /*
   if(sinal_compra && !TemOrdemAberta(OP_BUY))
   {
      double sl = NormalizeDouble(vmp[0] - 50 * _Point, _Digits);   // exemplo SL abaixo da MP
      double tp = NormalizeDouble(Ask + 100 * _Point, _Digits);    // exemplo TP
      OrderSend(_Symbol, OP_BUY, Lote, Ask, Slippage, sl, tp, "Compra Tendência", MagicNumber, 0, clrGreen);
   }

   if(sinal_venda && !TemOrdemAberta(OP_SELL))
   {
      double sl = NormalizeDouble(vmp[0] + 50 * _Point, _Digits);
      double tp = NormalizeDouble(Bid - 100 * _Point, _Digits);
      OrderSend(_Symbol, OP_SELL, Lote, Bid, Slippage, sl, tp, "Venda Tendência", MagicNumber, 0, clrRed);
   }
   */
  }


// =====================================================================
// Função auxiliar: verifica se já existe ordem aberta do tipo desejado
// =====================================================================
bool TemOrdemAberta(int tipo)
  {
   /*   for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol() == _Symbol && OrderMagicNumber() == MagicNumber && OrderType() == tipo)
               return true;
         }
      }
      return false;
   */
   return false;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
