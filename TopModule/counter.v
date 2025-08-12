module counter_logic #(
    parameter WIDTH = 4
)(
    input                  clk,
    input                  rst_n,
    input                  en,
    input  [WIDTH-1:0]     time_light,
    output reg [WIDTH-1:0] counter_out,
    output reg             pre_last
);

    reg [WIDTH-1:0] counter;

    // Combination logic to check conditions
    wire eq_zero = (counter == {WIDTH{1'b0}});               // counter == 0
    wire eq_one  = (counter == {{(WIDTH-1){1'b0}}, 1'b0});   // counter == 1
    wire [WIDTH-1:0] counter_dec = counter - 1'b1;

    // Counter register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= time_light;
        else if (en) begin
            if (eq_zero)
                counter <= time_light;  // load new value
            else
                counter <= counter_dec; // decrement
        end
    end

    // Output counter_out register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter_out <= time_light;
        else if (en)
            counter_out <= counter;
    end

    // Output pre_last register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pre_last <= 1'b0;
        else if (en)
            pre_last <= eq_one;
    end

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
