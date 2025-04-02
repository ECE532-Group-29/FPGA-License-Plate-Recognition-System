`timescale 1ns / 1ps

module top_tb;

    // Parameters
    localparam SMALL_DEPTH = 28*28;
    localparam LARGE_DEPTH = 56*56;

    // Inputs
    reg i_top_clk;
    reg i_top_rst;
    reg i_top_cam_start;
    reg i_top_cam_capture;
    reg i_top_gray_en;
    reg i_top_inverse_gray_en;
    reg i_top_high_contrast_en;
    reg i_top_seven_seg_en;
    reg i_top_segment;
    reg i_top_pclk;
    reg [7:0] i_top_pix_byte;
    reg i_top_pix_vsync;
    reg i_top_pix_href;

    // Outputs
    wire o_top_cam_done;
    wire o_top_led1_done;
    wire o_top_led2_done;
    wire o_top_led3_done;
    wire o_top_led4_done;
    wire o_top_led5_done;
    wire o_top_led6_done;
    wire o_top_led7_done;
    wire o_top_led8_done;
    wire o_top_led9_done;
    wire o_top_led10_done;
    wire o_top_led11_done;
    wire o_top_led12_done;
    wire o_top_led13_done;
    wire o_top_led14_done;
    wire o_top_dummy_output;
    wire o_top_reset;
    wire o_top_pwdn;
    wire o_top_xclk;
    wire o_top_siod;
    wire o_top_sioc;
    wire [3:0] o_top_vga_red;
    wire [3:0] o_top_vga_green;
    wire [3:0] o_top_vga_blue;
    wire o_top_vga_vsync;
    wire o_top_vga_hsync;
    wire [6:0] seg;
    wire [7:0] an;

    // Instantiate the Unit Under Test (UUT)
    top #(
        .SMALL_DEPTH(SMALL_DEPTH),
        .LARGE_DEPTH(LARGE_DEPTH)
    ) uut (
        .i_top_clk(i_top_clk),
        .i_top_rst(i_top_rst),
        .i_top_cam_start(i_top_cam_start),
        .i_top_cam_capture(i_top_cam_capture),
        .o_top_cam_done(o_top_cam_done),
        .i_top_gray_en(1),
        .i_top_inverse_gray_en(1),
        .i_top_high_contrast_en(1),
        .i_top_seven_seg_en(1),
        .i_top_segment(i_top_segment),
        .o_top_led1_done(o_top_led1_done),
        .o_top_led2_done(o_top_led2_done),
        .o_top_led3_done(o_top_led3_done),
        .o_top_led4_done(o_top_led4_done),
        .o_top_led5_done(o_top_led5_done),
        .o_top_led6_done(o_top_led6_done),
        .o_top_led7_done(o_top_led7_done),
        .o_top_led8_done(o_top_led8_done),
        .o_top_led9_done(o_top_led9_done),
        .o_top_led10_done(o_top_led10_done),
        .o_top_led11_done(o_top_led11_done),
        .o_top_led12_done(o_top_led12_done),
        .o_top_led13_done(o_top_led13_done),
        .o_top_led14_done(o_top_led14_done),
        .o_top_dummy_output(o_top_dummy_output),
        .i_top_pclk(i_top_pclk),
        .i_top_pix_byte(i_top_pix_byte),
        .i_top_pix_vsync(i_top_pix_vsync),
        .i_top_pix_href(i_top_pix_href),
        .o_top_reset(o_top_reset),
        .o_top_pwdn(o_top_pwdn),
        .o_top_xclk(o_top_xclk),
        .o_top_siod(o_top_siod),
        .o_top_sioc(o_top_sioc),
        .o_top_vga_red(o_top_vga_red),
        .o_top_vga_green(o_top_vga_green),
        .o_top_vga_blue(o_top_vga_blue),
        .o_top_vga_vsync(o_top_vga_vsync),
        .o_top_vga_hsync(o_top_vga_hsync),
        .seg(seg),
        .an(an)
    );

    // Clock generation
    initial begin
        i_top_clk = 0;
        forever #1 i_top_clk = ~i_top_clk;  // Generate a clock with 10ns period (100 MHz)
    end

    // Initialize Inputs and apply test vectors
    initial begin
        // Reset
        //# 50000
        i_top_rst = 1;
        //# 550000
        # 15
        i_top_rst = 0;
        i_top_segment = 0;
        /*
        // Start simulation
        # 50000
        i_top_cam_start = 1;
        # 550000
        i_top_cam_start = 0;
        
        # 50000
        i_top_cam_capture= 1;
        # 550000
        i_top_cam_capture= 0;
        */

    end
    initial begin
        #3080000; //the rntire frame data is feeded in. 
        i_top_segment =1; // start the segmentation process
        # 1100000
        //# 550000
        i_top_segment =0;
        
        #3500000
        $finish;
    end

endmodule
