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