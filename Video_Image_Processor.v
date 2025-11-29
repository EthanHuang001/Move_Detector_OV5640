`timescale 1ns/1ns
module Video_Image_Processor
#(
	parameter	[9:0]	IMG_HDISP = 10'd640,	//640*480
	parameter	[9:0]	IMG_VDISP = 10'd480
)
(
	//global clock
	input				clk,  				//cmos video pixel clock
	input				rst_n,				//global reset

	//Image data prepred to be processd
	input          cmos_frame_clken,	               
	input          cmos_frame_vsync,	
	input          cmos_frame_href,	
	input  [15:0]  cmos_frame_data, 

	//Image data has been processd
	output			post_frame_vsync,	//Processed Image data vsync valid signal
	output			post_frame_href,	//Processed Image data href vaild  signal
	output         post_frame_clken,
	output [15:0]	post_img_data,		//Processed Image Gray output
	input  [15:0]  sys_data_out1,//sdram
	output         gs_clken ,
	output  [15:0] gray_sft ,
	output         sdr_rd ,
	//user interface
	input		[7:0]	Sobel_Threshold	,	//Sobel Threshold for image edge detect	

output         gs_vsync 
);

wire        gs_vsync_1;
assign 		gs_vsync = gs_vsync_1;
wire        gs_href  ;
wire        sdr_nwr;

wire        post0_frame_vsync ;	
wire        post0_frame_href  ;	
wire        post0_frame_clken ;	
wire [7:0]  post0_data_Y   ;		

wire			post1_frame_vsync;	//Processed Image data vsync valid signal
wire			post1_frame_href;	//Processed Image data href vaild  signal
wire			post1_frame_clken;	//Processed Image data output/capture enable clock
wire	[7:0]	post1_data_diff;		//Processed Image Bit flag outout(1: Value, 0:inValid)
		
wire			post2_frame_vsync;	//Processed Image data vsync valid signal
wire			post2_frame_href;	//Processed Image data href vaild  signal
wire			post2_frame_clken;	//Processed Image data output/capture enable clock
wire			post2_img_Bit;		//Processed Image Bit flag outout(1: Value, 0:inValid)

wire			post3_frame_vsync;	//Processed Image data vsync valid signal
wire			post3_frame_href;	//Processed Image data href vaild  signal
wire			post3_frame_clken;	//Processed Image data output/capture enable clock
wire			post3_img_Bit;		//Pro

rgb_to_ycbcr	rgb_to_ycbcr_u0(
					.clk   (clk),
					.i_r_8b({cmos_frame_data[15:11],3'b111}),
					.i_g_8b({cmos_frame_data[10:5] ,2'b11}),
					.i_b_8b({cmos_frame_data[4:0],3'b111}),

					.i_h_sync (cmos_frame_href),
					.i_v_sync (cmos_frame_vsync),
					.i_data_en(cmos_frame_clken),

					.o_y_8b(post0_data_Y),
					.o_cb_8b(),
					.o_cr_8b(),

					.o_h_sync(post0_frame_href),
					.o_v_sync(post0_frame_vsync),                                                                                                  
					.o_data_en(post0_frame_clken)   
);
//step2
gray_shift    u_gray_shift( 
                  .clk    ( clk  ) , 
                  .resetb ( rst_n ) , 
                  .clken  ( post0_frame_clken) , 
                  .ivsync ( post0_frame_vsync ) , 
                  .ihsync ( post0_frame_href ) , 
                  .graya  ( post0_data_Y ) ,  //next frame 
                  .grayb  ( sys_data_out1) ,  //before frame
						
                  .oe     ( gs_clken ) ,
					   .ovsync ( gs_vsync_1),
					   .ohsync ( gs_href) ,
					   //.oclken ( gs_clken),	
					   .ogray  ( gray_sft ), 	
                  .sdr_rd ( sdr_rd   ) , 
						.sdr_nwr( sdr_nwr  )

						);
//step3					
//--------------------------------------------------	
Diff_frame Diff_frame_inst
(
	.clk              (clk) ,	// input  clk
	.rst_n            (rst_n) ,	// input  rst_n
	//.data_en(data_en),
	.per_frame_vsync  (gs_vsync_1),
	.per_frame_href   (gs_href),
	.per_frame_clken  (gs_clken),
	.data_cur         (gray_sft[7:0]) ,	// input [7:0] data1
	.data_next        (gray_sft[15:8]) ,	// input [7:0] data2
	.threshold        (Sobel_Threshold ) ,	// input [7:0] threshold
	//Image data has been processd
	.post_frame_vsync	(post1_frame_vsync),		//Processed Image data vsync valid signal
	.post_frame_href	(post1_frame_href),		//Processed Image data href vaild  signal
	.post_frame_clken	(post1_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_Bit		(post1_data_diff)			//Processed Image Bit flag outout(1: Value, 0:inValid)

);



VIP_Bit_Erosion_Detector
#(
	.IMG_HDISP	(10'd640),	//640*480
	.IMG_VDISP	(10'd480)
)
u_VIP_Bit_Erosion_Detector
(
	//global clock
	.clk					(clk),  				//cmos video pixel clock
	.rst_n					(rst_n),				//global reset

	//Image data prepred to be processd
	.per_frame_vsync		(post1_frame_vsync),	//Prepared Image data vsync valid signal
	.per_frame_href		(post1_frame_href),		//Prepared Image data href vaild  signal
	.per_frame_clken		(post1_frame_clken),	//Prepared Image data output/capture enable clock
	.per_img_Bit			(post1_data_diff[7]),		//Processed Image Bit flag outout(1: Value, 0:inValid)

	//Image data has been processd
	.post_frame_vsync		(post2_frame_vsync),		//Processed Image data vsync valid signal
	.post_frame_href		(post2_frame_href),		//Processed Image data href vaild  signal
	.post_frame_clken		(post2_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_Bit			(post2_img_Bit)			//Processed Image Bit flag outout(1: Value, 0:inValid)
);

//step4
//--------------------------------------
//Bit Image Process with Dilation after Erosion Detector.

VIP_Bit_Dilation_Detector
#(
	.IMG_HDISP	(10'd640),	//640*480
	.IMG_VDISP	(10'd480)
)
u_VIP_Bit_Dilation_Detector
(
	//global clock
	.clk					(clk),  				//cmos video pixel clock
	.rst_n					(rst_n),				//global reset

	//Image data prepred to be processd
	.per_frame_vsync		(post2_frame_vsync),	//Prepared Image data vsync valid signal
	.per_frame_href		(post2_frame_href),		//Prepared Image data href vaild  signal
	.per_frame_clken		(post2_frame_clken),	//Prepared Image data output/capture enable clock
	.per_img_Bit			(post2_img_Bit),		//Processed Image Bit flag outout(1: Value, 0:inValid)

	//Image data has been processd
	.post_frame_vsync		(post3_frame_vsync),		//Processed Image data vsync valid signal
	.post_frame_href		(post3_frame_href),		//Processed Image data href vaild  signal
	.post_frame_clken		(post3_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_Bit			(post3_img_Bit)			//Processed Image Bit flag outout(1: Value, 0:inValid)
);

//--------------------------------------------------------------------
find_box	
#(
	.IMG_Width	(11'd640),	//640*480
	.IMG_High	(11'd480)
)
find_box_u0
(
	//global clock
	.clk					(clk),  			//cmos video pixel clock
	.rst_n					(rst_n),			//global reset

	//Image data prepred to be processd
	.per_frame_vsync		(post3_frame_vsync),		//Prepared Image data vsync valid signal
	.per_frame_href		(post3_frame_href),		//Prepared Image data href vaild  signal
	.per_frame_clken		(post3_frame_clken),		//Prepared Image data output/capture enable clock
	.per_img_Y		      (post3_img_Bit),			//Prepared Image brightness input

	.cmos_frame_clken		(cmos_frame_clken), 	//Prepared Image data vsync valid signal
	.cmos_frame_vsync		(cmos_frame_vsync), 		//Prepared Image data href vaild  signal
	.cmos_frame_href		(cmos_frame_href ), 	//Prepared Image data output/capture enable clock
	.cmos_frame_data     (cmos_frame_data),			//Prepared Image brightness input

	//Image data has been processd
	.post_frame_vsync		(post_frame_vsync),		//Processed Image data vsync valid signal
	.post_frame_href		(post_frame_href),		//Processed Image data href vaild  signal
	.post_frame_clken		(post_frame_clken),		//Processed Image data output/capture enable clock
	.post_img_Y    	   (post_img_data)			//Processed Image brightness output
);
	

endmodule
