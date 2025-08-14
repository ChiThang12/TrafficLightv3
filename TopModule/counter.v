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

`timescale 1ns/1ps

module tb_counter_logic;

    parameter WIDTH = 4;

    reg                  clk;
    reg                  rst_n;
    reg                  en;
    reg  [WIDTH-1:0]     time_light;
    wire [WIDTH-1:0]     counter_out;
    wire                 pre_last;

    // Instantiate DUT
    counter_logic #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .time_light(time_light),
        .counter_out(counter_out),
        .pre_last(pre_last)
    );

    // Clock generation (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Dump waveform
        $dumpfile("counter_logic_tb.vcd");
        $dumpvars(0, tb_counter_logic);

        // Initial values
        rst_n = 0;
        en = 0;
        time_light = 4'd5;

        // Release reset
        #12;
        rst_n = 1;

        // Enable counting
        #3;
        en = 1;

        // Chạy vài chu kỳ để xem reset và reload khi counter=0
        #100;

        // Thay đổi time_light giữa chừng
        time_light = 4'd3;
        #50;

        // Tắt enable
        en = 0;
        #20;

        // Bật enable lại
        en = 1;
        #50;

        $finish;
    end

endmodule
