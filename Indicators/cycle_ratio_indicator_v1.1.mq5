//+------------------------------------------------------------------+
//|                                        cycle_ratio_indicator.mq5 |
//| cycle ratio indicator v1.1                Copyright 2015, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.1"
#include <MovingAverages.mqh>
#property indicator_separate_window
#property indicator_buffers 9
#property indicator_plots   1

#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1   65
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  LimeGreen,Gray,Red
#property indicator_width1 2
//--- input parameters
input int InpOscPeriod=5; // Oscillator Period 
input int InpSqPeriod=40; // 1st Squeeze Period 
input int InpCyclePeriod=120; //1st CyclePeriod Period 


input double InpUpper=66.66;//  Upper
input double InpUnder=33.33;//  Lower

input double InpThreshold=3.0; // Threshold
input int InpSmoothing=2;// Smoothing Period 

input int InpRSIPeriod=40; // Calc Period

//---- will be used as indicator buffers
double OscBuffer[];
double StochBuffer[];
double ColorBuffer[];
double SmoothBuffer[];
double SpBuffer[];
double SigBuffer[];
double PosBuffer[];
double DigitBuffer[];
double RSIBuffer[];

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

   SetIndexBuffer(0,DigitBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,OscBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,RSIBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,StochBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,PosBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,SpBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,SmoothBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,SigBuffer,INDICATOR_CALCULATIONS);
//---
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---

   string short_name="cycle ratio indicator v1.1";

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

      if(osc<=InpUnder) StochBuffer[i]=0;
      else if(osc>=InpUpper) StochBuffer[i]=100;
      else StochBuffer[i]=50;

      int i2nd=i1st+InpCyclePeriod+1;
      if(i<=i2nd) continue;
      double v=0;
      for(int j=0;j<InpCyclePeriod;j++)
         v+=MathAbs(StochBuffer[i-j]-StochBuffer[(i-j)-1]);
      
      
      dmax=high[ArrayMaximum(high,i-(InpSqPeriod-1),InpSqPeriod)];
      dmin=low[ArrayMinimum(low,i-(InpSqPeriod-1),InpSqPeriod)];
      
      double hl=(dmax-dmin);
      v =(hl==0)? v: v/hl;
      OscBuffer[i]= v *_Point;

      int i3rd=i2nd+InpRSIPeriod+1;
      if(i<=i3rd)continue;
      double sumP=_Point;
      double sumN=_Point;
      for(int j=0;j<InpRSIPeriod;j++)
        {
         double diff=OscBuffer[i-j]-OscBuffer[i-j-1];
         sumP+=(diff>0?diff:0);
         sumN+=(diff<0? -diff:0);
        }

      RSIBuffer[i]=100.0-(100.0/(1.0+sumP/sumN));

      int i4th=i3rd+InpSmoothing*2;
      if(i<=i4th) continue;
      double avg2=0;
      for(int j=0;j<InpSmoothing;j++) 
        {
        int ii=i-j;
        double avg1=0;
        for(int k=0;k<InpSmoothing;k++)
          {
           int iii=ii-k;
           double avg0=0;
           for(int l=0;l<InpSmoothing;l++) avg0+=RSIBuffer[iii-l];
           avg1 += avg0/InpSmoothing;
          }              
        avg2 += avg1/InpSmoothing;
        }
        
      SmoothBuffer[i]=avg2/InpSmoothing;  
      int i5th=i4th+1;
      if(i<=i5th) continue;
      if((DigitBuffer[i-1]+InpThreshold) < SmoothBuffer[i] )DigitBuffer[i]=SmoothBuffer[i];
      else if((DigitBuffer[i-1]-InpThreshold) > SmoothBuffer[i] )DigitBuffer[i]=SmoothBuffer[i];
      else DigitBuffer[i]=DigitBuffer[i-1];


      int i6th=i5th+1;
      if(i<=i6th) continue;

      if(DigitBuffer[i-1]<DigitBuffer[i])   SigBuffer[i]=2;
      else if(DigitBuffer[i-1]>DigitBuffer[i])    SigBuffer[i]=0;
      else SigBuffer[i]=SigBuffer[i-1];
  
      ColorBuffer[i]=SigBuffer[i];

     }
//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
