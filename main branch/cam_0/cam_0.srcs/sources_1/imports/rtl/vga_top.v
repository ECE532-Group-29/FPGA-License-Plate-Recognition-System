`timescale 1ns / 1ps
`default_nettype none 

/*
 *  Uses X,Y pixel counters from VGA driver
 *  to form an address generator to read from BRAM; output
 *  RGB pixel data from BRAM during active video region;  
 *  wraps VGA sync pulses 
 *
 *  NOTE:  
 *  
 *  - Address generator only increments when
 *      1. Two complete VGA frames passed since reset
 *      2. Current posedge of VGA clock is a valid video pixel position
 *      3. Next posedge of VGA clock is a valid video pixel position
 *  
 *  - Address generator set to 0 in either circumstance
 *      1. Address to BRAM reaches 307199 (x = 640, y = 479)
 *      2. Next posedge of VGA clock is NOT valid video  
 *
 */

module vga_top
#(
    parameter SMALL_DEPTH = 28*28
)
    (   input wire          i_clk25m,
        input wire          i_rstn_clk25m,
        input wire          i_seven_seg_done_rst,
        input wire          i_gray_en,
        input wire          i_inverse_gray_en, 
        input wire          i_high_contrast_en, 
        input wire          i_segment,
        input wire [2:0]    i_which_char_to_seg,
        // VGA driver signals
        output wire [9:0]   o_VGA_x,
        output wire [9:0]   o_VGA_y, 
        output wire         o_VGA_vsync,
        output wire         o_VGA_hsync, 
        output wire         o_VGA_video,
        output wire [3:0]   o_VGA_red,
        output wire [3:0]   o_VGA_green,
        output wire [3:0]   o_VGA_blue,
        
        output wire         o_led1_done,
        output wire         o_led2_done,
        
        // VGA read from BRAM 
        input  wire [11:0] i_pix_data, 
        output reg  [18:0] o_pix_addr,
        
        //small_image
        output wire o_image_data_for_cnn,
        output wire [$clog2(SMALL_DEPTH)-1:0]o_top_bram_read_Addr,
        output wire o_bram_data_valid
        
    );
    
    vga_driver
    #(  .hDisp(640), 
        .hFp(16), 
        .hPulse(96), 
        .hBp(48), 
        .vDisp(480), 
        .vFp(10), 
        .vPulse(2),
        .vBp(33)                )
        
    vga_timing_signals
    (   .i_clk(i_clk25m         ),
        .i_rstn(i_rstn_clk25m   ),
        
        // VGA timing signals
        .o_x_counter(o_VGA_x    ),
        .o_y_counter(o_VGA_y    ),
        .o_video(o_VGA_video    ), 
        .o_vsync(o_VGA_vsync    ),
        .o_hsync(o_VGA_hsync    )
    );
    
    grayscale
    grayscale_converter
    (
        .i_rstn_clk25m_gray(i_rstn_clk25m),
        .i_pix_data(i_pix_data),
        .i_gray_inverse_gray_en(i_inverse_gray_en),
        .i_gray_high_contrast_en(i_high_contrast_en),
        .i_VGA_video_gray (o_VGA_video),
        
        .o_VGA_R_gray(r_VGA_R_gray),
        .o_VGA_G_gray(r_VGA_G_gray), 
        .o_VGA_B_gray(r_VGA_B_gray)
    );
    
    segmentation
    segmentation(
        .i_clk(i_clk25m),
        .i_rstn(i_rstn_clk25m),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_segment(i_segment),
        .i_which_char_to_seg(i_which_char_to_seg),
        .i_VGA_video (o_VGA_video),
        .i_VGA_x(o_VGA_x),
        .i_VGA_y(o_VGA_y),
        .i_VGA_red(r_VGA_R_gray),
        .i_VGA_green(r_VGA_G_gray),
        .i_VGA_blue(r_VGA_B_gray),
        .o_led1_done(o_led1_done),
        .o_VGA_red(w_VGA_R_segment),
        .o_VGA_green(w_VGA_G_segment),
        .o_VGA_blue(w_VGA_B_segment),
        .o_char_data(w_char_data),
        .o_char_addr(w_char_addr),
        .o_char_valid(w_char_valid)
    );
    
    wire w_small_image_data;
    
    wire [$clog2(SMALL_DEPTH)-1:0]w_small_image_addr; 
    wire [$clog2(SMALL_DEPTH)-1:0]w_small_image_read_addr;  
    wire small_image_bram_write_en;
    
    reg [0:SMALL_DEPTH-1] small_image_capture[6:0];

    
    rescaling rescaling (
        .i_clk(i_clk25m),
        .i_rstn(i_rstn_clk25m),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_large_image_data(w_char_data),
        .i_large_image_data_valid(w_char_valid), //starting of the extracted letter
        .i_large_image_addr(w_char_addr),
        
        .o_small_image_data(w_small_image_data),
        .o_small_image_addr(w_small_image_addr),
        .o_small_image_read_addr(w_small_image_read_addr),
        .rescaling_done_write_start(small_image_bram_write_en),
        .bram_data_valid(o_bram_data_valid)
    );
    
    mem_control
    mem_control
    (
        .i_top_clk(i_clk25m),
        .Wr_en(small_image_bram_write_en),
        .Addr(w_small_image_addr),
        .read_Addr(w_small_image_read_addr),
        .Wr_Data(w_small_image_data),
        .Rd_Data(o_image_data_for_cnn),
        .o_read_Addr(o_top_bram_read_Addr)
    );
    
    reg [3:0]   r_VGA_R;
    reg [3:0]   r_VGA_G; 
    reg [3:0]   r_VGA_B;
    
    wire [3:0]   r_VGA_R_gray;
    wire [3:0]   r_VGA_G_gray; 
    wire [3:0]   r_VGA_B_gray;
    
    wire [3:0]   w_VGA_R_segment;
    wire [3:0]   w_VGA_G_segment; 
    wire [3:0]   w_VGA_B_segment;
    
    wire                      w_char_data;
    wire [$clog2(56*56)-1:0]  w_char_addr;
    wire                      w_char_valid;
    
    reg [1:0]   r_SM_state;
    localparam [1:0]    WAIT_1  = 0,
                        WAIT_2  = 'd1,  
                        READ    = 'd2;
        
    always @(posedge i_clk25m or negedge i_rstn_clk25m)
        if(!i_rstn_clk25m)begin
            r_SM_state <= WAIT_1;
            o_pix_addr <= 0; 
        end
    else
        case(r_SM_state)
        // Skip two frames
        WAIT_1: r_SM_state <= (o_VGA_x == 640 && o_VGA_y == 480) ? WAIT_2 : WAIT_1;
        WAIT_2: r_SM_state <= (o_VGA_x == 640 && o_VGA_y == 480) ? READ : WAIT_2; 
        READ: begin
            // Currently active video 
            //if((o_VGA_y >= 170) && (o_VGA_y <= 310) && (o_VGA_x >= 40) && (o_VGA_x <= 600))
            if((o_VGA_y < 480) && (o_VGA_x < 639))
                //o_pix_addr <= (o_pix_addr == 79100) ? 0 : o_pix_addr + 1'b1;
                o_pix_addr <= (o_pix_addr == 307199) ? 0 : o_pix_addr + 1'b1;
            else begin           
            // Next clock is active video 
            if( (o_VGA_x == 799) && ( (o_VGA_y == 524) || (o_VGA_y < 480) ) )
                o_pix_addr <= o_pix_addr + 1'b1;
            // Next clock not active video 
            else if(o_VGA_y >= 480)
                o_pix_addr <= 0;
            end
            end 
        endcase
        
    localparam WINDOW_LOCATION = 50;
    
    // Valid Video selects between a black RGB Pixel and BRAM pixel data 
    always @(*)begin
        if(o_VGA_video)begin
            //start the grayscale
            if(i_gray_en)begin
                    if ((o_VGA_x<28) && (o_VGA_y<28)) begin
                        r_VGA_R = {4{small_image_capture[0][o_VGA_x+(o_VGA_y*28)]}};
                        r_VGA_G = {4{small_image_capture[0][o_VGA_x+(o_VGA_y*28)]}};
                        r_VGA_B = {4{small_image_capture[0][o_VGA_x+(o_VGA_y*28)]}};
                    end
                    // Border for the first area
                    else if (((o_VGA_x<=28)&&(o_VGA_y==28))||((o_VGA_y<=28)&&(o_VGA_x==28))) begin
                        r_VGA_R = 4'b1111;
                        r_VGA_G = 4'b0; 
                        r_VGA_B = 4'b0;
                    end
                    
                    // Second 28x28 pixel area 
                    else if ((o_VGA_x >= WINDOW_LOCATION) && (o_VGA_x < (WINDOW_LOCATION+27)) && (o_VGA_y < 28)) begin
                        r_VGA_R = {4{small_image_capture[1][(o_VGA_x - WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                        r_VGA_G = {4{small_image_capture[1][(o_VGA_x - WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                        r_VGA_B = {4{small_image_capture[1][(o_VGA_x - WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                    end
                    // Border for the second area
                    else if (((o_VGA_x >= WINDOW_LOCATION) && (o_VGA_x < (WINDOW_LOCATION+27)) && (o_VGA_y == 28)) //bottom line 
                            || ((o_VGA_y < 28) && (o_VGA_x == WINDOW_LOCATION+27))  // right
                            || ((o_VGA_y < 28) && (o_VGA_x == WINDOW_LOCATION-1))) //left boarder
                    begin
                        r_VGA_R = 4'b1111;
                        r_VGA_G = 4'b0; 
                        r_VGA_B = 4'b0;
                    end
                    
                     // third 28x28 pixel area 
                    else if ((o_VGA_x >= 2*WINDOW_LOCATION) && (o_VGA_x < (2*WINDOW_LOCATION+27)) && (o_VGA_y < 28)) begin
                        r_VGA_R = {4{small_image_capture[2][(o_VGA_x - 2*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                        r_VGA_G = {4{small_image_capture[2][(o_VGA_x - 2*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                        r_VGA_B = {4{small_image_capture[2][(o_VGA_x - 2*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                    end
                    // Border for the second area
                    else if (((o_VGA_x >= 2*WINDOW_LOCATION) && (o_VGA_x < (2*WINDOW_LOCATION+27)) && (o_VGA_y == 28)) //bottom line 
                            || ((o_VGA_y < 28) && (o_VGA_x == 2*WINDOW_LOCATION+27))  // right boarder
                            || ((o_VGA_y < 28) && (o_VGA_x == 2*WINDOW_LOCATION-1))) //left boarder
                    begin
                        r_VGA_R = 4'b1111;
                        r_VGA_G = 4'b0; 
                        r_VGA_B = 4'b0;
                    end
                    
                    // fourth 28x28 pixel area 
                    else if ((o_VGA_x >= 3*WINDOW_LOCATION) && (o_VGA_x < (3*WINDOW_LOCATION+27)) && (o_VGA_y < 28)) begin
                        r_VGA_R = {4{small_image_capture[3][(o_VGA_x - 3*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                        r_VGA_G = {4{small_image_capture[3][(o_VGA_x - 3*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                        r_VGA_B = {4{small_image_capture[3][(o_VGA_x - 3*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                    end
                    // Border for the second area
                    else if (((o_VGA_x >= 3*WINDOW_LOCATION) && (o_VGA_x < (3*WINDOW_LOCATION+27)) && (o_VGA_y == 28)) //bottom line 
                            || ((o_VGA_y < 28) && (o_VGA_x == 3*WINDOW_LOCATION+27))  // right boarder
                            || ((o_VGA_y < 28) && (o_VGA_x == 3*WINDOW_LOCATION-1))) //left boarder
                    begin
                        r_VGA_R = 4'b1111;
                        r_VGA_G = 4'b0; 
                        r_VGA_B = 4'b0;
                    end
                    
                    // fivth 28x28 pixel area 
                    else if ((o_VGA_x >= 4*WINDOW_LOCATION) && (o_VGA_x < (4*WINDOW_LOCATION+27)) && (o_VGA_y < 28)) begin
                        r_VGA_R = {4{small_image_capture[4][(o_VGA_x - 4*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                        r_VGA_G = {4{small_image_capture[4][(o_VGA_x - 4*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                        r_VGA_B = {4{small_image_capture[4][(o_VGA_x - 4*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                    end
                    // Border for the second area
                    else if (((o_VGA_x >= 4*WINDOW_LOCATION) && (o_VGA_x < (4*WINDOW_LOCATION+27)) && (o_VGA_y == 28)) //bottom line 
                            || ((o_VGA_y < 28) && (o_VGA_x == 4*WINDOW_LOCATION+27))  // right boarder
                            || ((o_VGA_y < 28) && (o_VGA_x == 4*WINDOW_LOCATION-1))) //left boarder
                    begin
                        r_VGA_R = 4'b1111;
                        r_VGA_G = 4'b0; 
                        r_VGA_B = 4'b0;
                    end
                    
                    // sixth 28x28 pixel area 
                    else if ((o_VGA_x >= 5*WINDOW_LOCATION) && (o_VGA_x < (5*WINDOW_LOCATION+27)) && (o_VGA_y < 28)) begin
                        r_VGA_R = {4{small_image_capture[5][(o_VGA_x - 5*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                        r_VGA_G = {4{small_image_capture[5][(o_VGA_x - 5*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                        r_VGA_B = {4{small_image_capture[5][(o_VGA_x - 5*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                    end
                    // Border for the second area
                    else if (((o_VGA_x >= 5*WINDOW_LOCATION) && (o_VGA_x < (5*WINDOW_LOCATION+27)) && (o_VGA_y == 28)) //bottom line 
                            || ((o_VGA_y < 28) && (o_VGA_x == 5*WINDOW_LOCATION+27))  // right boarder
                            || ((o_VGA_y < 28) && (o_VGA_x == 5*WINDOW_LOCATION-1))) //left boarder
                    begin
                        r_VGA_R = 4'b1111;
                        r_VGA_G = 4'b0; 
                        r_VGA_B = 4'b0;
                    end
                    
                    // seventh 28x28 pixel area 
                    else if ((o_VGA_x >= 6*WINDOW_LOCATION) && (o_VGA_x < (6*WINDOW_LOCATION+27)) && (o_VGA_y < 28)) begin
                        r_VGA_R = {4{small_image_capture[6][(o_VGA_x - 6*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                        r_VGA_G = {4{small_image_capture[6][(o_VGA_x - 6*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                        r_VGA_B = {4{small_image_capture[6][(o_VGA_x - 6*WINDOW_LOCATION) + (o_VGA_y * 28)]}};
                    end
                    // Border for the second area
                    else if (((o_VGA_x >= 6*WINDOW_LOCATION) && (o_VGA_x < (6*WINDOW_LOCATION+27)) && (o_VGA_y == 28)) //bottom line 
                            || ((o_VGA_y < 28) && (o_VGA_x == 6*WINDOW_LOCATION+27))  // right boarder
                            || ((o_VGA_y < 28) && (o_VGA_x == 6*WINDOW_LOCATION-1))) //left boarder
                    begin
                        r_VGA_R = 4'b1111;
                        r_VGA_G = 4'b0; 
                        r_VGA_B = 4'b0;
                    end
                    
                    else begin
                        r_VGA_R = w_VGA_R_segment; //r_VGA_R_gray; // TO CHECK 
                        r_VGA_G = w_VGA_G_segment; //r_VGA_G_gray; 
                        r_VGA_B = w_VGA_B_segment; //r_VGA_B_gray; 
                    end
            end 
            //NOTE: the implementation for this part is not right yet. 
            else begin
                r_VGA_R = (i_pix_data[11:8]*100)/100; 
                r_VGA_G = (i_pix_data[7:4]*100)/100; 
                r_VGA_B = (i_pix_data[3:0]*100)/100; 
            end
        end
            
        //default stage if we are not going to stream the video.     
        else begin 
            r_VGA_R = 0; 
            r_VGA_G = 0;
            r_VGA_B = 0;
        end
    end 
    
    always @(posedge i_clk25m) begin
        small_image_capture[i_which_char_to_seg][o_top_bram_read_Addr] <= o_image_data_for_cnn;
    end  
        
    assign o_VGA_red    = r_VGA_R;
    assign o_VGA_green  = r_VGA_G;
    assign o_VGA_blue   = r_VGA_B;
    
    assign o_led2_done = o_bram_data_valid;
      
endmodule
