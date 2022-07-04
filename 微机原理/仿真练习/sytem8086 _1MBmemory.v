
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
(1) 已经实例化了两个512KB的SRAM器件，用于构造8086的奇偶存储体；
(2) 将本文件加入工程，编译，选择以system8086_1MBmemory开始仿真；
(7) 将 label,clk_5, ok_start,ok_end, A19_0, D15_0, BHE_n, RD_n, WR_n, MIO, word_from_mem15_0,
	以及希望观察的其它信号加入wave窗口，将label的Radix设为“ASCII”，该字符串用于指示
	当前所执行的操作，以便于观察，部分信号说明如下；
	label: 字符串，用于标识当前正在进行的操作，便于理解波形图
	ok_start: 对所构造的存储空间的起始地址进行字读写操作的正确与否标注，高电平表示正确；
	ok_end: 对所构造的存储空间的最后地址进行字读写操作的正确与否标注，高电平表示正确；
(8) 点击run-all开始仿真;
(9) 仿真结束，如果观察到ok_in由低变高表示输入接口连接正确，ok_out由低变高表示输出接口连接正确

// 作者联系方式 sanghs@hust.edu.cn
// 202021207
*/
`timescale 1ns/1ns

module system8086_1MBmemory;

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

// 8086其它引脚
//reg  INTR_n, INTA;

// 定义8086工作时钟，5MHz
always #half_clk_period clk_5=~clk_5;

// 内部信号，辅助调试
reg ok_start,ok_end;
reg [20*8-1:0] label;

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


//------------------ 以下为器件定义与信号连接 自行设计部分开始 ---------------

// 1MB奇偶存储体
sram512KB sram512KB_1(
	.D7_0( D15_0[7:0]),
	.A18_0( A19_0[19:1]),
	.CS_n( !MIO | A19_0[0]),	   // 偶地址存储体
	.WR_n( WR_n),
	.RD_n( RD_n)
	);
	
sram512KB sram512KB_2(
	.D7_0( D15_0[15:8]),
	.A18_0( A19_0[19:1]),
	.CS_n( !MIO | BHE_n),		// 奇地址存储体
	.WR_n( WR_n),
	.RD_n( RD_n)
	);	
	
//----------------   自行设计部分结束 ------------------------

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
	ok_start=1'b0;
	ok_end=1'b0;
	#300;
	reset=1'b0;
	# clk_period;
	
//----------- 开始总线操作 -------------
	label=" write start address ";
	writeMEM(20'h0, 16'h34, 1'b0);	// 地址0写入34H
	writeMEM(20'h1, 16'h12, 1'b0);	// 地址1写入12H
	
	label=" write end address ";
	writeMEM(20'hffffe, 16'h78, 1'b0);	// 地址0fffeH写入5678H
	writeMEM(20'hfffff, 16'h56, 1'b0);	// 地址0fffeH写入5678H
	
	label=" read start address";
	readMEM(20'h0, 1'b1);				// 地址0字读出,D15:0应为1234H
	if(word_from_mem15_0==16'h1234)
		ok_start=1'b1;
	
	label=" read end address";
	readMEM(20'hffffe, 1'b1);				// 地址0fffeH读出，D15:0应为5678H
	if(word_from_mem15_0==16'h5678)
		ok_end=1'b1;

	label="  -over--";	
	#600;								// 延时600ns
	$stop;								// 仿真停止

end

// -----------------------------------------------------------------------------------------
// -----------------------------------------------------------------------------------------
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
			# clk_period;
				
			AMEM19_0=16'hx;
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
		AIO15_0=16'hx;
		MIO=1'bx;
	end
endtask

endmodule