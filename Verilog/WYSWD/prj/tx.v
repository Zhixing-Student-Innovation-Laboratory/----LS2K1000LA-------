module tx
#(
    parameter   UART_BPS    =   30'd9600,
    parameter   CLK_FREQ    =   30'd50_000_000
)
(
    input       wire                    sys_clk,
    input       wire                    sys_rst,
    input       wire        [7:0]       pi_data,
    input       wire                    pi_flag,
    
    output      reg                     tx_wire
);

parameter BAUD_CNT_MAX = CLK_FREQ/UART_BPS;      //1/50MHZ = 20ns,( ( 1/9600(波特率) )*10e9 )/20ns = 5208

reg                 work_en     ;
reg     [15:0]      baud_cnt    ;
reg                 bit_flag    ;
reg     [3:0]       bit_cnt     ;

always@(posedge sys_clk or negedge sys_rst)             //使能信号
    if(sys_rst == 1'b0)
        work_en <= 1'b0;
    else if(pi_flag == 1'b1)
        work_en <= 1'b1;
    else if((bit_cnt == 4'd9) && (bit_flag == 1'b1))
        work_en <= 1'b0;

always@(posedge sys_clk or negedge sys_rst)              //波特率计算
    if(sys_rst == 1'b0)
        baud_cnt <= 16'd0;
    else if((baud_cnt == BAUD_CNT_MAX) || (work_en == 1'b0))
        baud_cnt <= 16'd0;
    else if(work_en == 1'b1)
        baud_cnt <= baud_cnt + 1'd1;

always@(posedge sys_clk or negedge sys_rst)              //比特标志信号
    if(sys_rst == 1'b0)
        bit_flag <= 1'b0;
    else if(baud_cnt == 16'b1)
        bit_flag <= 1'b1;
    else
        bit_flag <= 1'b0;
        
always@(posedge sys_clk or negedge sys_rst)              //比特计数器
    if(sys_rst == 1'b0)        
        bit_cnt <= 4'd0;
    else if((bit_cnt == 4'd9) && (bit_flag == 1'b1))
        bit_cnt <= 4'd0;
    else if((work_en == 1'b1) && (bit_flag == 1'b1))
        bit_cnt <= bit_cnt + 1'b1;
        
always@(posedge sys_clk or negedge sys_rst)              //数据输出
    if(sys_rst == 1'b0)          
        tx_wire = 1'b1;
    else if(bit_flag == 1'b1)
        case(bit_cnt)
            0   : tx_wire <= 1'b0;
            1   : tx_wire <= pi_data[0];
            2   : tx_wire <= pi_data[1];
            3   : tx_wire <= pi_data[2];
            4   : tx_wire <= pi_data[3];
            5   : tx_wire <= pi_data[4];
            6   : tx_wire <= pi_data[5];
            7   : tx_wire <= pi_data[6];
            8   : tx_wire <= pi_data[7];
            9   : tx_wire <= 1'b1;
            default: tx_wire <= 1'b1;
        endcase

endmodule
