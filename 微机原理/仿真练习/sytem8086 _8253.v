
/*一般性说明
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
(1) 已经实例化了138、D触发器和8253器件；
(2) 定义了4Mhz的时钟信号CLK_4M；
(3) 设计138译码电路，使8253的端口地址分别为31H，33H，35H，37H；
(4) 设置8253工作方式，使通道0输出1KHz的方波信号，通道1输出1Hz方波信号，通道2的输出信号out2初始化为低电平，在3秒钟后变为高电平；
	由于8253特性，2.5秒~3.5秒均视为正确
(5) 根据代码中指明需要自行设计的部分完成电路设计和8253初始化
(6) 将本文件加入工程，编译，选择以system8086_8253开始仿真，
(7) 将label,clk_5,ok_0，ok_1,ok_2,A19_0,D15_0,BHE_n,RD_n,WR_n,MIO,CS_8253,CLK_4M,CLK_1K,CLK_1和t_3s等
	以及希望观察的其它信号加入wave窗口，可以直接调用预存的波形文件，do wave_8253.do
	其中部分信号说明如下：
	label: 字符串，用于标识当前正在进行的操作，便于理解波形图,将label的Radix设为“ASCII”
	ok_0，ok_1,ok_2: 分别表示通道0、1、2的输出是否正确，高电平表示正确；
(8) 点击run-all开始仿真，观察对8253的初始化操作是否正确,CS_8253在写操作期间是否变为低电平;
(9) 再次点击run_all开始仿真，将会运行较长时间，在label指示'3s'处仿真结束，观察ok_0，ok_1,ok_2是否都变为高电平

// 作者联系方式 sanghs@hust.edu.cn
// 202021207
*/
`timescale 1ns/1ns

module system8086_8253;

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
reg [10*8-1:0] label;

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


//------------------ 以下为器件定义与信号连接 自行设计电路部分开始 ---------------
wire t_3s;
reg clk_4M;			// 4MHz时钟源，作为8253的计时基准
always #125 clk_4M=~clk_4M;

// IO选通逻辑，为8253四个端口分配地址31H，33H，35H，37H
ls138 ls138_1(
	.G1(A19_0[0]),
	.G2A_n(A19_0[7] | MIO),
	.G2B_n(A19_0[6]),
	.C(A19_0[5]),
	.B(A19_0[4]),
	.A(A19_0[3]),
	.Y0_n( ),
	.Y1_n( ),
	.Y2_n( ),
	.Y3_n( ),
	.Y4_n( ),
	.Y5_n( ),
	.Y6_n(CS_8253),
	.Y7_n( )
	);
	
// 声明D触发器
Dflop Dfolp_1(
	.clk(clk_4M),
	.reset_n( ),
	.D(clk_2M_n),
	.Q(clk_2M),
	.Q_n(clk_2M_n)
	);
	
// 声明8253，并与其它信号和器件连接，三个通道的输出已经命名，请勿更改
intel8253 intel8253(
	.D7_0(D15_0[15:8]),
	.WR_n(WR_n),
	.RD_n(RD_n ),
	.CS_n(CS_8253 ),
	.A0(A19_0[1]),
	.A1(A19_0[2]),
	.CLK0(clk_2M),
	.GATE0(RD_n ),
	.OUT0(CLK_1K),
	.CLK1(CLK_1K),
	.GATE1(RD_n ),
	.OUT1(CLK_1),
	.CLK2(CLK_1),
	.GATE2(RD_n ),
	.OUT2(t_3s)
	);	

	
//----------------   自行设计电路部分结束 ------------------------

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
	#150;
	clk_4M=1'b0;
	#300;
	reset=1'b0;
	# clk_period;
	
//----------- 开始总线操作 -------------
//-----------以下需要自行填写，模拟编程，对8253进行初始化------------
// 示例：writeIO( 16'h地址, 8'h数据 );		// 设置命令模仿此格式添加,等价于 MOV AL, 数据；OUT 地址，AL

	label="  8253 initial ";
	writeIO(16'h37,8'b00110111);			// 初始化通道0，将2MHz分频为1KHz 
	writeIO(16'h31,8'h00);
	writeIO(16'h31,8'h20);

	writeIO(16'h37,8'b01110111);			// 初始化通道1，将1KHz分频为1Hz 
	writeIO(16'h33,8'h00);
	writeIO(16'h33,8'h10);
	
	writeIO(16'h37,8'b10110001);			// 初始化通道2，令3秒后输出变为高电平 
	writeIO(16'h35,8'h02);
	writeIO(16'h35,8'h00);
	
	#100;
	$stop;			// 此处暂停，写IO的总线操作是否正确正确将数据写入8253相应端口
//-----------自行填写模拟编程结束·------------------------------------------------------------
//--------------------------------------------------------------------------------------------	
	wait (~CLK_1);
	label=" 1s ";
	#1000000000;
	label=" 2s ";
	#1000000000;
	label=" 3s ";
	#1000000000;
	label="  -over--";	
	#600;							
	$stop;							// 仿真停止，观察ok_1,ok_2he ok_3信号是否变为高电平

end

// ----------------------
// -----------------------
// 辅助检测
reg CLK_1K_d,CLK_1_d;
reg ok_0,ok_1,ok_2;
reg [10:0] counter0;
reg [20:0] counter1;
reg [23:0] counter2;

//-----检测通道0输出是否正确--------
always @(posedge clk_4M or posedge reset)
if(reset)
	begin
		CLK_1K_d<=1'b0;
		counter0<=0;
		ok_0<=1'b0;
	end
else
	begin
		CLK_1K_d<= #100 CLK_1K;
		if(CLK_1K==1'b1)
			counter0<=counter0+1;
		else
			begin
				if(CLK_1K==1'b0 && CLK_1K_d==1'b1 && counter0==2000)
					ok_0<=1'b1;
				else if(CLK_1K==1'b0 && CLK_1K_d==1'b1 && counter0!=2000)
					ok_0<=1'b1;
				counter0<=0;
			end
	end
//-----检测通道1输出是否正确--------	
always @(posedge clk_4M or posedge reset)
if(reset)
	begin
		CLK_1_d<=1'b0;
		counter1<=0;
		ok_1<=1'b0;
	end
else
	begin
		CLK_1_d<= #100 CLK_1;
		if(CLK_1==1'b1)
			counter1<=counter1+1;
		else
			begin
				if(CLK_1==1'b0 && CLK_1_d==1'b1 && counter1==2000000)
					ok_1<=1'b1;
				else if(CLK_1==1'b0 && CLK_1_d==1'b1 && counter1!=2000000)
					ok_1<=1'b1;
				counter1<=0;
			end
	end
//-----检测通道2输出是否正确--------	
always @(posedge clk_4M or posedge reset)
if(reset)
	begin
		counter2<=0;
		ok_2<=1'b0;
	end
else
	begin
		if(t_3s==1'b0)
			counter2<=counter2+1;
		else
			if(t_3s==1'b1 && counter2>=2000000*5 && counter2<2000000*7)
				ok_2<=1'b1;
	end

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