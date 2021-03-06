//+------------------------------------------------------------------+
//|                                            Candle Strength.1.mq5 |
//| Candle Strengh v1.0                       Copyright 2015, fxborg |
//|                                  http://blog.livedoor.jp/fxborg/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, fxborg"
#property link      "http://blog.livedoor.jp/fxborg/"
#property version   "1.0"

#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   3
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrDodgerBlue,clrRed

#property indicator_type2   DRAW_LINE
#property indicator_color2  clrBlue
#property indicator_type3   DRAW_NONE


#property indicator_width1 4
#property indicator_width2 1
#property indicator_width3 1

#property indicator_style2 STYLE_DOT


//---
input int CS_Period=25; //  Candle Strength Period
input int CS_Smooth=5; // Candle Strength Smooth Period
input bool UseParabolic=true; // Use Paravolic   
int WildersPeriod=14; //  WildersPeriod


//---

//---

double CSColorBuffer[];
double CSBuffer[];
double CSMaBuffer[];
double CSSarBuffer[];
double CSAtrBuffer[];
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


//---- Initialization of variables of data calculation starting point
   min_rates_total=CS_Period+CS_Smooth*2+1;
//--- indicator buffers mapping
   SetIndexBuffer(0,CSMaBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,CSColorBuffer,INDICATOR_COLOR_INDEX);   
   SetIndexBuffer(2,CSSarBuffer,INDICATOR_DATA);   
   SetIndexBuffer(3,DmyBuffer,INDICATOR_DATA);   
   SetIndexBuffer(4,UpDnBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,CSBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,CSAtrBuffer,INDICATOR_CALCULATIONS);
 

//--- set drawing line empty value
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0);
//---
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
   string shortname="CandleStrength_v1.0";
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
      //---
      double udr=CalcUpDn(open,high,low,close,i);
      UpDnBuffer[i]= udr *( (high[i]-low[i])+MathAbs(close[i]-close[i-1]));
      //---

      double avg=0;
      for(int j=0;j<CS_Period;j++) avg+=UpDnBuffer[i-j];
      CSBuffer[i] = avg/CS_Period;
      int second =begin_pos+CS_Smooth*2;
      if(i<=second)continue;
     
      double avg2=0;
      for(int j=0;j<CS_Smooth;j++) 
        {
        int ii=i-j;
        double avg1=0;
        for(int k=0;k<CS_Smooth;k++) avg1+=CSBuffer[ii-k];
        avg2 += avg1/CS_Smooth;
        }
      //---      
      CSMaBuffer[i]=avg2/CS_Smooth;         
      DmyBuffer[i]=-CSMaBuffer[i];
      if(!UseParabolic)
         {
         if(CSMaBuffer[i]>=0)CSColorBuffer[i]=0;
         else CSColorBuffer[i]=1;
         }
      else
         {
         int third =second+WildersPeriod+WildersPeriod+1;
         if(i<=third)continue;
   
         
         //---
         avg=0;
         for(int j=0;j<WildersPeriod;j++)
          {
           int ii=i;         
           double atr=0;
           for(int k=0;k<WildersPeriod;k++)
              atr+=MathAbs(CSMaBuffer[ii-k-1]-CSMaBuffer[ii-k]);
           
           avg += atr/WildersPeriod;
           } 
         CSAtrBuffer[i]=avg/WildersPeriod;
         int forth =third+3;
         if(i<=forth)continue;
         if(CSSarBuffer[i-1]==EMPTY_VALUE)
            CSSarBuffer[i-1]=CSMaBuffer[i-1];
   
         double dar= CSAtrBuffer[i] * 4.236;
         double tr = CSSarBuffer[i-1];
         double dv = tr;
   
         if(CSMaBuffer[i]<tr)
           {
            tr=CSMaBuffer[i]+dar;
            if((CSMaBuffer[i-1]<dv) && (tr>dv)) tr=dv;
           }
         else if(CSMaBuffer[i]>tr)
           {
            tr=CSMaBuffer[i]-dar;
            if((CSMaBuffer[i-1]>dv) && (tr<dv)) tr=dv;
           }
         CSSarBuffer[i]=tr;
         if(CSMaBuffer[i]>=CSSarBuffer[i])CSColorBuffer[i]=0;
         else CSColorBuffer[i]=1;
      }

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
  