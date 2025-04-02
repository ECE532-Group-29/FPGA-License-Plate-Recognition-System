`timescale 1ns / 1ps
`default_nettype none

/*
 *  Infers a dual-port BRAM with variable width and depth 
 *  
 *  NOTE: 
 *  - One clock delay with read/write
 *
 */

module mem_bram
#(parameter WIDTH = 11,
    parameter DEPTH = 640*480)
    (   input wire                      i_wclk,
        input wire                      i_wr,
        input wire [$clog2(DEPTH)-1:0]  i_wr_addr,
        
        input wire                      i_rclk,
        input wire                      i_rd,
        input wire [$clog2(DEPTH)-1:0]  i_rd_addr,
        
        input wire                      i_cam_capture,
        input wire [9:0]                i_VGA_x,
        input wire [9:0]                i_VGA_y,
        
        input wire                      i_bram_en,
        input wire [WIDTH-1:0]          i_bram_data,
        output reg [WIDTH-1:0]          o_bram_data      
    );
    
    // Infer dual-port BRAM with dual clocks
    // https://docs.xilinx.com/v/u/2019.2-English/ug901-vivado-synthesis (page 126)
    localparam CAPTURED_DEPTH = 561*141;
    reg [WIDTH-1:0] captured_image [0:CAPTURED_DEPTH-1];
    reg capture_flag;
    reg [$clog2(CAPTURED_DEPTH)-1:0] counter;
    wire w_capture_db;
    reg stream_pause = 0;
    wire [9:0] r_wr_x, r_wr_y;
    
    assign r_wr_x = i_wr_addr % 10'd640;
    assign r_wr_y = i_wr_addr / 10'd640;
    
    debouncer 
    #(  .DELAY(240_000)         )    
    cam_btn_capture_db
    (   .i_clk(i_wclk            ), 
        .i_btn_in(i_cam_capture   ),
        
        // Debounced button to start cam init 
        .o_btn_db(w_capture_db    )
    );
    always @(posedge i_wclk) begin
        if(w_capture_db) begin
            stream_pause <= ~stream_pause;
        end
    end
    
    always @(posedge i_wclk) begin
        if(i_bram_en) begin
            if(i_wr) begin
                if(stream_pause) begin
                    capture_flag <= 1'b1;
                    counter <= {($clog2(CAPTURED_DEPTH)-1){1'b0}};
                end
                if(capture_flag  && (r_wr_x>=40) && (r_wr_x<=600) && (r_wr_y>=170) && (r_wr_y<=310)) begin
                    if (counter == CAPTURED_DEPTH) begin
                        capture_flag <= 1'b0;
                    end
                    else begin
                        captured_image[((r_wr_x-40)+561*(r_wr_y-170))] <= i_bram_data;
                    end
                    counter <= counter + 1'b1;
                end
            end
        end
    end
    
    always @(posedge i_rclk)
    if(i_rd) begin
        if ((i_VGA_x>=40) && (i_VGA_x<=600) && (i_VGA_y>=170) && (i_VGA_y<=310)) begin
            o_bram_data <= captured_image[((i_VGA_x-40)+561*(i_VGA_y-170))];
        end
        else begin
            o_bram_data <= 12'd4095;
        end
    end

endmodule

