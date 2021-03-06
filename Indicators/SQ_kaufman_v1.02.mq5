//+------------------------------------------------------------------+
//|                                             SQ_Kaufman_v1.02.mq5 |
//| SQ_Kaufman v1.02                          Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.02"

#property indicator_separate_window
#property indicator_buffers 12
#property indicator_plots   4

#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrGreen,clrRed
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGold

#property indicator_type3   DRAW_LINE
#property indicator_color3  clrSilver
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrSilver


#property indicator_width1 4
#property indicator_width2 1
#property indicator_width3 1
#property indicator_width4 1

#property indicator_style3 STYLE_DOT
#property indicator_style4 STYLE_DOT


//---
input ENUM_TIMEFRAMES CalcTF=PERIOD_M5; // Calclation TimeFrame
input int VolatPeriod=10; // Volatility Period
input int SmoothPeriod=3; // Smooth Period
input int SlowPeriod=70; // SlowPeriod 

//---
input double   Deviation=0.4; // Deviatoin
//---
int Scale=PeriodSeconds(PERIOD_CURRENT)/PeriodSeconds(CalcTF);
//---

//---

//---
double SQRangeBuffer[];
double SQColorBuffer[];
double SmoothSQBuffer[];
double SlowSQBuffer[];
double SQBuffer[];
double SlowVolatBuffer[];
double SlowStdDevBuffer[];
double BarVolatBuffer[];
double VolatBuffer[];

double StdDevBuffer[];
double MomBuffer[];
double MomMaBuffer[];
double MomHiBuffer[];
double MomLoBuffer[];
//---
//---- declaration of global variables
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   if(PeriodSeconds(PERIOD_CURRENT)<PeriodSeconds(CalcTF))
     {
      Alert("Calclation Time Frame is too Large");
      return(INIT_FAILED);
     }
   if(VolatPeriod<5)
     {
      Alert("VolatPeriod is too Small");
      return(INIT_FAILED);
     }

//---- Initialization of variables of data calculation starting point
   min_rates_total=VolatPeriod*10;
//--- indicator buffers mapping
   SetIndexBuffer(0,SQRangeBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SQColorBuffer,INDICATOR_COLOR_INDEX);   
   SetIndexBuffer(2,MomMaBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,MomHiBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,MomLoBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,BarVolatBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,SmoothSQBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,SlowSQBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,VolatBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,StdDevBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,SQBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,MomBuffer,INDICATOR_CALCULATIONS);
 

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(10,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(11,PLOT_EMPTY_VALUE,0);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   string shortname="SQ_Kaufman_v1.02";
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
   begin_pos=VolatPeriod;
//--- check for bars count
   if(rates_total<=min_rates_total)
      return(0);
//---

   first=begin_pos;

   if(first+1<prev_calculated && BarVolatBuffer[3]!=EMPTY_VALUE)
      first=prev_calculated-2;

//---
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
       //---

      //---
      bool isNewBar=(i==rates_total-1);
      //---
      double up_vol=0;
      double dn_vol=0;
      //---
      MqlRates tf_rates[];
      //---
      datetime from=(datetime)(time[i-1]-10);
      datetime to=(isNewBar)?TimeCurrent()+10:(datetime)(time[i+1]-10);
      int tf_rates_total=CopyRates(Symbol(),CalcTF,from,to,tf_rates);
      if(tf_rates_total<1) continue;
      //---
      double dsum=0;
      int tf_bar_count=0;
      for(int pos=0;pos<tf_rates_total;pos++)
        {
         //---
         BarVolatBuffer[i]=EMPTY_VALUE;
         if(tf_rates[pos].time>(time[i]-10))
           {
            double prev_price= tf_rates[pos].open;
            if((tf_bar_count==0 && pos>0 )||tf_bar_count>0)
               prev_price= tf_rates[pos-1].close;

            dsum+=MathAbs(prev_price-tf_rates[pos].close);
            tf_bar_count++;  
           }
         //---
        }
      //---
      BarVolatBuffer[i]=dsum;
      int second=begin_pos+VolatPeriod+SmoothPeriod;
      //---
      if(i<=second)continue;
      double v=0.0;
      for(int j=0;j<VolatPeriod;j++)v+=BarVolatBuffer[i-j];
      VolatBuffer[i]=v;
      //---
      int third=second+VolatPeriod;
      if(i<=third)continue;
      double dmax=high[i];
      double dmin=low[i];
      for(int j=0;j<VolatPeriod;j++)
       {
         if(dmax<high[i-j])dmax=high[i-j];
         if(dmin>low[i-j])dmin=low[i-j];
       }
      //---      
      MomBuffer[i]=(close[i]-close[i-VolatPeriod])/MathMax(0.000000001,VolatBuffer[i]);      
      SQBuffer[i]=(dmax-dmin)/MathMax(0.000000001,VolatBuffer[i]);
      //---      
          
      //---      
      int forth = third+MathMax(SmoothPeriod,SlowPeriod);
      if(i<=forth)continue;
      //---      
      double avg=0;
      for(int j=0;j<SmoothPeriod;j++)
          avg+=SQBuffer[i-j];
      SmoothSQBuffer[i]=avg/SmoothPeriod;
      //---      
      avg=0;
      for(int j=0;j<SlowPeriod;j++)
          avg+=SQBuffer[i-j];
      //---      
      SlowSQBuffer[i]=avg/SlowPeriod;
      SQRangeBuffer[i] =SmoothSQBuffer[i]-SlowSQBuffer[i];
      if(SQRangeBuffer[i]>=0)SQColorBuffer[i]=0.0;
      else SQColorBuffer[i]=1.0;
      //---      
      avg=0;
      for(int j=0;j<SmoothPeriod;j++)
          avg+=MomBuffer[i-j];
      MomMaBuffer[i]=avg/SmoothPeriod;
      //---      
      double stddev=0.0;
      for(int j=0;j<SlowPeriod;j++)
             stddev+=MathPow(0-MomBuffer[i-j],2);
      //---
      stddev=MathSqrt(stddev/SlowPeriod);
      MomHiBuffer[i]= stddev*Deviation;
      MomLoBuffer[i]= -stddev*Deviation;



     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
