module ADC
(
	input wire 			CLK_200M,
    input wire 	[3:0]	ADC_mode1,

    output reg			ADC1_CLK,
    output reg			ADC2_CLK,
    output reg			ADC1_flag,
    output wire			ADC2_flag
    
);

reg [19:0]	ADC1_cnt;
reg			ADC_CLK;
reg [19:0]	ADC1_aim = 20'd4999;

reg [3:0]	ADC1_flag_cnt;


assign ADC2_flag = ADC1_flag;

always@(posedge CLK_200M)//(posedge CLK_200M)
	begin
    case(ADC_mode1)
    	4'd0:ADC1_aim <= 20'd499999;
        4'd1:ADC1_aim <= 20'd249999;
        4'd2:ADC1_aim <= 20'd124999;
        4'd3:ADC1_aim <= 20'd49999;
        4'd4:ADC1_aim <= 20'd24999;
        4'd5:ADC1_aim <= 20'd9999;
        4'd6:ADC1_aim <= 20'd4999;
        4'd7:ADC1_aim <= 20'd2499;
        4'd8:ADC1_aim <= 20'd1249;
        4'd9:ADC1_aim <= 20'd499;
        4'd10:ADC1_aim <= 20'd249;
        4'd11:ADC1_aim <= 20'd324;
        4'd12:ADC1_aim <= 20'd249;
        4'd13:ADC1_aim <= 20'd209;
        4'd14:ADC1_aim <= 20'd200;
        4'd15:ADC1_aim <= 20'd200;//200
        default : ADC1_aim <= 20'd4999;
        endcase
        
    end
always@(posedge CLK_200M)
	begin
	if(ADC1_cnt == ((ADC1_aim)/2'd2))//+1'b1
    	begin
    	ADC1_CLK <= 1'b1;
        ADC2_CLK <= 1'b1;
        ADC_CLK <= 1'b1;
        ADC1_cnt <= ADC1_cnt + 1'b1;
        end
    else if(ADC1_cnt >= ADC1_aim)
    	begin
        ADC1_CLK <= 1'b0;
        ADC2_CLK <= 1'b0;
        ADC_CLK <= 1'b0;
        ADC1_cnt <= 20'd0;
        end
	else
    	ADC1_cnt <= ADC1_cnt + 1'b1;
	end



always@(posedge CLK_200M)
begin
if(ADC_CLK == 1'b0)
	begin
    if(ADC1_flag_cnt == 4'd5)
    	begin
        ADC1_flag <= 1'b0;
        end
    else
    	begin
        ADC1_flag_cnt <= ADC1_flag_cnt + 1'b1;
        ADC1_flag <= 1'b1;
        end
    end
else
	ADC1_flag_cnt <= 4'd0;

end


endmodule
