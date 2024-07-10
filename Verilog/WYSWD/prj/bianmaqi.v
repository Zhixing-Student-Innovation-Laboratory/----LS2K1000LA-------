module bianmaqi(input clk,input a,input b,output reg [3:0]num);
wire clk1;//1KHz
wire clk2;//50Hz
wire a1;
wire b1;
initial
begin
num <= 4'd6;
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
if(num <4'd15)
num=num+1;
end
else
begin
if(num > 1'b0)
	begin
	num=num-1'b1;
    end
end
endmodule
