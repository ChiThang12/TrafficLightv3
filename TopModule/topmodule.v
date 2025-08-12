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

    assign dec_value = count + 5'b11111;

    assign next_count = !rst_n              ? pGREEN_INIT_VAL :
                        init[pGREEN_IDX]    ? pGREEN_INIT_VAL   :
                        init[pYELLOW_IDX]   ? pYELLOW_INIT_VAL  :
                        init[pRED_IDX]      ? pRED_INIT_VAL     : 
                        en                  ? dec_value         : 1;


    // thanh ghi
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            count <= 0;
        end else if (en) begin 
            count <= next_count;
        end else begin
            count <= 0; // giữ nguyên giá trị
        end
    end

    // comparator
    assign last = (count == 4'b0) ? 1'b1 : 1'b0;
    assign count_out = count;

endmodule
// điều khiển trạng thái
module traffic_fsm #(
    parameter LIGHT_STATE_WIDTH = 3
)(
    input wire clk,
    input wire en,
    input wire rst_n,
    input wire last_cnt,
    output wire [LIGHT_STATE_WIDTH-1:0] light,
    output wire [LIGHT_STATE_WIDTH-1:0] light_cnt_init
);
    
//. Định nghĩa các tham số đèn
    parameter pGREEN_IDX = 0;
    parameter pYELLOW_IDX = 1;
    parameter pRED_IDX = 2;
    
    // Trạng thái của đèn
    parameter [1:0] IDLE = 2'b00;
    parameter [1:0] GREEN = 2'b01;
    parameter [1:0] YELLOW = 2'b10;
    parameter [1:0] RED = 2'b11;
    
   
    reg [1:0] light_current_state, light_next_state;
    reg [LIGHT_STATE_WIDTH-1:0] signal_light;
    reg [LIGHT_STATE_WIDTH-1:0] signal_light_cnt_init;
    
    
    // Trạng thái khi reset, en, và kích hoạt
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            light_current_state <= IDLE;
        end
        else if (en) begin
            light_current_state <= light_next_state;
        end
        else begin
            light_current_state <= IDLE;
        end
    end
    
    
    always @(*) begin
        light_next_state = IDLE;
        signal_light = 3'b000;
        signal_light_cnt_init = 3'b000;
        
        case (light_current_state)
            // Trạng thái IDLE: đèn tắt
            IDLE: begin
                if (en) begin
                    light_next_state = GREEN;
                    signal_light[pGREEN_IDX] = 1'b1;
                end
                else begin
                    light_next_state = IDLE;
                    signal_light = 3'b000;
                    signal_light_cnt_init = 3'b000;
                end
            end
            
            GREEN: begin
                if (last_cnt) begin
                    light_next_state = YELLOW;
                    signal_light[pYELLOW_IDX] = 1'b1;
                    signal_light_cnt_init[pYELLOW_IDX] = 1'b1;
                end
                else begin
                    light_next_state = GREEN;
                    signal_light[pGREEN_IDX] = 1'b1;
                end
            end
            
            YELLOW: begin
                if (last_cnt) begin
                    light_next_state = RED;
                    signal_light[pRED_IDX] = 1'b1;
                    signal_light_cnt_init[pRED_IDX] = 1'b1;
                end
                else begin
                    light_next_state = YELLOW;
                    signal_light[pYELLOW_IDX] = 1'b1;
                end
            end
            
            RED: begin
                if (last_cnt) begin
                    light_next_state = GREEN;
                    signal_light[pGREEN_IDX] = 1'b1;
                    signal_light_cnt_init[pGREEN_IDX] = 1'b1;
                end
                else begin
                    light_next_state = RED;
                    signal_light[pRED_IDX] = 1'b1;
                end
            end
        endcase
    end
    
    // Output assignments
    assign light = signal_light;
    assign light_cnt_init = signal_light_cnt_init;

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
    output wire [WIDTH-1:0]  counter_display
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
        .counter_display(counter_display)
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
