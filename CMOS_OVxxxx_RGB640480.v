
`timescale 1ns / 1ns
module CMOS_OVxxxx_RGB640480
(
	//global clock 50MHz
	input			clk,			//50MHz
	input			rst_n,			//global reset
	
	//sdram1 control
	output			sdram1_clk,		//sdram clock
	output			sdram1_cke,		//sdram clock enable
	output			sdram1_cs_n,		//sdram chip select
	output			sdram1_we_n,		//sdram write enable
	output			sdram1_cas_n,	//sdram column address strobe
	output			sdram1_ras_n,	//sdram row address strobe
   //output	[1:0]	sdram1_dqm,		//sdram data enable
	output	[1:0]	sdram1_ba,		//sdram bank address
	output	[12:0]  sdram1_addr,		//sdram address
	inout	[15:0]	sdram1_data,		//sdram data
	
	//sdram2 control
	output			sdram2_clk,		//sdram clock
	output			sdram2_cke,		//sdram clock enable
	output			sdram2_cs_n,		//sdram chip select
	output			sdram2_we_n,		//sdram write enable
	output			sdram2_cas_n,	//sdram column address strobe
	output			sdram2_ras_n,	//sdram row address strobe
   //output	[1:0]	sdram2_dqm,		//sdram data enable
	output	[1:0]	sdram2_ba,		//sdram bank address
	output	[12:0]  sdram2_addr,		//sdram address
	inout	[15:0]	sdram2_data,		//sdram data
	
	//lcd port
//	output			lcd_dclk,		//lcd pixel clock			
	output			lcd_hs,			//lcd horizontal sync 
	output			lcd_vs,			//lcd vertical sync
//	output			lcd_sync,		//lcd sync
//	output			lcd_blank,		//lcd blank(L:blank)
//	output			lcd_de,			//lcd data enable
	output	[4:0]	lcd_red,		//lcd red data
	output	[5:0]	lcd_green,		//lcd green data
	output	[4:0]	lcd_blue,		//lcd blue data
   
   //gray_port
   output			gray_hs,			//gray horizontal sync 
	output			gray_vs,			//gray vertical sync
	output	[7:0]	gray_data,		//gray data

	//cmos interface
    //摄像头接口
    input                 cam_pclk    ,  //cmos 数据像素时钟
	 output                cam_xclk    ,
    input                 cam_vsync   ,  //cmos 场同步信号
    input                 cam_href    ,  //cmos 行同步信号
    input        [7:0]    cam_data    ,  //cmos 数据  
    output                cam_rst_n   ,  //cmos 复位信号，低电平有效
    output                cam_pwdn    ,  //cmos 电源休眠模式选择信号
    output                cam_scl     ,  //cmos SCCB_SCL线
    inout                 cam_sda       //cmos SCCB_SDA线
	

);


wire[15:0]                      vout_data;
assign lcd_red   = {vout_data[15:11]};
assign lcd_green = {vout_data[10:5]};
assign lcd_blue  = {vout_data[4:0]};

//---------------------------------------------
//system global clock control
wire	sys_rst_n;		//global reset
wire	clk_ref;		//sdram ctrl clock
wire	clk_refout;		//sdram clock output
wire	clk_vga;		//vga clock
//wire	clk_cmos;		//24MHz cmos clock
//wire	clk_48M;		//48MHz SignalTap II Clock


system_ctrl_pll	u_system_ctrl_pll
(
	.clk				(clk),			//global clock
	.rst_n				(rst_n),		//external reset
	
	.sys_rst_n			(sys_rst_n),	//global reset
	.clk_c0				(clk_ref),		//100MHz 
	.clk_c1				(clk_refout),	//100MHz -90deg
	.clk_c2				(clk_vga),		//25MHz
	.clk_c3				(cam_xclk)	//24MHz
);
//----------------------------------------------
//parameter define
parameter  SLAVE_ADDR = 7'h3c         ;  //OV5640的器件地址7'h3c
parameter  BIT_CTRL   = 1'b1          ;  //OV5640的字节地址为16位  0:8位 1:16位
parameter  CLK_FREQ   = 26'd25_000_000;  //i2c_dri模块的驱动时钟频率 25MHz
parameter  I2C_FREQ   = 18'd250_000   ;  //I2C的SCL时钟频率,不超过400KHz
parameter  CMOS_H_PIXEL = 24'd640     ;  //CMOS水平方向像素个数,用于设置SDRAM缓存大小
parameter  CMOS_V_PIXEL = 24'd480     ;  //CMOS垂直方向像素个数,用于设置SDRAM缓存大小
wire                  i2c_exec        ;  //I2C触发执行信号
wire   [23:0]         i2c_data        ;  //I2C要配置的地址与数据(高8位地址,低8位数据)          
wire                  cam_init_done   ;  //摄像头初始化完成
wire	    	      sdram_init_done;			//sdram init done
wire                  i2c_done        ;  //I2C寄存器配置完成信号
wire                  i2c_dri_clk     ;  //I2C操作时钟
//不对摄像头硬件复位,固定高电平
assign  cam_rst_n = 1'b1;
//电源休眠模式选择 0：正常模式 1：电源休眠模式
assign  cam_pwdn = 1'b0;
 //I2C配置模块
i2c_ov5640_rgb565_cfg 
   #(
     .CMOS_H_PIXEL  (CMOS_H_PIXEL),
     .CMOS_V_PIXEL  (CMOS_V_PIXEL)
    )
   u_i2c_cfg(
    .clk           (i2c_dri_clk),
    .rst_n         (rst_n),
    .i2c_done      (i2c_done),
    .i2c_exec      (i2c_exec),
    .i2c_data      (i2c_data),
    .init_done     (cam_init_done)
    );    

//I2C驱动模块
i2c_dri 
   #(
    .SLAVE_ADDR  (SLAVE_ADDR),               //参数传递
    .CLK_FREQ    (CLK_FREQ  ),              
    .I2C_FREQ    (I2C_FREQ  )                
    ) 
   u_i2c_dri(
    .clk         (clk_vga   ),//25M
    .rst_n       (rst_n     ),   
    //i2c interface
    .i2c_exec    (i2c_exec  ),   
    .bit_ctrl    (BIT_CTRL  ),   
    .i2c_rh_wl   (1'b0),                     //固定为0，只用到了IIC驱动的写操作   
    .i2c_addr    (i2c_data[23:8]),   
    .i2c_data_w  (i2c_data[7:0]),   
    .i2c_data_r  (),   
    .i2c_done    (i2c_done  ),   
    .scl         (cam_scl   ),   
    .sda         (cam_sda   ),   
    //user interface
    .dri_clk     (i2c_dri_clk)               //I2C操作时钟
);
//CMOS图像数据采集模块
wire			cmos_frame_vsync;	//cmos frame data vsync valid signal
wire			cmos_frame_href;	//cmos frame data href vaild  signal
wire	[15:0]	cmos_frame_data;	//cmos frame data output: {cmos_data[7:0]<<8, cmos_data[7:0]}	
wire			cmos_frame_clken;	//cmos frame data output/capture enable clock
cmos_capture_data u_cmos_capture_data(
    .rst_n               (rst_n & cam_init_done), //系统初始化完成之后再开始采集数据 
    .cam_pclk            (cam_pclk),
    .cam_vsync           (!cam_vsync),
    .cam_href            (cam_href),
    .cam_data            (cam_data),         
    .cmos_frame_vsync    (cmos_frame_vsync),
    .cmos_frame_href     (cmos_frame_href),
    .cmos_frame_valid    (cmos_frame_clken),            //数据有效使能信号
    .cmos_frame_data     (cmos_frame_data)           //有效数据 
    );

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------
//cmos video image capture

//wire	[7:0]	led_data = cmos_fps_rate;
wire        lcd_request             ;
//wire	[7:0]	led_data = LUT_INDEX;
//wire	[7:0]	led_data = i2c_rdata;

//********************************************
wire [15:0]  gray_sft; 
wire         sdr_rd; 
wire         gs_clken ;
wire         post_frame_vsync;
wire         post_frame_href;
wire [15:0]  post_img_data;
wire         post_frame_clken;
//-------------------------------------


//Sdram_Control_4Port module 	
//sdram write port1
wire			 sdr_wr1_clk	  = cam_pclk     ;	//Change with input signal											
wire	[7:0]  sdr_wr1_wrdata  = gray_sft[15:8];
wire			 sdr_wr1_wrreq   = gs_clken ;//gs_clken ;

//sdram read  port1
wire			 sdr_rd1_clk	  = cam_pclk ;	//Change with vga timing	
wire	[7:0]  sys_data_out1   ;
wire			 sys_rd1         = sdr_rd ;
wire         RD1_EMPTY;


//sdram write port2
wire			 sdr_wr2_clk	  =   cam_pclk;	//Change with input signal											
wire	[15:0] sdr_wr2_wrdata  =   post_img_data ;// {16{post_img_Bit}};//{data_diff,data_diff}; //sys_data_sim for test
wire			 sdr_wr2_wrreq   =   post_frame_clken;//sys_we_sim for test
//sdram read  port2
wire			 sdr_rd2_clk	=	clk_vga;	//Change with vga timing	
wire	[15:0] sys_data_out2;
wire			 sys_rd2       =  lcd_request;
wire         RD2_EMPTY;



Video_Image_Processor 
#(
	.IMG_HDISP(10'd640),	//640*48s0
	.IMG_VDISP(10'd480)
)
Video_Image_Processor_u0
(
	//global clock
	.clk				   	(cam_pclk),  			//cmos video pixel clock
	.rst_n					(sys_rst_n),			//global reset
	.cmos_frame_clken		(cmos_frame_clken), 	//Prepared Image data vsync valid signal
	.cmos_frame_vsync		(cmos_frame_vsync), 		//Prepared Image data href vaild  signal
	.cmos_frame_href		(cmos_frame_href ), 	//Prepared Image data output/capture enable clock
	.cmos_frame_data     (cmos_frame_data),			//Prepared Image brightness input
	//Image data has been processd
	.post_frame_vsync    (post_frame_vsync),
	.post_frame_href		(post_frame_href),		//Processed Image data href vaild  signal
	.post_frame_clken		(post_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_data       (post_img_data),			//Processed Image brightness output
	.sys_data_out1       (sys_data_out1),
	.gs_clken            (gs_clken),
	.gray_sft            (gray_sft),
	.sdr_rd              (sdr_rd),
.gs_vsync(gs_vsync),
	//user interface
	.Sobel_Threshold     ( 8'd20 )		// 8'd10 ~8'd20
);
wire gs_vsync;
//wire sdram_init_done;
	/*Sdram_Control_4Port Sdram_Control_4Port(
		//	HOST Side
		.REF_CLK(clk_ref),
		.OUT_CLK(clk_refout),
		.RESET_N(sys_rst_n),	//复位输入，低电平复位
		//.SDRAM_INIT_DONE(sdram_init_done),
		//	FIFO Write Side 1
		.WR1_DATA(sdr_wr1_wrdata),			//写入端口1的数据输入端，16bit
		.WR1(sdr_wr1_wrreq),					//写入端口1的写使能端，高电平写入
		.WR1_ADDR(0),			//写入端口1的写起始地址
		.WR1_MAX_ADDR(640*480-1),		//写入端口1的写入最大地址
		.WR1_LENGTH(256),			//一次性写入数据长度
		.WR1_LOAD(~sys_rst_n),			//写入端口1清零请求，高电平清零写入地址和fifo
		.WR1_CLK(sdr_wr1_clk),				//写入端口1 fifo写入时钟
		.WR1_FULL(),			//写入端口1 fifo写满信号
		.WR1_USE(),				//写入端口1 fifo已经写入的数据长度

		//	FIFO Write Side 2
		.WR2_DATA(sdr_wr2_wrdata),			//写入端口2的数据输入端，16bit
		.WR2(sdr_wr2_wrreq),					//写入端口2的写使能端，高电平写入
		.WR2_ADDR(640*480),			//写入端口2的写起始地址
		.WR2_MAX_ADDR(640*480*2-1),		//写入端口2的写入最大地址
		.WR2_LENGTH(256),			//一次性写入数据长度
		.WR2_LOAD(~sys_rst_n),			//写入端口2清零请求，高电平清零写入地址和fifo
		.WR2_CLK(sdr_wr2_clk),				//写入端口2 fifo写入时钟
		.WR2_FULL(),			//写入端口2 fifo写满信号
		.WR2_USE(),				//写入端口2 fifo已经写入的数据长度

		//	FIFO Read Side 1
		.RD1_DATA(sys_data_out1),			//读出端口1的数据输出端，16bit
		.RD1(sys_rd1),					//读出端口1的读使能端，高电平读出
		.RD1_ADDR(0),			//读出端口1的读起始地址
		.RD1_MAX_ADDR(640*480-1),		//读出端口1的读出最大地址
		.RD1_LENGTH(128),			//一次性读出数据长度
		.RD1_LOAD(~sys_rst_n),			//读出端口1 清零请求，高电平清零读出地址和fifo
		.RD1_CLK(sdr_rd1_clk),				//读出端口1 fifo读取时钟
		.RD1_EMPTY(RD1_EMPTY),			//读出端口1 fifo读空信号
		.RD1_USE(),				//读出端口1 fifo已经还可以读取的数据长度

		//	FIFO Read Side 2
		.RD2_DATA(sys_data_out2),			//读出端口2的数据输出端，16bit
		.RD2(sys_rd2),					//读出端口2的读使能端，高电平读出
		.RD2_ADDR(640*480),			//读出端口2的读起始地址
		.RD2_MAX_ADDR(640*480*2-1),		//读出端口2的读出最大地址
		.RD2_LENGTH(128),			//一次性读出数据长度
		.RD2_LOAD(~sys_rst_n),			//读出端口2清零请求，高电平清零读出地址和fifo
		.RD2_CLK(sdr_rd2_clk),				//读出端口2 fifo读取时钟
		.RD2_EMPTY(RD2_EMPTY),			//读出端口2 fifo读空信号
		.RD2_USE(),				//读出端口2 fifo已经还可以读取的数据长度

		//	SDRAM Side
		
		.SA(sdram_addr),		//SDRAM 地址线，
		.BA(sdram_ba),		//SDRAM bank地址线
		.CS_N(sdram_cs_n),		//SDRAM 片选信号
		.CKE(sdram_cke),		//SDRAM 时钟使能
		.RAS_N(sdram_ras_n),	//SDRAM 行选中信号
		.CAS_N(sdram_cas_n),	//SDRAM 列选中信号
		.WE_N(sdram_we_n),		//SDRAM 写请求信号
		.DQ(sdram_data),		//SDRAM 双向数据总线
		.SDR_CLK(sdram_clk),
		.DQM(sdram_dqm),		//SDRAM 数据总线高低字节屏蔽信号
		.Sdram_Init_Done(sdram_init_done)
	);
*/
wire sdram1_init_done;
wire sdram2_init_done;
sdram_top   sdram1_top_inst(

    .sys_clk            (clk_ref    ),  //sdram 控制器参考时钟
    .clk_out            (clk_refout ),  //用于输出的相位偏移时钟
    .sys_rst_n          (sys_rst_n         ),  //系统复位
//用户写端口
    .wr_fifo_wr_clk     (sdr_wr1_clk    ),  //写端口FIFO: 写时钟
    .wr_fifo_wr_req     (sdr_wr1_wrreq  ),  //写端口FIFO: 写使能
    .wr_fifo_wr_data    (sdr_wr1_wrdata ),  //写端口FIFO: 写数据
    .sdram_wr_b_addr    (24'd0          ),  //写SDRAM的起始地址
    .sdram_wr_e_addr    (640*480        ),  //写SDRAM的结束地址
    .wr_burst_len       (10'd512        ),  //写SDRAM时的数据突发长度⭐⭐
    .wr_rst             (~rst_n         ),  //写端口复位: 复位写地址,清空写FIFO
//用户读端口
    .rd_fifo_rd_clk     (sdr_rd1_clk    ),  //读端口FIFO: 读时钟
    .rd_fifo_rd_req     (sys_rd1        ),  //读端口FIFO: 读使能
    .rd_fifo_rd_data    (sys_data_out1  ),  //读端口FIFO: 读数据
    .sdram_rd_b_addr    (24'd0          ),  //读SDRAM的起始地址
    .sdram_rd_e_addr    (640*480        ),  //读SDRAM的结束地址
    .rd_burst_len       (10'd512        ),  //从SDRAM中读数据时的突发长度
    .rd_rst             (~sys_rst_n     ),  //读端口复位: 复位读地址,清空读FIFO
	.rdempty            (RD1_EMPTY      ),   //读空信号
//用户控制端口
    .read_valid         (1'b1           ),  //SDRAM 读使能
    .pingpang_en        (1'b1           ),  //SDRAM 乒乓操作使能
    .init_end           (sdram1_init_done),  //SDRAM 初始化完成标志
//SDRAM 芯片接口
    .sdram_clk          (sdram1_clk      ),  //SDRAM 芯片时钟
    .sdram_cke          (sdram1_cke      ),  //SDRAM 时钟有效
    .sdram_cs_n         (sdram1_cs_n     ),  //SDRAM 片选
    .sdram_ras_n        (sdram1_ras_n    ),  //SDRAM 行有效
    .sdram_cas_n        (sdram1_cas_n    ),  //SDRAM 列有效
    .sdram_we_n         (sdram1_we_n     ),  //SDRAM 写有效
    .sdram_ba           (sdram1_ba       ),  //SDRAM Bank地址
    .sdram_addr         (sdram1_addr     ),  //SDRAM 行/列地址
    .sdram_dq           (sdram1_data      )  //SDRAM 数据


);


sdram_top   sdram2_top_inst(

    .sys_clk            (clk_ref    ),  //sdram 控制器参考时钟
    .clk_out            (clk_refout ),  //用于输出的相位偏移时钟
    .sys_rst_n          (sys_rst_n         ),  //系统复位
//用户写端口
    .wr_fifo_wr_clk     (sdr_wr2_clk    ),  //写端口FIFO: 写时钟
    .wr_fifo_wr_req     (sdr_wr2_wrreq  ),  //写端口FIFO: 写使能
    .wr_fifo_wr_data    (sdr_wr2_wrdata ),  //写端口FIFO: 写数据
    .sdram_wr_b_addr    (24'd0          ),  //写SDRAM的起始地址
    .sdram_wr_e_addr    (640*480        ),  //写SDRAM的结束地址
    .wr_burst_len       (10'd512        ),  //写SDRAM时的数据突发长度⭐⭐
    .wr_rst             (~sys_rst_n     ),  //写端口复位: 复位写地址,清空写FIFO
//用户读端口
    .rd_fifo_rd_clk     (sdr_rd2_clk    ),  //读端口FIFO: 读时钟
    .rd_fifo_rd_req     (sys_rd2        ),  //读端口FIFO: 读使能
    .rd_fifo_rd_data    (sys_data_out2  ),  //读端口FIFO: 读数据
    .sdram_rd_b_addr    (24'd0          ),  //读SDRAM的起始地址
    .sdram_rd_e_addr    (640*480        ),  //读SDRAM的结束地址
    .rd_burst_len       (10'd512        ),  //从SDRAM中读数据时的突发长度
    .rd_rst             (~sys_rst_n     ),  //读端口复位: 复位读地址,清空读FIFO
	.rdempty            (RD2_EMPTY      ),   //读空信号
//用户控制端口
    .read_valid         (1'b1           ),  //SDRAM 读使能
    .pingpang_en        (1'b1           ),  //SDRAM 乒乓操作使能
    .init_end           (sdram2_init_done),  //SDRAM 初始化完成标志
//SDRAM 芯片接口
    .sdram_clk          (sdram2_clk      ),  //SDRAM 芯片时钟
    .sdram_cke          (sdram2_cke      ),  //SDRAM 时钟有效
    .sdram_cs_n         (sdram2_cs_n     ),  //SDRAM 片选
    .sdram_ras_n        (sdram2_ras_n    ),  //SDRAM 行有效
    .sdram_cas_n        (sdram2_cas_n    ),  //SDRAM 列有效
    .sdram_we_n         (sdram2_we_n     ),  //SDRAM 写有效
    .sdram_ba           (sdram2_ba       ),  //SDRAM Bank地址
    .sdram_addr         (sdram2_addr     ),  //SDRAM 行/列地址
    .sdram_dq           (sdram2_data      )  //SDRAM 数据


);
//-------------------------------------
//LCD driver timing
lcd_driver u_lcd_driver
(
	//global clock
	.clk			(clk_vga),		
	.rst_n			(sys_rst_n), 
	 
	 //lcd interface
	.lcd_dclk		(),
	.lcd_blank		(),//lcd_blank
	.lcd_sync		(),		    	
	.lcd_hs			(lcd_hs),		
	.lcd_vs			(lcd_vs),
	.lcd_en			(),		
	.lcd_rgb		(vout_data),

	
	//user interface
	.lcd_request	(lcd_request),
	.lcd_data		(sys_data_out2),	
	.lcd_xpos		(),	
	.lcd_ypos		()
);
//GRAY driver timing
lcd_driver u_gray_driver
(
	//global clock
	.clk			(clk_vga),		
	.rst_n			(sys_rst_n), 
	 
	 //lcd interface
	.lcd_dclk		(),
	.lcd_blank		(),//lcd_blank
	.lcd_sync		(),		    	
	.lcd_hs			(gray_hs),		
	.lcd_vs			(gray_vs),
	.lcd_en			(),		
	.lcd_rgb		(gray_data),

	
	//user interface
	.lcd_request	(),
	.lcd_data		(sys_data_out1),	
	.lcd_xpos		(),	
	.lcd_ypos		()
);

endmodule
