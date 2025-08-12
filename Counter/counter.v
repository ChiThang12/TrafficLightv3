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
//   // Counter logic goes here


// // Cho đèn sáng theo thứ tự: xanh, vàng, đỏ
// // Đếm từ 14->0->2->17->0->14
// module counter #(
//     parameter pGREEN_INIT_VAL = 14,
//     parameter pYELLOW_INIT_VAL = 2,
//     parameter pRED_INIT_VAL = 17,
//     parameter pCNT_WIDTH = 5, // log2(pRED_INIT_VAL+1)
//     parameter pINIT_WIDTH = 3
// )(
//     input wire clk,
//     input wire en,
//     input wire rst_n,
//     input wire [pINIT_WIDTH-1:0] init,
//     output wire last,
//     output wire [pCNT_WIDTH-1:0] count_out
// );
    
    
//     parameter pGREEN_IDX = 0;
//     parameter pYELLOW_IDX = 1;
//     parameter pRED_IDX = 2;
    
    
//     reg [pCNT_WIDTH-1:0] count;
    
    
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             count <= pGREEN_INIT_VAL;
//         end
//         else if (init[pGREEN_IDX]) begin
//             count <= pGREEN_INIT_VAL;
//         end
//         else if (init[pYELLOW_IDX]) begin
//             count <= pYELLOW_INIT_VAL;
//         end
//         else if (init[pRED_IDX]) begin
//             count <= pRED_INIT_VAL;
//         end
//         else if (en) begin
//             count <= count - 1;
//         end
//     end
    
   
//     assign last = (count == 0) ? 1'b1 : 1'b0;
//     assign count_out = count;

// endmodule
`timescale 1ns/1ps
module counter_tb;

    // Parameters
    parameter pGREEN_INIT_VAL  = 14;
    parameter pYELLOW_INIT_VAL = 2;
    parameter pRED_INIT_VAL    = 17;
    parameter pCNT_WIDTH       = 5; // log2(pRED_INIT_VAL+1)
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
        .en(en),
        .rst_n(rst_n),
        .init(init),
        .last(last),
        .count_out(count_out)
    );

    // Clock generator
    always #(CLK_PERIOD/2) clk = ~clk;

    // VCD
    initial begin
        $dumpfile("counter_tb.vcd");
        $dumpvars(0, counter_tb);
    end

    // Test procedure
    initial begin
        // Initial values
        clk = 0;
        rst_n = 0;
        en = 0;
        init = 3'b000;

        // Reset
        #20;
        rst_n = 1;

        // Start with GREEN
        #10;
        init = 3'b001; // GREEN
        #10;
        init = 3'b000;
        en = 1;

        // Wait until GREEN expires
        wait (last);
        #9.99;
        en = 1;

        // Set YELLOW
        init = 3'b010;
        #10;
        init = 3'b000;
        en = 1;

        // Wait until YELLOW expires
        wait (last);
        #9.99;
        en = 1;

        // Set RED
        init = 3'b100;
        #10;
        init = 3'b000;
        en = 1;

        // Wait until RED expires
        wait (last);
        #9.99;
        en = 1;

        // Back to GREEN
        init = 3'b001;
        #10;
        init = 3'b000;
        en = 1;

        // Run for a bit then finish
        #(20 * CLK_PERIOD);
        $finish;
    end

endmodule