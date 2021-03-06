//+------------------------------------------------------------------+
//|                                            AdvMomemtum_v1.01.mq5 |
//| AdvMomemtum v1.01                         Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.01"
#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1 1



//---
input int MomPeriod=10;  // Momentum Period
input int FromMaPeriod=3;  //From Price Smoothing(Simple Ma)
input int CurMaPeriod=3;  // Current Price Smoothing(ZeroLag Ma)

//---

//---

double MomBuffer[];
double OrgBuffer[];


double MaBuffer[];
double LwMaBuffer[];
double LwMa2Buffer[];
double SlopeBuffer[];
double PriceBuffer[];
//---
//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {


//---- Initialization of variables of data calculation starting point
   min_rates_total=3;
//--- indicator buffers mapping
   SetIndexBuffer(0,MomBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,OrgBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,MaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,LwMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,LwMa2Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,SlopeBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,PriceBuffer,INDICATOR_CALCULATIONS);
 

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

 
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   string shortname="Advanced Momentum v1.01";
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int i,first,begin_pos;
   begin_pos=min_rates_total;
//--- check for bars count
   if(rates_total<=min_rates_total)
      return(0);
//---

   first=begin_pos;

   if(first+1<prev_calculated)
      first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      PriceBuffer[i]=(high[i]+low[i]+close[i])/3 ;

      
      int second=begin_pos+FromMaPeriod+CurMaPeriod;
      if(i<=second)continue;
      MaBuffer[i]=SimpleMA(i,FromMaPeriod,PriceBuffer);
      LwMaBuffer[i]=LinearWeightedMA(i,CurMaPeriod-1,PriceBuffer);     
      
      int third=second+CurMaPeriod;      
      if(i<=third)continue;
      LwMa2Buffer[i]=LinearWeightedMA(i,CurMaPeriod,LwMaBuffer);     

      int forth=third+MomPeriod;      
      if(i<=forth)continue;
     
      double ma=LwMaBuffer[i]*2- LwMa2Buffer[i];
      MomBuffer[i]= (ma+close[i])/2 -MaBuffer[i-MomPeriod];
      OrgBuffer[i]= close[i]-close[i-MomPeriod];
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }

