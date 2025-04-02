`timescale 1ns / 1ps

module maxpooling
#(
parameter SMALL_SIZE = 3, 
parameter LARGE_SIZE = 7, 
parameter SMALL_DEPTH = SMALL_SIZE*SMALL_SIZE,
parameter LARGE_DEPTH = LARGE_SIZE*LARGE_SIZE
)
(
    input wire i_clk,
    input wire i_rstn,
    input wire i_seven_seg_done_rst,
    input wire [14:0]i_large_image_data,
    input wire i_large_image_data_valid, //starting of the extracted letter
    input wire [$clog2(LARGE_DEPTH)-1:0] i_large_image_addr,
    
    output wire [14:0] o_small_image_data,
    output wire o_small_image_data_valid,
    output wire [$clog2(SMALL_DEPTH)-1:0] o_small_image_addr,
    output wire [$clog2(SMALL_DEPTH)-1:0] o_small_image_read_addr,
    output wire o_small_image_data_ready
    
    
);
    
    reg [$clog2(SMALL_DEPTH)-1:0]small_image_addr;
    reg [$clog2(SMALL_DEPTH)-1:0]small_image_read_addr;
    reg [14:0]small_image_data; 
    reg small_image_data_valid;
    
    reg small_image_data_ready;

    integer i;
    reg [14:0] FIFO [0:LARGE_SIZE+1];

    //first time 
    //  X X X X ..... X X X 
    //  X X - -
    //second
    //  - - X X ..... X X X
    //  X X X X - - 
    
    //so we need 56 + 2 = 58 space for the fifo queue. 
    reg small_addr_reset;
    reg read_bram_done;
    reg fix_timing_glitch;
    
   // reg [14:0]maxp_out_image [0 : SMALL_DEPTH-1]; //this is purely for debug prupose, we do not need to have them 
   // reg [14:0]input_image [0 : LARGE_DEPTH-1]; //this is purely for debug prupose, we do not need to have them 
    
    
    reg [14:0]win_0;
    reg [14:0]win_1;
    reg [14:0]win_2;
    reg [14:0]win_3;

    always @ (posedge i_clk) begin
        if (!i_rstn || i_seven_seg_done_rst) begin
            read_bram_done <= 0;
            small_addr_reset <= 1;
            fix_timing_glitch <= 0;
            small_image_data_valid <=0;
            small_image_data_ready <=0;
            
            // Clear FIFO on reset
            for (i = 0; i < LARGE_SIZE+2; i = i + 1) begin
                FIFO[i] <= 16'd0;
            end
            
            small_image_data <= 15'b0;
            small_image_addr <= 0;
            
        end else begin
            if (i_large_image_addr == LARGE_DEPTH - 1 && !read_bram_done) begin
                fix_timing_glitch <= 1;
            end
            
            if (i_large_image_data_valid || fix_timing_glitch) begin //if1
                // Shift FIFO contents
                for (i = LARGE_SIZE+1; i > 0; i = i - 1) begin 
                    FIFO[i] <= FIFO[i - 1];
                end
    
                FIFO[0] <= i_large_image_data;
                
                // Process every second clock to allow for full data availability
                if (((i_large_image_addr-1) % 2 == 1 && ((i_large_image_addr-1) / LARGE_SIZE) % 2 == 1) || fix_timing_glitch) begin // if2
                    
                    win_3 <=   FIFO[0];    // pixel window  0 1
                    win_2 <=   FIFO[1];    //               2 3
                    win_1 <=   FIFO[LARGE_SIZE];
                    win_0 <=   FIFO[LARGE_SIZE+1];          
                    
                    // maxpooling 
                    small_image_data <= (FIFO[0] >= FIFO[1] && FIFO[0] >= FIFO[LARGE_SIZE] && FIFO[0] >= FIFO[LARGE_SIZE+1]) ? FIFO[0] :
                                            (FIFO[1] >= FIFO[0] && FIFO[1] >= FIFO[LARGE_SIZE] && FIFO[1] >= FIFO[LARGE_SIZE+1]) ? FIFO[1] :
                                            (FIFO[LARGE_SIZE] >= FIFO[0] && FIFO[LARGE_SIZE] >= FIFO[1] && FIFO[LARGE_SIZE] >= FIFO[LARGE_SIZE+1]) ? FIFO[LARGE_SIZE] : 
                                            FIFO[LARGE_SIZE+1]; 
                    
                    // average pooling 
                    //small_image_data <= ((FIFO[0] + FIFO[1] + FIFO[LARGE_SIZE] + FIFO[LARGE_SIZE+1]) / 4) ; 
                    
                    if ( small_addr_reset && (i_large_image_addr >= LARGE_SIZE+1) ) begin // start to write data into bram with addr incrementing. //if3
                        small_image_data_ready <= 1;
                        small_image_addr <= 0;
                        small_image_data_valid <=1;
                        small_addr_reset <= ~small_addr_reset;//only execute once. 
                        
                    end else if (small_image_addr < SMALL_DEPTH -1) begin
                        small_image_addr <= small_image_addr + 1; //addr incrementing here
                        small_image_data_valid <=1;
                        
                    end//if3
                   //maxp_out_image[small_image_addr] <= small_image_data;    
                    
                end else begin //if2 
                    if (small_image_addr == SMALL_DEPTH-1) begin // keep the data valid high since all data is transmitted. 
                        small_image_data_valid <=1;
                    end else begin
                        small_image_data_valid <=0;
                    end    
                end
                
            end//if1
            
            // ------ this porting is used to generate read addr ------
            if ((small_image_addr == SMALL_DEPTH - 1) && !read_bram_done) begin
                //small_image_data_ready <= 0;
                small_image_read_addr <= 0;
                fix_timing_glitch <= 0;
                
                if (small_image_read_addr < SMALL_DEPTH - 1) begin
                    small_image_read_addr <= small_image_read_addr + 1;
                    if (small_image_read_addr == SMALL_DEPTH - 1) begin
                        read_bram_done <= 1;
                    end
                end
            end            
            // ------ this porting is used to generate read addr ------
            
        end//after rst begin
    end//always end


    assign o_small_image_data = small_image_data;
    assign o_small_image_addr = small_image_addr;
    assign o_small_image_read_addr = small_image_read_addr;
    assign o_small_image_data_ready = small_image_data_ready;
    assign o_small_image_data_valid = small_image_data_valid;

//this is purely for debug prupose, we do not need to have them ---------------------------------
/*
    
   
    //this is purely for debug prupose, we do not need to have them 
    always @(posedge i_clk) begin
        if (i_large_image_data_valid)begin
            input_image[i_large_image_addr] <= i_large_image_data;
        end
    end  
    

        
    integer M,N,B;
    integer file_mem_large,file_mem_large_L2,file_mem_large_L3; 
    always @ (*) begin
        if(LARGE_DEPTH == 28*28) begin    
            file_mem_large = $fopen("input_maxpool_L1.mem", "w"); // Open the file in write mode
                if (file_mem_large) begin
                    for (M = 0; M < LARGE_DEPTH; M = M + 1) begin
                        $fdisplay(file_mem_large, "%b", input_image[M]); // Write each bit on a new line
                    end
                    $fclose(file_mem_large); // Close the file
                end
         end  
         
         if(LARGE_DEPTH == 14*14) begin    
            file_mem_large_L2 = $fopen("input_maxpool_L2.mem", "w"); // Open the file in write mode
                if (file_mem_large_L2) begin
                    for (N = 0; N < LARGE_DEPTH; N = N + 1) begin
                        $fdisplay(file_mem_large_L2, "%b", input_image[N]); // Write each bit on a new line
                    end
                    $fclose(file_mem_large_L2); // Close the file
                end
         end
        
        if(LARGE_DEPTH == 6*6) begin    
            file_mem_large_L3 = $fopen("input_maxpool_L3.mem", "w"); // Open the file in write mode
                if (file_mem_large_L3) begin
                    for (B = 0; B < LARGE_DEPTH; B = B + 1) begin
                        $fdisplay(file_mem_large_L3, "%b", input_image[B]); // Write each bit on a new line
                    end
                    $fclose(file_mem_large_L3); // Close the file
                end
         end  
              
    end
         
    integer Z,X,C;
    integer file_mem_small,file_mem_small_L2,file_mem_small_L3; 
    always @ (*) begin 
        if(SMALL_DEPTH == 14*14)begin 
            file_mem_small = $fopen("output_maxpool_L1.mem", "w"); // Open the file in write mode
                if (file_mem_small) begin
                    for (Z = 0; Z < SMALL_DEPTH; Z = Z + 1) begin
                        $fdisplay(file_mem_small, "%b", maxp_out_image[Z]); // Write each bit on a new line
                    end
                    $fclose(file_mem_small); // Close the file
                end
          end  
          
        if(SMALL_DEPTH == 7*7)begin 
            file_mem_small_L2 = $fopen("output_maxpool_L2.mem", "w"); // Open the file in write mode
                if (file_mem_small_L2) begin
                    for (X = 0; X < SMALL_DEPTH; X = X + 1) begin
                        $fdisplay(file_mem_small_L2, "%b", maxp_out_image[X]); // Write each bit on a new line
                    end
                    $fclose(file_mem_small_L2); // Close the file
                end
          end
          
          if(SMALL_DEPTH == 3*3)begin 
            file_mem_small_L3 = $fopen("output_maxpool_L3.mem", "w"); // Open the file in write mode
                if (file_mem_small_L3) begin
                    for (C = 0; C < SMALL_DEPTH; C = C + 1) begin
                        $fdisplay(file_mem_small_L3, "%b", maxp_out_image[C]); // Write each bit on a new line
                    end
                    $fclose(file_mem_small_L3); // Close the file
                end
          end     
           
    end 
    
*/
endmodule

