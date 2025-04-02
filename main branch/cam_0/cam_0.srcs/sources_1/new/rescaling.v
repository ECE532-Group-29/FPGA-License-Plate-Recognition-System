`timescale 1ns / 1ps

module rescaling
#(
parameter SMALL_SIZE = 28,
parameter LARGE_SIZE = 56,
parameter SMALL_DEPTH = SMALL_SIZE*SMALL_SIZE,
parameter LARGE_DEPTH = LARGE_SIZE*LARGE_SIZE
)
(
    input wire i_clk,
    input wire i_rstn,
    input wire i_seven_seg_done_rst,
    input wire i_large_image_data,
    input wire i_large_image_data_valid, //starting of the extracted letter
    input wire [$clog2(LARGE_DEPTH)-1:0] i_large_image_addr,
    
    output wire o_small_image_data,
    output wire [$clog2(SMALL_DEPTH)-1:0] o_small_image_addr,
    output wire [$clog2(SMALL_DEPTH)-1:0] o_small_image_read_addr,
    output wire rescaling_done_write_start,
    output wire bram_data_valid
    
    
);
    
    reg [$clog2(SMALL_DEPTH)-1:0]small_image_addr;
    reg [$clog2(SMALL_DEPTH)-1:0]small_image_read_addr;
    reg small_image_data; 
    
    reg FIFO_Valid;
    reg bram_write_en;

    integer i, j;
    reg FIFO [0:LARGE_SIZE+1];

    //first time 
    //  X X X X ..... X X X 
    //  X X - -
    
    //second
    //  - - X X ..... X X X
    //  X X X X - - 
    
    //so we need 56 + 2 = 58 space for the fifo queue. 
    reg small_addr_reset;
    reg fix_timing_glitch;
    reg [$clog2(LARGE_DEPTH)-1:0] last_addr; // Register to hold the previous address
    reg read_bram_done;
    reg r_bram_data_valid;
    
    always @ (posedge i_clk) begin
        if (!i_rstn || i_seven_seg_done_rst) begin
            FIFO_Valid <=0;
            bram_write_en <= 1; // bram is always start with write enable 
            fix_timing_glitch <= 0;
            read_bram_done <= 0;
            small_addr_reset <= 1;
            r_bram_data_valid <= 0;
            last_addr <= 0; // Reset the last address register           
            // Clear FIFO on reset
            for (i = 0; i < LARGE_SIZE+1; i = i + 1) begin
                FIFO[i] <= 1'b0;
            end
            
            //clear on addr
            small_image_addr <= 1'b0;
            small_image_read_addr <= 1'b0;

    
        end else begin
            if (i_large_image_addr == LARGE_SIZE+1)begin
                FIFO_Valid <=1;
            end
            // Logic from the first block
            if (i_large_image_addr == LARGE_DEPTH - 1 && !read_bram_done) begin
                fix_timing_glitch <= 1;
            end
    
            if ((small_image_addr == SMALL_DEPTH - 1) && !read_bram_done) begin
                bram_write_en <= 0;
                fix_timing_glitch <= 0;
                small_image_read_addr <= 0;
                
                
                if (small_image_read_addr < SMALL_DEPTH - 1) begin
                    small_image_read_addr <= small_image_read_addr + 1;
                    r_bram_data_valid <=1;
                    if (small_image_read_addr == SMALL_DEPTH - 1) begin
                        read_bram_done <= 1;
                        //small_image_read_addr <=0;
                    end
                end
            end
    
            // Logic from the second block
            if (i_large_image_data_valid && (i_large_image_addr != last_addr) || fix_timing_glitch) begin
                // Shift FIFO contents
                for (i = LARGE_SIZE+1; i > 0; i = i - 1) begin 
                    FIFO[i] <= FIFO[i - 1];
                end
    
                FIFO[0] <= i_large_image_data;
                last_addr <= i_large_image_addr; // Update last address with current address
    
                // Process every second clock to allow for full data availability
                if (((i_large_image_addr-1) % 2 == 1 && ((i_large_image_addr-1) / LARGE_SIZE) % 2 == 1) || fix_timing_glitch) begin
                    // Use FIFO to calculate new pixel value
                    if (FIFO_Valid) begin
                        small_image_data <= (FIFO[0] + FIFO[1] + FIFO[LARGE_SIZE] + FIFO[LARGE_SIZE+1] >= 2) ? 1 : 0;
                        
                        if (small_addr_reset) begin
                            bram_write_en <= 1;
                            small_image_addr <= 0;
                            small_addr_reset <= ~small_addr_reset;
                        end else if (small_image_addr < SMALL_DEPTH - 1) begin
                            small_image_addr <= small_image_addr + 1;
                        end
                    end   
                end
            end
        end
    end


    assign o_small_image_data = small_image_data;
    assign o_small_image_addr = small_image_addr;
    assign o_small_image_read_addr = small_image_read_addr;
    assign rescaling_done_write_start = bram_write_en;
    assign bram_data_valid = r_bram_data_valid;

/*
//this is purely for debug prupose, we do not need to have them ---------------------------------

    reg large_image [0 : LARGE_DEPTH-1]; //this is purely for debug prupose, we do not need to have them 
   
    //this is purely for debug prupose, we do not need to have them 
    always @(posedge i_clk) begin
        if (i_large_image_data_valid)begin
            large_image[i_large_image_addr] <= i_large_image_data;
        end
    end  
    

    integer Z;
    integer file_mem_large; 
        always @ (*) begin    
            file_mem_large = $fopen("output_seg_image.mem", "w"); // Open the file in write mode
                if (file_mem_large) begin
                    for (Z = 0; Z < LARGE_DEPTH; Z = Z + 1) begin
                        $fdisplay(file_mem_large, "%b", large_image[Z]); // Write each bit on a new line
                    end
                    $fclose(file_mem_large); // Close the file
                end
        end 

    */

endmodule

