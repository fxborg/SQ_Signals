//+------------------------------------------------------------------+
//|                                        cycle_ratio_indicator.mq5 |
//| cycle ratio indicator v1.00               Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   1

#property indicator_type1   DRAW_LINE
#property indicator_color1  Red
#property indicator_width1 2
//--- input parameters
input int InpOscPeriod=5; // Oscillator Period 
input int InpCyclePeriod=30; // CyclePeriod Period 
input int InpSqPeriod=10; // Squeeze Period 
input double InpUpper=66.66;//  Upper
input double InpUnder=33.33;//  Under


//---- will be used as indicator buffers
double UpBuffer[];
double DnBuffer[];
double UpperLvBuffer[];
double LowerLvBuffer[];
double OscBuffer[];
double SmoothBuffer[];
double ColorBuffer[];
double SpBuffer[];
double PosBuffer[];
double DigitBuffer[];
//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   min_rates_total=InpOscPeriod*2;
//--- indicator buffers mapping

   SetIndexBuffer(0,OscBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DigitBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,PosBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,SpBuffer,INDICATOR_CALCULATIONS);
//---
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---

   string short_name="cycle ratio indicator v1.00";

   IndicatorSetString(INDICATOR_SHORTNAME,short_name);

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
   int i,first;
   if(rates_total<=min_rates_total)
      return(0);
//---

//+----------------------------------------------------+
//|Set Median Buffeer                                |
//+----------------------------------------------------+
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      double dmax=high[ArrayMaximum(high,i-(InpOscPeriod-1),InpOscPeriod)];
      double dmin=low[ArrayMinimum(low,i-(InpOscPeriod-1),InpOscPeriod)];
      PosBuffer[i]=(close[i]-dmin);
      SpBuffer[i]=(dmax-dmin);

      int i1st=begin_pos+3;
      if(i<=i1st)continue;
      double pos=0;
      double sp=0;
      for(int j=0;j<3;j++)
        {
         pos+=PosBuffer[i-j];
         sp+=SpBuffer[i-j];
        }
      double osc=(sp==0)? 100 : 100*pos/sp;

      if(osc<=InpUnder) DigitBuffer[i]=0;
      else if(osc>=InpUpper) DigitBuffer[i]=100;
      else DigitBuffer[i]=50;

      int i2nd=i1st+InpCyclePeriod+1;
      if(i<=i2nd) continue;
      double v=0;
      for(int j=0;j<InpCyclePeriod;j++)
         v+=MathAbs(DigitBuffer[i-j]-DigitBuffer[(i-j)-1]);
      v*=_Point;
      dmax=high[ArrayMaximum(high,i-(InpSqPeriod-1),InpSqPeriod)];
      dmin=low[ArrayMinimum(low,i-(InpSqPeriod-1),InpSqPeriod)];
      double hl=(dmax-dmin);
      OscBuffer[i]=(hl==0)? v: v/hl;

     }
//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
