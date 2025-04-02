`timescale 1ns / 1ps


module data_flow_loop_control(
    input wire i_seven_seg_clk, //190hz
    input wire i_top_clk,
    input wire i_top_rst,
    input wire i_top_seven_seg_en, 
    
    input wire which_seven_seg_mode,
    input wire i_top_cnn_seg_test_1,
    input wire i_top_cnn_seg_test_2,
    input wire i_top_cnn_seg_test_3,
    input wire i_top_cnn_seg_test_4,
    input wire i_top_cnn_seg_test_5,
    input wire i_top_cnn_seg_test_6,
    input wire i_top_cnn_seg_test_7,    
    
    input wire cnn_prediction_done,

    input wire [7:0]first_prediction,
    input wire [7:0]second_prediction,
    input wire [7:0]third_prediction,

    output wire [6:0] seg,//the seven segment of each display 
    output wire [7:0] an, // since we have 8 display, each of them has their only anode
    
    input wire [2:0]i_which_char_to_seg, //NOTE this signal tells you which char is currently predicting. range from 0 to 6 
    output wire o_seven_seg_done_rst     //NOTE this signal acts like a reset pulse. 
         
    );
    
        reg [7:0] r_display_0;
        reg [7:0] r_display_1; 
        reg [7:0] r_display_2; 
        reg [7:0] r_display_3; 
        reg [7:0] r_display_4; 
        reg [7:0] r_display_5; 
        reg [7:0] r_display_6; 
        reg [7:0] r_display_7; 
        
        reg [7:0] char_num_prediction_1 [6:0];  // each precition data is 8 bits, and we have seven chars need to be stored. 
        reg [7:0] char_num_prediction_2 [6:0];
        reg [7:0] char_num_prediction_3 [6:0];
        
        reg trigger_pulse;
        reg all_char_done;
        reg r_seven_seg_done_rst;
        reg last_cnn_prediction_done;
        
        integer i;
        
        reg [6:0]sw_controlled_which_char_display;
        
        // Sequential logic for handling sw_controlled_which_char_display
        always @(posedge i_top_clk) begin
            if (i_top_rst) begin
                sw_controlled_which_char_display <= 7'd0; // Reset the display control to 0
            end else begin
                if (i_top_cnn_seg_test_1)
                    sw_controlled_which_char_display <= 7'd0;
                else if (i_top_cnn_seg_test_2)
                    sw_controlled_which_char_display <= 7'd1;
                else if (i_top_cnn_seg_test_3)
                    sw_controlled_which_char_display <= 7'd2;
                else if (i_top_cnn_seg_test_4)
                    sw_controlled_which_char_display <= 7'd3;
                else if (i_top_cnn_seg_test_5)
                    sw_controlled_which_char_display <= 7'd4;
                else if (i_top_cnn_seg_test_6)
                    sw_controlled_which_char_display <= 7'd5;
                else if (i_top_cnn_seg_test_7)
                    sw_controlled_which_char_display <= 7'd6; 
                else 
                    sw_controlled_which_char_display <= 7'd0; // Keep or reset the value   
            end
        end
        
        /*
        always @(posedge i_top_clk) begin
            if (i_top_rst) begin
                for (i = 0; i < 7; i = i + 1) begin
                    char_num_prediction_1[i] <= 8'b0;
                    char_num_prediction_2[i] <= 8'b0;
                    char_num_prediction_3[i] <= 8'b0;
                end
                
                r_seven_seg_done_rst <= 0;
                all_char_done <= 0;
                trigger_pulse <= 0;
                last_cnn_prediction_done <= 0;
            end else begin
                // Edge detection for cnn_prediction_done
                if (!last_cnn_prediction_done && cnn_prediction_done) begin
                    trigger_pulse <= 1;  // Set the trigger only on rising edge
                end
                last_cnn_prediction_done <= cnn_prediction_done;  // Update the last known state
                
                if (trigger_pulse) begin
                    char_num_prediction_1[i_which_char_to_seg] <= first_prediction;
                    char_num_prediction_2[i_which_char_to_seg] <= second_prediction;
                    char_num_prediction_3[i_which_char_to_seg] <= third_prediction;
                    
                    r_seven_seg_done_rst <= 1;
                    trigger_pulse <= 0;  // Clear the trigger
                end else begin
                    r_seven_seg_done_rst <= 0;
                end
                
                if (i_which_char_to_seg >= 6) begin
                    all_char_done <= 1;
                end
            end    
        end
        */
        
        always @(posedge i_top_clk) begin
            if (i_top_rst) begin
                for (i = 0; i < 7; i = i + 1) begin
                    char_num_prediction_1[i] <= 8'b0;
                    char_num_prediction_2[i] <= 8'b0;
                    char_num_prediction_3[i] <= 8'b0;
                end
                
                r_seven_seg_done_rst <= 0;
                all_char_done <= 0;
                trigger_pulse <= 0;
                last_cnn_prediction_done <= 0;
            end else begin
                if (i_which_char_to_seg <= 6) begin
                    // Edge detection for cnn_prediction_done
                    if (!last_cnn_prediction_done && cnn_prediction_done) begin
                        trigger_pulse <= 1;  // Set the trigger only on rising edge
                    end
                    last_cnn_prediction_done <= cnn_prediction_done;  // Update the last known state
                    
                    if (trigger_pulse) begin
                        char_num_prediction_1[i_which_char_to_seg] <= first_prediction;
                        char_num_prediction_2[i_which_char_to_seg] <= second_prediction;
                        char_num_prediction_3[i_which_char_to_seg] <= third_prediction;
                        
                        r_seven_seg_done_rst <= 1;
                        trigger_pulse <= 0;  // Clear the trigger
                    end else begin
                        r_seven_seg_done_rst <= 0;
                    end
                end else if (i_which_char_to_seg > 6) begin
                    all_char_done <= 1;
                    r_seven_seg_done_rst <= 0;   
                end
            end    
        end
        
        
        
        always@(*)begin
            if (i_top_rst) begin
                r_display_0 = 8'h0;
                r_display_1 = 8'h0;
                r_display_2 = 8'h0;
                r_display_3 = 8'h0;
                r_display_4 = 8'h0;
                r_display_5 = 8'h0;
                r_display_6 = 8'h0;
                r_display_7 = 8'h0;
            end else begin
                if(all_char_done && (which_seven_seg_mode == 0))begin // if equals to zero, show the entire plate 
                    r_display_0 = char_num_prediction_1[0];
                    r_display_1 = char_num_prediction_1[1];
                    r_display_2 = char_num_prediction_1[2];
                    r_display_3 = char_num_prediction_1[3];
                    r_display_4 = 8'h24;// "-" 
                    r_display_5 = char_num_prediction_1[4];
                    r_display_6 = char_num_prediction_1[5];
                    r_display_7 = char_num_prediction_1[6];
                    
                end else if(all_char_done&&(which_seven_seg_mode == 1))begin
                
                    r_display_0 = 8'h24;// "-" 
                    r_display_1 = 8'h24;// "-" 
                    r_display_2 = 8'h24;// "-" 
                    r_display_3 = 8'h24;// "-" 
                    r_display_4 = 8'h24;// "-" 
                    r_display_5 = char_num_prediction_1[sw_controlled_which_char_display];
                    r_display_6 = char_num_prediction_2[sw_controlled_which_char_display];
                    r_display_7 = char_num_prediction_3[sw_controlled_which_char_display];
                end else begin
                    r_display_0 = 8'h10;// "G" 
                    r_display_1 = 8'h1B;// "R"
                    r_display_2 = 8'h18;// "O" 
                    r_display_3 = 8'h1E;// "U" 
                    r_display_4 = 8'h19;// "P" 
                    r_display_5 = 8'h24;// "-" 
                    r_display_6 = 8'h2;// "2" 
                    r_display_7 = 8'h9;// "9" 
                end   
                
            end
        end
            

    assign o_seven_seg_done_rst = r_seven_seg_done_rst;
    
    
    seven_seg_display_interface
    seven_seg_display_interface
    (
        .i_seven_seg_clk(i_seven_seg_clk),
        .i_top_rst(i_top_rst),
        .i_top_seven_seg_en(i_top_seven_seg_en),
        
        .display_0(r_display_0), 
        .display_1(r_display_1), 
        .display_2(r_display_2),
        .display_3(r_display_3),
        .display_4(r_display_4),
        .display_5(r_display_5),
        .display_6(r_display_6), 
        .display_7(r_display_7),

        .seg(seg),
        .an(an)
    );
endmodule
