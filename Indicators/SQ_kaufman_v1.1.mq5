//+------------------------------------------------------------------+
//|                                              SQ_Kaufman_v1.1.mq5 |
//| SQ_Kaufman v1.1                           Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.1"

#property indicator_separate_window
#property indicator_buffers 13
#property indicator_plots   4

#property indicator_type1   DRAW_COLOR_ARROW
#property indicator_color1  clrRed, clrGold,clrLime, clrGreen
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrDodgerBlue,clrRed

#property indicator_type3   DRAW_LINE
#property indicator_color3  clrBlue
#property indicator_type4   DRAW_NONE


#property indicator_width1 4
#property indicator_width2 2
#property indicator_width3 1

#property indicator_style3 STYLE_DOT


//---
input ENUM_TIMEFRAMES CalcTF=PERIOD_M10; // Calclation TimeFrame
input int VolatPeriod=10; // Volatility Period
input int VolatSmooth=5; //  Volatility Smooth Period
input int VolatSlowPeriod=70; // Volatility Slow Period 
input double   VolatMid=0.3; // Volatility Mid Deviation

input int MomPeriod=25; //  Mom Period
input int MomSmooth=5; // Mom Smooth Period

int WildersPeriod=14; //  WildersPeriod

//---
int Scale=PeriodSeconds(PERIOD_CURRENT)/PeriodSeconds(CalcTF);
//---

//---

//---
double VolatBuffer[];
double Volat2Buffer[];
double SQColorBuffer[];
double SQBuffer[];
double SlowVolatBuffer[];
double SlowStdDevBuffer[];
double BarVolatBuffer[];

double StdDevBuffer[];
double MomColorBuffer[];
double MomBuffer[];
double MomMaBuffer[];
double MomSarBuffer[];
double MomAtrBuffer[];
double SQSigBuffer[];
double DmyBuffer[];

double UpDnBuffer[];

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
   min_rates_total=VolatPeriod*5;
//--- indicator buffers mapping
   SetIndexBuffer(0,SQSigBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SQColorBuffer,INDICATOR_COLOR_INDEX);   
   SetIndexBuffer(2,MomMaBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,MomColorBuffer,INDICATOR_COLOR_INDEX);   
   SetIndexBuffer(4,MomSarBuffer,INDICATOR_DATA);   
   SetIndexBuffer(5,DmyBuffer,INDICATOR_DATA);   
   SetIndexBuffer(6,VolatBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,Volat2Buffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,BarVolatBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,SQBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,UpDnBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,MomBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,MomAtrBuffer,INDICATOR_CALCULATIONS);
 

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(10,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(11,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(12,PLOT_EMPTY_VALUE,0);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   string shortname="SQ_Kaufman_v1.1";
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
   begin_pos=3+VolatPeriod;
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
      //---
      double udr=CalcUpDn(open,high,low,close,i);
      UpDnBuffer[i]= udr *( (high[i]-low[i]));
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
      if(tf_rates_total<1) return (0);
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
      int second=begin_pos+VolatPeriod;
      if(i<=second)continue;

      double volat=0.0;
      for(int j=0;j<VolatPeriod;j++)volat+=BarVolatBuffer[i-j];
      //---
      Volat2Buffer[i]=volat;
      
      
      
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
      SQBuffer[i]=(dmax-dmin)/MathMax(0.000000001,Volat2Buffer[i]);
      //---      
      int forth = third+VolatSmooth+VolatSlowPeriod;
      if(i<=forth)continue;
      //---      
      double avg1,avg2;

      avg1=0;
      for(int j=0;j<VolatSmooth;j++)
          avg1+=SQBuffer[i-j];
      avg1/=VolatSmooth;
      //---      
      avg2=0;
      for(int j=0;j<VolatSlowPeriod;j++)
          avg2+=SQBuffer[i-j];
      //---      
      avg2/=VolatSlowPeriod;
      VolatBuffer[i] = avg1-avg2;

      //---      
      int fifth = forth+VolatSlowPeriod;
      if(i<=fifth)continue;
   
   
      double stddev=0.0;
      for(int j=0;j<VolatSlowPeriod;j++)
             stddev+=MathPow(0-VolatBuffer[i-j],2);
      //---
      double mid = MathSqrt(stddev/VolatSlowPeriod)*VolatMid;

      
      if(VolatBuffer[i] < -mid)SQColorBuffer[i]=0.0;
      else if(VolatBuffer[i]>= -mid && VolatBuffer[i]<=0)SQColorBuffer[i]=1.0;
      else if(VolatBuffer[i]<= mid && VolatBuffer[i]>0)SQColorBuffer[i]=2.0;
      else SQColorBuffer[i]=3.0;
      SQSigBuffer[i]=0;

      //---      
      int sixis =fifth+MomPeriod;
      if(i<=sixis)continue;
      double avg=0;
      for(int j=0;j<MomPeriod;j++) avg+=UpDnBuffer[i-j];
      MomBuffer[i] = avg/MomPeriod;
      int sevens =sixis+MomSmooth+MomSmooth;
      if(i<=sevens)continue;
      
      avg2=0;
      for(int j=0;j<MomSmooth;j++) 
        {
        int ii=i-j;
        avg1=0;
        for(int k=0;k<MomSmooth;k++) avg1+=MomBuffer[ii-k];
        avg2 += avg1/MomSmooth;
        }
      //---      
      MomMaBuffer[i]=avg2/MomSmooth;

      int eights =sevens+WildersPeriod+WildersPeriod+1;
      if(i<=eights)continue;

      
      //---
      avg=0;
      for(int j=0;j<WildersPeriod;j++)
       {
        int ii=i;         
        double atr=0;
        for(int k=0;k<WildersPeriod;k++)
           atr+=MathAbs(MomMaBuffer[ii-k-1]-MomMaBuffer[ii-k]);
        
        avg += atr/WildersPeriod;
        } 
      MomAtrBuffer[i]=avg/WildersPeriod;
      int nines =eights+3;
      if(i<=nines)continue;
      if(MomSarBuffer[i-1]==EMPTY_VALUE)
         MomSarBuffer[i-1]=MomMaBuffer[i-1]+MomAtrBuffer[i-1];

      double dar= MomAtrBuffer[i] * 4.236;
      double tr = MomSarBuffer[i-1];
      double dv = tr;

      if(MomMaBuffer[i]<tr)
        {
         tr=MomMaBuffer[i]+dar;
         if((MomMaBuffer[i-1]<dv) && (tr>dv)) tr=dv;
        }
      else if(MomMaBuffer[i]>tr)
        {
         tr=MomMaBuffer[i]-dar;
         if((MomMaBuffer[i-1]>dv) && (tr<dv)) tr=dv;
        }
      MomSarBuffer[i]=tr;
      if(MomMaBuffer[i]>=MomSarBuffer[i])MomColorBuffer[i]=0;
      else MomColorBuffer[i]=1;

      DmyBuffer[i]=-MomMaBuffer[i];

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
  