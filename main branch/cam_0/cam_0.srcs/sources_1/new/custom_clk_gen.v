`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/28 13:49:46
// Design Name: 
// Module Name: custom_clk_gen
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


module custom_clk_gen(
    input wire i_top_clk, //100Mhz
    input wire i_top_rst,
    
    input wire i_top_seven_seg_en,
        
    output wire o_seven_seg_clk
    );

    //reg [4:0] refresh_counter;
    reg [17:0] refresh_counter; // 19 bit refresh counter can count up to 2^19 - 1 = 524287
                                // The clock input is 100Mhz. So you can obtain the refresh rate = 100,000,000/524,287 = 190 Hz.
    reg r_seven_seg_clk;
    
    always @ (posedge i_top_clk or posedge i_top_rst) begin
        if (i_top_rst) begin
            refresh_counter <= 0;
            r_seven_seg_clk <= 0;
        end else if (i_top_seven_seg_en )begin
            if (refresh_counter == 18'b11111111111111111)begin
            //if (refresh_counter == 5'b11111) begin
                r_seven_seg_clk <= ~r_seven_seg_clk;
                refresh_counter <= 0;
            end else begin
                refresh_counter <= refresh_counter + 1;
            end
        end
    end
    
    assign o_seven_seg_clk = r_seven_seg_clk;
    
endmodule