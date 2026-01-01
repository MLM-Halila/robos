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
input int SEGS = 60; // Tempo (SEGUNDOS)
input bool TEL = false; // MSG telegram
input int GL = 1; // Grava ou Le (1, 2)
datetime INItempo[10];
double SALDO_Inicial = 0;
double SALDO_Anterior = 0;
string arquivo = "RobosR.txt";
string lock = "RobosL.txt";
//+------------------------------------------------------------------+
//| Função de inicialização                                          |
//+------------------------------------------------------------------+
int OnInit()
  {
   SALDO_Inicial = 0;
   SALDO_Anterior = 0;
   if(GL == 2)
     {
    int x = Resumo_Deleta(arquivo, lock);
    Print("Del X", x);
     }
   GRAVA_TELMSG();
   /*
      string data_path   = TerminalInfoString(TERMINAL_DATA_PATH);
      string common_path = TerminalInfoString(TERMINAL_COMMONDATA_PATH);
      PrintFormat("TERMINAL_DATA_PATH   = %s", data_path);
      PrintFormat("TERMINAL_COMMONDATA_PATH = %s", common_path);
   */
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
      if(GL == 1)
        {
         GRAVA_TELMSG();
        }
      if(GL == 2)
        {
         Print("NNNNNNNNNNNNN");
         GL2();
        }
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   bool NewCandle = TemosNewCandle();
   if(NewCandle)
     {
      if(GL == 1)
        {
         GRAVA_TELMSG();
        }
      if(GL == 2)
        {
         //         GL2();
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
void GRAVA_TELMSG()
  {
   long NConta = (AccountInfoInteger(ACCOUNT_LOGIN));
   string XConta = DoubleToString(NConta,0);
   double SALDO_Atual = SALDO_Corrigido();
   if(SALDO_Inicial == 0)
     {
      SALDO_Inicial = SALDO_Atual;
     }
   if(SALDO_Anterior == 0)
     {
      SALDO_Anterior = SALDO_Atual;
     }
   DASHBOARD((SALDO_Atual-SALDO_Inicial));
   string Telegram_Message=
      XConta+" "+
      DoubleToString((SALDO_Atual-SALDO_Inicial),2)+
      " "+VER;
   Print(Telegram_Message);
   bool x = Resumo_Atualizar(arquivo, lock, XConta, Telegram_Message);
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
//|                                                                  |
//+------------------------------------------------------------------+
void GL2()
  {
   string buffer[];
   double Restot = 0;
   double ORsal;
   int ms = Resumo_LerTudo(arquivo, lock, buffer);
   if(ms > 0)
     {
      for(int i=0; i<ArraySize(buffer); i++)
        {
         string partes[];
         ushort delimitador = ' ';
         int qp = StringSplit(buffer[i], delimitador, partes);
         if(qp == 3)
           {
            ORsal = StringToDouble(partes[1]);
            Restot = Restot + ORsal;
           }
         Print("L ",buffer[i]," ",ORsal);
         if(TEL == true)
           {
            SendMessage(InpToken, GroupChatId, buffer[i]);
           }
        }
      string PP ="_________________ "+Restot;
      Print(PP);
      if(TEL == true)
        {
         SendMessage(InpToken, GroupChatId, PP);
        }

     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Resumo_Atualizar(string Arq_caminho, string Arq_lock, string id_robo, string texto)
  {
   int    tent = 0;

//--- espera o Arq_lock
   while(FileIsExist(Arq_lock) && tent++ < 100)
      Sleep(100);
   if(tent >= 100)
      return false;

//--- cria o Arq_lock (agora somos donos exclusivos)
   int l = FileOpen(Arq_lock, FILE_WRITE|FILE_TXT|FILE_COMMON);
   if(l == INVALID_HANDLE)
      return false;
   FileClose(l);

//--- abre o arquivo atual (ou cria se não existir)
   int h = FileOpen(Arq_caminho, FILE_READ|FILE_WRITE|FILE_TXT|FILE_COMMON);
   if(h == INVALID_HANDLE)
      h = FileOpen(Arq_caminho, FILE_WRITE|FILE_TXT|FILE_COMMON);
   if(h == INVALID_HANDLE)
     {
      FileDelete(Arq_lock);
      return false;
     }

   string linhas[];
   int    total = 0;
   bool   encontrou = false;

//--- lê todas as linhas e procura pelo ID do robô
   while(!FileIsEnding(h))
     {
      string linha = FileReadString(h);
      if(StringLen(linha) > 0)
        {
         // Verifica se a linha começa com o ID do robô seguido de |
         if(StringFind(linha, id_robo + "|") == 0)
            encontrou = true;           // já existe → vamos substituir
         else
           {
            ArrayResize(linhas, total+1);
            linhas[total++] = linha;     // mantém as outras linhas
           }
        }
     }
   FileClose(h);

//--- reescreve o arquivo com o novo registro (substituindo ou adicionando)
   h = FileOpen(Arq_caminho, FILE_WRITE|FILE_TXT|FILE_COMMON);  // limpa tudo e recria
   if(h != INVALID_HANDLE)
     {
      // primeiro grava todas as linhas que não são deste robô
      for(int i=0; i<total; i++)
         FileWrite(h, linhas[i]);

      // agora grava o registro NOVO deste robô (sempre no final ou substitui)
      string registro_final = id_robo + "|" + texto;
      FileWrite(h, registro_final);

      FileClose(h);
     }

   FileDelete(Arq_lock);
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Resumo_LerTudo(string Arq_caminho, string Arq_lock, string &linhas[])
  {
   ArrayFree(linhas);

   int    tent = 0;

   while(FileIsExist(Arq_lock) && tent++ < 100)
      Sleep(100);
   if(tent >= 100)
      return false;

   int l = FileOpen(Arq_lock, FILE_WRITE|FILE_TXT|FILE_COMMON);
   if(l == INVALID_HANDLE)
      return false;
   FileClose(l);

   int h = FileOpen(Arq_caminho, FILE_READ|FILE_TXT|FILE_COMMON);
   if(h == INVALID_HANDLE)
     {
      FileDelete(Arq_lock);
      return false;
     }

   int total = 0;
   while(!FileIsEnding(h))
     {
      string temp = FileReadString(h);
      if(StringLen(temp) > 0)
        {
         ArrayResize(linhas, total+1);
         linhas[total++] = temp;
        }
     }
   FileClose(h);

   FileDelete(Arq_caminho);   // apaga tudo depois de ler
   FileDelete(Arq_lock);

   return (total > 0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Resumo_Deleta(string Arq_caminho, string Arq_lock)
  {
   int    tent = 0;

   while(FileIsExist(Arq_lock) && tent++ < 100)
      Sleep(100);
   if(tent >= 100)
      return 1; 

   int l = FileOpen(Arq_lock, FILE_WRITE|FILE_TXT|FILE_COMMON);
   if(l == INVALID_HANDLE)
      return 2;
   FileClose(l);

   int h = FileOpen(Arq_caminho, FILE_READ|FILE_TXT|FILE_COMMON);
   if(h == INVALID_HANDLE)
     {
      FileDelete(Arq_lock);
      return 3;
     }
   FileClose(h);
   FileDelete(Arq_caminho);
   FileDelete(Arq_lock);
   return 4;
  }
//+------------------------------------------------------------------+
