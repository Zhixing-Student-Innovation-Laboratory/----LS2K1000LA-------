module xiaodou(input clk,input in,output reg out);
reg flag=1'd0;
always@(posedge clk)
begin
out=flag|in;
flag<=in;
end


endmodule
