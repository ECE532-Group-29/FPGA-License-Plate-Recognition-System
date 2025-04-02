`timescale 1ns / 1ps

module padding_zeros
#(
parameter WIDTH = 28,
parameter INPUT_SIZE = WIDTH*WIDTH
)
(
    input wire i_clk,
    input wire i_rstn,
    input wire i_seven_seg_done_rst,
    input wire i_en,
    input wire [14:0] i_pix_data,
    input wire [$clog2(WIDTH*WIDTH)-1:0] i_pix_addr,
    output wire o_valid,
    output wire o_ready,
    //output wire [$clog2((WIDTH+2)*(WIDTH+2))-1:0] o_pix_addr
    output wire [14:0] o_pix_data
    );
    
    localparam DEPTH = WIDTH*WIDTH;
    localparam DEPTH_PADDED = (WIDTH+2)*(WIDTH+2);
    
    reg [14:0] padded_image [0:DEPTH_PADDED-1];
    reg [$clog2(DEPTH)-1:0] counter;
    reg [$clog2(DEPTH_PADDED)-1:0] counter_padded;
    reg capture_done_flag, w_valid, w_ready;
    reg [14:0] w_pix_data;
    //reg [$clog2((WIDTH+2)*(WIDTH+2))-1:0] w_pix_addr;
    integer i;
    wire [$clog2(WIDTH*WIDTH)-1:0] r_x, r_y;
    
    assign r_x = (i_pix_addr % WIDTH) + 1'b1;
    assign r_y = ((i_pix_addr < WIDTH) ? 0 : i_pix_addr / WIDTH) + 1'b1;
    
    always @(posedge i_clk or negedge i_rstn or posedge i_seven_seg_done_rst) begin
        if (!i_rstn || i_seven_seg_done_rst) begin
            for (i = 0; i < DEPTH_PADDED; i = i + 1) begin
                padded_image[i] <= 15'd0;
            end
            counter <= {($clog2(DEPTH)-1){1'b0}};
            counter_padded <= {($clog2(DEPTH_PADDED)-1){1'b0}};
            capture_done_flag <= 1'b0;
            w_valid <= 1'b0;
            w_ready <= 1'b0;
            w_pix_data <= 15'b0;
        end
        else begin
            if (i_en && !capture_done_flag) begin
                if (i_pix_addr == INPUT_SIZE -1) begin
                //if (counter == DEPTH)  begin
                    capture_done_flag <= 1'b1;
                    counter <= {($clog2(DEPTH)-1){1'b0}};
                end
                else begin
                    padded_image[r_x + ((WIDTH+2)*r_y)] <= i_pix_data;
                    counter <= counter + 1'b1;
                end
            end
            else if (capture_done_flag) begin
                w_pix_data <= padded_image[counter_padded];
                //w_pix_addr <= counter_padded;
                w_valid <= 1'b1;
                w_ready <= 1'b1;
                if (counter_padded == DEPTH_PADDED-1) begin
                    counter_padded <= {($clog2(DEPTH_PADDED)-1){1'b0}};
                    //w_valid <= 1'b0;
                end
                else begin
                    counter_padded <= counter_padded + 1'b1;
                end
            end
        end
    end
    
    assign o_valid = w_valid;
    assign o_ready = w_ready;
    //assign o_pix_addr = w_pix_addr;
    assign o_pix_data = w_pix_data;
 
/*     
integer J,K,L;
integer file_mem,file_mem_2,file_mem_3; 
always @ (*) begin    
    if(WIDTH==28)begin
        file_mem = $fopen("padded_image_1.mem", "w"); // Open the file in write mode
            if (file_mem) begin
                for (J = 0; J < DEPTH_PADDED; J = J + 1) begin
                    $fdisplay(file_mem, "%b", padded_image[J]); // Write each bit on a new line
                end
                $fclose(file_mem); // Close the file
            end
        end 
        
     if(WIDTH==14)begin
        file_mem_2 = $fopen("padded_image_2.mem", "w"); // Open the file in write mode
            if (file_mem_2) begin
                for (K = 0; K < DEPTH_PADDED; K = K + 1) begin
                    $fdisplay(file_mem_2, "%b", padded_image[K]); // Write each bit on a new line
                end
                $fclose(file_mem_2); // Close the file
            end
        end   
      
      if(WIDTH==7)begin
        file_mem_3 = $fopen("padded_image_3.mem", "w"); // Open the file in write mode
            if (file_mem_3) begin
                for (L = 0; L < DEPTH_PADDED; L = L + 1) begin
                    $fdisplay(file_mem_3, "%b", padded_image[L]); // Write each bit on a new line
                end
                $fclose(file_mem_3); // Close the file
            end
        end  
    end
    
    */
endmodule
