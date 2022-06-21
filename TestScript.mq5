//+------------------------------------------------------------------+
//|                                                   TestScript.mq5 |
//|                                    Copyright 2022, Omega Joctan. |
//|                        https://www.mql5.com/en/users/omegajoctan |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Omega Joctan."
#property link      "https://www.mql5.com/en/users/omegajoctan"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//#include "DecisionTreeLib.mqh";
#include "decisiontree_2.mqh";
CDecisionTree *tree;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
    tree  = new CDecisionTree();
    
    string file_name = "PlayTennis vs wheather.csv";
    
    tree.Init(6,"2,3,4,5",file_name); 
    tree.BuildTree();
    
    delete (tree);
  
  }
//+------------------------------------------------------------------+
