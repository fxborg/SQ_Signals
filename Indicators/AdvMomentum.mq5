//+------------------------------------------------------------------+
//|                                             AdvMomemtum.v1.0.mq5 |
//| AdvMomemtum v1.0                          Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.0"
#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   1
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1 2



//---
input int MomPeriod=10;  // Momentum Period
int MaPeriod=3;  // Smoothing


//---

//---

double MomBuffer[];


double MaBuffer[];
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
   SetIndexBuffer(1,MaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,SlopeBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,PriceBuffer,INDICATOR_CALCULATIONS);
 

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

 
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   string shortname="Advanced Momentum v1.0";
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
      
      int second=begin_pos+MomPeriod;
      if(i<=second)continue;
      
      MaBuffer[i]=SimpleMA(i,MaPeriod,PriceBuffer);
      
      
      int third=second+MomPeriod+1;
      
      if(i<=third)continue;
      
      MomBuffer[i]= close[i]-MaBuffer[i-MomPeriod];
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }

