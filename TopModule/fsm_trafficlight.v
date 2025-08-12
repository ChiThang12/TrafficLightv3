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