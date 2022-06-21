No licence free of use/copy open source library
all the information about the library and the code used in this repo can be found on my Article about Decision Trees in mql5 linked
here https://www.mql5.com/en/articles/11061/113599

### To start using the library add these line of code to your script

```
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
```

### I welcome any thoughts,

Any contribution to the library will be appreciated

# Support the Project
This is a free and open-source project that has cost me time to figure things out and to present in an easy to use and a friendly manner, kindly donate to the project on this link https://www.buymeacoffee.com/omegajoctan if you appreciate the effort

# Hire me on your next big Project on Machine Learning
hire me to create trading robots, indicators or scripts based on 
***
    * Neural Networks
    * Linear Regressions
    * Support Vector Machine
    * Logistic Regressions
    * Classification trees
    * and many more Aspects of machine learning 

Using this link https://www.mql5.com/en/job/new?prefered=omegajoctan