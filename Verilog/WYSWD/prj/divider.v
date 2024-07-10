module divider
#(
    parameter   frequency1 = 10'd10,   //输出频率 clk_out = 50MHz/frequency
    parameter   frequency2 = 10'd10   //输出频率 clk_out = 50MHz/frequency
)
(
    input   wire    clk_in,
    output  reg     clk_out1,
    output  reg     clk_out2
);
reg [20:0]count1;
reg [20:0]count2;

always@(posedge clk_in)
if(count1 >= (frequency1/2'd2)-1'b1)
    begin
    clk_out1 <= ~clk_out1;
    count1 <= 1'b0;
    end
else
    count1 <= count1 + 1'b1;

always@(posedge clk_in)
if(count2 >= (frequency2/2'd2)-1'b1)
    begin
    clk_out2 <= ~clk_out2;
    count2 <= 1'b0;
    end
else
    count2 <= count2 + 1'b1;
endmodule
