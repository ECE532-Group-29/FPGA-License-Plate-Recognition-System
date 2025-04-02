`timescale 1ns / 1ps
//I think a single port config for this mem is okay since we do not need to 
//read and write at the same time as the VGA output is doing. 
//instead, we need to store the entire image before CNN can process them. 
module mem_control
#(
parameter SMALL_DEPTH = 28*28
)
(
    input wire i_top_clk,
    input wire Wr_en,
    input wire [$clog2(SMALL_DEPTH)-1:0]Addr,
    input wire [$clog2(SMALL_DEPTH)-1:0]read_Addr,
    input wire Wr_Data,
    output wire Rd_Data,
    output wire [$clog2(SMALL_DEPTH)-1:0]o_read_Addr
);
    reg small_image [0 : SMALL_DEPTH-1]; //the original image stored from segmentation extraction. 
    reg [$clog2(SMALL_DEPTH)-1:0] reg_addr; 
    
    always @ (posedge i_top_clk) begin
        if (Wr_en)begin // when high, write data in ram at the current Addr
            small_image[Addr] <= Wr_Data;
        end else begin // when low, read out data 
            reg_addr <= read_Addr;
            
        end
    end
    assign Rd_Data = small_image[reg_addr];
    assign o_read_Addr = reg_addr;
 /*   
integer l;
integer file_mem_small; 
    always @ (*) begin    
        file_mem_small = $fopen("input_bram_to_cnn_image.mem", "w"); // Open the file in write mode
            if (file_mem_small) begin
                for (l = 0; l < SMALL_DEPTH; l = l + 1) begin
                    $fdisplay(file_mem_small, "%b", small_image[l]); // Write each bit on a new line
                end
                $fclose(file_mem_small); // Close the file
            end
    end
    */
    
endmodule
