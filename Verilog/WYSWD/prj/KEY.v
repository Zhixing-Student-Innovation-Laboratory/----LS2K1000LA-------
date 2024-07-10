module KEY
(
    input wire 			sys_clk,
    input wire 			CLK_5,
    
    input wire			CH1_A,
    input wire			CH1_B,
    input wire 			CH2_A,
    input wire 			CH2_B,
    input wire 			X_A,
    input wire 			X_B,
    input wire 			TIG_A,
    input wire 			TIG_B,
    
    input wire 			SAVE_key,
    input wire 			READ_key,
    input wire 			STOP_key,
    input wire 			Single_key,
    input wire 			ADC1_ouhe,
    input wire 			ADC2_ouhe,
    input wire 			bianyan_key,
    
    output wire [3:0] 	CH1_num,
    output wire [3:0] 	CH2_num,
    output wire [3:0] 	X_num,
    output wire [11:0] 	TIG_num,
    
    output reg 			SAVE_flag,
    output reg 			READ_flag,
    output reg 			STOP_flag,
    output reg 			Single_flag,
    output reg 			ADC1_ouhe_mode = 1,
    output reg 			ADC2_ouhe_mode = 1,
    output reg 			bianyan_flag,
    
    output reg [1:0]	REALY_AD1,
    output reg [1:0]	REALY_AD2

);

reg bianyan_flag_t;
reg ADC1_ouhe_t;
reg ADC2_ouhe_t;

always@(posedge CLK_5)
begin
SAVE_flag <= SAVE_key;
READ_flag <= READ_key;
STOP_flag <= STOP_key;
Single_flag <= Single_key;
ADC1_ouhe_t <= ADC1_ouhe;
ADC2_ouhe_t <= ADC2_ouhe;
bianyan_flag_t <= bianyan_key;
end

always@(posedge bianyan_flag_t)
begin
bianyan_flag <= ~bianyan_flag;
end
always@(posedge ADC1_ouhe_t)
begin
ADC1_ouhe_mode <= ~ADC1_ouhe_mode;
end
always@(posedge ADC2_ouhe_t)
begin
ADC2_ouhe_mode <= ~ADC2_ouhe_mode;
end


always@(posedge sys_clk)//(posedge CLK_200M)
	begin
    case(CH1_num)
    	4'd0:REALY_AD1 <= 2'b11;
        4'd1:REALY_AD1 <= 2'b11;
        4'd2:REALY_AD1 <= 2'b11;
        4'd3:REALY_AD1 <= 2'b11;
        4'd4:REALY_AD1 <= 2'b01;
        4'd5:REALY_AD1 <= 2'b01;
        4'd6:REALY_AD1 <= 2'b10;
        4'd7:REALY_AD1 <= 2'b10;
        4'd8:REALY_AD1 <= 2'b10;
        4'd9:REALY_AD1 <= 2'b00;
        4'd10:REALY_AD1 <=2'b00;
        4'd11:REALY_AD1 <=2'b00;
        4'd12:REALY_AD1 <=2'b00;
        4'd13:REALY_AD1 <=2'b00;
        4'd14:REALY_AD1 <=2'b00;
        4'd15:REALY_AD1 <=2'b00;//200
        default : REALY_AD1 <= 2'b11;
        endcase
        
    end
always@(posedge sys_clk)//(posedge CLK_200M)
	begin
    case(CH2_num)
    	4'd0:REALY_AD2 <= 2'b11;
        4'd1:REALY_AD2 <= 2'b11;
        4'd2:REALY_AD2 <= 2'b11;
        4'd3:REALY_AD2 <= 2'b11;
        4'd4:REALY_AD2 <= 2'b01;
        4'd5:REALY_AD2 <= 2'b01;
        4'd6:REALY_AD2 <= 2'b10;
        4'd7:REALY_AD2 <= 2'b10;
        4'd8:REALY_AD2 <= 2'b10;
        4'd9:REALY_AD2 <= 2'b00;
        4'd10:REALY_AD2 <=2'b00;
        4'd11:REALY_AD2 <=2'b00;
        4'd12:REALY_AD2 <= 2'b00;
        4'd13:REALY_AD2 <= 2'b00;
        4'd14:REALY_AD2 <= 2'b00;
        4'd15:REALY_AD2 <= 2'b00;//200
        default : REALY_AD2 <= 2'b11;
        endcase
        
    end
bianmaqi	bianmaqi_init1
(.clk(sys_clk),.a(CH1_A),.b(CH1_B),.num(CH1_num));

bianmaqi	bianmaqi_init2
(.clk(sys_clk),.a(CH2_A),.b(CH2_B),.num(CH2_num));

bianmaqi	bianmaqi_init3
(.clk(sys_clk),.a(X_A),.b(X_B),.num(X_num));

bianmaqi_dingzhi	bianmaqi_init4
(.clk(sys_clk),.a(TIG_A),.b(TIG_B),.num(TIG_num));


endmodule
