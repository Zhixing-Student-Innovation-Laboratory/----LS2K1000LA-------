module sending
(
	input wire sys_clk,
    input wire rst_n,
    
    input wire [11:0]	ADC1_data,
    input wire [11:0]	ADC2_data,
    
    input wire [3:0]	CH1_mode,
    input wire [3:0]	CH2_mode,
    
    input wire ADC_flag,
    input wire [3:0] ADC_mode,
    input wire begin_flag,
    input wire bianyan_flag,
    
    output wire  ADC1_tx,
    output wire  ADC2_tx,
    output reg [2:0] state
);
reg [9:0] ADC1_buchang;
reg [9:0] ADC2_buchang;

reg [7:0] ADC2_data400[799:0];
reg [9:0] ADC_cnt_400;
reg [9:0] UART_cnt_400;
reg UART_CLK;
reg UART_flag;
reg [2:0] UART_flag_cnt;
reg [30:0]	UART_cnt;


reg ADC_EN = 1'b0;
reg UART_EN = 1'b0;
wire begin_flag_reality;
reg ADC_full;
reg ADC_empty;

reg [8:0]	buchang;


reg [7:0] UART1_send;
reg [7:0] UART2_send;


assign begin_flag_reality = bianyan_flag ^ (begin_flag & rst_n);
//always@(posedge sys_clk)
//begin
//if(begin_flag_reality == 0)
//	begin
//     case(CH2_mode)
//	4'd0:ADC2_buchang <= 10'd80;
//    4'd1:ADC2_buchang <= 10'd80;
//    4'd2:ADC2_buchang <= 10'd80;
//    4'd3:ADC2_buchang <= 10'd80;
//    4'd4:ADC2_buchang <= 10'd80;//tiaohao80
//    4'd5:ADC2_buchang <= 10'd80;
//    4'd6:ADC2_buchang <= 10'd82;//
//    4'd7:ADC2_buchang <= 10'd82;
//    4'd8:ADC2_buchang <= 10'd82;
//    4'd9:ADC2_buchang <= 10'd80;
//    4'd10:ADC2_buchang <= 10'd80;
//    4'd11:ADC2_buchang <= 10'd80;
//    4'd12:ADC2_buchang <= 10'd80;
//    4'd13:ADC2_buchang <= 10'd80;
//    4'd14:ADC2_buchang <= 10'd82;
//    4'd15:ADC2_buchang <= 10'd82;
//    default : ADC2_buchang <= 10'd82;
//    endcase
//    end
// end   
always@(posedge sys_clk)
begin
if(begin_flag_reality == 0)
	begin
    case(CH2_mode)
	4'd0:ADC2_buchang <= 10'd81;
    4'd1:ADC2_buchang <= 10'd81;
    4'd2:ADC2_buchang <= 10'd80;
    4'd3:ADC2_buchang <= 10'd81;
    4'd4:ADC2_buchang <= 10'd82;//tiaohao80
    4'd5:ADC2_buchang <= 10'd82;
    4'd6:ADC2_buchang <= 10'd82;//
    4'd7:ADC2_buchang <= 10'd82;
    4'd8:ADC2_buchang <= 10'd82;
    4'd9:ADC2_buchang <= 10'd80;
    4'd10:ADC2_buchang <= 10'd80;
    4'd11:ADC2_buchang <= 10'd80;
    4'd12:ADC2_buchang <= 10'd80;
    4'd13:ADC2_buchang <= 10'd80;
    4'd14:ADC2_buchang <= 10'd82;
    4'd15:ADC2_buchang <= 10'd82;
    default : ADC2_buchang <= 10'd82;
    endcase
	case(CH1_mode)//tongdaotx2
	4'd0:ADC1_buchang <= 10'd80;//80
    4'd1:ADC1_buchang <= 10'd80;
    4'd2:ADC1_buchang <= 10'd80;
    4'd3:ADC1_buchang <= 10'd80;
    4'd4:ADC1_buchang <= 10'd80;//
    4'd5:ADC1_buchang <= 10'd80;
    4'd6:ADC1_buchang <= 10'd80;//
    4'd7:ADC1_buchang <= 10'd80;
    4'd8:ADC1_buchang <= 10'd80;
    4'd9:ADC1_buchang <= 10'd80;//
    4'd10:ADC1_buchang <= 10'd80;
    4'd11:ADC1_buchang <= 10'd81;
    4'd12:ADC1_buchang <= 10'd83;
    4'd13:ADC1_buchang <= 10'd84;
    4'd14:ADC1_buchang <= 10'd71;
    4'd15:ADC1_buchang <= 10'd71;
    default : ADC1_buchang <= 10'd80;
    endcase
   
    end
end
always@(posedge sys_clk)
begin
if(begin_flag_reality == 0)
begin
if(ADC_mode == 4'd15)
	buchang <= 9'd200;
else
	buchang <= 9'd400;
    end
end    
parameter       EMPTY  			= 3'b000,          //
                BEGIN   		= 3'b001,         //
                WAIT  		    = 3'b100,         //
                MEASUREEND  	= 3'b010,          //
                ALLEND  		= 3'b011;          //

reg WAIT_flag;
reg [23:0]WAIT_cnt;
always@(posedge sys_clk)       //模式切换
	begin
        case(state)
            EMPTY    		:   if(begin_flag_reality == 1)begin state <= BEGIN; end    
            BEGIN    		:   if(ADC_full == 1'b1)begin state <= WAIT;end
            WAIT			:	if(WAIT_flag == 1'b1)begin state <= MEASUREEND;end
            MEASUREEND		:   if(ADC_empty == 1'b1)begin state <= ALLEND;end
            ALLEND   		:   if(begin_flag_reality == 0)begin state <= EMPTY;end
            default 		:   begin state <= EMPTY;end
        endcase   
    end
    
always@(posedge sys_clk)
    if(state == WAIT)
    	begin
        if(WAIT_cnt == 24'd5_000_000)
        	begin
            WAIT_flag <= 1'b1;
           
            end
        else
        	begin
            WAIT_cnt <= WAIT_cnt + 1'b1;
            end
        end
    else
    	begin
        WAIT_flag <= 1'b0;
        WAIT_cnt <= 24'd0;
        end

    
always@(posedge ADC_flag)//ADC_flag
	begin
	if(state == BEGIN)
    	begin
        if(ADC_cnt_400 == buchang)
        	begin
        	ADC_full = 1'b1;
            end
        else
        	begin
			if(buchang == 9'd400)
            begin
            if(ADC2_data >= 12'd2864)
            begin
            ADC2_data400[ADC_cnt_400] = 8'd0;//(((ADC2_data>>4)-63)*255)/132;//>>4;
        	ADC2_data400[ADC_cnt_400+400] = 8'd0;//(((ADC1_data>>4)-63)*255)/132;//>>4;
            end
            else if(ADC2_data <= 12'd1232)
            begin
            ADC2_data400[ADC_cnt_400] = 8'd255;//(((ADC2_data>>4)-63)*255)/132;//>>4;
        	ADC2_data400[ADC_cnt_400+400] = 8'd255;//(((ADC1_data>>4)-63)*255)/132;//>>4;
            end
            else
            begin

            ADC2_data400[ADC_cnt_400] =8'd255 - (((ADC2_data>>4) - ADC1_buchang)*255)/95 - ((((ADC2_data>>4) - ADC1_buchang)*255)%95 >= 48);//(((ADC2_data>>4)-63)*255)/132;//>>4;
        	ADC2_data400[ADC_cnt_400+400] =8'd255 - (((ADC1_data>>4) - ADC2_buchang)*255)/95 - ((((ADC1_data>>4) - ADC2_buchang)*255)%95 >= 48);//(((ADC1_data>>4)-63)*255)/132;//>>4;
        
            end
            end
            else
            begin
            if(ADC2_data >= 12'd2864)
            begin
            ADC2_data400[(ADC_cnt_400*2)] = 8'd0;//(((ADC2_data>>4)-63)*255)/132;//>>4;
            ADC2_data400[(ADC_cnt_400*2)+1] = 8'd0;//(((ADC2_data>>4)-63)*255)/132;//>>4;
        	ADC2_data400[(ADC_cnt_400*2)+400] = 8'd0;//(((ADC1_data>>4)-63)*255)/132;//>>4;
            ADC2_data400[(ADC_cnt_400*2)+401] = 8'd0;//(((ADC1_data>>4)-63)*255)/132;//>>4;
            end
            else if(ADC2_data <= 12'd1232)
            begin
            ADC2_data400[(ADC_cnt_400*2)] = 8'd255;//(((ADC2_data>>4)-63)*255)/132;//>>4;
            ADC2_data400[(ADC_cnt_400*2)+1] = 8'd255;//(((ADC2_data>>4)-63)*255)/132;//>>4;
        	ADC2_data400[(ADC_cnt_400*2)+400] = 8'd255;//(((ADC1_data>>4)-63)*255)/132;//>>4;
            ADC2_data400[(ADC_cnt_400*2)+401] = 8'd255;//(((ADC1_data>>4)-63)*255)/132;//>>4;
            end
            else
            begin

            ADC2_data400[(ADC_cnt_400*2)] =8'd255 - (((ADC2_data>>4) - ADC1_buchang)*255)/95 - ((((ADC2_data>>4) - ADC1_buchang)*255)%95 >= 48);//(((ADC2_data>>4)-63)*255)/132;//>>4;
            ADC2_data400[(ADC_cnt_400*2)+1] =8'd255 - (((ADC2_data>>4) - ADC1_buchang)*255)/95 - ((((ADC2_data>>4) - ADC1_buchang)*255)%95 >= 48);//(((ADC2_data>>4)-63)*255)/132;//>>4;
        	ADC2_data400[(ADC_cnt_400*2)+400] =8'd255 - (((ADC1_data>>4) - ADC2_buchang)*255)/95 - ((((ADC1_data>>4) - ADC2_buchang)*255)%95 >= 48);//(((ADC1_data>>4)-63)*255)/132;//>>4;
            ADC2_data400[(ADC_cnt_400*2)+401] =8'd255 - (((ADC1_data>>4) - ADC2_buchang)*255)/95 - ((((ADC1_data>>4) - ADC2_buchang)*255)%95 >= 48);//(((ADC1_data>>4)-63)*255)/132;//>>4;
            end
            end
            ADC_cnt_400 = ADC_cnt_400 + 1'b1;
            end
        end
    else
    	begin
        ADC_cnt_400 = 1'b0;
        ADC_full = 1'b0;
        end
	end

always@(posedge UART_flag)
	begin
	if(state == MEASUREEND)
    	begin
        if(UART_cnt_400 == 10'd800)
        	begin
        	ADC_empty = 1'b1;
            UART_EN = 1'b0;
            end
        else
        	begin
            UART_EN = 1'b1;
			UART2_send = ADC2_data400[UART_cnt_400];
            UART_cnt_400 = UART_cnt_400 + 1'b1;
            ADC_empty = 1'b0;
            end
        end
    else
    	begin
        UART_cnt_400 = 9'd0;
        ADC_empty = 1'b0;
        UART_EN = 1'b0;
        end
	end




    
always@(posedge sys_clk)
	begin
	if(UART_cnt == 25'd2499)//2499
    	begin
    	UART_CLK <= 1'b0;
        UART_cnt <= UART_cnt + 1'b1;
        end
    else if(UART_cnt == 25'd4999)//4999
    	begin
        UART_CLK <= 1'b1;
        UART_cnt <= 14'd0;
        end
	else
    	UART_cnt <= UART_cnt + 1'b1;
	end
always@(posedge sys_clk)
begin
if(UART_CLK == 1'b1)
	begin
    if(UART_flag_cnt == 3'd2)
    	begin
        UART_flag <= 1'b0;
        end
    else
    	begin
        UART_flag_cnt <= UART_flag_cnt + 1'b1;
        UART_flag <= 1'b1;
        end
    end
else
	UART_flag_cnt <= 3'd0;    
end    


tx
#(
    .UART_BPS(18'd115200),
    .CLK_FREQ(28'd50_000_000)
)
tx_init1
(
    .sys_clk(sys_clk),
    .sys_rst(UART_EN),//UART_EN
    .pi_data(UART1_send),
    .pi_flag(UART_flag),

    .tx_wire(ADC1_tx)
);
tx
#(
    .UART_BPS(18'd115200),
    .CLK_FREQ(28'd50_000_000)
)
tx_init2
(
    .sys_clk(sys_clk),
    .sys_rst(UART_EN),
    .pi_data(UART2_send),
    .pi_flag(UART_flag),

    .tx_wire(ADC2_tx)
);
endmodule
