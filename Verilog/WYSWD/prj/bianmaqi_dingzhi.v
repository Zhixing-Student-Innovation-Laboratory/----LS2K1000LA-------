module bianmaqi_dingzhi(input clk,input a,input b,output reg [11:0]num);
wire clk1;//1KHz
wire clk2;//50Hz
wire a1;
wire b1;
initial
begin
num <= 12'b0111_1111_1111;
end
clock #(.pam(16'd49999)) clock1(
.clk(clk),
.clk1(clk1)
);
clock #(.pam(20'd999999)) clock2(
.clk(clk),
.clk1(clk2)
);
xiaodou xiaodou_init1(
.clk(clk1),
.in(a),
.out(a1)
);
xiaodou xiaodou_init2(
.clk(clk1),
.in(b),
.out(b1)
);
always@(posedge a1)
if(b1)
begin
if(num <12'd3996)
num=num+7'd100;
end
else
begin
if(num > 12'd99)
	begin
	num=num-7'd100;
    end
end
endmodule

