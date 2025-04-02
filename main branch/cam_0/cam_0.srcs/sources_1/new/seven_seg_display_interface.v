`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/25 10:55:35
// Design Name: 
// Module Name: seven_seg_display_interface
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


module seven_seg_display_interface(
    input wire i_seven_seg_clk, //190hz
    input wire i_top_rst,
    input wire i_top_seven_seg_en,

    // input content for each of the display
    input wire [7:0] display_0 ,
    input wire [7:0] display_1 ,
    input wire [7:0] display_2 ,
    input wire [7:0] display_3 ,
    input wire [7:0] display_4 ,
    input wire [7:0] display_5 ,
    input wire [7:0] display_6 ,
    input wire [7:0] display_7 ,

    output wire [6:0] seg,//the seven segment of each display 
    output wire [7:0] an // since we have 8 display, each of them has their only anode
    
    );
    
    
    reg [7:0] content_to_display;
    reg [7:0] Anode_Activate;
    reg [6:0] r_seg; 
    
    reg [2:0] which_led_on; 
    // this the step counter 
    //  0 -> 1 -> 2 -> 3 -> ......
    //led0 led1 led2 led3 ......
    
    
    always @ (posedge i_seven_seg_clk or posedge i_top_rst) begin
        if (i_top_rst ) begin
            which_led_on <= 0; 
        end else begin 
            if (which_led_on == 3'b111) begin
                which_led_on <= 0; // Reset counter to 0
            end else begin
                which_led_on <= which_led_on + 1; // Otherwise, increment counter
            end
        end
    end
    
    always @(*)begin
        case(which_led_on)
        3'b000: begin //led0
            Anode_Activate = 8'b01111111; 
            // activate LED0 and Deactivate LED1, LED2, LED3, LED4, LED5, LED6, LED7
            content_to_display = display_0;
              end
        3'b001: begin//led1
            Anode_Activate = 8'b10111111; 
            content_to_display = display_1;
              end
        3'b010: begin//led2
            Anode_Activate = 8'b11011111; 
            content_to_display = display_2;
                end
        3'b011: begin//led3
            Anode_Activate = 8'b11101111; 
            content_to_display = display_3; 
               end
        3'b100: begin//led4
            Anode_Activate = 8'b11110111; 
            content_to_display = display_4;
               end
         3'b101: begin//led5
            Anode_Activate = 8'b11111011; 
            content_to_display = display_5;
               end
         3'b110: begin//led6
            Anode_Activate = 8'b11111101; 
            content_to_display = display_6;
               end
         3'b111: begin//led7
            Anode_Activate = 8'b11111110; 
            content_to_display = display_7;
               end                              
        endcase
    end
    /*
    -----A-----
    |         |
    F         B
    |         |
    -----G-----
    |         |
    E         C
    |         |
    -----D-----
    */
    always @(*) begin    
        case(content_to_display)
                        //GFEDCBA     if you turn the seg on, set that segment to 0
        8'h0: r_seg = 7'b1000000; // "0"
        8'h1: r_seg = 7'b1111001; // "1" 
        8'h2: r_seg = 7'b0100100; // "2" 
        8'h3: r_seg = 7'b0110000; // "3" 
        8'h4: r_seg = 7'b0011001; // "4" 
        8'h5: r_seg = 7'b0010010; // "5" 
        8'h6: r_seg = 7'b0000010; // "6" 
        8'h7: r_seg = 7'b1111000; // "7" 
        8'h8: r_seg = 7'b0000000; // "8"
        8'h9: r_seg = 7'b0010000; // "9" 
                        //GFEDCBA
        8'hA: r_seg = 7'b0100000; // "A" 
        8'hB: r_seg = 7'b0000011; // "B" 
        8'hC: r_seg = 7'b0100111; // "C" 
        8'hD: r_seg = 7'b0100001; // "D" 
        8'hE: r_seg = 7'b0000110; // "E" 
        8'hF: r_seg = 7'b0001110; // "F" 
        8'h10: r_seg = 7'b1000010; // "G" 
        8'h11: r_seg = 7'b0001011; // "H" 
        8'h12: r_seg = 7'b1111001; // "I" 
        8'h13: r_seg = 7'b1110010; // "J" 
        8'h14: r_seg = 7'b0001010; // "K" 
        8'h15: r_seg = 7'b1000111; // "L" 
        8'h16: r_seg = 7'b0101010; // "M" 
        8'h17: r_seg = 7'b0101011; // "N" 
        8'h18: r_seg = 7'b0100011; // "O" 
        8'h19: r_seg = 7'b0001100; // "P" 
        8'h1A: r_seg = 7'b0011000; // "Q" 
        8'h1B: r_seg = 7'b0101111; // "R"
        8'h1C: r_seg = 7'b1010010; // "S" 
        8'h1D: r_seg = 7'b0000111; // "T" 
        8'h1E: r_seg = 7'b1100011; // "U" 
        8'h1F: r_seg = 7'b1010101; // "v" 
        8'h20: r_seg = 7'b0010101; // "W"
        8'h21: r_seg = 7'b1101011; // "x" 
        8'h22: r_seg = 7'b0010001; // "y" 
        8'h23: r_seg = 7'b1100100; // "Z"

        8'h24: r_seg = 7'b0111111; // "-" 
        default: r_seg = 7'b1000000; // "0"
        endcase
        
        if (~i_top_seven_seg_en)begin
            r_seg = 7'b1111111;
        end
    end  

    assign seg = r_seg;
    assign an = Anode_Activate;

endmodule
