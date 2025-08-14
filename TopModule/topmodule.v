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
// điều khiển trạng thái
// FSM điều khiển đèn giao thông - viết gọn với toán tử 3 ngôi
module traffic_fsm #(
    parameter LIGHT_STATE_WIDTH = 3
)(
    input  wire clk,
    input  wire en,
    input  wire rst_n,
    input  wire last_cnt,
    output reg  [LIGHT_STATE_WIDTH-1:0] light,
    output reg  [LIGHT_STATE_WIDTH-1:0] light_cnt_init
);

    // Định nghĩa trạng thái
    localparam IDLE   = 2'b00;
    localparam GREEN  = 2'b01;
    localparam YELLOW = 2'b10;
    localparam RED    = 2'b11;

    reg [1:0] state, next_state;

    // =========================
    // 1. Thanh ghi trạng thái
    // =========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else if (en)
            state <= next_state;
        else
            state <= IDLE;
    end

    // =========================
    // 2. Logic chuyển trạng thái & xuất tín hiệu
    // =========================
    always @(*) begin
        // Mặc định
        light          = 3'b000;
        light_cnt_init = 3'b000;
        next_state     = state;

        case (state)
            IDLE: begin
                next_state = en ? GREEN : IDLE;
                light      = en ? 3'b100 : 3'b000; // Green khi bắt đầu
            end

            GREEN: begin
                next_state     = last_cnt ? YELLOW : GREEN;
                light          = last_cnt ? 3'b010 : 3'b100; // Yellow : Green
                light_cnt_init = last_cnt ? 3'b010 : 3'b000;
            end

            YELLOW: begin
                next_state     = last_cnt ? RED : YELLOW;
                light          = last_cnt ? 3'b001 : 3'b010; // Red : Yellow
                light_cnt_init = last_cnt ? 3'b001 : 3'b000;
            end

            RED: begin
                next_state     = last_cnt ? GREEN : RED;
                light          = last_cnt ? 3'b100 : 3'b001; // Green : Red
                light_cnt_init = last_cnt ? 3'b100 : 3'b000;
            end
        endcase
    end

endmodule

module segment_display (
    input  wire [4:0] count_value,
    output wire [6:0] seg_a, // hàng chục
    output wire [6:0] seg_b  // hàng đơn vị
);

    wire [3:0] digit_a = count_value / 10;
    wire [3:0] digit_b = count_value % 10;

    display dis_a (
        .value(digit_a),
        .seg(seg_a)
    );

    display dis_b (
        .value(digit_b),
        .seg(seg_b)
    );

endmodule


module display (
    input  [3:0] value,
    output reg [6:0] seg
);

    always @(*) begin
        case (value)
            4'd0: seg = 7'b1111110;
            4'd1: seg = 7'b0110000;
            4'd2: seg = 7'b1101101;
            4'd3: seg = 7'b1111001;
            4'd4: seg = 7'b0110011;
            4'd5: seg = 7'b1011011;
            4'd6: seg = 7'b1011111;
            4'd7: seg = 7'b1110000;
            4'd8: seg = 7'b1111111;
            4'd9: seg = 7'b1111011;
            default: seg = 7'b0000000;
        endcase
    end

endmodule

module traffic_light_top #(
    parameter WIDTH = 5,
    parameter LIGHT_STATE_WIDTH = 3
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              en,
    output wire              Red,
    output wire              Yellow, 
    output wire              Green,
    output wire [WIDTH-1:0]  counter_display,
    output wire [6:0]        seg_a, // hàng chục
    output wire [6:0]        seg_b  // hàng đơn vị
);
    // Internal signals
    wire last_cnt;
    wire [LIGHT_STATE_WIDTH-1:0] light;
    wire [LIGHT_STATE_WIDTH-1:0] light_cnt_init;

    // FSM instance
    traffic_fsm #(
        .LIGHT_STATE_WIDTH(LIGHT_STATE_WIDTH)
    ) fsm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .last_cnt(last_cnt),
        .light(light),
        .light_cnt_init(light_cnt_init)
    );

    // Counter instance
    counter #(
        .pCNT_WIDTH(WIDTH),
        .pINIT_WIDTH(LIGHT_STATE_WIDTH),
        .pGREEN_INIT_VAL(14),
        .pYELLOW_INIT_VAL(2),
        .pRED_INIT_VAL(17)
    ) counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .init(light_cnt_init),    // Connect to FSM init signal
        .last(last_cnt),          // Connect to FSM last signal
        .count_out(counter_display)
    );

    // Segment display instance
    segment_display seg_display (
        .count_value(counter_display),
        .seg_a(seg_a), // hàng chục
        .seg_b(seg_b)  // hàng đơn vị
    );

    // Light decode - direct mapping from FSM light signal
    assign Green  = light[0];  // LSB = GREEN
    assign Yellow = light[1];  // Middle bit = YELLOW
    assign Red    = light[2];  // MSB = RED

endmodule

`timescale 1ns/1ps
module traffic_light_top_tb();
    parameter WIDTH = 5;
    parameter CLK_PERIOD = 10;
    parameter LIGHT_STATE_WIDTH = 3;

    reg clk;
    reg rst_n;
    reg en;
    wire Red, Yellow, Green;
    wire [WIDTH-1:0] counter_display;
    wire [6:0] seg_a; // hàng chục
    wire [6:0] seg_b; // hàng đơn vị

    // DUT instance
    traffic_light_top #(
        .WIDTH(WIDTH),
        .LIGHT_STATE_WIDTH(LIGHT_STATE_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .Red(Red),
        .Yellow(Yellow),
        .Green(Green),
        .counter_display(counter_display),
        .seg_a(seg_a),
        .seg_b(seg_b)
    );

    // Clock generation (50% duty)
    always #(CLK_PERIOD/2) clk = ~clk;

    // Monitor traffic light changes
    initial begin
        $monitor("%t: GREEN=%b, YELLOW=%b, RED=%b, CNT=%0d", 
                 $time, Green, Yellow, Red, counter_display);
    end
    
    // Test sequence
    initial begin
        // Dump waveform to file
        $dumpfile("traffic_light_top_tb.vcd");  
        $dumpvars(0, traffic_light_top_tb);
        
        // Initialize signals
        clk = 1'b0;
        rst_n = 1'b0;
        en = 0;
        
        // Release reset and enable
        #(5*CLK_PERIOD) rst_n = 1'b1;
        #(2*CLK_PERIOD-1) en = 1;
        
        // Run simulation for enough cycles
        #(1000*CLK_PERIOD)
        
        // Finish simulation
        $finish;
    end
endmodule
