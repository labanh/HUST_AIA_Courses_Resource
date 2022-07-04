DATA1 SEGMENT           ;数据段定义，可以改变段名

;在此加入变量定义

      ASK_N1   DB  'Please Enter Number1',0AH,0DH,'$'   
      ASK_N2   DB  'Please Enter Number2',0AH,0DH,'$'
      ASK_OPR  DB  'Please Enter Operator +, -, *, /',0AH,0DH,'$'
      ANSWER   DB  'RESULT = ',0AH,0DH,'$' 
      _MOD     DB  'MOD = ','$'
      MOD      DB  6 DUP('$') 
      OPR      DB  1 DUP(0)
      NUM1     DB  '+',5 DUP('$')
      NUM2     DB  '+',5 DUP('$')
      NUM      DB  '+',5 DUP('$') 
      RESULT   DB  '+',5 DUP('$')
      ERR1     DB  'ERROR! Please Enter Number 0-9!',0AH,0DH,'$'
      ERR2     DB  'ERROR! Please Enter Operator!',0AH,0DH,'$'
      ERR3     DB  'ERROR! Please Enter No More Than 4 Numbers!',0AH,0DH,'$'
      ERR4     DB  'ERROR! OVERSIZE',0AH,0DH,'$' 
      ERR5     DB  'ERROR! DIVIDEND CANNOT BE 0',0AH,0DH,'$'
      _CR      DB   0AH,0DH,'$' 
      NUM1_16  DW  0
      NUM2_16  DW  0

DATA1 ENDS

STACK1 SEGMENT            ;堆栈段定义，可以改变段名
   STT DB 100 DUP(0FFH)   ;可以改变堆栈名和深度
   STACK1 ENDS

CODE1 SEGMENT           ;代码段定义，可以改变段名
   ASSUME CS:CODE1,DS:DATA1,SS:STACK1  ;代码段、数据段、堆栈段的声明，相应改变段名
   START:                 ;程序开始执行的第一条指令的标号，标号名可变
   MOV AX,STACK1        ;堆栈段初始化，可以改变段名
   MOV SS,AX
   MOV SP,100		   ;根据自己设置的深度填写
   MOV AX,DATA1         ;数据段初始化，可以改变段名
   MOV DS,AX		   ;如果需要定义扩展段，请仿照上述语法添加

   MOV AX,DATA1
   MOV DS,AX 
   MOV AX,0
;在此加入你的代码

MAIN:  
   MOV CL,1        
   CALL INPUT        
   CALL D2H          ;将十进制输入转换为十六进制

   MOV NUM1_16, AX  
   CALL CPY2_N1   
   CALL OPR_PT    ;OPR INPUT PROMPT 提示输入运算符

   MOV CL,2       ;读取第二个输入
   CALL INPUT      
   CALL D2H 
   MOV NUM2_16,AX   
   CALL CPY2_N2    

   CALL CALCULATE   ;计算
   CALL OUTPUT      ;输出

   CALL CR

   CALL CLR_ALL   ;将所有变量清零
   JMP MAIN        ;重新开始主程序读取输入

   HLT 

INPUT PROC  
   MOV DX,OFFSET ASK_N1 
   CMP CL,1          ;判断是否需要输入第二个数字
   JE INPUT_1ST
   MOV DX,OFFSET ASK_N2

INPUT_1ST:
   MOV AH, 09H       ;提示输入第一个数字
   INT 21H    
   MOV CX,0

INPUT_2ST:        
   MOV AH,1       
   INT 21H 
   CMP AL,0DH    
   JE END_INPUT

   CALL COM       
   CALL WRITE    

   CMP CL,5      
   JNE INPUT_2ST  
   MOV DX,OFFSET ERR3 
   MOV AH,09H
   INT 21H 
   CALL CLR_N   
   JMP INPUT_1ST

END_INPUT: 
   CALL CR
   RET 
   INPUT ENDP


COM PROC      
   CMP AL,0DH
   JE END_INPUT

   CMP AL,'-' 
   JE NEG

   CMP AL,30H   
   JB DIGIT_ERR  
   CMP AL,39H   
   JA DIGIT_ERR 
   INC CL
   JMP END

NEG:          
   CMP CL,0   
   JE END 

DIGIT_ERR:
   MOV DX,OFFSET ERR1
   MOV AH,09H
   INT 21H 
   MOV CX,0
   CALL CLR_N 

   END: 
   RET
   COM ENDP 


OPR_PT PROC
   MOV DX,OFFSET ASK_OPR 
   MOV AH,09H
   INT 21H

INPUT_OPR: 
   MOV AH,1     
   INT 21H

   CMP AL,'+'  
   JE END_F 
   CMP AL,'-'
   JE END_F
   CMP AL,'*'
   JE END_F
   CMP AL,'/'
   JE END_F

   MOV DX,OFFSET ERR2
   MOV AH,09H
   INT 21H 
   JMP INPUT_OPR   

END_F:
   MOV OPR,AL 
   CALL CR
   RET
   OPR_PT ENDP 


CALCULATE PROC
   CMP OPR,'+'     
   JE ADD
   CMP OPR,'-'
   JE SUB
   CMP OPR,'*'
   JE MULTP
   CMP OPR,'/'
   JE DIVIDE

ADD: 
   CALL _ADD     
   JMP END_C   

SUB: 
   CALL _SUB     
   JMP END_C   

MULTP: 
   CALL _MULTP      
   JMP END_C  

DIVIDE:
   CALL _DIVIDE
   JMP END_C

END_C:      
   RET
   CALCULATE ENDP

_ADD PROC             
   MOV DH,NUM1
   MOV DL,NUM2
   CMP DH,DL
   JE SAME_ADD

   MOV AX,NUM1_16       
   MOV BX,NUM2_16     
   CMP AX,BX           
   JA A_GRE
   MOV CL,NUM2
   MOV RESULT,CL        
   JMP IS_A_NEG

A_GRE:
   MOV CL,NUM1
   MOV RESULT,CL        

IS_A_NEG:                     
   CMP NUM1,'+'             
   JE IS_B_NEG           
   NEG AX 

IS_B_NEG:     
   CMP NUM2,'+'
   JE ER_Z
   NEG BX  

ER_Z: 
   ADD AX,BX
   CMP RESULT,'+'
   JE JGZ
   NEG AX               
   CMP AX,270FH       
   JA OVER_

JGZ:      
   CALL H2D
   RET

SAME_ADD:            
   MOV AX,NUM1_16
   MOV BX,NUM2_16
   ADD AX,BX       

   CMP AX,270FH        
   JA OVER_

   CALL H2D
   MOV RESULT,'+'      
   MOV DL,NUM2
   MOV RESULT,DL  
   RET

OVER_:
   MOV DX,OFFSET ERR4   
   MOV AH,09H
   INT 21H 
   RET

   RET
   _ADD ENDP


_SUB PROC           
   MOV CL,NUM2
   PUSH CX           
   CMP NUM2,'+'
   JE P2N
   MOV NUM2,'+'
   JMP ADD_S

P2N:
   MOV NUM2,'-'

ADD_S:
   CALL _ADD
   POP CX
   MOV NUM2,CL

   RET
   _SUB ENDP


_MULTP PROC         
   MOV AX,NUM1_16
   MOV BX,NUM2_16
   MUL BX
   CMP AX,9999         
   JA OVER
   CALL H2D
   MOV DH,NUM1
   MOV DL,NUM2
   
   CMP DH,DL
   MOV RESULT,'+'      
   JE PASS
   MOV RESULT,'-'    
PASS:
   RET

OVER:
   MOV DX,OFFSET ERR4 
   MOV AH,09H
   INT 21H 
   RET
   _MULTP ENDP


_DIVIDE PROC           
   MOV AX,NUM1_16
   MOV BX,NUM2_16
   MOV DX,0 
   CMP BX,0         
   JE ERR
   
   DIV BX

   XCHG AX,DX 
   MOV DH,NUM1
   MOV DL,NUM2
   CMP DH,DL          
   JE RMD          
   NEG AX
   ADD AX,NUM2_16

RMD:       
   CALL H2D    
   MOV AL,RESULT
   MOV MOD,AL
   MOV AL,RESULT+1
   MOV MOD+1,AL
   MOV AL,RESULT+2     
   MOV MOD+2,AL
   MOV AL,RESULT+3
   MOV MOD+3,AL
   MOV AL,RESULT+4
   MOV MOD+4,AL 

   MOV AX,NUM1_16
   MOV BX,NUM2_16
   MOV DX,0
   DIV BX

   MOV DH,NUM1
   MOV DL,NUM2
   CMP DH,DL          
   JE RMD_              
   INC AX

RMD_:       
   CALL H2D      

   MOV DH,NUM1
   MOV DL,NUM2
   CMP DH,DL
   MOV RESULT,'+'       
   JE _PASS
   MOV RESULT,'-'       
   _PASS:
   RET 

ERR:                 
   MOV DX,OFFSET ERR5  
   MOV AH,09H
   INT 21H
   _DIVIDE ENDP  


D2H PROC        
   MOV AX,0                    
   MOV CX,10           
   CMP NUM+1,'$'         
   JE END_D2H
   MUL CX
   MOV BL,NUM+1
   SUB BL,30H
   ADD AX,BX
   CMP NUM+2,'$'
   JE END_D2H
   MUL CX
   MOV BL,NUM+2
   SUB BL,30H
   ADD AX,BX 
   CMP NUM+3,'$'
   JE END_D2H
   MUL CX
   MOV BL,NUM+3
   SUB BL,30H
   ADD AX,BX
   CMP NUM+4,'$'
   JE END_D2H
   MUL CX
   MOV BL,NUM+4
   SUB BL,30H
   ADD AX,BX

   END_D2H:
   CMP NUM,'$'
   JE ER
   ;NEG AX
   ER:
   RET
   D2H ENDP   

H2D PROC        
   MOV BX,2FFFH         
   MOV CX,10
   MOV DX,0             
   PUSH BX

   IDIV CX
   PUSH DX 
   CMP AL,0
   JE END_H2D
   MOV DX,0

   IDIV CX
   PUSH DX
   CMP AL,0
   JE END_H2D
   MOV DX,0

   IDIV CX
   PUSH DX 
   CMP AL,0
   JE END_H2D 
   MOV DX,0

   IDIV CX
   PUSH DX
   CMP AL,0
   JE END_H2D 
   MOV DX,0

END_H2D:
   POP BX 
   CMP BX,2FFFH
   JE END2_H2D
   ADD BL,30H
   MOV RESULT+1,BL

   POP BX 
   CMP BX,2FFFH
   JE END2_H2D
   ADD BL,30H
   MOV RESULT+2,BL

   POP BX 
   CMP BX,2FFFH
   JE END2_H2D
   ADD BL,30H
   MOV RESULT+3,BL

   POP BX 
   CMP BX,2FFFH
   JE END2_H2D
   ADD BL,30H
   MOV RESULT+4,BL 

   POP BX 

END2_H2D: 
   RET
   H2D ENDP


OUTPUT PROC  
   CMP RESULT+1,'$'
   JNE N_MOD             
   RET

N_MOD:  
   MOV DX,OFFSET ANSWER 
   MOV AH,09H
   INT 21H

   MOV DX,OFFSET RESULT
   MOV BL,RESULT 
   CMP BL,'-'       
   JE NEG_NUM
   MOV DX,OFFSET RESULT+1  

Y_MOD:
   MOV AH,09H
   INT 21H

   CMP OPR,'/'             
   JNE END_O
   MOV DX,OFFSET _MOD         
   MOV AH,09H
   INT 21H
   MOV DX,OFFSET MOD+1      
   MOV AH,09H
   INT 21H
   
NEG_NUM:
   CMP RESULT+1,'0'
   JNE Y_MOD
   MOV DX,OFFSET RESULT+1   

END_O:
   RET
   OUTPUT ENDP

CLR_N PROC   
   MOV NUM+0,'+' 
   MOV NUM+1,'$'
   MOV NUM+2,'$'
   MOV NUM+3,'$'
   MOV NUM+4,'$' 
   MOV NUM+5,'$' 
   RET
   CLR_N ENDP


CPY2_N1 PROC   
   MOV BL,NUM
   MOV NUM1,BL 
   MOV BL,NUM+1
   MOV NUM1+1,BL
   MOV BL,NUM+2
   MOV NUM1+2,BL
   MOV BL,NUM+3
   MOV NUM1+3,BL
   MOV BL,NUM +4
   MOV NUM1+4,BL
   CALL CLR_N
   RET
   CPY2_N1 ENDP 

CPY2_N2 PROC     
   MOV BL,NUM
   MOV NUM2,BL 
   MOV BL,NUM+1
   MOV NUM2+1,BL
   MOV BL,NUM+2
   MOV NUM2+2,BL
   MOV BL,NUM+3
   MOV NUM2+3,BL
   MOV BL,NUM +4
   MOV NUM2+4,BL
   CALL CLR_N
   RET
   CPY2_N2 ENDP

   CLR_ALL PROC   
   CALL CLR_N 
   MOV NUM1+0,'+' 
   MOV NUM1+1,'$'
   MOV NUM1+2,'$'
   MOV NUM1+3,'$'
   MOV NUM1+4,'$' 
   MOV NUM1+5,'$'

   MOV NUM1_16,0
   MOV NUM2_16,0 

   MOV NUM2+0,'+' 
   MOV NUM2+1,'$'
   MOV NUM2+2,'$'
   MOV NUM2+3,'$'
   MOV NUM2+4,'$' 
   MOV NUM2+5,'$'

   MOV AX,0
   MOV BX,0
   MOV CX,0
   MOV DX,0

   MOV RESULT+0,'+' 
   MOV RESULT+1,'$'
   MOV RESULT+2,'$'
   MOV RESULT+3,'$'
   MOV RESULT+4,'$' 
   MOV RESULT+5,'$'

   RET
   CLR_ALL ENDP

WRITE PROC     
   CMP AL,'$'
   JE W_END

   CMP CL,0 
   JE WRT_0
   CMP CL,1 
   JE WRT_1
   CMP CL,2 
   JE WRT_2  
   CMP CL,3 
   JE WRT_3
   CMP CL,4 
   JE WRT_4
WRT_0:
   MOV NUM+0,AL
   JMP W_END    
WRT_1:
   MOV NUM+1,AL
   JMP W_END    
WRT_2:
   MOV NUM+2,AL
   JMP W_END    
WRT_3:
   MOV NUM+3,AL
   JMP W_END    
WRT_4:
   MOV NUM+4,AL
   JMP W_END     
   W_END:
   RET
   WRITE ENDP


CR PROC
   MOV DX,OFFSET _CR
   MOV AH,09H
   INT 21H
   RET
   CR ENDP

   ;暂停
   CODE1 ENDS               ;代码段结束
   END START               ;汇编结束，从start开始执行，可以改变标号名




