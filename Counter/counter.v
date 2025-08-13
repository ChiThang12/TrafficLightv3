module counter #(
    parameter pGREEN_INIT_VAL = 14,
    parameter pYELLOW_INIT_VAL = 2,
    parameter pRED_INIT_VAL = 17,
    parameter pCNT_WIDTH = 5,
    parameter pINIT_WIDTH = 3
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [pINIT_WIDTH-1:0] init,
    output wire last,
    output wire [pCNT_WIDTH-1:0] count_out
);

    localparam pGREEN_IDX = 0;
    localparam pYELLOW_IDX = 1;
    localparam pRED_IDX = 2;

    reg [pCNT_WIDTH-1:0] count;
    wire [pCNT_WIDTH-1:0] next_count;
    wire [pCNT_WIDTH-1:0] dec_value;

    // Check if count is zero
    wire count_is_zero = (count == {pCNT_WIDTH{1'b0}});

    // Decrement only if count is not zero
    assign dec_value = count_is_zero ? count : count + 5'b11111;

    // Next count logic
    assign next_count = !rst_n              ? pGREEN_INIT_VAL :
                       init[pGREEN_IDX]     ? pGREEN_INIT_VAL :
                       init[pYELLOW_IDX]    ? pYELLOW_INIT_VAL :
                       init[pRED_IDX]       ? pRED_INIT_VAL : 
                       en                   ? dec_value : count;

    // Counter register
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            count <= pGREEN_INIT_VAL;  // Reset to GREEN value
        end else if (en) begin 
            count <= next_count;
        end else begin
            count <= count;  // Hold value when not enabled
        end
    end

    // Output logic
    assign last = count_is_zero;
    assign count_out = count;

endmodule

// Testbench
`timescale 1ns/1ps
module counter_tb;
    // Parameters
    parameter pGREEN_INIT_VAL  = 14;
    parameter pYELLOW_INIT_VAL = 2;
    parameter pRED_INIT_VAL    = 17;
    parameter pCNT_WIDTH       = 5;
    parameter pINIT_WIDTH      = 3;
    parameter CLK_PERIOD       = 10;

    // Signals
    reg clk;
    reg rst_n;
    reg en;
    reg [pINIT_WIDTH-1:0] init;
    wire last;
    wire [pCNT_WIDTH-1:0] count_out;

    // Instantiate DUT
    counter #(
        .pGREEN_INIT_VAL(pGREEN_INIT_VAL),
        .pYELLOW_INIT_VAL(pYELLOW_INIT_VAL),
        .pRED_INIT_VAL(pRED_INIT_VAL),
        .pCNT_WIDTH(pCNT_WIDTH),
        .pINIT_WIDTH(pINIT_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .init(init),
        .last(last),
        .count_out(count_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t rst_n=%b en=%b init=%b count=%d last=%b",
                 $time, rst_n, en, init, count_out, last);
    end

    initial begin
        $dumpfile("counter_tb.vcd");
        $dumpvars(0, counter_tb);
    end

    // Test sequence
    initial begin
        // Initialize
        rst_n = 0;
        en = 0;
        init = 3'b000;
        #20;

        // Test GREEN
        rst_n = 1;
        en = 1;
        init = 3'b001;
        #10;
        init = 3'b000;
        repeat(14) @(posedge clk);

        // Test YELLOW
        init = 3'b010;
        #10;
        init = 3'b000;
        repeat(2) @(posedge clk);

        // Test RED
        init = 3'b100;
        #10;
        init = 3'b000;
        repeat(17) @(posedge clk);

        // Test disable
        en = 0;
        #20;

        $finish;
    end

endmodule