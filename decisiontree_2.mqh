//+------------------------------------------------------------------+
//|                                              DecisionTreeLib.mqh |
//|                                    Copyright 2022, Omega Joctan. |
//|                        https://www.mql5.com/en/users/omegajoctan |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Omega Joctan."
#property link      "https://www.mql5.com/en/users/omegajoctan"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CDecisionTree
  {
      private:             
                           string  TargetArr[];                 //TargetArr Variable 
                           string  m_dataset[];                 //all the independent variables + dependent variable
                           string  m_DatasetClasses[];          //class(es) available inside our Independent variable
                           string  DataColumnNames[];           //string of all the columns names
                           
                           
                           string  tree_file;
                           int     _n;   //for counting Column names
                           int     m_targetvar_column;
                           int     m_colschosen; //columns chosen from our dataset
                           int     rows_total;  //all the rows total combined from dataset
                           string  m_dataColsArray[];  //string of numbers of columns chosen
                           
                           int     single_rowstotal;  //single column rows total
                           bool    m_debug;
                           int     m_handle;
                           string  m_delimiter;
                           string  m_filename;
                           
      protected:
                           bool    fileopen();  
                           void    GetAllDataToArray(string &toArr[]); 
                           void    GetColumnDatatoArray(int from_column_number, string &toArr[]);
                           void    MatrixRemoveRow(string &dataArr[], string content_detect, int cols);
                           void    MatrixRemoveColumn(string &dataArr[],int column,int rows);
                           void    MatrixClassify(string &dataArr[], string &Classes[],int cols);
                           void    MatrixPrint(string &Matrix[],int rows,int cols,int digits=0);
                           void    MatrixUnTranspose(string &Matrix[],int torows, int tocolumns);
                           void    GetClasses(string &Array[],string &Classes[],int &ClassNumbers[]);
                           void    GetSamples(string &Array[],string &ArrTarget[], string Class, int &SamplesNumbers[]);
                           
                           double  Entropy(int &SampleNumbers[], int total);               
                           double  InformationGain(double parent_entropy, double &EntropyArr[], int &ClassNumbers[], int rows_);                                   
                           double  Proba(int number,double total); //find the probability function
                           double  log2(double value);  //find the log of base 2
                           
                           void    DrawTree(string &Classes[],string node, int index);
      
      public:              
                           void    Init(int targetvar_column,string x_columns,string filename,string delimiter=",",bool debugmode=true);
                           void    BuildTree();
                           
                           CDecisionTree(void);
                          ~CDecisionTree(void);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDecisionTree::CDecisionTree(void)
 {
   ArrayResize(m_DatasetClasses,2); //classes in our target variable
   
   tree_file = "decisiontree.txt";
   FileDelete(tree_file); //delete this output file if it exists
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CDecisionTree::~CDecisionTree(void)
 {
   ArrayFree(TargetArr);
   ArrayFree(m_dataset); 
   ArrayFree(DataColumnNames);
   ArrayFree(m_dataColsArray);
   ArrayFree(m_DatasetClasses);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDecisionTree::Init(int targetvar_column,string x_columns,string filename,string delimiter=",",bool debugmode = true)
 {
   m_targetvar_column = targetvar_column;
   m_filename = filename;
   m_delimiter = delimiter;
   m_debug = debugmode;
   
//---

   ushort separator = StringGetCharacter(m_delimiter,0);
   StringSplit(x_columns,separator,m_dataColsArray);
   ArrayResize(m_dataColsArray,ArraySize(m_dataColsArray)+1);  //plus the independent variables column
   
   int dataset_cols = ArraySize(m_dataColsArray);
   
   m_colschosen = dataset_cols;
   
   ArrayResize(DataColumnNames,m_colschosen); 
   
   m_dataColsArray[m_colschosen-1] = string(targetvar_column); //Add the target variable to the last column

//---
   
   GetAllDataToArray(m_dataset);
   GetColumnDatatoArray(targetvar_column,TargetArr);
   
   if (rows_total % m_colschosen != 0)
     Alert("There is variance(s) in your dataset rows, Calculations may fall short");
   
   else   
      single_rowstotal = rows_total/m_colschosen;
   
//--- 
   
   MatrixUnTranspose(m_dataset,m_colschosen,single_rowstotal); //we untranspose the Array to be in Matrix human-readable form
  
  
   if (m_debug)
    {
      Print("The Entire Dataset \nEach Columns rows  =",single_rowstotal," Columns =",m_colschosen);
      
      ArrayPrint(DataColumnNames);
      MatrixPrint(m_dataset,m_colschosen,single_rowstotal); //To Print the matrix put rows in a place of columns and viceversa
   
      PrintFormat("Target variable %s",DataColumnNames[m_colschosen-1]);
      MatrixPrint(TargetArr,1,single_rowstotal);
    }
   
//---
 
    /* 
      printf("%s classes",DataColumnNames[m_colschosen-1]);
      ArrayPrint(m_DatasetClasses);
      ArrayPrint(ClassNumbers,0,"      ");
   */
//---
   
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDecisionTree::GetClasses(string &Array[],string &Classes[],int &ClassNumbers[])
 {
     string TempArr[], TempArr2[];
     ArrayCopy(TempArr,Array);
     ArrayCopy(TempArr2,TempArr);
     
//--- find classified contents
        
     string Content;
     int n_classes=0, total_class_contents=0;
     
     for (int i=0; i<ArraySize(TempArr); i++)
       {
         int counter = 0; //for counting the same contents
         
           for (int j=0; j<ArraySize(TempArr2); j++)
              {
                if (TempArr[i] == TempArr2[j])
                    {                              
                        counter++;
                        
                        if (counter==1)
                          Content = TempArr2[j]; //Get the first element of the class
                        
                        TempArr2[j] = NULL; //we put null to all the values we have already counted to avoid counting them again
                         
                        if (counter > ArraySize(TempArr))
                           break; //Get out of this loop as it might be an Infinity one              
                    }
              }           
//---
             
             if (counter>0) //if new different class has been detected
                {            
                    total_class_contents += counter;
                      
                    n_classes++;
                    ArrayResize(Classes,n_classes);
                    ArrayResize(ClassNumbers,n_classes);
                    
                    ClassNumbers[n_classes-1] = counter;
                    Classes[n_classes-1] = Content;
                     
                    //if (m_debug) printf("There are %d %s total_class_contents =%d ",counter,Content,total_class_contents);
               }
//---
           if ( total_class_contents >= ArraySize(TempArr))
                break; //we are done getting the numbers get out of the loop
      }
      
      
     ArrayFree(TempArr);
     ArrayFree(TempArr2);  
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDecisionTree::GetSamples(string &Array[], string &ArrTarget[], string Class, int &SamplesNumbers[])
 {
     ArrayResize(SamplesNumbers,ArraySize(m_DatasetClasses));
      
     if (ArraySize(Array) != ArraySize(ArrTarget))
      Print("There is unequal size of Array and Its target Array in Funtion", __FUNCTION__);
            
       for (int i=0; i<ArraySize(m_DatasetClasses); i++) 
        {
          int counter =0;
          for (int j=0; j<ArraySize(Array); j++)
             if (Class == Array[j]) 
              {
                  if (ArrTarget[j] == m_DatasetClasses[i])
                      counter++;
              }
              
            //if (m_debug) Print(Class," counter ",counter," ",m_DatasetClasses[i]);
            SamplesNumbers[i] = counter;   
       }      
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDecisionTree::BuildTree(void)
 {   
    int ClassNumbers[];
    
    int max_gain = 0;
    double IGArr[]; 
    //double parent_entropy = Entropy(p_ClassNumbers,single_rowstotal);
    
    string p_Classes[];     //parent classes
    double P_EntropyArr[];  //Parent Entropy
    int p_ClassNumbers[]; //parent/ Target variable class numbers
    
    GetClasses(TargetArr,m_DatasetClasses,p_ClassNumbers);
    
    ArrayResize(P_EntropyArr,1);
    P_EntropyArr[0] = Entropy(p_ClassNumbers,single_rowstotal);

//--- temporary disposable arrays for parent node information

   string TempP_Classes[];
   double TempP_EntropyArr[];
   int    TempP_ClassNumbers[];
   
//---

    if (m_debug) Print("Default Parent Entropy ",P_EntropyArr[0]);
   
    int cols = m_colschosen; 
     
        
      for (int A =0; A<ArraySize(P_EntropyArr); A++)  
        {
           printf("<<<<<<<<    Parent Entropy  %.5f  A = %d  >>>>>>>> ",P_EntropyArr[A],A);
           
           
             for (int i=0; i<cols-1; i++) //we substract with one to remove the independent variable coumn
               {
                  int rows = ArraySize(m_dataset)/cols;
                    
                    string Arr[]; //ArrayFor the current column
                    string ArrTarg[]; //Array for the current target
                    
                    ArrayResize(Arr,rows);
                    ArrayResize(ArrTarg,rows);
                    
                       printf("   <<<<<   C O L U M N  %s   >>>>>  ",DataColumnNames[i]);
                       int index_target=cols-1;
                       for (int j=0; j<rows; j++) //get column data and its target column
                          {
                              int index = i+j * cols;
                              //Print("index ",index);
                              Arr[j] = m_dataset[index];
         
                              //printf("ArrTarg[%d] = %s m_dataset[%d] =%s ",j,ArrTarg[j],index_target,m_dataset[index_target]);
                              ArrTarg[j] = m_dataset[index_target];
                              
                              //printf("Arr[%d] = %s ArrTarg[%d] = %s ",j,Arr[j],j,ArrTarg[j]); 
                              
                              index_target += cols; //the last index of all the columns
                          }  
                        
                        //Print("Target Array");
                        //ArrayPrint(ArrTarg);
         //---
                        string Classes[];  
                        
                        GetClasses(Arr,Classes,ClassNumbers); 
                        //ArrayPrint(Classes);
                        //ArrayPrint(ClassNumbers);
         
         //--- Finding the Entropy
                        
                        int SamplesNumbers[];
                        double EntropyArr[];
                        ArrayResize(EntropyArr,ArraySize(ClassNumbers));
                        
                        for (int k=0; k<ArraySize(ClassNumbers); k++)
                          {
                                              
                             GetSamples(Arr,ArrTarg,Classes[k],SamplesNumbers);
                             Print("     <<   ",Classes[k],"   >> total > ",ClassNumbers[k]);
                             
                                
                             ArrayPrint(m_DatasetClasses);
                             ArrayPrint(SamplesNumbers);
                             
                             EntropyArr[k] = Entropy(SamplesNumbers,ClassNumbers[k]);
                             
                             //Print("Arraysize Class numbers ",ArraySize(ClassNumbers));
                             printf("Entropy of %s = %.5f",Classes[k],Entropy(SamplesNumbers,ClassNumbers[k]));  
                             
                          }
                        
         //--- Finding the Information Gain
                        
                        ArrayResize(IGArr,i+1); //information gains matches the columns number
                        
                        IGArr[i] = InformationGain(P_EntropyArr[A],EntropyArr,ClassNumbers,rows);
                        
                        max_gain = ArrayMaximum(IGArr); 
                        
                        if (m_debug)
                           printf("<<<<<<  Column Information Gain %.5f >>>>>> \n",IGArr[i]);

//---

                        if (i == max_gain)
                         { 
                           //printf("Max gain found the EntropyArray is i =%d max_gain = %d",i,max_gain);
                           
                           ArrayCopy(TempP_Classes,Classes);
                           ArrayCopy(TempP_EntropyArr,EntropyArr);
                           ArrayCopy(TempP_ClassNumbers,ClassNumbers);
                         }
                  
         //---
                  
                  ZeroMemory(ClassNumbers);
                  ZeroMemory(SamplesNumbers);
                  
               }
               
         //---- Get the parent Entropy, class and class numbers
               
                  ArrayCopy(p_Classes,TempP_Classes);
                  ArrayCopy(P_EntropyArr,TempP_EntropyArr);
                  ArrayCopy(p_ClassNumbers,TempP_ClassNumbers);
               
         //---
         
            string Node[1]; 
            Node[0] = DataColumnNames[max_gain];
            
            if (m_debug)
            printf("Parent Node will be %s with IG = %.5f",Node[0],IGArr[max_gain]);
            
            if (A == 0)
             DrawTree(Node,"parent",A);
             
             DrawTree(p_Classes,"child",A);
            
            if (m_debug)
            {
               Print("Parent Entropy Array and Class Numbers");
               ArrayPrint(p_Classes);
               ArrayPrint(P_EntropyArr);
               ArrayPrint(p_ClassNumbers);
               //Print("New Array");
               //MatrixPrint(m_dataset,cols,rows_total);
            }
            
         //---  CLASSIFY THE MATRIX
         MatrixClassify(m_dataset,p_Classes,cols);
         
         if (m_debug)
          {
            Print("Classified matrix dataset");
            ArrayPrint(DataColumnNames);
            MatrixPrint(m_dataset,cols,ArraySize(m_dataset));
          }
          
         //--- Search if there is zero entropy in Array
         
            int zero_entropy_index = 0;
            bool zero_entropy = false;
            for (int e=0; e<ArraySize(P_EntropyArr); e++)
              if (P_EntropyArr[e] == 0) { zero_entropy = true; zero_entropy_index=e; break; }
            
            if (zero_entropy) //if there is zero in the Entropy Array 
              {
                MatrixRemoveRow(m_dataset,p_Classes[zero_entropy_index],cols);    
               
                rows_total = ArraySize(m_dataset); //New number of total rows from Array   
                 if (m_debug)
                  {
                    printf("%s is A LEAF NODE its Rows have been removed from the dataset remaining Dataset is ..",p_Classes[zero_entropy_index]);
                    ArrayPrint(DataColumnNames);
                    MatrixPrint(m_dataset,cols,rows_total);
                  }
                
                //we also remove the entropy form the Array and its information everywehre else from the parent Node That we are going ot build next
                
                ArrayRemove(P_EntropyArr,zero_entropy_index,1);
                ArrayRemove(p_Classes,zero_entropy_index,1);
                ArrayRemove(p_ClassNumbers,zero_entropy_index,1);
              }
            
            if (m_debug)  
             Print("rows total ",rows_total," ",p_Classes[zero_entropy_index]," ",p_ClassNumbers[zero_entropy_index]);
            
//---    REMOVING THE PARENT/ ROOT NODE FROM OUR DATASET

            MatrixRemoveColumn(m_dataset,max_gain,cols);
         
         // After removing the columns assing the new values to these global variables
         
            cols = cols-1;   // remove that one column that has been removed
            rows_total = rows_total - single_rowstotal; //remove the size of one column rows
            
         // we also remove the column from column names Array 
            ArrayRemove(DataColumnNames,max_gain,1);

//---

            printf("Column %d removed from the Matrix, The remaining dataset is",max_gain+1);
            ArrayPrint(DataColumnNames);
            MatrixPrint(m_dataset,cols,rows_total);
            
//---

            Print("Final Parent Entropy Array and Class Numbers");
            ArrayPrint(p_Classes);
            ArrayPrint(P_EntropyArr);
            ArrayPrint(p_ClassNumbers); 
         
      }

//--- free the memory

    ArrayFree(TempP_ClassNumbers);
    ArrayFree(TempP_Classes);
    ArrayFree(TempP_EntropyArr);
    ArrayFree(p_ClassNumbers);
    ArrayFree(p_Classes);
    ArrayFree(P_EntropyArr);  
    ArrayFree(ClassNumbers); 
    ArrayFree(IGArr);
      
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDecisionTree::DrawTree(string &Classes[],string node, int index)
 {
     
    int file_handle = FileOpen(tree_file,FILE_WRITE|FILE_READ|FILE_ANSI|FILE_TXT,",");
    
    if (file_handle != INVALID_HANDLE)
      {
        string left =  "  ";
        string right = "  ";        
        
//--- Concatenate String from Array
      
      if (node == "root")
        {
            string write = "";
            for (int i=0; i<ArraySize(Classes); i++)
              {
                write += Classes[i];
                for (int j=0; j<int(single_rowstotal/2.5); j++)
                  {
                    left += left;
                    right = left;
                  }
                write = left + write + right; 
              }  
            
           FileWrite(file_handle,write);
           FileWrite(file_handle," "); //put a space
           FileWrite(file_handle," "); //put a space
       }
//---
       else if (node == "child")
          {
          
           left =  "    ";
           right = " ";      
           
            string write = "";
             for (int A = 0; A<index; A++)
               for (int i=0; i<ArraySize(Classes); i++)
                 {
                   for (int j=0; j<int(single_rowstotal/2.5); j++)
                       left += left;
                    
                     
                   StringSetLength(left,uint(MathSqrt(StringLen(left))));
                   right = left+left; 
                   write += left + Classes[i] + right;
                   
                 }  
          //---
               
             if (FileSeek(file_handle,0,SEEK_END)) 
              {
                 FileWrite(file_handle,write);      
                 FileWrite(file_handle," "); //put a space
                 FileWrite(file_handle," "); //put a space 
                 FileWrite(file_handle," "); //put a space
                 FileWrite(file_handle," "); //put a space
              }
            }
        else Print("Unknown Node, Could draw it to ",tree_file);
        
        FileClose(file_handle);
      }
    else
        printf("Could not draw a decision Tree to file %s Invalid File Handle Err %d ",tree_file,GetLastError());
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDecisionTree::MatrixClassify(string &dataArr[],string &Classes[], int cols)
 {
   string ClassifiedArr[];
   ArrayResize(ClassifiedArr,ArraySize(dataArr));
   
   int fill_start = 0, fill_ends = 0;
   int index = 0;
   for (int i = 0; i<ArraySize(Classes); i++)
     {
      int start = 0;  int curr_col = 0;
      for (int j = 0; j<ArraySize(dataArr); j++)
        { 
          curr_col++;
          
            if (Classes[i] == dataArr[j])
              {
                //printf("Classes[%d] = %s dataArr[%d] = %s ",i,Classes[i],j,dataArr[j]);
                
                 if (curr_col == 1) 
                     fill_start =  j;
                 else
                   {
                      if (j>curr_col)
                        fill_start = j - (curr_col-1);
                      else fill_start = (curr_col-1) - j;
                          
                      fill_start  = fill_start;
                      //Print("j ",j," j-currcol ",j-(curr_col-1)," curr_col ",curr_col," columns ",cols," fill start ",fill_start );
                      
                   }
                 
                 fill_ends = fill_start + cols; 
                 
                 //printf("fillstart %d fillends %d j index = %d i = %d ",fill_start,fill_ends,j,i);
//---
                  //if (ArraySize(ClassifiedArr) >= ArraySize(dataArr)) break;
                  //Print("ArraySize Classified Arr ",ArraySize(ClassifiedArr)," dataArr size ",ArraySize(dataArr)," i ",i);
                  
                  
                  for (int k=fill_start; k<fill_ends; k++)
                    {
                      index++;
                      //printf(" k %d index %d",k,index);
                      //printf("dataArr[%d] = %s index = %d",k,dataArr[k],index-1);
                      ClassifiedArr[index-1] = dataArr[k];
                    }
                    
                if (index >= ArraySize(dataArr)) break; //might be infinite loop if this occurs
              }
              
          if (curr_col == cols) curr_col = 0;
        } 
         
      if (index >= ArraySize(dataArr)) break; //might be infinite loop if this occurs
     }
     
    ArrayCopy(dataArr,ClassifiedArr);
    ArrayFree(ClassifiedArr);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDecisionTree::MatrixRemoveRow(string &dataArr[], string content_detect, int cols)
 {
    int curr_col = 0; //The current column we are at
    int fill_start = 0, fill_ends = 0;
    
    for (int i=0; i<ArraySize(dataArr); i++)
       {
          curr_col++;   
          
           if (dataArr[i] == content_detect)
             {
                 if (curr_col == 1) 
                     fill_start =  i;
                 else
                   {
                     fill_start = i-curr_col;
                   }
                  
                 
                 fill_ends = fill_start + cols; 
                  
                 //printf("fill start %d ends %d",fill_start,fill_ends);
                 //ArrayPrint(dataArr,0,NULL,fill_start,fill_ends-fill_start);
                 
                 //Arrayfill string 
                  for (int j=fill_start; j<fill_ends; j++)
                    dataArr[j] = NULL;
                 
             }
//---
          if (curr_col == cols) curr_col = 0;
       }
       
//--- Now it's time to remove all the NULL

      string NewArr[];
      int index=0;
      
      for (int i=0; i<ArraySize(dataArr); i++,)
       {
        if (dataArr[i] != NULL)
           { 
               index++;
               ArrayResize(NewArr,index);
               
               NewArr[index-1] = dataArr[i];
           }
           
         if (index > ArraySize(dataArr)) //this might be infinite loop
           break;
       }  
       
     ArrayFree(dataArr);
     ArrayCopy(dataArr,NewArr);    
     ArrayFree(NewArr); //dump this Array
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDecisionTree::MatrixRemoveColumn(string &dataArr[],int column,int rows)
 {
    int index = column;
      for (int i=0; i<ArraySize(dataArr); i++)
         {
           //Print("i = ",i," column ",column);
            dataArr[column] = NULL;
            
            column += rows;
            
            if (column >= ArraySize(dataArr))
              break; //were done adding null values
         }
//--- After we've just put the null values it's time to remove those null values
      
      for (int i=-0; i<ArraySize(dataArr); i++)
        if (dataArr[i] == NULL)
          ArrayRemove(dataArr,i,1); //remove that specific item only
      
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDecisionTree::Entropy(int &SampleNumbers[],int total)
 {
    double Entropy = 0;
    double entropy_out =0; //the value of entropy that will be returned
     
     for (int i=0; i<ArraySize(SampleNumbers); i++)
        {       
            if (SampleNumbers[i] == 0) { Entropy = 0; break; } //Exception
            
              double probability1 = Proba(SampleNumbers[i],total); 
              Entropy += probability1 * log2(probability1);
        }
     
     if (Entropy==0)     entropy_out = 0;  //handle the exception
     else                entropy_out = -Entropy;
    
    return(entropy_out);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDecisionTree::InformationGain(double parent_entropy, double &EntropyArr[], int &ClassNumbers[], int rows_)
 {
    double IG = 0;
    
    for (int i=0; i<ArraySize(EntropyArr); i++)
      {  
        double prob = ClassNumbers[i]/double(rows_); 
        IG += prob * EntropyArr[i];
      }
     
     return(parent_entropy - IG);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDecisionTree::Proba(int number,double total)
 {
    return(number/total);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CDecisionTree::log2(double value)
 {
   return (log10(value)/log10(2));
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CDecisionTree::fileopen(void)
 { 
    m_handle  = FileOpen(m_filename,FILE_READ|FILE_CSV|FILE_ANSI,m_delimiter); 

    if (m_handle == INVALID_HANDLE)
      {
         return(false);
         Print(__FUNCTION__," Invalid csv handle err=",GetLastError());
      }
   return (true);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDecisionTree::GetAllDataToArray(string &toArr[])
 {
    int counter=0; 
    for (int i=0; i<ArraySize(m_dataColsArray); i++)
      {                    
        if (fileopen())
         {  
          int column = 0, rows=0;
          while (!FileIsEnding(m_handle))
            {
              string data = FileReadString(m_handle);

              column++;
   //---      
              if (column==(int)m_dataColsArray[i])
                 {                      
                     if (rows>=1) //Avoid the first column which contains the column's header
                       {   
                           counter++;
                           
                           ArrayResize(toArr,counter); //array size for all the columns 
                           toArr[counter-1]=data;
                       }   
                     else 
                        DataColumnNames[i]=data;
                 }
   //---
              if (FileIsLineEnding(m_handle))
                {                     
                   rows++;
                   column=0;
                }
            } 
          rows_total += rows-1; //since we are avoiding the first row we have to also remove it's number on the list here
          //adding a plus equals sign to rows total ensures that we get the total number of rows for the entire dataset
          
        }
         FileClose(m_handle); 
     }
    
    if (m_debug)
     Print("All data Array Size ",ArraySize(toArr)," consuming ", sizeof(toArr)," bytes of memory");
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDecisionTree::GetColumnDatatoArray(int from_column_number, string &toArr[])
 {
    int counter=0;
    int column = 0, rows=0;
    
    fileopen(); 
    while (!FileIsEnding(m_handle))
      {
        string data = FileReadString(m_handle);
        column++;
//---      
        if (column==from_column_number)
           {
               if (rows>=1) //Avoid the first column which contains the column's header
                 {   
                     counter++;
                     ArrayResize(toArr,counter); 
                     toArr[counter-1]=data;
                 }   
           }
//---
        if (FileIsLineEnding(m_handle))
          {                     
            rows++;
            column=0;
          }
      }
    
    FileClose(m_handle);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDecisionTree::MatrixPrint(string &Matrix[],int rows,int cols,int digits=0) 
 {
   Print("[ ");
   int start = 0; 
    //if (rows>=cols)
      for (int i=0; i<cols; i++)
        {
          ArrayPrint(Matrix,digits,NULL,start,rows);
          start += rows;     
        } 
   printf("] \ncolumns = %d rows = %d",rows,cols);
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CDecisionTree::MatrixUnTranspose(string &Matrix[],int torows, int tocolumns)
 {
    int rows, columns;
    
    string Temp_Mat[]; //temporary array
  
      rows = torows;
      columns = tocolumns;
       
//--- UnTransposing Array Starting

          ArrayResize(Temp_Mat,ArraySize(Matrix));
          
          int index=0; int start_incr = 0;
          
           for (int C=0; C<columns; C++)
              {
                 start_incr= C; //the columns are the ones resposible for shaping the new array
                 
                  for (int R=0; R<rows; R++, index++) 
                     {
                       //if (m_debug)
                       //Print("Old Array Access key = ",index," New Array Access Key = ",start_incr);
                       
                       Temp_Mat[index] = Matrix[start_incr];                       
                       
                       start_incr += columns;
                     }
                     
              }
       
       ArrayCopy(Matrix,Temp_Mat);
       ArrayFree(Temp_Mat);
      
 }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
