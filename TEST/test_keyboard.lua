run    = true
hTable = nil


--------------------------------------------------------------------OnInit
function OnInit(path)  
  
   hTable = AllocTable() 
 
   AddColumn(hTable,1 ,"", true, QTABLE_STRING_TYPE, 10)
   AddColumn(hTable,2 ,"SO limit price", true, QTABLE_STRING_TYPE, 10)
   
   AddColumn(hTable,3, "SO real price",true,QTABLE_STRING_TYPE,10)
   AddColumn(hTable,4, "TP price",true, QTABLE_STRING_TYPE,10)
   AddColumn(hTable,5, "SL limit price",true, QTABLE_STRING_TYPE,10)
   AddColumn(hTable,6, "SL price",true, QTABLE_STRING_TYPE,10)
   
   AddColumn(hTable,7, "TP offset",true, QTABLE_STRING_TYPE,10)
   AddColumn(hTable,8, "TP SPREAD",true, QTABLE_STRING_TYPE,10)
   
   CreateWindow(hTable)
   SetWindowCaption(hTable, "xxx")
   
   row = InsertRow(hTable, -1)
   SetCell(hTable, 1, 1, "Buy")
   
   InsertRow(hTable, -1)   
   
   InsertRow(hTable, -1)   
   SetCell(hTable, 3, 1, "Sell")
   
   InsertRow(hTable, -1)
   InsertRow(hTable, -1)
     SetCell(hTable, 5, 1, "1")
     SetCell(hTable, 5, 2, "2")
     SetCell(hTable, 5, 3, "3")
   InsertRow(hTable, -1)
     SetCell(hTable, 6, 1, "4")
     SetCell(hTable, 6, 2, "5")
     SetCell(hTable, 6, 3, "6")
   InsertRow(hTable, -1)
     SetCell(hTable, 7, 1, "7")
     SetCell(hTable, 7, 2, "8")
     SetCell(hTable, 7, 3, "9")
     SetCell(hTable, 7, 4, "0")
     SetCell(hTable, 7, 5, "<")
      
  SetTableNotificationCallback(hTable, tableCallback)
   
end 
-----------------------------------------------------------------------------

lastSelectedCol = 3
lastSelectedRow = 1

numpad = { {1,2,3}, {4,5,6}, {7,8,9,0,-1}}

------------------------------------------------
function tableCallback(t_id, msg, par1, par2)

if msg == QTABLE_VKEY then
    
      if par2>=49 and par2<=57 or par2==189 then--numpad[par2]~=nil then
       
            if par2==189 then 
                par2 = 48 
            end
         
            local num = GetCell(hTable,lastSelectedRow,lastSelectedCol)
         
            if num.image == "" then 
                    
                num=0                 
            else                            
                num = tonumber(num.image)
            end
                  
            SetCell(hTable, lastSelectedRow, lastSelectedCol, tostring(num*10+((par2-48)%10)))
            
      elseif par2==8 then
         
            local num = GetCell(hTable,lastSelectedRow, lastSelectedCol)
         
            if num.image == "" then 
                  
                num=0 
            else            
                num = tonumber(num.image)
            end
        
                SetCell(hTable, lastSelectedRow, lastSelectedCol, tostring(num/10 - (num%10)/10))
            end
elseif msg == QTABLE_LBUTTONDOWN  then
  
      if (par1==1 or par1==3) then
    
          SetColor(hTable,lastSelectedRow, lastSelectedCol, QTABLE_DEFAULT_COLOR,QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR,QTABLE_DEFAULT_COLOR)     
          lastSelectedCol = par2
          lastSelectedRow = par1
  
          SetColor(hTable,par1, par2, RGB(100,250,100),QTABLE_DEFAULT_COLOR, QTABLE_DEFAULT_COLOR,QTABLE_DEFAULT_COLOR)
  
      elseif (par1>=5) and numpad[par1-4][par2]~=nil then
               
          local oldVal = GetCell(hTable,lastSelectedRow,lastSelectedCol).image
          local num = GetCell(hTable,par1,par2).image
                    
          if num == "<" then      
                    
                SetCell(hTable,lastSelectedRow,
                lastSelectedCol,string.sub(oldVal,1,string.len(oldVal)-1) or "")                   
          else
                SetCell(hTable,lastSelectedRow,lastSelectedCol,oldVal..num)   
          end
      end
   
end

end

---------------------------------------------------------------------------main  
function main()  
  
  while run do
    sleep(2000)
  end  
 
 end
 
 -------------------------------------------------------------------------------OnStop
 
 function OnStop(s)
   run = false 
   DestroyTable(hTable)
 end 