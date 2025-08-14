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
`timescale 1ns/1ps

module fsm_trafficlight_tb();
    // Parameters
    parameter WIDTH = 5;
    parameter CLK_PERIOD = 10;  // 10ns clock period

    // Test signals
    reg clk;
    reg rst_n;
    reg en;
    reg last_light;
    wire [1:0] state;
    wire [WIDTH-1:0] time_light;

    // Instantiate DUT
    fsm_trafficlight #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .last_light(last_light),
        .state(state),
        .time_light(time_light)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Setup waveform dumping
        $dumpfile("fsm_trafficlight.vcd");
        $dumpvars(0, fsm_trafficlight_tb);

        // Test 1: Reset
        rst_n = 0;
        en = 0;
        last_light = 0;
        #(CLK_PERIOD*2);
        
        // Test 2: Enable but no last_light
        rst_n = 1;
        en = 1;
        last_light = 0;
        #(CLK_PERIOD*2);
        
        // Test 3: Complete state transition sequence
        // IDLE -> RED -> GREEN -> YELLOW -> RED
        
        // IDLE to RED
        last_light = 1;
        #(CLK_PERIOD);
        last_light = 0;
        #(CLK_PERIOD*2);
        
        // RED to GREEN
        last_light = 1;
        #(CLK_PERIOD);
        last_light = 0;
        #(CLK_PERIOD*2);
        
        // GREEN to YELLOW
        last_light = 1;
        #(CLK_PERIOD);
        last_light = 0;
        #(CLK_PERIOD*2);
        
        // YELLOW to RED
        last_light = 1;
        #(CLK_PERIOD);
        last_light = 0;
        #(CLK_PERIOD*2);
        
        // Test 4: Disable while in state
        en = 0;
        #(CLK_PERIOD*2);
        last_light = 1;
        #(CLK_PERIOD*2);
        
        // End simulation
        #(CLK_PERIOD*2);
        $finish;
    end

    // Monitor state changes
    initial begin
        $monitor("Time=%0t rst_n=%0b en=%0b last_light=%0b state=%0b time_light=%0d",
                 $time, rst_n, en, last_light, state, time_light);
    end

    // Assertions
    always @(posedge clk) begin
        // Check reset state
        if (!rst_n && (state !== 2'b00))
            $display("Error: Invalid reset state at time %0t", $time);
            
        // Check time_light values
        case (state)
            2'b00: // IDLE
                if (time_light !== 5'd18)
                    $display("Error: Invalid IDLE time at time %0t", $time);
            2'b01: // RED
                if (time_light !== 5'd18)
                    $display("Error: Invalid RED time at time %0t", $time);
            2'b10: // GREEN
                if (time_light !== 5'd15)
                    $display("Error: Invalid GREEN time at time %0t", $time);
            2'b11: // YELLOW
                if (time_light !== 5'd3)
                    $display("Error: Invalid YELLOW time at time %0t", $time);
        endcase
    end

endmodule