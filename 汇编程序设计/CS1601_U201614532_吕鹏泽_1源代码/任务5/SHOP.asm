.386
STACK SEGMENT USE16 STACK
DB 200 DUP(0)
STACK ENDS
DATA SEGMENT USE16
BNAME DB 'LVPENGZE',0,0			;管理员姓名
BPASS DB 'test',0,0				;密码
AUTH DB ?						;标记登陆状态
N EQU 30
S1 DB 'SHOP1',0					;网店1名称，用0结束
GA1 DB 'PEN',7 DUP(0)			;商品1
	DW 35,56,70,50,?			;进货价、销售价、进货总数、已售数量、利润率
GA2 DB 'BOOK',6 DUP(0)			;商品2
	DW 12,30,25,25,?
GAN DB N-2 DUP('Temp-Value',15,0,20,0,30,0,30,0,?,?);其他商品

S2 DB 'SHOP2',0					;网店2名称，用0结束,商品类型同网店1
GB1 DB 'PEN',7 DUP(0)			;商品1		
	DW 35,56,70,50,?			;进货价、销售价、进货总数、已售数量、利润率	
GB2 DB 'BOOK',6 DUP(0)			;商品2    
	DW 12,30,25,25,?
GBN DB N-2 DUP('Temp-Value',15,0,20,0,30,0,30,0,?,?);其他商品

PR1 DW 0						;商店1利润率 
PR2 DW 0						;商店2利润率 
APR DW 0						;平均利润率
SIGN DB ?						;APR大于0置1，否则置0
MSG1 DB 0AH,0DH,'Input your account:',0DH,0AH,'$'
MSG2 DB 'Input your password:',0DH,0AH,'$'
MSG3 DB 'WRONG ACCOUNT',0DH,0AH,'$'
MSG4 DB 'Enter the name of the item:',0DH,0AH,'$'

CRLF DB 0DH,0AH,'$'				;回车换行
in_name  DB 11					;姓名缓冲区  
         DB ? 
         DB 11 DUP(0)
in_pwd	 DB 7					;密码缓冲区  
         DB ? 
         DB 7 DUP(0)
in_goods DB 11					;商品名缓冲区
		 DB ?
		 DB 11 DUP(0)


DATA ENDS
CODE SEGMENT USE16
ASSUME CS:CODE,DS:DATA,SS:STACK
START:
	MOV AX,DATA
	MOV DS,AX
NEXT:							;功能1，提示登陆
	LEA DX,MSG1
	MOV AH,9
	INT 21H						;9号调用，提示用户输入姓名
	
	LEA DX,in_name
	MOV AH,10
	INT 21H						;10号调用，用户输入姓名
	CALL PRINTCRLF
	
	LEA DX,MSG2
	MOV AH,9
	INT 21H						;9号调用，提示用户输入密码
	
	LEA DX,in_pwd
	MOV AH,10
	INT 21H						;10号调用，用户输入密码
	CALL PRINTCRLF
	
	MOV BL,in_name[2]
	CMP BL,'q'
	JE	EXIT					;输入'q'，退出程序
	
	MOV AH,1
	MOV SIGN,AH
	MOV BL,in_name[1]
	CMP BL,0
	JE UNLOGIN					;输入回车,转未登录
	JMP LOGIN					;否则转登录
	
UNLOGIN:
	MOV AH,0
	MOV AUTH,AH					;标记登陆状态
	JMP PROFIT					;转利润率计算
	
LOGIN:							;功能2，判断登陆
	MOV CX,0
	MOV SI,0					;循环条件初始化
LOOP1:							;循环比较姓名
	MOV BL,in_name[SI+2]
	CMP BL,BNAME[SI]
	JNE ACCOUNTWRONG			;姓名不匹配转ACCOUNTWRONG
	
	INC SI
	INC CX
	MOV AL,in_name[1]
	CBW							;将字节转换成字
	CMP CX,AX					
	JNE LOOP1					;循环未结束
	
	MOV BL,0
	CMP BL,BNAME[SI]
	JNZ ACCOUNTWRONG			;输入的字符串是定义字符串的子集
	
	MOV AL,in_pwd[1]			;循环比较密码
	CBW
	MOV CX,AX	
	MOV SI,0					;循环条件初始化
LOOP2:					
	MOV BL,in_pwd[SI+2]
	CMP BL,BPASS[SI]
	JNE ACCOUNTWRONG			;密码不匹配转ACCOUNTWRONG
	INC SI
	DEC CX
	JNZ LOOP2
	MOV BL,0
	CMP BL,BPASS[SI]
	JNZ ACCOUNTWRONG			;输入为子集，转ACCOUNTWRONG
	JMP	SUCCESS					;账号密码都相同转登陆成功
	
ACCOUNTWRONG:					;登陆失败
	LEA DX,MSG3
	MOV AH,9
	INT 21H						;9号调用，提示登录失败
	JMP NEXT					;回到初始状态
	
SUCCESS:						;登陆成功
	MOV AH,1
	MOV AUTH,AH
	JMP PROFIT
	
PROFIT:							;功能3，计算利润率
	LEA DX,MSG4
	MOV AH,9
	INT 21H						;9号调用，提示输入商品名称
	
	LEA DX,in_goods
	MOV AH,10
	INT 21H						;10号调用，用户输入商品名称
	CALL PRINTCRLF
	
	MOV BL,in_goods[1]			;00B7H
	CMP BL,0
	JE NEXT						;输入回车,回到初始状态

	MOV CX,0					;CX控制第一层循环
	MOV BX,0					;BX基址寄存器
	MOV SI,0					;SI变址寄存器
LOOP3:							;第一层循环，顺序查询N件商品
	MOV SI,0
	MOV AL,in_goods[1]
	CBW
	MOV DX,AX					;DX控制第二层循环
	LOOP4:						;第二层循环，比较商品名称
		MOV AH,GA1[BX][SI]
		CMP AH,in_goods[SI+2]
		JNE F1					;名称不同
		
		INC SI					;变址++
		DEC DX					
		CMP DX,0				
		JE JUDGE				;找到商品,转JUDGE
		JMP LOOP4	
F1:
	ADD BX,20
	INC CX
	CMP CX,N
	JNE LOOP3
	
	JMP PROFIT					;未找到商品，重新输入商品名称
JUDGE:
	CMP SI,10					;商品名称恰好10个字符
	JE F2
	
	MOV AH,GA1[BX][SI]
	CMP AH,0
	JNE F1						;商品名称为子集,属于未找到
	
F2:	MOV AH,AUTH
	CMP AH,1
	JE L1						;登陆状态转L1
	JMP L2						;未登录状态转L2
L1:
	MOV ECX,EBX					;
	MOV EAX,0
    LEA BP,GA1[BX][10]			;S1中商品信息基址
	MOV AX,WORD PTR DS:[BP+2] 	;销售价
	IMUL AX,WORD PTR DS:[BP+6]	;AX=销售价*已售数量
	
	MOV EBX,0
	MOV BX,WORD PTR DS:[BP] 	;进货价
	IMUL BX,WORD PTR DS:[BP+4]	;BX=进货价*进货总数
	
	SUB AX,BX					;AX=利润
	CWDE
	IMUL EAX,100
	MOV EDX,EAX
	SHR EDX,16					;将EAX的高16位移动到DX中
	IDIV BX						;AX=利润率
	MOV PR1,AX
	MOV WORD PTR DS:[BP+8],AX		;商店1利润率
	
	MOV EBX,ECX
	MOV EAX,0
    LEA BP,GB1[BX][10]			;S1中商品信息基址
	MOV AX,WORD PTR DS:[BP+2] 	;销售价
	IMUL AX,WORD PTR DS:[BP+6]	;AX=销售价*已售数量
	
	MOV EBX,0
	MOV BX,WORD PTR DS:[BP] 	;进货价
	IMUL BX,WORD PTR DS:[BP+4]	;BX=进货价*进货总数
	
	SUB AX,BX					;AX=利润
	CWDE
	IMUL EAX,100
	MOV EDX,EAX
	SHR EDX,16					;将EAX的高16位移动到DX中
	IDIV BX						;AX=利润率
	MOV PR2,AX
	MOV WORD PTR DS:[BP+8],AX		;商店2利润率
	
	MOV AX,PR1
	ADD AX,PR2
	SAR AX,1					;计算总利润率
	MOV APR,AX
	CMP AX,0
	JL SET0
	JMP LEVEL
SET0:							;利润率小于0
	MOV AH,0
	MOV SIGN,AH
	JMP LEVEL
	
L2:
    MOV AL,in_goods[1]
    CBW
    MOV SI,AX
	MOV AH,'$'  
    MOV in_goods[SI+2],AH
	
	LEA DX,in_goods[2]
	MOV AH,9
	INT 21H						;9号调用，输出商品名称
	
	CALL PRINTCRLF
	
	JMP NEXT					;回到初始状态
LEVEL:							;功能4，商品等级判断
						
	MOV AH,SIGN
	CMP AH,0					;利润率为负，输出一个负号，并求APR的绝对值
	JNE _J
	mov ax, APR ; 赋值
	cwde
    cdq ; 扩展符号位

       ;求补对正数无效
       ;求补对负数等于是取绝对值
    xor eax, edx ; 取反
    sub eax, edx ; 加1
    mov APR, ax ; 出参		
	MOV AH,2
	MOV DL,'-'
	INT 21H						;输出负号
_J:	
	
	MOV AX,APR
	CWD
	MOV EBX,10
	CALL PRINTAX
	MOV AH,2
	MOV DL,'%'
	INT 21H	
	CALL PRINTCRLF
	MOV AX,APR
	MOV BH,0
	CMP BH,SIGN
	JE _F						;利润率为负
	CMP AX,90
	JGE _A						;利润率大于90%
	CMP AX,50
	JGE _B						;利润率大于50%
	CMP AX,20
	JGE _C						;利润率大于20%
	JMP _D						;利润率大于0%

_A:
	MOV AH,2
	MOV DL,'A'
	INT 21H	
	CALL PRINTCRLF
	JMP NEXT
_B:
	MOV AH,2
	MOV DL,'B'
	INT 21H	
	CALL PRINTCRLF
	JMP NEXT
_C:
	MOV AH,2
	MOV DL,'C'
	INT 21H
	CALL PRINTCRLF
	JMP NEXT
_D:
	MOV AH,2
	MOV DL,'D'
	INT 21H	
	CALL PRINTCRLF
	JMP NEXT
_F:
	MOV AH,2
	MOV DL,'F'
	INT 21H	
	CALL PRINTCRLF
	JMP NEXT

EXIT:
	MOV AH,4CH
    INT 21H						;退出程序
	
;------------------------------以10进制输出AX中的无符号整数
PRINTAX PROC    
     PUSH CX
	 PUSH EDX					;保护现场
	 XOR CX,CX					;计数器清0
_LOP1:							;(EAX)除以P，所得商->EAX，余数入栈，CX++，记录余数个数
	XOR EDX,EDX
	DIV EBX
	PUSH DX
	INC CX
	OR EAX,EAX
	JNZ _LOP1
_LOP2:							;从栈中弹出一位P进制数，并将该数转换成ASCII码后输出
	POP AX
	CMP AL,10
	JB _L1
	ADD AL,7
_L1:							;输出P进制数
	ADD AL,30H
	MOV DL,AL
	MOV AH,2
	INT 21H
	LOOP _LOP2
	POP EDX
	POP CX						;恢复现场
	RET
	
	
PRINTAX ENDP
;------------------------------

;------------------------------输出回车换行
PRINTCRLF PROC
	LEA DX,CRLF					
	MOV AH,9
	INT 21H	
	RET
PRINTCRLF ENDP
;------------------------------
CODE ENDS
END START
