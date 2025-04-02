`timescale 1ns / 1ps

module size_trim
#(
parameter INPUT_SIZE = 7, // Input image size (7x7)
parameter OUTPUT_SIZE = 6, // Output image size (6x6)
parameter INPUT_DEPTH = INPUT_SIZE * INPUT_SIZE,
parameter OUTPUT_DEPTH = OUTPUT_SIZE * OUTPUT_SIZE
)
(
    input wire i_clk,
    input wire i_rstn,
    input wire i_seven_seg_done_rst,
    input wire [14:0] i_image_data,
    input wire i_image_data_valid,
    input wire [$clog2(INPUT_DEPTH)-1:0] i_image_addr,

    output reg [14:0] o_image_data,
    output reg o_image_data_valid,
    output reg [$clog2(OUTPUT_DEPTH)-1:0] o_image_addr
);

integer current_row;
integer current_col;
// Use a simple logic to only transfer data from the first 6 columns of the first 6 rows
always @(posedge i_clk) begin
    if (!i_rstn || i_seven_seg_done_rst) begin
        o_image_data <= 0;
        o_image_data_valid <= 0;
        o_image_addr <= 0;
    end else if (i_image_data_valid) begin
        // Calculate the current row and column from the address
            current_row = i_image_addr / INPUT_SIZE;
            current_col = i_image_addr % INPUT_SIZE;

        // Check if the address is within the first 6 rows and columns
        if (current_row < 6 && current_col < 6) begin
            // Calculate the output address
            o_image_addr <= current_row * OUTPUT_SIZE + current_col;

            // Transfer the data to the output
            o_image_data <= i_image_data;
            o_image_data_valid <= 1;
        end else begin
            // If the data is not within the desired range, invalidate the output
            o_image_data_valid <= 0;
        end
    end
end

endmodule
