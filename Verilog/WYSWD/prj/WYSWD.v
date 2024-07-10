module WYSWD
( 
	input  wire CLK_50M,
    input  wire rst_n,
    
    input  wire [11:0]	ADC1_data,
    input  wire [11:0]	ADC2_data,
    
    input wire CH1_A,
    input wire CH1_B,
    input wire CH2_A,
    input wire CH2_B,
    input wire X_A,
    input wire X_B,
    input wire TIG_A,
    input wire TIG_B,
    
    input wire TIG_flag,
    
	input wire 			SAVE_key,
    input wire 			READ_key,
    input wire 			STOP_key,
    input wire 			Single_key,
    input wire 			ADC1_ouhe,
    input wire 			ADC2_ouhe,
    input wire 			bianyan_key,
    
    output wire	ADC1_CLK,
    output wire	ADC2_CLK,
	output wire	ADC1_flag,
    output wire	LDAC,
    output wire	SYNC,
    output wire	SCLK,
    output wire	DIN,
    
    output wire ADC1_tx,
    output wire ADC2_tx,
    output wire [2:0]state,
	output wire	[3:0] CH1_num,
	output wire	[3:0] CH2_num,
	output wire	[3:0] X_num,
    
    output wire CLK_100K,
    output wire 			SAVE_flag,
    output wire 			READ_flag,
    output wire 			STOP_flag,
    output wire 			Single_flag,
    output wire 			ADC1_ouhe_mode,
    output wire 			ADC2_ouhe_mode,
    output wire 			ADC1_ouhe_display,
    output wire 			ADC2_ouhe_display,
    output wire 			bianyan_flag,
    
    output wire [1:0]	REALY_AD1,
    output wire [1:0]	REALY_AD2

);
wire ADC11_CLK;
wire ADC22_CLK;

assign ADC1_CLK = ADC22_CLK | ADC11_CLK;
assign ADC2_CLK = ADC22_CLK | ADC11_CLK;

wire CLK_200M;
wire CLK_10M;
wire CLK_5;
assign ADC1_ouhe_display = ADC1_ouhe_mode;
assign ADC2_ouhe_display = ADC2_ouhe_mode;
wire	[11:0] TIG_num;
wire			ADC_flag;

PLL pll_init(
  .refclk(CLK_50M),
  .reset(1'b0),
  .clk0_out(CLK_200M),
  .clk1_out(CLK_10M) 
);
sending sending_init
(
	.sys_clk(CLK_50M),
    .rst_n(rst_n),

    .ADC1_data(ADC1_data),
    .ADC2_data(ADC2_data),
    
    .CH1_mode(CH1_num),
    .CH2_mode(CH2_num),

    .ADC_flag(ADC1_flag),
    .ADC_mode(X_num),
    .begin_flag(TIG_flag),
    .bianyan_flag(bianyan_flag),

    .  ADC1_tx(ADC1_tx),
    .  ADC2_tx(ADC2_tx),
    .	state(state)
    
);
ADC ADC_init
(
	.CLK_200M(CLK_200M),
    .ADC_mode1(X_num),


    .ADC1_CLK(ADC11_CLK),
    .ADC2_CLK(ADC22_CLK),
    .ADC1_flag(ADC1_flag),
    .ADC2_flag(ADC_flag)
);

DAC DAC_init
(
    .sys_clk(CLK_50M),
    .sys_rst_n(rst_n),
	.DA1_mode(CH1_num),
    .DA2_mode(CH2_num),
	.TIG_mode(TIG_num),
    
    .LDAC(LDAC),
    .SYNC(SYNC),
    .SCLK(SCLK),
    .DIN(DIN)
);

KEY KEY_init
(
    .sys_clk(CLK_50M),
    .CLK_5(CLK_5),
    
    .CH1_A(CH1_A),
    .CH1_B(CH1_B),

    .CH2_A(CH2_A), 
	.CH2_B(CH2_B), 
  
	.X_A(X_A),   
	.X_B(X_B),   
   
	.TIG_A(TIG_A), 
	.TIG_B(TIG_B), 
 
 	.SAVE_key(SAVE_key),
    .READ_key(READ_key),
    .STOP_key(STOP_key),
    .Single_key(Single_key),
    .ADC1_ouhe(ADC1_ouhe),
    .ADC2_ouhe(ADC2_ouhe),
    .bianyan_key(bianyan_key),
 
	.CH1_num(CH1_num),
	.CH2_num(CH2_num),
	.X_num(X_num), 
	.TIG_num(TIG_num),
    
    .SAVE_flag(SAVE_flag),
    .READ_flag(READ_flag),
    .STOP_flag(STOP_flag),
    .Single_flag(Single_flag),
    .ADC1_ouhe_mode(ADC1_ouhe_mode),
    .ADC2_ouhe_mode(ADC2_ouhe_mode),
    .bianyan_flag(bianyan_flag),
    
    .REALY_AD1(REALY_AD1),
    .REALY_AD2(REALY_AD2)
);
divider
#(
    .frequency1(10'd100),   //输出频率 clk_out = 50MHz/frequency
    .frequency2(21'd2_00_000)   //输出频率 clk_out = 50MHz/frequency
)
divider_init
(
    .clk_in(CLK_10M),
    .clk_out1(CLK_100K),
    .clk_out2(CLK_5)
);

endmodule
