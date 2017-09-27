data test0 ;
input id time cd4 visit ts_cd4 ;
cards ;
1 0 320  1 0 
1 1 320  0 1
1 2 300  1 0
1 3 300  0 1
1 4 340  1 0
;
 
run;


data test ;
input id time cd4 visit ts_cd4 ;
cards ;
1 0 320  1 0 
1 1 320  0 1
1 2 345  1 0
1 3 345  0 1
1 4 345  0 2
1 5 345  0 3
1 6 345  0 4
1 7 345  0 5
1 8 345  0 6
1 9 300  1 0
;
 
run;



data test ;
input id time cd4 visit ts_cd4 ;
cards ;
1 0 320  1 0 
1 1 320  0 1
1 2 345  1 0
1 3 345  0 1
1 4 345  0 2
1 5 345  0 3
1 6 400  1 0
1 7 400  0 1
1 8 400  0 2
1 9 300  1 0
;
 
run;




data test ;
input id time cd4 visit ts_cd4 ;
cards ;
1 0 400  1 0 
1 1 400  0 1
1 2 365  1 0
1 3 365  0 1
1 4 365  0 2
1 5 365  0 3
1 6 400  1 0
1 7 400  0 1
1 8 400  0 2
1 9 500  1 0
1 10 500 0 1
1 11 500 0 2
1 12 500 0 3
1 13 500 0 4 
1 14 300 1 0 
1 15 300 0 1
1 16 300 0 2
1 17 310 1 0 
1 18 310 0 1
1 19 310 0 2 
1 20 340 1 0
;
 
run;
proc sort data = test ;
by id time ;
run; 


%macro create_branches ;
 branchholder = trim(branch) ;
                        oldbranch = ','||trim(branch)||',' ;
                        newbranches = ','||trim(branch)||'0,'||trim(branch)||'1,' ;
                       ** put time= branch= branchholder= oldbranch= newbranches= activebranches= ;
                        activebranches = tranwrd(activebranches,compress(oldbranch),compress(newbranches));
                        branchreplacement2 = compress(branchholder||'0,'||branchholder||'1,');
                       
                        allbranches = cat(trim(allbranches),branchreplacement2) ;
                       **  put allbranches=  oldbranch= branchholder=  newbranches= activebranches= branchreplacement2= ;
                       
                                      
                        branch = cat(trim(branchholder),'0');
                        allbranches = allbranches||branch||',' ;
                        nbranches = nbranches + 1 ; 
                        
                        
                       
                        cd4 = lastcd4 ;
                        visit = 0 ;
                        ts_cd4 = ts_cd4_l1 + 1 ;
                        output tmp ;
                        branch = cat(trim(branchholder),'1');                     
                                
                        ts_cd4 = 0 ;
                        visit = 1 ;
                        cd4 = cd4holder ;
                        output tmp ;               
%mend ;



%macro mycopy ;
data tmp ;
set test ;
length activebranches allbranches $100 branch $10 ;
activebranches = ',1,';
allbranches = ',1,';
branch = '1' ;
run;

proc sql noprint;
create table branches as select id, branch as firstbranch , allbranches as oldallbranches,
 activebranches as oldactivebranches  from tmp (where = (time = 0)) order by id ;
select max(time) as maxtime into :maxtime from tmp ;
quit;
 

%let maxtime = %sysfunc(left(&maxtime));


%do  testtime = 1 %to  &maxtime ;

    data tmp branches(keep = id firstbranch allbranches activebranches 
                 rename = (allbranches=oldallbranches activebranches = oldactivebranches)) ;
     merge tmp  (drop = ts_cd4   activebranches allbranches ) branches (rename = (firstbranch = branch));
    by id  branch;
    
     
    retain allbranches activebranches ;
     
    retain ts_cd4 ;
  
   
    if first.id then do ;
        allbranches = oldallbranches ;
        activebranches = oldactivebranches ;
    end;
 
    if time = &testtime then visit_orig = visit ;

    branchtest = ','||compress(branch)||',' ;
    testa = index(activebranches,branchtest) ;
    *put time= branch= branchtest= activebranches= testa= censor= ;
    if index(activebranches,branchtest)> 0 then do;
          censor = 0 ;
    end;

    cd4holder = cd4 ;
    *censor = 0 ;
    lastcd4 = lag(cd4);
    ts_cd4_l1 = ts_cd4 ;
    if time < &testtime then do;
         if visit = 0 then ts_cd4 = ts_cd4_l1 + 1;
         else ts_cd4 = 0 ;
         output  tmp;
    end;
    
    if time = &testtime then do ;

        if lastcd4 <= 350 then do ;
            
            if ts_cd4_l1 = 0   then do ;
                  cd4 = lastcd4 ;
                  ts_cd4 = ts_cd4_l1 + 1 ;
                  visit = 0 ;
                  output tmp ;
            end;
            else do ;
                if 1 <= ts_cd4_l1 <= 5 then do ;
                    if visit = 1 then do ;
                       %create_branches ;                       
                    end;
                    else do ;                  
                       ts_cd4 = ts_cd4_l1 + 1;
                       output tmp;
                    end;
                end;
                else do ;
                    if visit = 1 then do ;
                        cd4 = cd4holder ;
                        ts_cd4 = 0 ;
                        output tmp ;
                    end;
                    else do ;
                        censor = 1 ;
                        * need to remove brach as being active ;
                        branchholder = trim(branch) ;
                        oldbranch = ','||trim(branch)||',' ;
                         
                        newbranches = ',';
                        activebranches = tranwrd(activebranches,compress(oldbranch),compress(newbranches));
                        put branch= time= ts_cd4_l1= activebranches= ;
                        output tmp ;
                   end; 
               end;                           
            end;
        end;
        else if lastcd4 >= 350 then do ;
              if ts_cd4_l1 < 7 then do ;
                   cd4 = lastcd4;
                   ts_cd4 = ts_cd4_l1 + 1 ;
                   visit = 0 ;
                   output tmp ;
              end;
              else if  7 <= ts_cd4_l1 <= 11 then do ;
                if visit = 1 then do ;
                    %create_branches ;
                end;
                else do ;
                    cd4 = lastcd4 ;
                    ts_cd4 = ts_cd4_l1 + 1;
                    visit = 0 ;
                    output tmp ;
                end;
              end;
              else if ts_cd4_l1 = 12 then do ;
                if visit = 1 then do ;
                   cd4 = cd4holder ;
                   ts_cd4 = 0;
                   output tmp ;
                end;
                else do ;
                    censor = 1 ;
                    * need to remove brach as being active ;
                     branchholder = trim(branch) ;
                     oldbranch = ','||trim(branch)||',' ;
                         
                     newbranches = ',';
                     activebranches = tranwrd(activebranches,compress(oldbranch),compress(newbranches));
                     put branch= time= ts_cd4_l1= activebranches= ;
                     output tmp ;
                end;
              end;

        end;

    end;
    if time = &testtime + 1 then do ;
             nbranches = countc(activebranches,',') - 1 ;
           **  put "&testtime"  id= time= nbranches= activebranches= ;
             do i = 1 to nbranches ;
                 branch = scan(activebranches,i,',') ;
                 ** put i= activebranches= branch= ;                
                 output tmp;
             end;         
    end;
  
    if time > &testtime + 1 then do;
          copy = 1e10;
          branch = '1111111111';
          output tmp ;
    end;
    length firstbranch $10 ;
    firstbranch='1' ;
    if last.id then output branches ; 
    drop  oldactivebranches oldallbranches ;
    run;


   proc sort data = tmp ;
    by id branch time  ;
    run;

 

*proc print data = branches ;
*run;

 
 

%end;


title "results of testime = &maxtime ";

proc print data = tmp ;
var id  branch time censor cd4 cd4holder visit  visit_orig lastcd4  ts_cd4 ts_cd4_l1  /* activebranches allbranches */;
run;

proc print data = branches ;
run;
title ;
%mend;
options ps = 80 ls = 130 ;
options mprint ;
%mycopy ;
