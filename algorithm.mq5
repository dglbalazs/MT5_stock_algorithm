//+------------------------------------------------------------------+
//|                                                       GoldPredictorIndicator.mq5 |
//|                                                        dglbalazs |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "dglbalazs"
#property link      ""
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   8

//----My indicator :)

#property indicator_label1  "iPredictor" 
#property indicator_type1   DRAW_LINE 
#property indicator_color1  clrGold 
#property indicator_style1  STYLE_SOLID 
#property indicator_width1  1 

/*
#property indicator_label2  "Average Directional Movement" 
#property indicator_type2   DRAW_LINE 
#property indicator_color2  clrBlue 
#property indicator_style2  STYLE_SOLID 
#property indicator_width2  1 

#property indicator_label3  "Directional movement Positive" 
#property indicator_type3   DRAW_LINE 
#property indicator_color3  clrHoneydew 
#property indicator_style3  STYLE_SOLID 
#property indicator_width3  1 

#property indicator_label4  "Directional movement Negative" 
#property indicator_type4   DRAW_LINE 
#property indicator_color4  clrCyan 
#property indicator_style4  STYLE_SOLID 
#property indicator_width4  1 

#property indicator_label5  "Williams R" 
#property indicator_type5   DRAW_LINE 
#property indicator_color5  clrWhite 
#property indicator_style5  STYLE_SOLID 
#property indicator_width5  1 

#property indicator_label6  "Moving Average" 
#property indicator_type6   DRAW_LINE 
#property indicator_color6  clrRed 
#property indicator_style6  STYLE_SOLID 
#property indicator_width6  1 

#property indicator_label7  "Center of Gravity - Current" 
#property indicator_type7   DRAW_LINE 
#property indicator_color7  clrGreen 
#property indicator_style7  STYLE_SOLID 
#property indicator_width7  1 

#property indicator_label8  "Center of Gravity - Average" 
#property indicator_type8   DRAW_LINE 
#property indicator_color8  clrAzure 
#property indicator_style8  STYLE_SOLID 
#property indicator_width8  1 
*/

//+------------------------------------------------------------------+
// GLOBAL VARIABLES
//+------------------------------------------------------------------+

//-------BUFFERS-----------------------------------------------------+
double         iPredictorBuffer[];  // My gold predictor's buffer

double         iADXBuffer[];        // Average Directional Movement buffer
double         iDI_plusBuffer[];    // Directional movement - positive buffer
double         iDI_minusBuffer[];   // Directional movement - negative buffer

double         iWilliamsBuffer[];   // Williams%R buffer

double         iMABuffer[];         // Moving Average buffer

double         iCOGBuffer1[];       // Center of Gravity buffer - 1
double         iCOGBuffer2[];       // Center of Gravity buffer - 2

//--------------------------------------------------------------------

    //OVERALL
string                     symbol=" ";                         // Symbol  
input ENUM_TIMEFRAMES      period=PERIOD_CURRENT;              // Timeframe (default: Current)
input ENUM_APPLIED_PRICE   applied_price=PRICE_CLOSE;          // Type of price (default: Close)
input double               win_percentage=20;                  // Percentage above which it should open a trade (default: 40)

    //Average Directional Movement 
input int                  adx_period=14;                      // Average Directional Movement - period (default: 14)

    //Williams%R Indicator
input int                  williams_period=14;                 // Williams%R Indicator - period (default: 14)

    //Moving Average Indicator
input int                  ma_period=200;                      // Moving Avg. - Period (default: 200)
input int                  ma_shift=0;                         // Moving Avg. - Shift (default: 0) 
input ENUM_MA_METHOD       ma_method=MODE_SMA;                 // Moving Avg. - Smoothing (default: Simple)
input double               ma_difference=0;                    // Moving Avg. - Activation percentage of difference between current price (default: 0)


    //Center of Gravity Indicator
input int                  COG_period=10;                      // Center of Gravity - period (default: 10)
input int                  COG_smooth=3;                       // Center of Gravity - Smoothing (default: 3)
input int                  COG_method=MODE_SMA;                // Center of Gravity - Smoothing Type (default: Simple)

//-------HANDLES-----------------------------------------------------+

int             ADX_handle;                     // Average Directional Movement - handle
int             Williams_handle;                // Williams%R Indicator - handle
int             MA_handle;                      // Moving Average Indicator - handle


//-------BARS CALCULATED---------------------------------------------+
int             ADX_bars_calculated=0;          // Average Directional Movement - bars calculated
int             Williams_bars_calculated = 0;   // Williams%R Indicator - bars calculated
int             MA_bars_calculated=0;           // Moving Average Indicator - bars calculated
int             COG_bars_calculated=0;          // Center of Gravity Indicator - bars calculated
int             GoldDigger_bars_calculated=0;   // Gold Predictor Indicator - bars calculated

//-------PROFIT CALCULATORS
double          ProfitLossSUM;
int             ProfitTransaction;
int             LoseTransaction;

//-------HELPER VARIABLES
int             DataLimit;

//-------INITIAL VARIABLES
int TickNumber=0;          // Number of ticks handled
bool blnAboveBelow;        // Low Moving Average below or above Medium Moving Average


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  
//--- SYMBOL

   symbol = _Symbol;
  
//--- create timer
      
   int ProfitReportHour = 24;
   int intSetTimer = ProfitReportHour * 60;
   EventSetTimer(intSetTimer);
   
//---------------------------------
// -----    D E F A U L T ---------

    DataLimit = adx_period;

    if (DataLimit<williams_period)
    {
        DataLimit = williams_period;
    };

    if (DataLimit<ma_period)
    {
        DataLimit = ma_period;
    };

    if (DataLimit<COG_period)
    {
        DataLimit = COG_period;
    };

   //+------------------------------------------------------------------+  
   //CREATE THE AWESOME GOLD PREDICTOR INDICATOR
   //+------------------------------------------------------------------+
   SetIndexBuffer(0,iPredictorBuffer,INDICATOR_DATA);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,clrGold);
   
   //---- indicator name to be displayed in DataWindow and subwindow 
   IndicatorSetString(INDICATOR_SHORTNAME,"Gold digger"); 
   //--- set index of the bar the drawing starts from 
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,0); 
   //--- set 0.0 as an empty value that is not drawn 
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0); 
   //--- indicator accuracy to be displayed 
   IndicatorSetInteger(INDICATOR_DIGITS,5); 
   
   //+------------------------------------------------------------------+  
   //CREATE THE AVERAGE DIRECTIONAL MOVEMENT INDICATOR
   //+------------------------------------------------------------------+

    SetIndexBuffer(1,iADXBuffer,INDICATOR_DATA);
    SetIndexBuffer(2,iDI_plusBuffer,INDICATOR_DATA);
    SetIndexBuffer(3,iDI_minusBuffer,INDICATOR_DATA);

    MqlParam ADX_pars[1];
    ADX_pars[0].type = TYPE_INT;
    ADX_pars[0].integer_value = adx_period;
    ADX_handle = IndicatorCreate(symbol,period,IND_ADX,1,ADX_pars);

    if(ADX_handle==INVALID_HANDLE)
        {
        //--- tell about the failure and output the error code
        PrintFormat("Failed to create handle of the iADX indicator for the symbol %s/%s, error code %d",
                    symbol,
                    EnumToString(period),
                    GetLastError());
        //--- the indicator is stopped early
        return(INIT_FAILED);
        }


   //+------------------------------------------------------------------+  
   //CREATE THE WILLIAMS%R INDICATOR
   //+------------------------------------------------------------------+

   SetIndexBuffer(4,iWilliamsBuffer,INDICATOR_DATA);

   MqlParam Williams_pars[1];

   Williams_pars[0].type = TYPE_INT;
   Williams_pars[0].integer_value = williams_period;
   Williams_handle = IndicatorCreate(symbol,period,IND_WPR,1,Williams_pars);

    if(Williams_handle==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the WilliamsR indicator for the symbol %s/%s, error code %d",
                  symbol,
                  EnumToString(period),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }

    //+------------------------------------------------------------------+  
    //CREATE MOVING AVERAGE INDICATORs
    //+------------------------------------------------------------------+

   SetIndexBuffer(5,iMABuffer,INDICATOR_DATA); 

   //--- set shift 
   PlotIndexSetInteger(5,PLOT_SHIFT,ma_shift);    

   //--- create handle
   MqlParam MA_pars[4]; 
   
    //--- period 
   MA_pars[0].type=TYPE_INT; 
   MA_pars[0].integer_value=ma_period; 
   //--- shift 
   MA_pars[1].type=TYPE_INT; 
   MA_pars[1].integer_value=ma_shift; 
   //--- type of smoothing 
   MA_pars[2].type=TYPE_INT; 
   MA_pars[2].integer_value=ma_method; 
   //--- type of price 
   MA_pars[3].type=TYPE_INT; 
   MA_pars[3].integer_value=applied_price; 
   MA_handle=IndicatorCreate(symbol,period,IND_MA,4,MA_pars); 
   
         
   //--- if the handle is not created
   if(MA_handle==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the Moving Avg. indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }

    //+------------------------------------------------------------------+  
    //CREATE CENTER OF GRAVITY INDEX
    //+------------------------------------------------------------------+

    SetIndexBuffer(6,iCOGBuffer1,INDICATOR_DATA);
    SetIndexBuffer(7,iCOGBuffer2,INDICATOR_DATA);

    PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,0); 
    PlotIndexSetInteger(7,PLOT_DRAW_BEGIN,0); 
//---
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+ 
//|  Gold diggaaa indicator calculation                                  | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,     // price[] array size  
                const int prev_calculated, // number of previously handled bars 
                const int begin,           // where significant data start from  
                const double &price[])     // value array for handling 
  { 
  
    //Awesome stuff
int               Awesome_Round_Counter=0;

    // Center of gravity
double            COG_PriceSum1=0;
double            COG_PriceSum2=0;
double            COG_Avg_PriceSum=0;
double            COG_Avg=0;
double            COG_Oszto=0;
int               COG_Round_Counter=0;

   // Average directional movement
double            ADX_Sum_Helper1=0;
double            ADX_Sum_Helper2=0;
double            ADX_Sum_Helper3=0;
double            ADX_Index1_Avg=0;
double            ADX_Index2_Avg=0;
double            ADX_Index3_Avg=0;
double            ADX_Oszto=0;
double            ADX_Ratio_Helper=0;
double            ADX_Ratio_Buy=0;
double            ADX_Ratio_Sell=0;
      

   // Williams R indicator
double            Williams_Sum_Helper=0;
double            Williams_Avg=0;
double            Williams_Oszto=0;

   // Moving Avg.
double            MA_Sum_Helper=0;
double            MA_Avg=0;
double            MA_Oszto=0;


   // Buy or sell variables
double            BuyScore = 0;
double            SellScore = 0;


//--------------------------------------------------------------------------------------------
//----------    Checking if correct iteration   -------------
//--------------------------------------------------------------------------------------------

if (rates_total<DataLimit)
{
    return(0);
};

if (BarsCalculated(MA_handle)<rates_total)
{
    PrintFormat("Not all data for Moving Average has been calculated. Error ",GetLastError());
    return(0);
}

if (BarsCalculated(ADX_handle)<rates_total)
{
    PrintFormat("Not all data for Average Direcitonal Movement has been calculated. Error ",GetLastError());
    return(0);
}

if (BarsCalculated(Williams_handle)<rates_total)
{
    PrintFormat("Not all data for Williams R has been calculated. Error ",GetLastError());
    return(0);
}

if(IsStopped())
{
    return(0);
};

//--------------------------------------------------------------------------------------------

int CopyNumber;

if (prev_calculated>rates_total || prev_calculated<0)
{
    CopyNumber = rates_total;
} else 
{
    CopyNumber = rates_total - prev_calculated;
    if(prev_calculated>0)
    {
        CopyNumber++;
    }
};

//--- initial position for calculations 
   int StartCalcPosition=begin; 
   
//---- if calculation data is insufficient 
   if(rates_total<StartCalcPosition) 
      return(0);  // exit with a zero value - the indicator is not calculated 


//--------------------------------------------------------------------------------------------
//--- correct draw begin 
   if(begin>0) 
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,StartCalcPosition); 
      PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,StartCalcPosition); 
      PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,StartCalcPosition);
      PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,StartCalcPosition); 
      PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,StartCalcPosition); 
      PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,StartCalcPosition); 
      PlotIndexSetInteger(6,PLOT_DRAW_BEGIN,StartCalcPosition); 
      PlotIndexSetInteger(7,PLOT_DRAW_BEGIN,StartCalcPosition); 
      
//--- start calculations, define the starting position 
    int pos;

    if (prev_calculated<DataLimit)
    {
        for(int i=0;i<=DataLimit;i++)
        {
            iCOGBuffer1[i] = 0.0;
            iCOGBuffer2[i] = 0.0;
            iPredictorBuffer[i] = 0.0;
        }
        pos = DataLimit+1;
    }
    else
    {
        pos = prev_calculated-1;
    }

//--------------------------------------------------------------------------------------------
//---------     BUFFER COPY     -------------


        //--- Average Directional Movement Indicator

    if(CopyBuffer(ADX_handle,0,0,CopyNumber,iADXBuffer)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iADX indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0);
     }
 
      //--- fill a part of the DI_plusBuffer array with values from the indicator buffer that has index 1
   if(CopyBuffer(ADX_handle,1,0,CopyNumber,iDI_plusBuffer)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iADX indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0);
     }
 
      //--- fill a part of the DI_minusBuffer array with values from the indicator buffer that has index 2
   if(CopyBuffer(ADX_handle,2,0,CopyNumber,iDI_minusBuffer)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iADX indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0);
     }


        //--- Williams R

    if(CopyBuffer(Williams_handle,0,0,CopyNumber,iWilliamsBuffer)<0)
    {
        //--- if the copying fails, tell the error code
        PrintFormat("Failed to copy data from the Williams R indicator, error code %d",GetLastError());
        //--- quit with zero result - it means that the indicator is considered as not calculated
        return(0);
    }


        //--- Moving Average
    
    if(CopyBuffer(MA_handle,0,0,CopyNumber,iMABuffer)<0)
        {
         //--- if the copying fails, tell the error code
         PrintFormat("Failed to copy data from the Moving Average indicator, error code %d",GetLastError());
         //--- quit with zero result - it means that the indicator is considered as not calculated
         return(0);
        }

//--------------------------------------------------------------------------------------------
//-----  M A I N    C A L C U L A T I O N

for(int i=pos;i<rates_total && !IsStopped();i++) 
{

    // INITIALIZING
    BuyScore = 0;
    SellScore = 0;

    // Center Of Gravity

        COG_PriceSum1 = 0;
        COG_PriceSum2 = 0;
        COG_Avg_PriceSum = 0;
        COG_Oszto = 0;
        
        
        for(int p=COG_period-1;p>=0;p--)
        {
            if((i-p)>=0)
            {
                COG_PriceSum1 += (COG_period-p) * price[i-p];
                COG_PriceSum2 += price[i-p];
            }

        };

        iCOGBuffer1[i] = (-COG_PriceSum1 / COG_PriceSum2);
        
        for(int p=0;p<(COG_period-COG_smooth);p++)
        {
            if((i-p)>0)
            {
                COG_Avg_PriceSum += iCOGBuffer1[i-p];
                COG_Oszto++;
            } else {
                COG_Avg_PriceSum += 0;
            }
        };

        COG_Avg = COG_Avg_PriceSum/COG_Oszto;
        iCOGBuffer2[i] = (COG_Avg - iCOGBuffer1[i])*1000;
        
        
   //       Average Directional Movement Indicator
      ADX_Sum_Helper1 = 0;
      ADX_Sum_Helper2 = 0;
      ADX_Sum_Helper3 = 0;
      ADX_Oszto = 0;
      
      for (int p=0;p<3;p++)
      {
         if ((i-p)>0)
         {
            ADX_Sum_Helper1 += iADXBuffer[i-p];
            ADX_Sum_Helper2 += iDI_plusBuffer[i-p];
            ADX_Sum_Helper3 += iDI_minusBuffer[i-p];
            ADX_Oszto++;
         };
      }
      
      ADX_Index1_Avg = ADX_Sum_Helper1 / ADX_Oszto;
      ADX_Index2_Avg = ADX_Sum_Helper2 / ADX_Oszto;
      ADX_Index3_Avg = ADX_Sum_Helper3 / ADX_Oszto;
      ADX_Ratio_Helper = ADX_Index2_Avg - ADX_Index3_Avg;
            
      if(ADX_Ratio_Helper>1)
      {
         ADX_Ratio_Sell = 1/ADX_Ratio_Helper;
         ADX_Ratio_Buy = 1 - ADX_Ratio_Sell;
      } else {
         ADX_Ratio_Sell = ADX_Ratio_Helper;
         ADX_Ratio_Buy = 1 - ADX_Ratio_Sell;
      };
      
      //       Williams R
      Williams_Sum_Helper = 0;
      Williams_Oszto = 0;
      
      for (int p=0;p<3;p++)
      {
         if ((i-p)>0)
         {
           Williams_Sum_Helper += iWilliamsBuffer[i-p];
           Williams_Oszto++;
         };
      };
      
      Williams_Avg = Williams_Sum_Helper / Williams_Oszto;
      
      //       Moving Average
      MA_Sum_Helper = 0;
      MA_Oszto = 0;
      
      for (int p=0;p<3;p++)
      {
           MA_Sum_Helper += iMABuffer[i-p];
           MA_Oszto++;
      };
      
      MA_Avg = MA_Sum_Helper / MA_Oszto;
      
      if (iCOGBuffer2[i]<-0.2)
      {
         SellScore+=1;
      } else if (iCOGBuffer2[i]>0.2)
      {
         BuyScore+=1;
      }
      
      if (ADX_Index1_Avg<45)
      {
         SellScore+=1;
         BuyScore+=1;
      } else {
         SellScore += -10;
         BuyScore += -10;
      };
      
      if (ADX_Ratio_Sell>0.5)
      {
         BuyScore+=1;
         SellScore--;
      } else if (ADX_Ratio_Buy>0.5)
      {
         SellScore+=1;
         BuyScore--;
      };
      
      if (Williams_Avg<-65)
      {
         BuyScore+=1;
         SellScore--;
      } else if (Williams_Avg>-35)
      {
         SellScore+=1;
         BuyScore--;
      } else {
         BuyScore+=-1;
         SellScore+=-1;
      };

      if (MA_Avg<price[i-1])
      {
         SellScore+=1;
         BuyScore-=1;
      } else if (MA_Avg>price[i-1])
      {
         BuyScore+=1;
         SellScore-=1;
      };
     
   if (BuyScore>2)
   {
      iPredictorBuffer[i]=100;
   } else if (SellScore>2)
   {
      iPredictorBuffer[i]=50;
   } else 
   {
      iPredictorBuffer[i]=75;
   };
   
   PrintFormat(DoubleToString(BuyScore));
   PrintFormat(DoubleToString(SellScore));
   PrintFormat(DoubleToString(iPredictorBuffer[i]));
    
}
//--- OnCalculate execution is complete. Return the new prev_calculated value for the subsequent call 
   return(rates_total); 
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   


};
   
//+------------------------------------------------------------------+

  
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
// CUSTOM FUNCTIONS
//+------------------------------------------------------------------+

//=================================================================================================
//--------------- L I N E   D R A W E R   --------
//=================================================================================================

//+------------------------------------------------------------------+
//| Mathematics functions                                            |
//+------------------------------------------------------------------+  

//=================================================================================================
//--------------- A N G L E    C A L C U L A T O R   --------
//=================================================================================================


double AngleCalculator  (   double y1,
                            double y2,
                            double y3,
                            double y4
                        )
{

    double RadianCalc = 57.2957795;

    double x1,x2,x3,x4;
    double vectorA1;
    double vectorA2;
    double vectorB1;
    double vectorB2;

    double CosAngle;
    double CosAngleDivision;

    double ArcCosRad;
    double Angle;

    bool blnDescending;

    x1 = 0;
    x2 = 1;
    x3 = 0;
    x4 = 1;

    if (y1>y2)
    {
        blnDescending = true;
    } else
    {
        blnDescending = false;
    };

    vectorA1 = (x2-x1);
    vectorB1 = (x4-x3);
    vectorA2 = (y2-y1);
    vectorB2 = (y4-y3);
      
    CosAngle = ((vectorA1*vectorB1+vectorA2*vectorB2) / (MathSqrt(MathPow(vectorA1,2)+MathPow(vectorA2,2)) * MathSqrt(MathPow(vectorB1,2) + MathPow(vectorB2,2))));
   
    CosAngleDivision = MathSqrt(((-1*CosAngle)*CosAngle)+1);

    //PrintFormat("CosAngle : "+DoubleToString(CosAngle) + " // CosAngle Division : " + DoubleToString(CosAngleDivision));
    
    if ((CosAngleDivision==0) || (DoubleToString(CosAngle)=="1.00000000"))
    {
      PrintFormat("Division by zero - returning.");
      return 0;
    }
    
    ArcCosRad = atan((-1*CosAngle)/CosAngleDivision) + 2 * atan(1);
    Angle = ArcCosRad * RadianCalc;

    if (Angle>90)
    {
        Angle = 180 - Angle;
    };

    if (blnDescending)
    {
        Angle = Angle * -1;
    };

    return Angle;

};

//=================================================================================================
//--------------- A B O V E    B E L O W   --------
//=================================================================================================

bool AboveBelow     (   double y2,
                        double y4
                    )
{
  if (y2>y4)
  {
      return true;
  }  else 
  {
      return false;
  };
};

//=================================================================================================
//--------------- S W I T C H    P L A C E   --------
//=================================================================================================


bool SwitchPlace       (    bool blnAbove,
                            double y2,
                            double y4
                        )
{
    if ((y2<y4) && blnAbove)
    {
        return true;
    } else if ((y2>y4) && (!blnAbove) )
    {
        return true;
    } else
    {
        return false;
    };
};

//=================================================================================================
//--------------- R I S K    C A L C U L A T E   --------
//=================================================================================================


double  RiskCalculate   (double Signal,
                        double MACD,
                        double RSI,
                        double ATR,
                        double Angle)
{
    //-------------------------------------------

    double RSI_Division_Factor = 90;
    double RSI_Short_Division_FactorB = 100;
    
    double RSI_Long_Min = 45;
    double RSI_Short_Min = 55;
    
    double ATR_Division_Factor = 15;
    double MACD_Disivion_Factor = 15;
    
    
    
    double Signal_MACD_Long_rate;
    double RSI_Long_rate;

    double Signal_MACD_Short_rate;
    double RSI_Short_rate;

    double Beta_Long_Win_Rate;
    double Beta_Short_Win_Rate;

    double Beta_Win_Diff;

    double Volatility_Diff_Ratio;
    double Beta_VolDiff_Rate = 0;

    bool LongPosition = false;
    bool ShortPosition = false;

    double Alpha_BetaFinalWin_Angle_Rate;
    double Outcome=0;

    //-------------------------------------------

    if (Angle==0)
    {
      PrintFormat("Angle is zero - returning");
      return 0;
    }
    
    
    Signal_MACD_Long_rate = ((Signal + MACD)/2)/-MACD_Disivion_Factor;
    if (RSI<RSI_Long_Min)
    {
        RSI_Long_rate = 0;    
    } else 
    {
        RSI_Long_rate = RSI / RSI_Division_Factor;
    };

    Beta_Long_Win_Rate = ((Signal_MACD_Long_rate+RSI_Long_rate)/2)*100;

    //----------------

    Signal_MACD_Short_rate = ((Signal + MACD)/2)/MACD_Disivion_Factor;
    if (RSI>RSI_Short_Min)
    {
        RSI_Short_rate = 0;    
    } else 
    {
        RSI_Short_rate = (RSI-RSI_Short_Division_FactorB) / -RSI_Division_Factor;
    };

    Beta_Short_Win_Rate = ((Signal_MACD_Short_rate+RSI_Short_rate)/2)*100;

    //----------------

    if (Beta_Long_Win_Rate > Beta_Short_Win_Rate) {
        LongPosition = true;
    } else {
        ShortPosition = true;
    }

    Beta_Win_Diff = Beta_Long_Win_Rate - Beta_Short_Win_Rate;
    Beta_Win_Diff = MathAbs(Beta_Win_Diff);
    Beta_Win_Diff = (1-10/(Beta_Win_Diff))*100;

    if (Beta_Win_Diff>100)
    {
        Beta_Win_Diff = 100;
    } else if (Beta_Win_Diff<-100)
    {
        Beta_Win_Diff = -100;
    };

    Volatility_Diff_Ratio = Beta_Win_Diff * (ATR/ATR_Division_Factor);

    if (LongPosition)
    {
        Beta_VolDiff_Rate = (Volatility_Diff_Ratio+Beta_Long_Win_Rate)/2;
    } else if (ShortPosition)
    {
        Beta_VolDiff_Rate = ((Volatility_Diff_Ratio+Beta_Short_Win_Rate)/2)*-1;
    }

    Alpha_BetaFinalWin_Angle_Rate = (Beta_VolDiff_Rate+((MathAbs(Angle)/90)*100))/2;

    if ((LongPosition && Alpha_BetaFinalWin_Angle_Rate<20) || (ShortPosition && Alpha_BetaFinalWin_Angle_Rate>-20))
    {
        Outcome = 0;
    } else 
    {
        if (Angle<0)
        {
            Outcome = Alpha_BetaFinalWin_Angle_Rate/100;
        };
    };

    if (Outcome>=1)
    {
        Outcome = 0.99;
    } else if (Outcome<=-1)
    {
        Outcome = -0.99;
    };

    return Outcome;

};

//=================================================================================================
//--------------- T  -  P R O B A  --------
//=================================================================================================


bool TProba(double &values[],
            double Elemszam,
            double Nullhipotezis,
            double hatarertek 
            )
{

   double Sum,Atlag,VegOsszeg;
   
   Sum = 0;
   
   for(int i=0;i<Elemszam;i++)
   {
      Sum += values[i];
   };

   Atlag = Sum/Elemszam;
   
   if (MathSqrt(Elemszam)!=0 && Szorasbecsles(Elemszam,values)!=0)
   {
      VegOsszeg = (Atlag - Nullhipotezis) / (Szorasbecsles(Elemszam,values)/MathSqrt(Elemszam));
   } else
   {
      PrintFormat("HIBA");
      return(false);
   }
   
   if (MathAbs(VegOsszeg)>hatarertek)
   {
      return(true);
   } else 
   {
      return(false);
   };

};

//=================================================================================================
//--------------- S Z O R A S  -  B E C S L E S   --------
//=================================================================================================


double Szorasbecsles(double Elemszam,
                     double &values[]
                     )
   {
   
      double Szabadsagfok = Elemszam - 1;
      double FirstParameter,Sum,Atlag,VegOsszeg;
      Sum = 0;
      
      FirstParameter = 1 / Szabadsagfok;
      
      for(int i=0;i<=Szabadsagfok;i++)
      {
         Sum += values[i];
      };
      
      Atlag = Sum/Elemszam;
      Sum = 0;
      
      for(int i=0;i<=Szabadsagfok;i++)
      {
         Sum += MathPow(values[i] - Atlag,2);
      };
      
      VegOsszeg = MathSqrt(FirstParameter * Sum);
      
      return(VegOsszeg);
   
   };
   
//+------------------------------------------------------------------+
//| Opening positions function                                       |
//+------------------------------------------------------------------+  

//=================================================================================================
//--------------- P L A C E   O R D E R   --------
//=================================================================================================


 void PlaceOrder(string BullOrBear,
                 double VolumeToTrade,
                 string Comm)
 
 {
 
     bool BullOpen, BearOpen;
     
     BullOpen = false;
     BearOpen = false;
     
     
     if (BullOrBear=="Bull")
     {
      BullOpen = true;
      BearOpen = false;
     } else if(BullOrBear=="Bear")
     {
      BullOpen = false;
      BearOpen = true;
     };
     
    //--- declare and initialize the trade request and result of trade request
      MqlTradeRequest request={0};
      MqlTradeResult  result={0};
   //--- parameters of request
      request.action   =TRADE_ACTION_DEAL;                     // type of trade operation
      request.symbol   =Symbol();                              // symbol
      if (BullOpen==true)
      {
         request.volume   =VolumeToTrade*1;
      } else {
         request.volume   =VolumeToTrade*0.1;
      };
      
      if (BullOpen==true) {
         request.type     =ORDER_TYPE_BUY;
         request.price    =SymbolInfoDouble(Symbol(),SYMBOL_ASK);
      } else {
         request.type     =ORDER_TYPE_SELL;
         request.price    =SymbolInfoDouble(Symbol(),SYMBOL_BID);
      };
      request.deviation=5;                                     // allowed deviation from the price
      request.magic    =123456;                          // MagicNumber of the order
      request.comment = Comm;
   //--- send the request
      if(!OrderSend(request,result))
         {
         PrintFormat("OrderSend error %d",GetLastError());     // if unable to send the request, output the error code
         }
   //--- information about the operation
      //PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
   
 };


//+------------------------------------------------------------------+
//| Closing orders function                                          |
//+------------------------------------------------------------------+

//=================================================================================================
//--------------- C L O S E   O R D E R  -  V E R S I O N  -  1 S T  --------
//=================================================================================================


void CloseOrders(double ProfitPercent,double LosePercent)
{
   bool BearClose,BullClose;
   
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total=PositionsTotal(); // number of open positions   
   //--- iterate over all open positions
   for(int i=total-1; i>=0; i--)
     {
      //--- parameters of the order
      BearClose = false;
      BullClose = false;
      ulong  position_ticket=PositionGetTicket(i);                                      // ticket of the position
      string position_symbol=PositionGetString(POSITION_SYMBOL);                        // symbol 
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);              // number of decimal places
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber of the position
      double volume=PositionGetDouble(POSITION_VOLUME);                                 // volume of the position
      string Comm = PositionGetString(POSITION_COMMENT);                                // comment of the position
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // type of the position
      //--- output information about the position
      /*PrintFormat("#%I64u %s  %s  %.2f  %s [%I64d]",
                  position_ticket,
                  position_symbol,
                  EnumToString(type),
                  volume,
                  DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                  magic);
      */
      //--- if the MagicNumber matches
      if(magic==123456)
        {
         //--- zeroing the request and result values
         ZeroMemory(request);
         ZeroMemory(result);
         //--- setting the operation parameters
         request.action   =TRADE_ACTION_DEAL;        // type of trade operation
         request.position =position_ticket;          // ticket of the position
         request.symbol   =position_symbol;          // symbol 
         request.volume   =volume;                   // volume of the position
         request.deviation=5;                        // allowed deviation from the price
         request.magic    =123456;             // MagicNumber of the position
         //--- set the price and order type depending on the position type
         if(type==POSITION_TYPE_BUY)
           {
            request.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
            request.type =ORDER_TYPE_SELL;
            if (((PositionGetDouble(POSITION_PROFIT))>(PositionGetDouble(POSITION_PRICE_OPEN)*ProfitPercent)) || ((PositionGetDouble(POSITION_PROFIT))<(PositionGetDouble(POSITION_PRICE_OPEN)*(-1)*LosePercent)))
            {
               BullClose = true;
            };
           }
         else
           {
            request.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
            request.type =ORDER_TYPE_BUY;
            if (((PositionGetDouble(POSITION_PROFIT))>(PositionGetDouble(POSITION_PRICE_OPEN)*ProfitPercent)) || ((PositionGetDouble(POSITION_PROFIT))<(PositionGetDouble(POSITION_PRICE_OPEN)*(-1)*LosePercent)))
            {
               BearClose = true;
            };
           };
         //--- output information about the closure
        
         //--- send the request
         if (BearClose==true || BullClose==true)
         {
            //PrintFormat("Close #%I64d %s %s",position_ticket,position_symbol,EnumToString(type));
            
            if (PositionGetDouble(POSITION_PROFIT)>0)
            {
              request.comment = Comm + " / Profit: " + DoubleToString(PositionGetDouble(POSITION_PROFIT));
              ProfitTransaction += 1;
            } else {
              request.comment = Comm + " / Loss: " + DoubleToString(PositionGetDouble(POSITION_PROFIT));
              LoseTransaction += 1;
            };
            
            
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
            //--- information about the operation   
            //PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            //-- 
         };
        }
     }
 };

//================================================================================================= 
//--------------- C L O S E   O R D E R  -  V E R S I O N  -  2 N D   --------
//=================================================================================================

 
void CloseOrders_Version2(double ChangeLowAvg)
{
   bool BearClose,BullClose;
   
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total=PositionsTotal(); // number of open positions   
   //--- iterate over all open positions
   for(int i=total-1; i>=0; i--)
     {
      //--- parameters of the order
      BearClose = false;
      BullClose = false;
      ulong  position_ticket=PositionGetTicket(i);                                      // ticket of the position
      string position_symbol=PositionGetString(POSITION_SYMBOL);                        // symbol 
      int    digits=(int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);              // number of decimal places
      ulong  magic=PositionGetInteger(POSITION_MAGIC);                                  // MagicNumber of the position
      double volume=PositionGetDouble(POSITION_VOLUME);                                 // volume of the position
      string Comm = PositionGetString(POSITION_COMMENT);                                // comment of the position
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);    // type of the position
      double Position_Risk = StringToDouble(Comm);
      //--- output information about the position
      /*PrintFormat("#%I64u %s  %s  %.2f  %s [%I64d]",
                  position_ticket,
                  position_symbol,
                  EnumToString(type),
                  volume,
                  DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),digits),
                  magic);
      */
      //--- if the MagicNumber matches
      if(magic==123456)
        {
         //--- zeroing the request and result values
         ZeroMemory(request);
         ZeroMemory(result);
         //--- setting the operation parameters
         request.action   =TRADE_ACTION_DEAL;        // type of trade operation
         request.position =position_ticket;          // ticket of the position
         request.symbol   =position_symbol;          // symbol 
         request.volume   =volume;                   // volume of the position
         request.deviation=5;                        // allowed deviation from the price
         request.magic    =123456;             // MagicNumber of the position
         //--- set the price and order type depending on the position type
         if(type==POSITION_TYPE_BUY)
           {
            request.price=SymbolInfoDouble(position_symbol,SYMBOL_BID);
            request.type =ORDER_TYPE_SELL;
            if (ChangeLowAvg<-2)
            {
               BullClose = true;
            };
           }
         else
           {
            request.price=SymbolInfoDouble(position_symbol,SYMBOL_ASK);
            request.type =ORDER_TYPE_BUY;
            if (ChangeLowAvg>2)
            {
               BearClose = true;
            };
           };
         //--- output information about the closure
        
         //--- send the request
         if (BearClose==true || BullClose==true)
         {
            //PrintFormat("Close #%I64d %s %s",position_ticket,position_symbol,EnumToString(type));
            
            if (PositionGetDouble(POSITION_PROFIT)>0)
            {
              request.comment = Comm + " / Profit: " + DoubleToString(PositionGetDouble(POSITION_PROFIT));
              ProfitTransaction += 1;
            } else {
              request.comment = Comm + " / Loss: " + DoubleToString(PositionGetDouble(POSITION_PROFIT));
              LoseTransaction += 1;
            };
            
            
            if(!OrderSend(request,result))
               PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
            //--- information about the operation   
            //PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
            //-- 
         };
        }
     }
 };
 


//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
//--- time of the OnTimer() first call 
   static datetime start_time=TimeCurrent(); 
   
//--- trade server time during the first OnTimer() call 
   static datetime start_tradeserver_time=0; 
   
//--- calculated trade server time 
   static datetime calculated_server_time=0; 
   
//--- local PC time 
   datetime local_time=TimeLocal(); 
   
//--- current estimated trade server time 
   datetime trade_server_time=TimeTradeServer(); 
   
//--- if a server time is unknown for some reason, exit ahead of time 
   if(trade_server_time==0) 
      return; 
      
//--- if the initial trade server value is not set yet 
   if(start_tradeserver_time==0) 
     { 
      start_tradeserver_time=trade_server_time; 
//--- set a calculated value of a trade server       
      Print(trade_server_time); 
      calculated_server_time=trade_server_time; 
     } 
   else 
     { 
//--- increase time of the OnTimer() first call 
      if(start_tradeserver_time!=0) 
         calculated_server_time=calculated_server_time+1;; 
     } 
//---  
   string com=StringFormat("                  Start time: %s\r\n",TimeToString(start_time,TIME_MINUTES|TIME_SECONDS)); 
   com=com+StringFormat("                  Local time: %s\r\n",TimeToString(local_time,TIME_MINUTES|TIME_SECONDS)); 
   com=com+StringFormat("TimeTradeServer time: %s\r\n",TimeToString(trade_server_time,TIME_MINUTES|TIME_SECONDS)); 
   com=com+StringFormat(" EstimatedServer time: %s\r\n",TimeToString(calculated_server_time,TIME_MINUTES|TIME_SECONDS)); 
   com=com+StringFormat(" P/L in previous 24 hours: %s\r\n",DoubleToString(ProfitLossSUM)); 
//--- display values of all counters on the chart 
   Comment(com); 
   
   ProfitLossSUM = 0;
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| TesterDeinit function                                            |
//+------------------------------------------------------------------+
void OnTesterDeinit()
  {
//---
   PrintFormat("Profitable transactions: " + IntegerToString(ProfitTransaction));
   PrintFormat("Loss transactions: " + IntegerToString(LoseTransaction));
  }
//+------------------------------------------------------------------+
