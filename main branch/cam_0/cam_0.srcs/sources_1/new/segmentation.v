`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/01/2025 07:09:39 PM
// Design Name: 
// Module Name: segmentation
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


module segmentation#(
    parameter WIDTH = 12,
    parameter DEPTH = 640*480,
    parameter CHAR_DEPTH = 56*56,
    parameter SMALL_DEPTH = 28*28
    )
    (
    input wire          i_clk,
    input wire          i_rstn,
    input wire          i_seven_seg_done_rst,
    input wire          i_segment,
    input wire [2:0]    i_which_char_to_seg,
    input wire          i_VGA_video,
    input wire [9:0]    i_VGA_x,
    input wire [9:0]    i_VGA_y,
    input wire [3:0]    i_VGA_red,
    input wire [3:0]    i_VGA_green,
    input wire [3:0]    i_VGA_blue,
    
    output wire         o_led1_done,
    
    output wire [9:0]   o_VGA_x,
    output wire [9:0]   o_VGA_y,
    output wire [3:0]   o_VGA_red,
    output wire [3:0]   o_VGA_green,
    output wire [3:0]   o_VGA_blue,
    
    output wire                          o_char_data,
    output wire [$clog2(CHAR_DEPTH)-1:0]  o_char_addr,
    output wire                          o_char_valid
    );
    reg [2:0] char_num;
    //---------------TODO, change to automatic controlled signal ----------
    always @(*) begin
        char_num <= i_which_char_to_seg;
    end
    
    wire [WIDTH-1:0] pixel_data;
    reg [9:0] vertical_histogram_count [560:0];
    reg [9:0] horizontal_histogram_count [140:0];
    // [3] top_y, [2] bottom_y, [1] left_x, [0] right_x
    reg [9:0] char_bound [6:0][3:0];
    
    reg found_top_flag, found_bottom_flag, found_left_flag, found_right_flag;
    reg [9:0] v_counter;
    reg [9:0] h_counter;
    reg [2:0] vert_char_found;
    
    reg [3:0] w_VGA_red, w_VGA_green, w_VGA_blue;
    
    integer i, j, k, n, l;
    wire w_segment_db;
    reg segment_start_flag, profile_done_flag, bound_done_flag, start_char_save_flag, char_save_done_flag, rescale_done_flag;
    reg [$clog2(DEPTH)-1:0] counter;
    
    reg [$clog2(CHAR_DEPTH)-1:0] char_counter;
    reg char_data, char_valid;
    reg [$clog2(CHAR_DEPTH)-1:0] r_char_addr;
    reg [9:0] x_diff, y_diff;
    
    assign o_VGA_x = i_VGA_x;
    assign o_VGA_y = i_VGA_y;
    assign o_VGA_red = w_VGA_red;
    assign o_VGA_green = w_VGA_green;
    assign o_VGA_blue = w_VGA_blue;
    
    assign o_char_data = char_data;
    assign o_char_valid = char_valid;
    assign o_char_addr = r_char_addr;
    
    assign o_led1_done = ((char_bound[0][0]-char_bound[0][1]) < 10'd56)&&((char_bound[0][2]-char_bound[0][3]) < 10'd56)
    &&((char_bound[1][0]-char_bound[1][1]) < 10'd56)&&((char_bound[1][2]-char_bound[1][3]) < 10'd56)
    &&((char_bound[2][0]-char_bound[2][1]) < 10'd56)&&((char_bound[2][2]-char_bound[2][3]) < 10'd56)
    &&((char_bound[3][0]-char_bound[3][1]) < 10'd56)&&((char_bound[3][2]-char_bound[3][3]) < 10'd56)
    &&((char_bound[4][0]-char_bound[4][1]) < 10'd56)&&((char_bound[4][2]-char_bound[4][3]) < 10'd56)
    &&((char_bound[5][0]-char_bound[5][1]) < 10'd56)&&((char_bound[5][2]-char_bound[5][3]) < 10'd56)
    &&((char_bound[6][0]-char_bound[6][1]) < 10'd56)&&((char_bound[6][2]-char_bound[6][3]) < 10'd56);
   
    debouncer 
    #(  .DELAY(240_000)         )    
    cam_btn_capture_db
    (   .i_clk(i_clk            ), 
        .i_btn_in(i_segment   ),
        
        // Debounced button to start cam init 
        .o_btn_db(w_segment_db    )
    );
    
    assign pixel_data = {i_VGA_red, i_VGA_green, i_VGA_blue};

    always @(*) begin
        if ((bound_done_flag && (
            ((((i_VGA_y==char_bound[0][3])||(i_VGA_y==char_bound[0][2]))&&((i_VGA_x>=char_bound[0][1])&&(i_VGA_x<=char_bound[0][0])))||(((i_VGA_x==char_bound[0][1])||(i_VGA_x==char_bound[0][0]))&&((i_VGA_y>=char_bound[0][3])&&(i_VGA_y<=char_bound[0][2]))))
            || ((((i_VGA_y==char_bound[1][3])||(i_VGA_y==char_bound[1][2]))&&((i_VGA_x>=char_bound[1][1])&&(i_VGA_x<=char_bound[1][0])))||(((i_VGA_x==char_bound[1][1])||(i_VGA_x==char_bound[1][0]))&&((i_VGA_y>=char_bound[1][3])&&(i_VGA_y<=char_bound[1][2]))))
            || ((((i_VGA_y==char_bound[2][3])||(i_VGA_y==char_bound[2][2]))&&((i_VGA_x>=char_bound[2][1])&&(i_VGA_x<=char_bound[2][0])))||(((i_VGA_x==char_bound[2][1])||(i_VGA_x==char_bound[2][0]))&&((i_VGA_y>=char_bound[2][3])&&(i_VGA_y<=char_bound[2][2]))))
            || ((((i_VGA_y==char_bound[3][3])||(i_VGA_y==char_bound[3][2]))&&((i_VGA_x>=char_bound[3][1])&&(i_VGA_x<=char_bound[3][0])))||(((i_VGA_x==char_bound[3][1])||(i_VGA_x==char_bound[3][0]))&&((i_VGA_y>=char_bound[3][3])&&(i_VGA_y<=char_bound[3][2]))))
            || ((((i_VGA_y==char_bound[4][3])||(i_VGA_y==char_bound[4][2]))&&((i_VGA_x>=char_bound[4][1])&&(i_VGA_x<=char_bound[4][0])))||(((i_VGA_x==char_bound[4][1])||(i_VGA_x==char_bound[4][0]))&&((i_VGA_y>=char_bound[4][3])&&(i_VGA_y<=char_bound[4][2]))))
            || ((((i_VGA_y==char_bound[5][3])||(i_VGA_y==char_bound[5][2]))&&((i_VGA_x>=char_bound[5][1])&&(i_VGA_x<=char_bound[5][0])))||(((i_VGA_x==char_bound[5][1])||(i_VGA_x==char_bound[5][0]))&&((i_VGA_y>=char_bound[5][3])&&(i_VGA_y<=char_bound[5][2]))))
            || ((((i_VGA_y==char_bound[6][3])||(i_VGA_y==char_bound[6][2]))&&((i_VGA_x>=char_bound[6][1])&&(i_VGA_x<=char_bound[6][0])))||(((i_VGA_x==char_bound[6][1])||(i_VGA_x==char_bound[6][0]))&&((i_VGA_y>=char_bound[6][3])&&(i_VGA_y<=char_bound[6][2])))))
            ) || (i_VGA_x == 10'd40)||(i_VGA_x == 10'd600)||(i_VGA_y == 10'd170)||(i_VGA_y == 10'd310)
        ) begin
            w_VGA_red = 4'b0;
            w_VGA_green = 4'b1111;
            w_VGA_blue = 4'b0;
        end
        else if ((i_VGA_y == 10'd184)||(i_VGA_y == 10'd296)) begin
            w_VGA_red = 4'b1111;
            w_VGA_green = 4'b0;
            w_VGA_blue = 4'b0;
        end
        else if ((i_VGA_y == 10'd198)||(i_VGA_y == 10'd282)) begin
            w_VGA_red = 4'b0;
            w_VGA_green = 4'b0;
            w_VGA_blue = 4'b1111;
        end
        else begin
            w_VGA_red = i_VGA_red;
            w_VGA_green = i_VGA_green;
            w_VGA_blue = i_VGA_blue;
        end
    end
    
    //always @(posedge i_clk or negedge i_rstn or posedge w_segment_db) begin
    always @(posedge i_clk or negedge i_rstn or posedge w_segment_db or posedge i_seven_seg_done_rst) begin
        if (!i_rstn || w_segment_db || i_seven_seg_done_rst) begin
            for (i = 0; i <= 560; i = i + 1) begin
                vertical_histogram_count[i] <= 10'd0;
            end
            for (j = 0; j <= 140; j = j + 1) begin
                horizontal_histogram_count[j] <= 10'd0;
            end
            for (n = 0; n <= 6; n = n + 1) begin
                for (k = 0; k <= 3; k = k + 1) begin 
                    char_bound[n][k]<=10'd0;
                end
            end
            counter <= {($clog2(DEPTH)-1){1'b0}};
            char_counter <= {($clog2(CHAR_DEPTH)-1){1'b0}};
            // char_num <= 3'd0;   ----------------TODO, change to automatic controlled signal ----------
            found_top_flag <= 1'b0;
            found_bottom_flag <= 1'b0;
            found_left_flag <= 1'b0;
            found_right_flag <= 1'b0;
            v_counter <= 10'd0;
            h_counter <= 10'd0;
            vert_char_found <= 3'd0;
            x_diff <= 10'd0;
            y_diff <= 10'd0;
            profile_done_flag <= 1'b0;
            bound_done_flag <= 1'b0;
            start_char_save_flag <= 1'b0;
            char_save_done_flag <= 1'b0;
            char_valid <= 1'b0;
            char_data <= 1'b0;
            r_char_addr <= {($clog2(CHAR_DEPTH)-1){1'b0}};
            if (!i_rstn) begin
                segment_start_flag <= 1'b0;
            end
            else begin
                segment_start_flag <= 1'b1;
            end
        end
        else begin
            // do vertical and horizontal projection profiles
            if (segment_start_flag && i_VGA_video) begin
                if (counter == DEPTH) begin
                    segment_start_flag <= 1'b0;
                    profile_done_flag <= 1'b1;
                end
                else begin
                    // only check if x>=20 bc of error/defect on left of image
                    if ((i_VGA_x >= 10'd40)&&(i_VGA_x <= 10'd600)&&(i_VGA_y >= 10'd170)&&(i_VGA_y <= 10'd310)&&(pixel_data == 12'd4095)) begin
                        vertical_histogram_count[i_VGA_x-40] <= vertical_histogram_count[i_VGA_x-40]+1'b1;
                        horizontal_histogram_count[i_VGA_y-170] <= horizontal_histogram_count[i_VGA_y-170]+1'b1;
                    end
                end
                counter <= counter + 1'b1;
            end
            
            // find character boundaries
            else if (profile_done_flag && !bound_done_flag) begin
                // if horizontal boundaries not found, find horizontal boundaries
                if (!found_top_flag || !found_bottom_flag) begin
                    if ((horizontal_histogram_count[h_counter] >= 10'd10) && (!found_top_flag)) begin
                        for (i=0; i<7; i=i+1) begin
                            char_bound[i][3] <= (h_counter+170)-2;
                            found_top_flag <= 1'b1;
                        end
                    end
                    else if ((horizontal_histogram_count[h_counter] <= 10'd5) && (found_top_flag) && (!found_bottom_flag)) begin
                        for (i=0; i<7; i=i+1) begin
                            char_bound[i][2] <= h_counter+170;
                            found_bottom_flag <= 1'b1;
                        end
                    end
                    else if ((h_counter == 10'd309) && (!found_bottom_flag)) begin //(h_counter == 10'd479 - 10'd170)
                        for (i=0; i<7; i=i+1) begin
                            char_bound[i][2] <= h_counter+170;
                            found_bottom_flag <= 1'b1;
                        end
                    end
                    h_counter <= h_counter + 1'b1;
                end
                
                // if vertical boundaries not found, find vertical boundaries
                if (vert_char_found < 3'b111) begin
                    if (!found_left_flag || !found_right_flag) begin
                        if ((vertical_histogram_count[v_counter] > 10'd5) && (!found_left_flag)) begin
                            char_bound[vert_char_found][1] <= (v_counter+40)-2;
                            
                            // set found left boundary flag
                            found_left_flag <= 1'b1;
                            
                            // if not first character clear found_right_flag
                           // if (vert_char_found != 3'd0) begin
                                found_right_flag <= 1'b0;
                            //end
                        end
                        else if ((vertical_histogram_count[v_counter] <= 10'd5) && (found_left_flag) && (!found_right_flag)) begin
                            char_bound[vert_char_found][0] <= v_counter+40;
                            
                            // if not last character clear found_left_flag
                            if (vert_char_found != 3'd6) begin
                                found_left_flag <= 1'b0;
                            end
    
                            // set found right boundary flag
                            found_right_flag <= 1'b1;
                            vert_char_found <= vert_char_found + 1'b1;
                        end
                        else if ((v_counter == 10'd599) && (!found_right_flag)) begin //(v_counter == 10'd639 - 10'd40) 
                            char_bound[6][0] <= v_counter+40;
                            // set found right boundary flag
                            found_right_flag <= 1'b1;
                            vert_char_found <= vert_char_found + 1'b1;
                        end
                        v_counter <= v_counter + 1'b1;
                    end 
                end
                
                //if (found_top_flag && found_bottom_flag && found_left_flag && found_right_flag) begin
                if (found_top_flag && found_bottom_flag && found_left_flag && found_right_flag && (vert_char_found == 3'b111)) begin
                    bound_done_flag <= 1'b1;
                end
            end
            else if (bound_done_flag && !char_save_done_flag) begin
                
                // if first pixel
                if (!start_char_save_flag && ((i_VGA_x==char_bound[char_num][1])&&(i_VGA_y==char_bound[char_num][3]))) begin
                    start_char_save_flag <= 1'b1;
                    // save one bit of pixel data
                    char_data <= i_VGA_red[0];
                    r_char_addr <= char_counter;
                    char_valid <= 1'b1;
                    char_counter <= char_counter+1'b1;
                    x_diff <= 10'd56 - (char_bound[char_num][0]-char_bound[char_num][1]) - 1'b1;
                    y_diff <= 10'd56 - (char_bound[char_num][2]-char_bound[char_num][3]) - 1'b1;
                end
                else if (start_char_save_flag && ((i_VGA_x>=char_bound[char_num][1])&&(i_VGA_x<=char_bound[char_num][0])&&(i_VGA_y>=char_bound[char_num][3])&&(i_VGA_y<=char_bound[char_num][2]))) begin
                    // save one bit of pixel data
                    char_data <= i_VGA_red[0];
                    char_counter <= char_counter + 1'b1;
                    r_char_addr <= char_counter;
                end
                else if (start_char_save_flag && (i_VGA_x>char_bound[char_num][0]) && (i_VGA_x<=char_bound[char_num][0]+x_diff)) begin
                    // pad end of row with black pixels if x boundary is less than 56
                    char_data <= 1'b0;
                    char_counter <= char_counter + 1'b1;
                    r_char_addr <= char_counter;
                end
                else if (start_char_save_flag && (i_VGA_y>char_bound[char_num][2]) && (i_VGA_y<=char_bound[char_num][2]+y_diff)&&(i_VGA_x>=char_bound[char_num][1]) && (i_VGA_x<=char_bound[char_num][0])) begin
                    // pad end of column with black pixels if y boundary is less than 56
                    char_data <= 1'b0;
                    char_counter <= char_counter + 1'b1;
                    r_char_addr <= char_counter;
                end
                // if last pixel of character
                if (start_char_save_flag && (i_VGA_x==char_bound[char_num][0]+x_diff)&&(i_VGA_y==char_bound[char_num][2]+y_diff)) begin 
                    char_save_done_flag <= 1'b1;
                    start_char_save_flag <= 1'b0;
                end
            end
            else if (char_save_done_flag) begin
                char_valid <= 1'b0;
                char_counter <= {($clog2(CHAR_DEPTH)-1){1'b0}};
            end
        end
    end
    
    
endmodule
