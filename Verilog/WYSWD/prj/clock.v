module clock
#(parameter pam = 10'd10)
(input wire clk,output reg clk1);

reg [31:0]fenpin;
always@(posedge clk)
if(fenpin>=pam)
begin
clk1=~clk1;
fenpin<=0;
end
else
fenpin<=fenpin+1;


endmodule
