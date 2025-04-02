`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/16 10:37:06
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top
#(
    parameter SMALL_DEPTH = 28*28,
    parameter LARGE_DEPTH = 56*56
)
(
        input wire          i_clk25m,
        input wire          i_rstn_clk25m,
        input wire          i_gray_en,
        input wire          i_inverse_gray_en, 
        input wire          i_high_contrast_en, 
        input wire          i_segment,
        input wire [2:0]    i_top_which_char_to_seg,
        
        output wire [7:0] dummy_index1,
        output wire [7:0] dummy_index2,
        output wire [7:0] dummy_index3,
        output wire dummy_valid
    );

wire top_resized_image_data;
wire [$clog2(SMALL_DEPTH)-1:0]o_bram_read_Addr;
wire w_top_bram_data_valid;
 

vga_top
vga_top
(
        .i_clk25m(i_clk25m),
        .i_rstn_clk25m(i_rstn_clk25m),
        .i_gray_en(i_gray_en),
        .i_inverse_gray_en(i_inverse_gray_en),
        .i_high_contrast_en(i_high_contrast_en),
        .i_segment(i_segment),
        .o_image_data_for_cnn(top_resized_image_data),
        .o_top_bram_read_Addr(o_bram_read_Addr),
        .o_bram_data_valid(w_top_bram_data_valid),
        .i_which_char_to_seg(i_top_which_char_to_seg)
);

cnn_interface
cnn_interface
(
        .i_top_clk(i_clk25m),
        .i_top_rstn(i_rstn_clk25m),
        .i_top_bram_read_Addr(o_bram_read_Addr),
        .i_bram_top_valid(w_top_bram_data_valid),
        .Rd_Data(top_resized_image_data),
        .dummy_index1(dummy_index1),
        .dummy_index2(dummy_index2),
        .dummy_index3(dummy_index3),
        .dummy_valid(dummy_valid)
);

endmodule