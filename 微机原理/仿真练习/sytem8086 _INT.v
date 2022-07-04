
/*
一般性说明
本模块用于测试模拟8086总线操作，观察IO电路的运行情况
(1) 建立了8086总线，244，245，373，8255，8253，共阴极8段数码管，共阳极8段数码管，矩阵式键盘
(2) 信号名称中后缀带有_n表示低电平有效
(3) 常用符号： 运算符号：或 | 与 & 取反 ！
    逻辑判断符号： 或|| 与&& 取非 !
(4) 数的表示 n'hxxxx, n表示位数，h表示16进制，还有b：二进制，d、；十进制；XXXX表示用前述进制表示的数；
(5) 观察信号的一般知识：
		X：表示不确定，表示该信号没有被赋值，当从存储器读出为随机数时（存储单元没有被写入），
			或者存在输出冲突时，会出现该状态；
		Z：表示高阻，蓝色，该信号没有被驱动；
(6) 需要关注的信号有：
		时钟信号：			clk_5，5MHz时钟信号
		8086地址总线: 		A19_0，其中用于IO寻址的是其中的低16位，命名为 AIO15_0
		8086数据总线: 		D15_0，遵从偶地址数据从低八位传输，奇地址数据从高八位传输的原则
		8086读信号：		RD_n
		8086写信号：		WR_n
		8086存储器IO选择信号：MIO
		8086高字节使能：	BHE_n
		以上信号按照8086总线周期T1~T4送出，A19_0和BHE_n是经过地址锁存器锁存后的数据；
		word_from_mem15_0：	表示读存储器指令最终得到的数据，如果读取的是规则字，就等于D15_0中传递的数据，
							如果读取的是非规则字，则是由两次访问拼接得到的数据；
		byte_from_IO7_0：	表示读IO指令最终得到的字节；
(7) 如需为输入接口的输入端施加固定的电平，需要定义中间信号，再将该信号连接到输入端；
(8) 以task形式提供的总线操作有：
		readIO(16位地址)：	
				读取16位地址指定的输入型IO端口，只能进行字节访问，读取的数据放入 byte_from_IO7_0；
		writeIO(16位地址, 8位数据)：
				将8位数据写入16位地址指定的输出型IO端口；
		readMEM(20位地址, 字操作标志)：
				字操作标志位1'b1表示进行字读取，为1'b0表示进行字节读取；
				如果进行字读取且20位地址是偶数，则产生一个总线周期；如果进行字操作且20位地址
				是奇数，则为非规则字，将会产生2个总线周期，分别读取第一个奇地址字节和第二个偶
				地址字节，并将其拼接为一个16bit数据放在word_from_mem15_0中；
				如果进行字节读取，只产生一个相应的总线周期；
		writeMEM(20位地址, 16位数据, 字操作标志)：
				字操作标志位1'b1表示进行字写入，为1'b0表示进行字节写入，写入16位数据的低字节；；
				如果进行字写入且20位地址是偶数，则产生一个总线周期；如果进行字写入且20位地址
				是奇数，则为非规则字，将会产生2个总线周期，分别希尔第一个奇地址字节和第二个偶
				地址字节；
				如果进行字节写入，只产生一个相应的总线周期；
(9) initial中可以通过添加上述任务来模拟生成8086总线访问，任务顺序执行；
(10) initial最后通过$stop停止仿真；

本模块要求实现的任务：
(1) 已经实例化了244，Dflop（单个D触发器），并且已经为8086设计了1MB的存储空间；
(2) 外设产生了高电平有效的中断请求信号INT_request；
(3) 设计电路将该信号连接到D触发器，输出作为8086的中断请求信号，当8086响应该中断时清除INTR；
(4) 设计电路将该中断的中断类型号30H送到8086；
(5) 在initial中为该中断设置中断向量表，设中断服务程序的入口地址为1000H：2000H；
(6) 上述3，4，5条需要自己完成
(7) 首先将本文件加入工程，编译，选择以system8086_INT开始仿真，
(8) 将label,clk_5,ok_intnumber,ok_intvector,ok_clear,A19_0,D15_0,BHE_n,RD_n,WR_n,MIO,
	INT_request,INTR,INTA_n,INTnumber,intvector,以及希望观察的其它信号加入wave窗口，
	将label的Radix设为“ASCII”，该字符串用于指示当前所执行的操作，以便于观察，部分信号说明如下：
	label: 字符串，用于标识当前正在进行的操作，便于理解波形图
	ok_intnumber: 指示从外部电路读取的中断类型号是否正确，高电平表示正确，仿真末尾进行判断和置位；
	ok_intvector: 指示从中断向量表中读取的中断向量是否正确，高电平表示正确，仿真末尾进行判断和置位；
	ok_clear: 指示外部电路在8086响应该中断后，是否正确清除了INTR上的中断请求信号，高电平表示正确，仿真末尾
			  进行判断和置位；
    INT_request：外设发起的中断请求信号，从低电平变为高电平后保持，本设计中学生不要改变该信号的状态；
	INTR: 8086可屏蔽外中断请求信号，高电平有效，中断响应后，该信号应被清除，即置为低电平；
	INTA_n: 8086对INTA进行响应时，会输出2个INTA_n为低电平的响应周期，每个周期包含4个时钟周期，其中T2T3
			中INTA_n为低电平，8086要求在INTA_n为低电平期间，将该中断的中断类型号通过数据总线D7:0上传递给8086；
	INTnumber: 从外部电路读取的中断类型号，8bit位宽；
	intvector：从中断向量表中读取的中断向量，高16位为段地址，低16位为偏移地址；
	
(9) 点击run-all开始仿真;
(10) 仿真结束，如果观察到ok_intnumber由低变高表示中断类信号设置正确，ok_intvector由低变高表示中断向量
	设置正确，ok_clear由低变高表示中断响应后INTR被正确清除


// 20201207
*/
`timescale 1ns/1ns

module system8086_INT;

parameter clk_period=200;
parameter half_clk_period=clk_period/2;

// 全局信号
reg clk_5,reset;

// 8086控制总线
reg RD_n, WR_n, MIO, BHE_n;

// 8086地址总线
reg [19:0] A19_0;

// 8086数据总线
wire [15:0] D15_0; 
reg [15:0] word_from_mem15_0;	//读取并拼接的16bit数据存放于word_from_mem15_0以便于观察
reg [7:0] byte_from_IO7_0;		//从IO读取的字节数据存放于byte_from_IO7_0以便于观察

// 8086中断相关引脚与其它信号
wire INTR;
reg INTA_n;
reg [31:0] intvector;		// 根据中断类型号得到的中断向量
reg [7:0] INTnumber;		// 从外部电路读取的中断类型号
reg  INT_request;			// 外设发起的中断请求

// 定义8086工作时钟，5MHz
always #half_clk_period clk_5=~clk_5;

// 内部信号，辅助调试
reg ok_intnumber,ok_intvector,ok_clear;
reg [40*8-1:0] label;

// 生成20位地址总线
reg [19:0] AMEM19_0;
reg [15:0] AIO15_0;		

always @(*)
begin
	if(MIO==1'b1)
		A19_0=AMEM19_0;
	else
		A19_0 = {3'bx,AIO15_0} ;
end

// 生成16位数据总线
reg [15:0] DO15_0;

assign D15_0 = ( WR_n ==1'b0 ) ?  DO15_0 : 16'hz;

//////////////////   信号定义结束  //////////////////////

//------------------ 以下为器件定义与信号连接 自行电路设计部分开始 ---------------

// 声明74ls244, 引脚名称前加p，表示pin
ls244 ls244_1(
	.p1A1_4( 4'b0000 ),
	.p2A1_4( 4'b0011 ),
	.p1G_n( INTA_n ),
	.p2G_n( INTA_n ),
	.p1Y1_4( D15_0[3:0] ),
	.p2Y1_4( D15_0[7:4] )
	);

// 声明D触发器
Dflop Dfolp_1(
	.clk( INT_request ),
	.reset_n( INTA_n ),
	.D( 1'b1 ),
	.Q( INTR ),
	.Q_n(  )
	);
	
// 1MB奇偶存储体，已经连接好
sram512KB sram512KB_1(
	.D7_0(D15_0[7:0]),
	.A18_0(A19_0[19:1]),
	.CS_n(A19_0[0] | !MIO),	// 偶地址存储体
	.WR_n(WR_n),
	.RD_n(RD_n)
	);
	
sram512KB sram512KB_2(
	.D7_0(D15_0[15:8]),
	.A18_0(A19_0[19:1]),
	.CS_n(BHE_n | !MIO),		// 奇地址存储体
	.WR_n(WR_n),
	.RD_n(RD_n)
	);	
//----------------   自行电路设计部分结束 ------------------------

/////////////   模拟指令产生的总线操作  /////////////////
initial
begin
//----------- 初始化 -------------
	label="  initial";
	clk_5=1'b0;
	RD_n=1'b1;
	WR_n=1'b1;
	MIO=1'b1;
	BHE_n=1'b1;
	reset=1'b1;
	ok_intnumber=1'b0;
	ok_intvector=1'b0;
	ok_clear=1'b0;
	INT_request=1'b0;
	#300;
	reset=1'b0;
	# clk_period;
	
//----------- 开始总线操作 -------------

//-----------以下需要自行填写，模拟编程，为类型号30H的中断设置中断向量1000H：2000H------------

	label="   set int vector   ";
	writeMEM( 20'h30*4, 16'h2000 ,1'b1  );				// 中断向量表初始化
	writeMEM( 20'h30*4+2, 16'h1000 ,1'b1  );				// 中断向量表初始化
	
//-----------自行填写模拟编程结束·------------------------------------------------------------	

	label="  int request and answer";
	INT_request=1'b1;		// 外设发起中断请求
	INTanswer;
	
	# (clk_period*9);
	
	if(INTnumber== 8'h30)
		ok_intnumber=1'b1;
	if(intvector=={16'h1000,16'h2000})
		ok_intvector=1'b1;
	if(INTR==1'b0)
		ok_clear=1'b1;
		
	label="  -over--";	
	#600;							// 延时100ns
	$stop;							// 仿真停止

end

// -----------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------
//--------------------- 以下定义8086可屏蔽外中断响应中期,不要修改  -------------------------
// 收到INTR，给出两个周期的INTA，并根据得到的中断类型号读取中断向量，存放在intvector

task INTanswer;
	begin
		wait( INTR );
	// T1
		INTA_n=1'b1;
		# clk_period;
	// T2
		INTA_n=1'b0;
		# clk_period;
	// T3
		# clk_period;
		INTnumber=D15_0[7:0];
	// T4
		INTA_n=1'b1;
		# clk_period;
	// T1
		INTA_n=1'b1;
		# clk_period;
	// T2
		INTA_n=1'b0;
		# clk_period;
	// T3
		# clk_period;
	// T4
		INTA_n=1'b1;
		# clk_period;
		readMEM(INTnumber*4,1'b1);
		intvector[15:0]=word_from_mem15_0;
		readMEM(INTnumber*4+2,1'b1);
		intvector[31:16]=word_from_mem15_0;
	end
endtask
//--------------------- 以下定义8086 总线操作,不要修改  ------------------------------------

// 8086写存储器操作	
// 需要考虑规则字和非规则字的操作
// A0=0 & word=1 一次字操作
// word=0 一次字节操作
// A0=1 & word=1 两次字节操作
task writeMEM;
	input[19:0] address;
	input[15:0] data;
	input word;
	begin
	// T1
		wait(!clk_5);
		wait(clk_5);
		AMEM19_0=address;
		if(AMEM19_0[0]==1'b1 && word==1'b0 || AMEM19_0[0]==1'b0 && word==1'b1 || AMEM19_0[0]==1'b1 && word==1'b1) // 奇地址字节操作,偶地址字操作,奇地址字操作均置BHE为有效
			BHE_n=1'b0;
		else 
			BHE_n=1'b1;		// 偶地址字节操作
		RD_n=1'b1;
		WR_n=1'b1;
		MIO=1'b1;
		# clk_period;
	// T2
		WR_n=1'b0;
		if(AMEM19_0[0]==1'b0 && BHE_n==1'b0)		//规则字访问
			DO15_0=data;				
		else 
			if(AMEM19_0[0]==1'b1 && BHE_n==1'b0 )	// 奇地址字节访问或非规则字
			begin
				DO15_0[15:8]=data[7:0];	
				DO15_0[7:0]=8'hx;	
			end
			else 
				if(word==1'b0 && AMEM19_0[0]==1'b0 )	// 偶地址字节访问
				begin
					DO15_0[7:0]=data[7:0];
					DO15_0[15:8]=8'hx;
				end
		# clk_period;
	// T3
		# clk_period;
	// T4
		RD_n=1'b1;
		WR_n=1'b1;
		# clk_period;
		BHE_n=1'b1;
		AMEM19_0=20'hx;	
		
// 非规则字的第二次写操作
		if(AMEM19_0[0]==1'b1 && word==1'b1)
		begin
			AMEM19_0=address+1;
			BHE_n=1'b1;		// 偶地址字节操作
			RD_n=1'b1;
			WR_n=1'b1;
			MIO=1'b1;
			# clk_period;
		// T2
			WR_n=1'b0;
			DO15_0[7:0]=data[15:8];		// 输出非规则字的高字节
			DO15_0[15:8]=8'hx;			// 输出非规则字的高字节
			# clk_period;
		// T3
			# clk_period;
		// T4
			RD_n=1'b1;
			WR_n=1'b1;

			# clk_period;
				
			AMEM19_0=16'hx;
			MIO=1'bx;
		end
	end
endtask

		
// 8086读存储器操作	
// 需要考虑规则字和非规则字的操作
// A0=0 & word=1 一次字操作
// word=0 一次字节操作
// A0=1 & word=1 两次字节操作
// 读取并拼接的16bit数据存放于word_from_mem15_0以便于观察
task readMEM;
	input[19:0] address;
	input word;
	begin
	// T1
		wait(!clk_5);
		wait(clk_5);
		word_from_mem15_0=16'hx;
		AMEM19_0=address;
		if(AMEM19_0[0]==1'b1 && word==1'b0 || AMEM19_0[0]==1'b0 && word==1'b1 || AMEM19_0[0]==1'b1 && word==1'b1) // 奇地址字节操作,偶地址字操作,奇地址字操作均置BHE为有效
			BHE_n=1'b0;
		else 
			BHE_n=1'b1;		// 偶地址字节操作
		RD_n=1'b1;
		WR_n=1'b1;
		MIO=1'b1;
		# clk_period;
	// T2
		RD_n=1'b0;
		# clk_period;
	// T3
		if(AMEM19_0[0]==1'b0 && BHE_n==1'b0)		//规则字访问
			word_from_mem15_0=D15_0;				
		else if(AMEM19_0[0]==1'b1 && BHE_n==1'b0 )	// 奇地址字节访问或非规则字
			word_from_mem15_0[7:0]=D15_0[15:8];	
		else if(word==1'b0 && AMEM19_0[0]==1'b0 )	// 偶地址字节访问
			word_from_mem15_0[7:0]=D15_0[7:0];
		# clk_period;
	// T4
		RD_n=1'b1;
		WR_n=1'b1;
		# clk_period;
		BHE_n=1'b1;
		AMEM19_0=20'hx;		
		
// 非规则字的第二次读操作
		if(AMEM19_0[0]==1'b1 && word==1'b1)
		begin
			AMEM19_0=address+1;
			BHE_n=1'b1;		// 偶地址字节操作
			RD_n=1'b1;
			WR_n=1'b1;
			MIO=1'b1;
			# clk_period;
		// T2
			RD_n=1'b0;
			# clk_period;
		// T3
			word_from_mem15_0[15:8]=D15_0[7:0];		// 获得非规则字的高字节
			# clk_period;
		// T4
			RD_n=1'b1;
			WR_n=1'b1;
			BHE_n=1'b1;
			# clk_period;
				
			AMEM19_0=20'hx;
			MIO=1'bx;
		end
	end
endtask

// 8086写IO操作	仅支持字节操作
task writeIO;
	input[15:0] address;
	input[7:0] data;
	begin
	// T1
		wait(!clk_5);
		wait(clk_5);
		AIO15_0=address;
		DO15_0=address;
		if(AIO15_0[0]==1'b1)
			BHE_n=1'b0;
		else
			BHE_n=1'b1;
			
		RD_n=1'b1;
		WR_n=1'b1;
		MIO=1'b0;
		# clk_period;
	// T2
		if(AIO15_0[0]==1'b0)
			DO15_0[7:0]=data;
		else
			DO15_0[15:8]=data;
		WR_n=1'b0;
		# clk_period;
	// T3
		# clk_period;
	// T4
		RD_n=1'b1;
		WR_n=1'b1;
		# clk_period;
		BHE_n=1'b1;		
		AIO15_0=16'hx;
		MIO=1'bx;
	end
endtask

		
// 8086读IO操作		仅支持字节操作
task readIO;
	input[15:0] address;
	begin
	// T1
		wait(!clk_5);
		wait(clk_5);
		AIO15_0=address;
		if(AIO15_0[0]==1'b1)
			BHE_n=1'b0;
		else
			BHE_n=1'b1;
		RD_n=1'b1;
		WR_n=1'b1;
		MIO=1'b0;
		# clk_period;
	// T2
		RD_n=1'b0;
		# clk_period;
	// T3
		if(AIO15_0[0]==1'b1)
			byte_from_IO7_0=D15_0[15:8];
		else 
			byte_from_IO7_0=D15_0[7:0];
		# clk_period;
	// T4
		RD_n=1'b1;
		WR_n=1'b1;
		# clk_period;
		BHE_n=1'b1;
		AIO15_0=16'hx;
		MIO=1'bx;
	end
endtask

endmodule