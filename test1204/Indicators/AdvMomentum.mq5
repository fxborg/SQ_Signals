//+------------------------------------------------------------------+
//|                                            AdvMomemtum_v1.01.mq5 |
//| AdvMomemtum v1.02                         Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.03"
#include <MovingAverages.mqh>

#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   5
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLightPink,clrRed,clrDarkSlateGray, clrDodgerBlue,clrLightSkyBlue
#property indicator_width1 3

#property indicator_type2   DRAW_LINE
#property indicator_color2  clrSilver
#property indicator_style2  STYLE_DOT

#property indicator_type3   DRAW_LINE
#property indicator_color3  clrSilver
#property indicator_style3  STYLE_DOT


#property indicator_type4   DRAW_LINE
#property indicator_color4  clrSilver
#property indicator_style4  STYLE_DOT

#property indicator_type5   DRAW_LINE
#property indicator_color5  clrSilver
#property indicator_style5  STYLE_DOT


#property indicator_type6   DRAW_LINE
#property indicator_color6  clrSilver
#property indicator_style6  STYLE_DOT


//---
input int MomPeriod=10;  // Momentum Period
double AngleFacter=0.05;  // Angle Factor
int FromMaPeriod=3;  //From Price Smoothing(Simple Ma)
int CurMaPeriod=3;  // Current Price Smoothing(ZeroLag Ma)
int StdDevPeriod=80;  // Slow Period

double MidLevel=0.5;  // Mid Level
double MaxLevel=1.5;  // Max Level

//---

//---

double MomBuffer[];
double MomColorBuffer[];

double MomUpBuffer[];
double MomDnBuffer[];
double MomUp2Buffer[];
double MomDn2Buffer[];

double MaBuffer[];
double LwMaBuffer[];
double LwMa2Buffer[];
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
   SetIndexBuffer(1,MomColorBuffer,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,MomUpBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,MomDnBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,MomUp2Buffer,INDICATOR_DATA);
   SetIndexBuffer(5,MomDn2Buffer,INDICATOR_DATA);
   SetIndexBuffer(6,MaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,LwMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,LwMa2Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,PriceBuffer,INDICATOR_CALCULATIONS);
 

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,2);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

 
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   string shortname="Advanced Momentum v1.03";
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

      
      int i2nd=begin_pos+FromMaPeriod+CurMaPeriod;
      if(i<=i2nd)continue;
      MaBuffer[i]=SimpleMA(i,FromMaPeriod,PriceBuffer);
      LwMaBuffer[i]=LinearWeightedMA(i,CurMaPeriod-1,PriceBuffer);     
      
      int i3rd=i2nd+CurMaPeriod;      
      if(i<=i3rd)continue;
      LwMa2Buffer[i]=LinearWeightedMA(i,CurMaPeriod,LwMaBuffer);     

      int i4th=i3rd+MomPeriod;      
      if(i<=i4th)continue;
     
      double ma=LwMaBuffer[i]*2- LwMa2Buffer[i];
      MomBuffer[i]= (ma+close[i])/2 -MaBuffer[i-MomPeriod];
      int i5th=i4th+StdDevPeriod;
      if(i<=i5th)continue;
      double stddev=0;
      for(int j=0;j<StdDevPeriod;j++)
         stddev+=MathPow(0-MomBuffer[i-j],2);
      //---
      stddev=MathSqrt(stddev/StdDevPeriod);
      MomUpBuffer[i]=stddev*MidLevel;
      MomDnBuffer[i]=-stddev*MidLevel;
      MomUp2Buffer[i]=stddev*MaxLevel;
      MomDn2Buffer[i]=-stddev*MaxLevel;

      int i6th=i5th+StdDevPeriod+MomPeriod+2;
      if(i<=i6th)continue;
      double avgatr=0;
      
      for(int j=0;j<StdDevPeriod;j++)
        {
        int ii=i-j;
        double atr=0;
        for(int k=0;k<MomPeriod;k++)  atr+= MathAbs(MomBuffer[ii-k]-MomBuffer[ii-k-1]);
        avgatr+=atr;  
        }
      avgatr /= StdDevPeriod;
      double scale=avgatr*AngleFacter;
      double angle=MomBuffer[i]-MomBuffer[i-1];
      if(angle <= -2*scale)MomColorBuffer[i]=0;
      else if(angle > -2*scale && angle <= -1*scale)MomColorBuffer[i]=1;
      else if(angle > -1*scale && angle < 1*scale) MomColorBuffer[i]=2;
      else if(angle < 2*scale && angle >= 1*scale) MomColorBuffer[i]=3;
      else if(angle >= 2*scale) MomColorBuffer[i]=4;
         
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }

