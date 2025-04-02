`timescale 1ns / 1ps

module cnn_interface
#(
parameter BRAM_IMAGE_DEPTH = 28*28, 

parameter L1_CONV_O_DATA_DEPTH = 28*28, // TODO change to 28*28
parameter L1_POOL_O_DATA_DEPTH = 14*14, // TODO change to 14*14

parameter L2_CONV_O_DATA_DEPTH = 14*14, // TODO change to 14*14
parameter L2_POOL_O_DATA_DEPTH = 7*7, 

parameter L3_CONV_O_DATA_DEPTH = 7*7, // TODO change to 14*14
parameter L3_POOL_O_DATA_DEPTH = 3*3 // TODO change to 12*12
)
(
    input wire i_top_clk,
    input wire i_top_rstn,
    input wire i_seven_seg_done_rst,
    
    input wire i_Rd_Data,
    input wire [$clog2(BRAM_IMAGE_DEPTH)-1:0]i_top_bram_read_Addr,
    input wire i_bram_top_valid,
    
    output wire [7:0] dummy_index1,
    output wire [7:0] dummy_index2,
    output wire [7:0] dummy_index3,
    output wire cnn_all_done_valid
    
    );



reg i_CNN_top_valid;
wire [14:0] L1_cnn_pix_i_data;
reg [14:0] L1_mem_pix_i_data;

wire [14:0]w_L1_conv_data;
wire [$clog2(L1_CONV_O_DATA_DEPTH)-1:0]w_L1_conv_data_addr;

wire w_L1_valid, w_conv_1_valid;
wire w_L1_ready, w_conv_1_ready;
reg [$clog2(BRAM_IMAGE_DEPTH)-1:0]i_top_pix_addr_pad_zero;


    padding_zeros# (
    .WIDTH(28)
    )
    padding_bram_to_conv1(
        .i_clk(i_top_clk),
        .i_rstn(i_top_rstn ),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_en(i_CNN_top_valid),
        //.i_en(i_bram_top_valid),
        .i_pix_data(L1_mem_pix_i_data),
        .i_pix_addr(i_top_pix_addr_pad_zero),
        .o_valid(w_conv_1_valid),
        .o_ready(w_conv_1_ready),
        //.o_pix_addr(),
        .o_pix_data(L1_cnn_pix_i_data)
        );
        
    CNN_pixel#(
        .TOTAL_PIX(30*30), 
        .total_pix_out(28*28), 
        .pix_out_size(28)        
    ) 
    conv_layer_1(
        .clk(i_top_clk),
        .reset(~i_top_rstn),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_valid(w_conv_1_valid),
        .i_ready(w_conv_1_ready),
        .i_x(L1_cnn_pix_i_data),
        .kernal_filter({16'd1207, 16'd1366, 16'd248, 16'd560, 16'd1192, 16'd872, -16'd5, 16'd561, 16'd565}),
        .bias(16'd194),
        .o_valid(w_L1_valid),
        .o_ready(w_L1_ready),
        .o_conv_data_addr(w_L1_conv_data_addr),
        .o_y(w_L1_conv_data)
    );
    
    wire [14:0] w_L1_pooling_data;
    wire [$clog2(L1_POOL_O_DATA_DEPTH)-1:0]w_L1_pooling_data_addr;
    wire w_L1_pooling_data_ready;
    wire w_L1_pooling_data_valid;
    maxpooling#(
    .LARGE_SIZE(28), //TODO change to 28
    .SMALL_SIZE(14)  //TODO change to 14
    ) 
    maxpooling_L1 (
        .i_clk(i_top_clk),
        .i_rstn(i_top_rstn),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_large_image_data(w_L1_conv_data),
        .i_large_image_data_valid(w_L1_valid), //starting of the extracted letter
        .i_large_image_addr(w_L1_conv_data_addr),
        
        .o_small_image_data(w_L1_pooling_data),
        .o_small_image_addr(w_L1_pooling_data_addr), //the conv layer do not need data addr for now. 
        .o_small_image_data_valid(w_L1_pooling_data_valid),
        .o_small_image_read_addr(),
        .o_small_image_data_ready(w_L1_pooling_data_ready)
    );
    
    wire w_conv_2_valid;
    wire w_conv_2_ready;
    wire [14:0] L2_cnn_pix_i_data;
    
    padding_zeros# (
    .WIDTH(14)
    )
    padding_maxp1_to_conv2(
        .i_clk(i_top_clk),
        .i_rstn(i_top_rstn),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_en(w_L1_pooling_data_valid),
        .i_pix_data(w_L1_pooling_data),
        .i_pix_addr(w_L1_pooling_data_addr),
        
        .o_valid(w_conv_2_valid),
        .o_ready(w_conv_2_ready),
        .o_pix_data(L2_cnn_pix_i_data)
        );
    
    
    
    wire w_L2_valid;
    wire w_L2_ready;
    wire [14:0]w_L2_conv_data;
    wire [$clog2(L2_CONV_O_DATA_DEPTH)-1:0]w_L2_conv_data_addr;

    CNN_pixel #(
        .TOTAL_PIX(16*16), //TODO change to 16*16 since previous conv out should be 28, then, in the maxpooling, the output is 14, and pad zero around = 14+2 = 16
        .total_pix_out(14*14), //TODO change to 14*14
        .pix_out_size(14) //TODO change to 14 
    )
    conv_layer_2(
        .clk(i_top_clk),
        .reset(~i_top_rstn),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_valid(w_conv_2_valid),
        .i_ready(w_conv_2_ready),
        .i_x(L2_cnn_pix_i_data),
        .kernal_filter({-16'd716, -16'd586, -16'd338, 16'd612, 16'd470, -16'd646, -16'd424, 16'd627, 16'd396}),
        .bias(16'd102),
        .o_valid(w_L2_valid),
        .o_ready(w_L2_ready),
        .o_conv_data_addr(w_L2_conv_data_addr),
        .o_y(w_L2_conv_data)
    );
    
    wire [14:0] w_L2_pooling_data;
    wire [$clog2(L2_POOL_O_DATA_DEPTH)-1:0]w_L2_pooling_data_addr;
    wire w_L2_pooling_data_ready;
    wire w_L2_pooling_data_valid;

    maxpooling#(
    .LARGE_SIZE(14), //TODO change to 14
    .SMALL_SIZE(7) //TODO change to 7
    
    ) 
    maxpooling_L2 (
        .i_clk(i_top_clk),
        .i_rstn(i_top_rstn),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_large_image_data(w_L2_conv_data),
        .i_large_image_data_valid(w_L2_valid), //starting of the extracted letter
        .i_large_image_addr(w_L2_conv_data_addr),
        
        .o_small_image_data(w_L2_pooling_data),
        .o_small_image_addr(w_L2_pooling_data_addr), //the conv layer do not need data addr for now. 
        .o_small_image_data_valid(w_L2_pooling_data_valid),
        .o_small_image_read_addr(),
        .o_small_image_data_ready(w_L2_pooling_data_ready)
    );
    
    wire w_conv_3_valid;
    wire w_conv_3_ready;
    wire [14:0] L3_cnn_pix_i_data;
    
    padding_zeros# (
    .WIDTH(7)
    )
    padding_maxp2_to_conv3(
        .i_clk(i_top_clk),
        .i_rstn(i_top_rstn),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_en(w_L2_pooling_data_valid),
        .i_pix_data(w_L2_pooling_data),
        .i_pix_addr(w_L2_pooling_data_addr),
        
        .o_valid(w_conv_3_valid),
        .o_ready(w_conv_3_ready),
        .o_pix_data(L3_cnn_pix_i_data)
        );
    
    wire w_L3_valid;
    wire w_L3_ready;
    wire [14:0]w_L3_conv_data;
    wire [$clog2(L3_CONV_O_DATA_DEPTH)-1:0]w_L3_conv_data_addr;    
    CNN_pixel #(
        .TOTAL_PIX(9*9), //TODO change to 16*16 since previous conv out should be 28, then, in the maxpooling, the output is 14, and pad zero around = 14+2 = 16
        .total_pix_out(7*7), //TODO change to 14*14
        .pix_out_size(7) //TODO change to 14 
    )
    conv_layer_3(
        .clk(i_top_clk),
        .reset(~i_top_rstn),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_valid(w_conv_3_valid),
        .i_ready(w_conv_3_ready),
        .i_x(L3_cnn_pix_i_data),
        .kernal_filter({16'd1364, 16'd1059, -16'd25, 16'd412, 16'd218, 16'd79, -16'd7, 16'd127, -16'd35}),
        .bias(-16'd14),
        .o_valid(w_L3_valid),
        .o_ready(w_L3_ready),
        .o_conv_data_addr(w_L3_conv_data_addr),
        .o_y(w_L3_conv_data)
    );
    
    wire [14:0] w_L3_trimmed_data;
    wire w_L3_trimmed_data_valid;
    wire [$clog2(6*6)-1:0] w_L3_trimmed_data_addr; 
    
    size_trim#(
        .INPUT_SIZE(7),
        .OUTPUT_SIZE(6)
    )
    trim_77_to_66
    (
        .i_clk(i_top_clk),
        .i_rstn(i_top_rstn),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_image_data(w_L3_conv_data),
        .i_image_data_valid(w_L3_valid),
        .i_image_addr(w_L3_conv_data_addr),
        .o_image_data(w_L3_trimmed_data),
        .o_image_data_valid(w_L3_trimmed_data_valid),
        .o_image_addr(w_L3_trimmed_data_addr)
    );  
    
    wire [14:0] w_L3_pooling_data;
    wire [$clog2(L3_POOL_O_DATA_DEPTH)-1:0]w_L3_pooling_data_addr;
    wire w_L3_pooling_data_ready;
    wire w_L3_pooling_data_valid; 
    
    maxpooling#(
    .LARGE_SIZE(6), 
    .SMALL_SIZE(3) 
    
    )  
    
    maxpooling_L3 (
        .i_clk(i_top_clk),
        .i_rstn(i_top_rstn),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_large_image_data(w_L3_trimmed_data),
        .i_large_image_data_valid(w_L3_trimmed_data_valid), //starting of the extracted letter
        .i_large_image_addr(w_L3_trimmed_data_addr),
        
        .o_small_image_data(w_L3_pooling_data),
        .o_small_image_addr(w_L3_pooling_data_addr), //the conv layer do not need data addr for now. 
        .o_small_image_data_valid(w_L3_pooling_data_valid),
        .o_small_image_read_addr(),
        .o_small_image_data_ready(w_L3_pooling_data_ready)
    );    

    wire [14:0] w_dense1_data;
    wire w_dense1_valid;
    wire [$clog2(18)-1:0] w_dense1_addr;
    
    dense_layer_1 dense_L1(
        .i_clk(i_top_clk),
        .i_rstn(i_top_rstn),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_data(w_L3_pooling_data),
        .i_addr(w_L3_pooling_data_addr),
        .i_valid(w_L3_pooling_data_valid && w_L3_pooling_data_ready),
        .o_valid(w_dense1_valid),
        .o_addr(w_dense1_addr),
        .o_data(w_dense1_data)
    ); 
    
    wire [7:0] w_dense2_index1, w_dense2_index2, w_dense2_index3;
    wire w_dense2_valid;
    
    dense_layer_2 dense_L2(
        .i_clk(i_top_clk),
        .i_rstn(i_top_rstn),
        .i_seven_seg_done_rst(i_seven_seg_done_rst),
        .i_data(w_dense1_data),
        .i_addr(w_dense1_addr),
        .i_valid(w_dense1_valid),
        .o_valid(w_dense2_valid),
        .o_index1(w_dense2_index1),
        .o_index2(w_dense2_index2),
        .o_index3(w_dense2_index3)
    ); 

    assign dummy_index1 = w_dense2_index1;
    assign dummy_index2 = w_dense2_index2;
    assign dummy_index3 = w_dense2_index3;
    assign cnn_all_done_valid = w_dense2_valid; 
    
    
    always @(posedge i_top_clk) begin
        if (!i_top_rstn || i_seven_seg_done_rst) begin
             i_CNN_top_valid <=0;
        end else begin
            //if the output from bram is valid, the Conv layer will start after one clk cycle due to data delay. 
            if (i_bram_top_valid) begin
                i_CNN_top_valid <= 1;
            end
            
            L1_mem_pix_i_data <= (i_Rd_Data == 1'b1) ? 15'b1111111111 : 15'b0; //since we are using Q5.10 
            i_top_pix_addr_pad_zero <= i_top_bram_read_Addr; // since we are delay the data, we need to delay the addr as well. 
            
        end
    end 
    
endmodule
