`timescale 1ns / 1ps

`default_nettype none

module top
#(
    parameter SMALL_DEPTH = 28*28,
    parameter LARGE_DEPTH = 56*56
)
    (   input wire i_top_clk,
        input wire i_top_rst,
        
        input wire  i_top_cam_start, 
        input wire  i_top_cam_capture,
        output wire o_top_cam_done, 
        
        //control switches for image processing
        input wire i_top_gray_en,
        input wire i_top_inverse_gray_en,
        input wire i_top_high_contrast_en,
        input wire i_top_seven_seg_en,
        
        input wire which_seven_seg_mode,
        input wire i_top_cnn_seg_test_1,
        input wire i_top_cnn_seg_test_2,
        input wire i_top_cnn_seg_test_3,
        input wire i_top_cnn_seg_test_4,
        input wire i_top_cnn_seg_test_5,
        input wire i_top_cnn_seg_test_6,
        input wire i_top_cnn_seg_test_7,
        
        // control to start segmentation
        input wire i_top_segment,
        output wire o_top_led1_done,
        output wire o_top_led2_done,
        output wire o_top_led3_done,
        output wire o_top_led4_done,
        output wire o_top_led5_done,
        output wire o_top_led6_done,
        output wire o_top_led7_done,
        output wire o_top_led8_done,
        output wire o_top_led9_done,
        output wire o_top_led10_done,
        output wire o_top_led11_done,
        output wire o_top_led12_done,
        output wire o_top_led13_done,
        output wire o_top_led14_done,
        output wire o_top_led15_done,
        //TODO 
        output wire o_top_dummy_output,
        
        // I/O to camera
        input wire       i_top_pclk, 
        input wire [7:0] i_top_pix_byte,
        input wire       i_top_pix_vsync,
        input wire       i_top_pix_href,
        output wire      o_top_reset,
        output wire      o_top_pwdn,
        output wire      o_top_xclk,
        output wire      o_top_siod,
        output wire      o_top_sioc,
        
        // I/O to VGA 
        output wire [3:0] o_top_vga_red,
        output wire [3:0] o_top_vga_green,
        output wire [3:0] o_top_vga_blue,
        output wire       o_top_vga_vsync,
        output wire       o_top_vga_hsync,
        
        
        //7 seg display 

        output wire [6:0] seg,
        output wire [7:0] an
    );
    
    // Connect cam_top/vga_top modules to BRAM
    wire [11:0] i_bram_pix_data,    o_bram_pix_data;
    wire [18:0] i_bram_pix_addr,    o_bram_pix_addr; 
    wire        i_bram_pix_wr;
           
    // Reset synchronizers for all clock domains
    reg r1_rstn_top_clk,    r2_rstn_top_clk;
    reg r1_rstn_pclk,       r2_rstn_pclk;
    reg r1_rstn_clk25m,     r2_rstn_clk25m; 
        
    wire w_clk25m; 
    wire [63:0] i_top_display_0;
    wire [63:0] i_top_display_1;
    wire [63:0] i_top_display_2;
    wire [63:0] i_top_display_3;
    wire [63:0] i_top_display_4;
    wire [63:0] i_top_display_5;
    wire [63:0] i_top_display_6;
    wire [63:0] i_top_display_7;
    // Generate clocks for camera and VGA
    clk_wiz_0
    clock_gen
    (
        .clk_in1(i_top_clk          ),
        .clk_out1(w_clk25m          ),
        .clk_out2(o_top_xclk        )
    );
    
    wire w_rst_btn_db; 
    
    // Debounce top level button - invert reset to have debounced negedge reset
    localparam DELAY_TOP_TB = 240_000; //240_000 when uploading to hardware, 10 when simulating in testbench 
    debouncer 
    #(  .DELAY(DELAY_TOP_TB)    )
    top_btn_db
    (
        .i_clk(i_top_clk        ),
        .i_btn_in(~i_top_rst    ),
        .o_btn_db(w_rst_btn_db  )
    ); 
    
    // Double FF for negedge reset synchronization 
    always @(posedge i_top_clk or negedge w_rst_btn_db)
        begin
            if(!w_rst_btn_db) {r2_rstn_top_clk, r1_rstn_top_clk} <= 0; 
            else              {r2_rstn_top_clk, r1_rstn_top_clk} <= {r1_rstn_top_clk, 1'b1}; 
        end 
    always @(posedge w_clk25m or negedge w_rst_btn_db)
        begin
            if(!w_rst_btn_db) {r2_rstn_clk25m, r1_rstn_clk25m} <= 0; 
            else              {r2_rstn_clk25m, r1_rstn_clk25m} <= {r1_rstn_clk25m, 1'b1}; 
        end
    always @(posedge i_top_pclk or negedge w_rst_btn_db)
        begin
            if(!w_rst_btn_db) {r2_rstn_pclk, r1_rstn_pclk} <= 0; 
            else              {r2_rstn_pclk, r1_rstn_pclk} <= {r1_rstn_pclk, 1'b1}; 
        end 
    
    // FPGA-camera interface
    cam_top 
    #(  .CAM_CONFIG_CLK(100_000_000)    )
    OV7670_cam
    (
        .i_clk(i_top_clk                ),
        .i_rstn_clk(r2_rstn_top_clk     ),
        .i_rstn_pclk(r2_rstn_pclk       ),
        
        // I/O for camera init
        .i_cam_start(i_top_cam_start    ),
        .o_cam_done(o_top_cam_done      ), 
        
        // I/O camera
        .i_pclk(i_top_pclk              ),
        .i_pix_byte(i_top_pix_byte      ), 
        .i_vsync(i_top_pix_vsync        ), 
        .i_href(i_top_pix_href          ),
        .o_reset(o_top_reset            ),
        .o_pwdn(o_top_pwdn              ),
        .o_siod(o_top_siod              ),
        .o_sioc(o_top_sioc              ), 
        
        // Outputs from camera to BRAM
        .o_pix_wr(                      ),
        .o_pix_data(i_bram_pix_data     ),
        .o_pix_addr(i_bram_pix_addr     )
    );
    
    mem_bram
    #(  .WIDTH(12                       ), 
        .DEPTH(640*480)                 )
     pixel_memory
     (
        // BRAM Write signals (cam_top)
        .i_wclk(i_top_pclk              ),
        .i_wr(1'b1                      ), 
        .i_wr_addr(i_bram_pix_addr      ),
        .i_bram_data(i_bram_pix_data    ),
        .i_bram_en(1'b1                 ),
        
        .i_VGA_x(X),
        .i_VGA_y(Y),
         
         // BRAM Read signals (vga_top)
        .i_rclk(w_clk25m                ),
        .i_rd(1'b1                      ),
        .i_rd_addr(o_bram_pix_addr      ), 
        .i_cam_capture(i_top_cam_capture    ),
        .o_bram_data(o_bram_pix_data    )
     );
     
    wire [9:0]  X; 
    wire [9:0 ] Y;
    wire top_resized_image_data;
    wire w_top_bram_data_valid;
    wire [$clog2(SMALL_DEPTH)-1:0]o_bram_read_Addr;
    //this reg decide which char to segmented from segmentation module 
    
    reg [2:0]i_top_which_char_to_seg;
    wire w_top_seven_seg_done_rst;
    
    always @(posedge w_clk25m) begin
        if(!r2_rstn_clk25m)begin
            i_top_which_char_to_seg <= 0;
        end else begin
            if(w_top_seven_seg_done_rst) begin
                i_top_which_char_to_seg <= i_top_which_char_to_seg+1;
            end
        end
    end
    /*
    always @(*) begin
    i_top_which_char_to_seg = {i_top_cnn_seg_test_2, 
                           i_top_cnn_seg_test_1, 
                           i_top_cnn_seg_test_0};
    end
    */
    // testing 
    vga_top
    display_interface
    (
        .i_clk25m(w_clk25m              ),
        .i_rstn_clk25m(r2_rstn_clk25m   ), 
        
        // VGA timing signals
        .o_VGA_x(X                      ),
        .o_VGA_y(Y                      ), 
        .o_VGA_vsync(o_top_vga_vsync    ),
        .o_VGA_hsync(o_top_vga_hsync    ), 
        .o_VGA_video(                   ),
        
        // VGA RGB Pixel Data
        .o_VGA_red(o_top_vga_red        ),
        .o_VGA_green(o_top_vga_green    ),
        .o_VGA_blue(o_top_vga_blue      ), 
        
        .o_led1_done(o_top_led1_done),
        .o_led2_done(o_top_led2_done),
        
        .i_gray_en(i_top_gray_en),
        .i_inverse_gray_en(i_top_inverse_gray_en),
        .i_high_contrast_en(i_top_high_contrast_en),
        .i_segment(i_top_segment),
        .i_which_char_to_seg(i_top_which_char_to_seg),
        .i_seven_seg_done_rst(w_top_seven_seg_done_rst),
        
        // VGA read/write from/to BRAM
        .i_pix_data(o_bram_pix_data     ), 
        .o_pix_addr(o_bram_pix_addr     ),
        .o_image_data_for_cnn(top_resized_image_data),
        .o_top_bram_read_Addr(o_bram_read_Addr),
        .o_bram_data_valid(w_top_bram_data_valid)
    );

    wire [7:0]w_cnn_layer_data_prediction_1;
    wire [7:0]w_cnn_layer_data_prediction_2;
    wire [7:0]w_cnn_layer_data_prediction_3;
    wire w_cnn_all_done_valid;
    
    
    data_flow_loop_control
    looping_for_all_seven_chars
    (    //control input
        .i_seven_seg_clk(seven_seg_clk),
        .i_top_clk(w_clk25m),
        .i_top_rst(i_top_rst),
        .i_top_seven_seg_en(i_top_seven_seg_en),
        .which_seven_seg_mode(which_seven_seg_mode),
        .i_top_cnn_seg_test_1(i_top_cnn_seg_test_1),
        .i_top_cnn_seg_test_2(i_top_cnn_seg_test_2),
        .i_top_cnn_seg_test_3(i_top_cnn_seg_test_3),
        .i_top_cnn_seg_test_4(i_top_cnn_seg_test_4),
        .i_top_cnn_seg_test_5(i_top_cnn_seg_test_5),
        .i_top_cnn_seg_test_6(i_top_cnn_seg_test_6),
        .i_top_cnn_seg_test_7(i_top_cnn_seg_test_7),
        
        //data and logic input 
        .i_which_char_to_seg(i_top_which_char_to_seg),
        .cnn_prediction_done(w_cnn_all_done_valid),
        .first_prediction(w_cnn_layer_data_prediction_1),
        .second_prediction(w_cnn_layer_data_prediction_2),
        .third_prediction(w_cnn_layer_data_prediction_3),
        
        //output 
        .o_seven_seg_done_rst(w_top_seven_seg_done_rst),
        .seg(seg),
        .an(an)
    );
    
    wire seven_seg_clk; 
    
    custom_clk_gen
    custom_clk_gen
    (
        .i_top_clk(i_top_clk),
        .i_top_rst(i_top_rst),
        .i_top_seven_seg_en(i_top_seven_seg_en),
        .o_seven_seg_clk(seven_seg_clk)
    );
    
    
    cnn_interface
    cnn_interface
(
        .i_top_clk(w_clk25m),
        .i_top_rstn(r2_rstn_clk25m),
        .i_top_bram_read_Addr(o_bram_read_Addr),
        .i_bram_top_valid(w_top_bram_data_valid),
        .i_Rd_Data(top_resized_image_data),
        .i_seven_seg_done_rst(w_top_seven_seg_done_rst),
        //output
        .dummy_index1(w_cnn_layer_data_prediction_1),
        .dummy_index2(w_cnn_layer_data_prediction_2),
        .dummy_index3(w_cnn_layer_data_prediction_3),
        .cnn_all_done_valid(w_cnn_all_done_valid)
        

);

    // TO REMOVE, LEDs used for debug
    assign o_top_led3_done = 1'b0;
    assign o_top_led4_done = 1'b0;
    assign o_top_led5_done = 1'b0;
    assign o_top_led6_done = 1'b0;
    assign o_top_led7_done = 1'b0;
    assign o_top_led8_done = 1'b0;
    assign o_top_led9_done = 1'b0;
    assign o_top_led10_done = 1'b0;
    assign o_top_led11_done = 1'b0;
    assign o_top_led12_done = 1'b0;
    assign o_top_led13_done = 1'b0;
    assign o_top_led14_done = 1'b0;
    assign o_top_led15_done = w_cnn_all_done_valid;
    
endmodule
