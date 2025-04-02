`timescale 1ns / 1ps

module vga_top_tb;
    
    // Inputs
    reg clk; // 25 Mhz
    reg rstn;
    reg i_segment;
    reg [2:0]i_top_which_char_to_seg;
    reg [3:0]frame_data;
    // 640 * 480 -1 = 307200 - 1 = 307199
    
    
    // Instantiate the Unit Under Test (UUT)
    top uut (

        
        .i_clk25m(clk),
        .i_rstn_clk25m(rstn),
        .i_gray_en(1),
        .i_inverse_gray_en(1), 
        .i_high_contrast_en(1), 
        .i_segment(i_segment),
        .i_top_which_char_to_seg(i_top_which_char_to_seg)
        

    );


    
    
    

    // Clock generation for 25 MHz
    initial begin
        clk = 0;
        forever #1 clk = ~clk; // 40 ns period -> 25 MHz
    end



    // Test stimulus
    initial begin
        // Initialize Reset
        rstn = 0; // Assert reset
        #15;     // Hold reset for 20ns
        rstn = 1; // Deassert reset
        i_top_which_char_to_seg = 3'b000;
        
        // Wait for some time to observe the small image output
        #3000000; //1s
        
        rstn = 0; // Assert reset
        #15;     // Hold reset for 20ns
        rstn = 1; // Deassert reset
        i_top_which_char_to_seg = 3'b001;
        
         #3000000; //1s
        
        $finish;
    end
    
    initial begin
        #650000; //the rntire frame data is feeded in. 
        i_segment =1; // start the segmentation process
        //# 1100000
        # 550000
        i_segment =0;
        
        
        
        #1700000;
        
        #650000; //the rntire frame data is feeded in. 
        i_segment =1; // start the segmentation process
        //# 1100000
        # 550000
        i_segment =0;
        
    end
    
    
    reg process_enable;
    initial begin
        //#1753089;        // Wait for 1000ns
        process_enable = 1;  // Enable the processing block
    end
    


endmodule
