`timescale 1ns / 1ps
           
// Compute grayscale using fixed-point arithmetic
// Weights are adjusted for 4-bit color depth (scale down the constants)
// 0.299 * 15 = 4.485, 0.587 * 15 = 8.805, 0.114 * 15 = 1.71
// Approximate integer weights for RGB444 could be 4, 9, and 2 respectively
            
module grayscale
    (    
        input wire i_rstn_clk25m_gray,
        input wire i_VGA_video_gray,
        input wire [11:0] i_pix_data,
        
        input wire i_gray_inverse_gray_en,
        input wire i_gray_high_contrast_en,
        
        output wire [3:0]   o_VGA_R_gray,
        output wire [3:0]   o_VGA_G_gray, 
        output wire [3:0]   o_VGA_B_gray
    );
    
    reg [11:0] gray_scale;
    reg [3:0] r_VGA_R_gray;
    reg [3:0] r_VGA_G_gray;
    reg [3:0] r_VGA_B_gray;
    
    always @( * )begin
        if (!i_rstn_clk25m_gray) begin
            gray_scale <= 0;
            r_VGA_R_gray <= 0;
            r_VGA_G_gray <= 0; 
            r_VGA_B_gray <= 0;
        end
        
        else if (i_VGA_video_gray)begin 
            gray_scale = (i_pix_data[11:8] * 4 +  // R component
                        i_pix_data[7:4] * 9 +     // G components
                        i_pix_data[3:0] * 2);     // B component
            
            gray_scale = gray_scale >> 4;
                        
            if (i_gray_inverse_gray_en) begin 
                if (i_gray_high_contrast_en) begin  // increase the contrast by introducing threshold. 
                    if(gray_scale > 6) begin
                        r_VGA_R_gray = 4'b0000;  // Set to black since we are in inverse gray scale mode. 
                        r_VGA_G_gray = 4'b0000;
                        r_VGA_B_gray = 4'b0000;
                    end else begin
                        r_VGA_R_gray = 4'b1111;  // Set to white
                        r_VGA_G_gray = 4'b1111;
                        r_VGA_B_gray = 4'b1111;
                    end
                        
                end else begin 
                    r_VGA_R_gray = ~gray_scale[3:0];
                    r_VGA_G_gray = ~gray_scale[3:0];
                    r_VGA_B_gray = ~gray_scale[3:0];
                end
            end
           
            // Output the same grayscale value on all color channels
            else begin                              
                if (i_gray_high_contrast_en) begin  // increase the contrast by introducing threshold. 
                    if(gray_scale > 6) begin
                        r_VGA_R_gray = 4'b1111;// Set to white
                        r_VGA_G_gray = 4'b1111;
                        r_VGA_B_gray = 4'b1111;
                    end else begin
                        r_VGA_R_gray = 4'b0000;// Set to black
                        r_VGA_G_gray = 4'b0000;
                        r_VGA_B_gray = 4'b0000;
                    end

                end else begin     
                    r_VGA_R_gray = gray_scale[3:0];
                    r_VGA_G_gray = gray_scale[3:0];
                    r_VGA_B_gray = gray_scale[3:0];
                end
            end        
            
        end
    
    end
    
    assign o_VGA_R_gray  = r_VGA_R_gray;
    assign o_VGA_G_gray  = r_VGA_G_gray;
    assign o_VGA_B_gray  = r_VGA_B_gray;
    
endmodule