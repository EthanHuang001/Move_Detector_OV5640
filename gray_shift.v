`timescale 1ns/ 1ns 
module gray_shift( 
                  clk, 
                  resetb, 
                  clken, 
                  ivsync, 
                  ihsync,
					   graya, 
                  grayb, 
				     //output		
                 oe,    //实时数据流
					   ovsync,
					   ohsync ,
					   //oclken,
					   ogray,
                  sdr_rd, //读sdram
						sdr_nwr //停止写入sdram             
) ; 
input         clk; 
input         resetb; 
input         clken; 
input         ivsync; 
input         ihsync; 
input  [ 7 : 0] graya;  //next 
input  [ 7 : 0] grayb;  //before 
output        oe;   //使能信号
output        sdr_rd; //延时一帧的使能信号
output        sdr_nwr;
output [ 15: 0] ogray; 
output        ovsync ;
output        ohsync ;
//output        oclken ;



/*reg[20:0] cent_x;
always@(posedge clk or negedge resetb) begin 
    if ( (!resetb)|(cent_x==307199)) 
        cent_x <=  0; 
    else 
        cent_x <= (cent_x+1);
end 
*/


parameter ck2q = 1; 

reg oe; 
always@(posedge clk or negedge resetb) begin 
    if ( !resetb) 
        oe <= # ck2q 0; 
    else 
        oe <= # ck2q ( clken & ivsync & ihsync) ; 
end 
reg ivsync_d0; 
always@(posedge clk or negedge resetb) begin 
    if ( !resetb) 
        ivsync_d0 <= # ck2q 0; 
    else 
        ivsync_d0 <= # ck2q ivsync; 
end 

reg ihsync_d0; 
always@(posedge clk or negedge resetb) begin 
    if ( !resetb) 
        ihsync_d0 <= # ck2q 0; 
    else 
        ihsync_d0 <= # ck2q ihsync; 
end 

reg clken_d0; 
always@(posedge clk or negedge resetb) begin 
    if ( !resetb) 
        clken_d0 <= # ck2q 0; 
    else 
        clken_d0 <= # ck2q clken; 
end 

reg rd_en; 
always@(posedge clk or negedge resetb) begin 
    if ( !resetb) 
        rd_en <= # ck2q 0; 
		      else if(~ivsync & ivsync_d0) 
        rd_en <= # ck2q 1'b1; 
end 
 
assign sdr_rd = rd_en & clken; 
assign sdr_nwr =rd_en ;
reg [ 7:0] graya_d0; 
always@(posedge clk or negedge resetb) begin 
    if ( !resetb) 
        graya_d0 <= # ck2q 0; 
    else 
        graya_d0 <= # ck2q graya; 
end 


assign ovsync = ivsync_d0 ;
assign ohsync = ihsync_d0 ;
//assign oclken = clken_d0  ;
assign ogray  = {graya_d0, grayb} ;

//assign ogray  = oe ? { graya_d0, grayb} : 16'd0; 

endmodule 

		  
		  
		  