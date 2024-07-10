module DAC
(
    input wire	sys_clk,
    input wire	sys_rst_n,
	input wire	[3:0]	DA1_mode,
    input wire	[3:0]	DA2_mode,
    input wire	[11:0]	TIG_mode,
    
    output reg LDAC,
    output reg SYNC,
    output reg SCLK,
    output reg DIN
);
reg	[1:0] channel;
reg	key_flag;
reg	[26:0]	flag_cnt;
reg [15:0]	Data;
reg [2:0]	DA1_mode_temp;
reg [2:0]	DA2_mode_temp;
parameter       IDLE  = 2'b01,          //等待状态
                WREN  = 2'b10;          //开始写数据


reg         [3:0]           state;
reg         [1:0]           cnt_clk1;        //开始等待时间         自动溢出，下面需要该最大数字
reg         [5:0]           cnt_clk2;        //发送数据时间
reg         [1:0]           cnt_clk3;        //结尾等待时间         自动溢出，下面需要该最大数字
reg         [3:0]           cnt_byte;
reg         [1:0]           cnt_sck;
reg         [3:0]           cnt_bit;        //写1bit数据时钟
integer i;
reg [11:0]nnn;
initial
	begin
		LDAC <= 1'b0;
        Data <= 16'b0000_1000_1111_000_0;
	end
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
    	begin
        key_flag <= 1'b0;
        flag_cnt <= 27'd0;
        end
     else   
        begin
        if(flag_cnt == 27'd10_000_000)
        	begin
        	key_flag <= 1'b1;
            flag_cnt <= 27'd0;
            
            channel <= channel + 1'b1;
            if(channel == 2'd0)
            	begin
                case(DA1_mode)
                4'd0:Data <= 16'b1100_1101_1100_000_0;
   				4'd1:Data <= 16'b0011_0111_1100_000_0;
   				4'd2:Data <= 16'b1001_0010_0010_000_0;
   				4'd3:Data <= 16'b1001_1011_1010_000_0;
   				4'd4:Data <= 16'b0000_0111_1000_000_0;
   				4'd5:Data <= 16'b1110_1010_0100_000_0;//?
   				4'd6:Data <= 16'b0111_0111_1100_000_0;
   				4'd7:Data <= 16'b0001_0010_0010_000_0;
   				4'd8:Data <= 16'b0110_1111_1010_000_0;
   				4'd9:Data <= 16'b0100_0111_1000_000_0;
   				4'd10:Data <= 16'b0000_1010_0100_000_0;//20mv
   				4'd11:Data <= 16'b0000_0111_0100_000_0;//10mv
   				4'd12:Data <= 16'b0101_1110_1100_000_0;//5mv
   				4'd13:Data <= 16'b0000_0011_1100_000_0;//4mv
   				4'd14:Data <= 16'b0000_0001_1010_000_0;//2mv
   				4'd15:Data <= 16'b0000_0001_1010_000_0;//2mv
   				default : Data <= 16'b0000_0000_0000_000_0;
   				endcase
                end
            else if(channel == 2'd1)
            	begin
                case(DA2_mode)
                4'd0:Data <= 16'b0001_0111_1100_100_0;
   				4'd1:Data <= 16'b1001_0100_0010_100_0;
   				4'd2:Data <= 16'b1111_1110_0010_100_0;
   				4'd3:Data <= 16'b1000_0111_1010_100_0;//
   				4'd4:Data <= 16'b1011_0010_0100_100_0;//0.4v
   				4'd5:Data <= 16'b0011_0011_0100_100_0;//
   				4'd6:Data <= 16'b0010_0100_0010_100_0;//
   				4'd7:Data <= 16'b1111_0001_0010_100_0;
   				4'd8:Data <= 16'b1000_0000_0110_100_0;//
   				4'd9:Data <= 16'b0000_1010_0100_100_0;
   				4'd10:Data <= 16'b0101_0011_0100_100_0;//
   				4'd11:Data <= 16'b0111_1000_1100_100_0;//
   				4'd12:Data <= 16'b0100_1010_1100_100_0;
   				4'd13:Data <= 16'b1000_1011_1100_100_0;
   				4'd14:Data <= 16'b0010_1111_1000_100_0;
   				4'd15:Data <= 16'b0010_1111_1000_100_0;
   				default : Data <= 16'b0000_0000_0000_100_0;
   				endcase
                end
            else if(channel == 2'd2)
            	begin

                Data <= ((TIG_mode<<11 & 12'b1000_0000_0000) + (TIG_mode<<9 & 12'b0100_0000_0000) + (TIG_mode<<7 & 12'b0010_0000_0000) + (TIG_mode<<5 & 12'b0001_0000_0000) + (TIG_mode<<3 & 12'b0000_1000_0000) + (TIG_mode<<11 & 12'b1000_0000_0000) + (TIG_mode<<1 & 12'b000_0100_0000) + (TIG_mode>>11 & 12'b0000_0000_0001) + (TIG_mode>>9 & 12'b0000_0000_0010) + (TIG_mode>>7 & 12'b0000_0000_0100) + (TIG_mode>>5 & 12'b0000_0000_1000) + (TIG_mode>>3 & 12'b0000_0001_0000) + (TIG_mode>>1 & 12'b0000_0010_0000))*16+4;
                end    
            end
        else
        	begin
            key_flag <= 1'b0;
            flag_cnt <= flag_cnt + 1'b1;
            end
        end
        
//always@(posedge sys_clk or negedge sys_rst_n)
//	if(sys_rst_n == 0)
//    	begin
//        Data <= 16'd0;
//        end
//	else











    
always@(posedge sys_clk or negedge sys_rst_n)       //模式切换
    if(sys_rst_n == 0)
        state <= IDLE;
    else
        case(state)
            IDLE    :   if(key_flag == 1)state <= WREN;     //开始写
            WREN    :   if(cnt_byte == 4'd2 && cnt_clk3 == 2'd3)state <= IDLE;
            default :   state <= IDLE;
        endcase    

always@(posedge sys_clk or negedge sys_rst_n)//*********三个阶段的计时器       
    if(sys_rst_n == 0)
        cnt_clk1 <= 2'd0;
    else if(state != IDLE && cnt_byte == 4'd0)
        cnt_clk1 <= cnt_clk1 + 1;
always@(posedge sys_clk or negedge sys_rst_n)       
    if(sys_rst_n == 0)
        cnt_clk2 <= 6'd0;
    else if(state != IDLE && cnt_byte == 4'd1)
        cnt_clk2 <= cnt_clk2 + 1;       
always@(posedge sys_clk or negedge sys_rst_n)//*********三个阶段的计时器       
    if(sys_rst_n == 0)
        cnt_clk3 <= 2'd0;
    else if(state != IDLE && cnt_byte == 4'd2)
        cnt_clk3 <= cnt_clk3 + 1;

always@(posedge sys_clk or negedge sys_rst_n)       //写入时三个阶段的切换
    if(sys_rst_n == 0)
        cnt_byte <= 0;
    else if(cnt_byte == 4'd0 && cnt_clk1 == 2'd3)
        cnt_byte <= 1;
    else if(cnt_byte == 4'd1 && cnt_clk2 == 6'd63)
        cnt_byte <= 2;
    else if(cnt_byte == 4'd2 && cnt_clk3 == 2'd3)
        cnt_byte <= 0;         


always@(posedge sys_clk or negedge sys_rst_n)       //4分频产生spi时钟
    if(sys_rst_n == 0)
        cnt_sck <= 2'd0;
    else if(state == WREN && cnt_byte == 4'd1)
        cnt_sck <= cnt_sck + 1;


always@(posedge sys_clk or negedge sys_rst_n)       //计算当前是第几bit
    if(sys_rst_n == 0)        
        cnt_bit <= 3'b0;
    else if(cnt_sck == 2'd2)        
        cnt_bit <= cnt_bit + 1'b1;

always@(posedge sys_clk or negedge sys_rst_n)       //从机选择信号，写完自动拉高
    if(sys_rst_n == 0)
        SYNC <= 1;
    else if(key_flag == 1)
        SYNC <= 0;
    else if(cnt_byte == 4'd2 && cnt_clk3 == 2'd3 && state == WREN)
        SYNC <= 1;


always@(posedge sys_clk or negedge sys_rst_n)       //数据注入
    if(sys_rst_n == 0)
        DIN <= 0;
    else if(state == WREN && cnt_byte == 4'd2)
        DIN <= 0;
    else if(state == WREN && cnt_byte == 4'd1 && cnt_sck == 2'd0)
        DIN <= Data[cnt_bit];



always@(posedge sys_clk or negedge sys_rst_n)//spi时钟翻转
    if(sys_rst_n == 0)
        SCLK  <= 1;
    else if(cnt_sck == 2'd0)
        SCLK  <= 1;
    else if(cnt_sck == 2'd2)
        SCLK  <= 0;


endmodule
