//+------------------------------------------------------------------+
//|                                                       SQI_v1.02.mq5 |
//| SQI v1.02                                  Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.02"
#include <MovingAverages.mqh>
#property indicator_separate_window
#property indicator_buffers 9
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrRed,clrOrange,clrLime, clrGreen
#property indicator_maximum 1.0

#property indicator_width1 3


//---
input int VolatPeriod=14; // Volatility Period
input int VolatSmooth=2; //  Volatility Smooth Period
input int VolatSlowPeriod=70; // Volatility Slow Period 
input double VolatLv1=0.3; // Volatility Level 1
input double VolatLv2=0.5; // Volatility Level 2

int MomSmooth=3;

//---

//---
double SQSigBuffer[];
double SQRawBuffer[];
double SQBuffer[];
double SQMaBuffer[];
double SQSlowBuffer[];
double SQColorBuffer[];

double MaBuffer[];
double MomMaRawBuffer[];
double MomMaBuffer[];

double DmyBuffer[];

double UpDnBuffer[];
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
   min_rates_total=VolatPeriod+1+VolatSmooth+1;
//--- indicator buffers mapping
   SetIndexBuffer(0,SQSigBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SQColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,SQBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,UpDnBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,SQRawBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,MaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,MomMaRawBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,MomMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,PriceBuffer,INDICATOR_CALCULATIONS);

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,0);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   string shortname="SQI v1.02";
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
      MomMaRawBuffer[i]=LinearWeightedMA(i,MomSmooth,close);
      SQSigBuffer[i]=0;
      PriceBuffer[i]=(high[i]+low[i]+close[i])/3;
      //---
      double udr=CalcUpDn(open,high,low,close,i);
      UpDnBuffer[i]=udr *((high[i]-low[i])+MathAbs(close[i]-close[i-1]));
      //---
      double avg=0;

      int sq1st=begin_pos+MathMax(VolatPeriod+1,VolatPeriod+4)+MomSmooth;
      if(i<=sq1st)continue;
      MaBuffer[i]=LinearWeightedMA(i,VolatPeriod,PriceBuffer);
      MomMaBuffer[i]=LinearWeightedMA(i,MomSmooth,MomMaRawBuffer);

      //sq
      double dmax=high[i];
      double dmin=low[i];
      for(int j=0;j<VolatPeriod;j++)
        {
         if(dmax<high[i-j])dmax=high[i-j];
         if(dmin>low[i-j])dmin=low[i-j];
        }

      double volat=0;
      for(int j=0;j<VolatPeriod;j++)
        {
         volat+=MathAbs(close[i-j-1]-close[i-j])
                +high[i-j]-low[i-j];

        }
      //---      
      double stddev=0.0;
      for(int j=0;j<VolatPeriod;j++)
         stddev+=MathPow(MaBuffer[i-j]-close[i-j],2);
      stddev=MathSqrt(stddev/VolatSlowPeriod);

      double from_price=(PriceBuffer[i-VolatPeriod]+PriceBuffer[i-VolatPeriod-1]+PriceBuffer[i-VolatPeriod-2])/3;
      double cur_price = (close[i]+MomMaRawBuffer[i]*2-MomMaBuffer[i])/2;
      //---
      double mom=MathAbs(cur_price-from_price);

      SQRawBuffer[i]=MathMax(mom,stddev*2)/MathMax(0.000000001,volat);

      int sq2nd=sq1st+MathMax(VolatSlowPeriod,VolatSmooth);
      if(i<=sq2nd)continue;
      double avg1,avg2;
      avg1=SimpleMA(i,VolatSmooth,SQRawBuffer);

      //---
      avg2=0;
      for(int j=0;j<VolatSlowPeriod;j++) avg2+=SQRawBuffer[i-j];
      avg2/=VolatSlowPeriod;

      //---      
      SQBuffer[i]=avg1-avg2;
      int sq3rd=sq2nd+VolatSlowPeriod;
      if(i<=sq3rd)continue;
      //---

      //---
      stddev=0.0;
      for(int j=0;j<VolatSlowPeriod;j++)
         stddev+=MathPow(0-SQBuffer[i-j],2);
      //---
      double mid=MathSqrt(stddev/VolatSlowPeriod)*VolatLv1;
      double under=MathSqrt(stddev/VolatSlowPeriod)*VolatLv2;

      //---
      if(SQBuffer[i]<-under)SQColorBuffer[i]=0.0;
      else if(SQBuffer[i]>= -under && SQBuffer[i] < -mid)SQColorBuffer[i]=1.0;
      else if(SQBuffer[i]>= -mid && SQBuffer[i]<=mid)SQColorBuffer[i]=2.0;
      else SQColorBuffer[i]=3.0;
      SQSigBuffer[i]=1;

     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalcUpDn(const double  &o[],const double  &h[],const double  &l[],const double  &c[],const int i)
  {
   double up= MathMax(0,(c[i]-o[i])) + (c[i]-l[i]);
   double dn= MathMax(0,(o[i]-c[i])) + (h[i]-c[i]);
   double dir=(up/MathMax(0.0000001,(up+dn)));
   return dir-0.5;

  }
//+------------------------------------------------------------------+
