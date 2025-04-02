`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/24/2025 08:15:47 PM
// Design Name: 
// Module Name: dense_layer1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dense_layer_1
#(
parameter US_DATA_WIDTH = 15,
parameter DATA_WIDTH = 16,
parameter INPUT_SIZE = 9,
parameter OUTPUT_SIZE = 18,
parameter WEIGHT_SIZE = OUTPUT_SIZE*INPUT_SIZE
)
(
    input wire i_clk,
    input wire i_rstn,
    input wire i_seven_seg_done_rst,
    input wire [US_DATA_WIDTH-1:0] i_data, //add positive sign bit before doing processing
    input wire [$clog2(INPUT_SIZE)-1:0] i_addr,
    input wire i_valid,
    output wire o_valid,
    output wire [$clog2(OUTPUT_SIZE)-1:0] o_addr,
    output wire [US_DATA_WIDTH-1:0] o_data
    );
    reg [DATA_WIDTH-1:0] input_matrix [INPUT_SIZE-1:0];
    reg [$clog2(INPUT_SIZE)-1:0] counter_input;
    reg [$clog2(OUTPUT_SIZE)-1:0] counter_output;
    reg capture_done_flag, mult_done_flag, sum_done_flag, r_valid;
    reg [$clog2(OUTPUT_SIZE)-1:0] r_addr;
    reg [US_DATA_WIDTH-1:0] r_data;
    
    logic signed [DATA_WIDTH-1:0] weight_matrix [0:WEIGHT_SIZE-1];
    logic signed [(2*DATA_WIDTH)-1:0] mult_matrix [WEIGHT_SIZE-1:0]; //use 32 bits for intermediate results
    logic signed [DATA_WIDTH-1:0] bias_matrix [0:OUTPUT_SIZE-1];
    logic signed [(2*DATA_WIDTH)-1:0] bias_matrix_32 [0:OUTPUT_SIZE-1];
    logic signed [(2*DATA_WIDTH)-1:0] result_matrix [OUTPUT_SIZE-1:0]; //reformat to 15 bits 5.10 -> 11.20 (cut-off)
    integer i,j,k,weights_file,biases_file;
    
    initial weight_matrix = {-16'd540, -16'd361, 16'd541, 16'd371, 16'd445, -16'd168, 16'd263, 16'd187, 16'd64, 16'd238, 16'd755, 
                            -16'd199, -16'd534, 16'd336, 16'd158, -16'd395, 16'd21, 16'd323, 16'd245, 16'd308, 16'd513, 
                            -16'd215, -16'd212, -16'd143, 16'd209, 16'd341, -16'd148, 16'd101, -16'd508, 16'd286, 16'd501, 
                            -16'd103, 16'd550, -16'd310, 16'd84, 16'd243, 16'd113, 16'd319, -16'd428, 16'd459, -16'd217, 
                            -16'd139, -16'd75, 16'd494, -16'd16, 16'd342, 16'd719, 16'd542, 16'd446, -16'd497, -16'd321, 
                            -16'd159, 16'd26, -16'd552, 16'd433, 16'd1, -16'd294, 16'd37, 16'd289, 16'd401, -16'd119, 
                            -16'd33, -16'd59, -16'd205, 16'd320, 16'd462, -16'd87, 16'd321, -16'd312, -16'd342, -16'd320, 
                            16'd316, 16'd664, 16'd154, 16'd334, -16'd215, -16'd51, 16'd862, 16'd428, -16'd304, 16'd342, 
                            -16'd108, -16'd127, -16'd303, 16'd112, -16'd211, 16'd2, 16'd173, 16'd447, -16'd57, 16'd417, 
                            16'd344, -16'd85, -16'd66, 16'd143, 16'd221, 16'd406, 16'd384, -16'd22, 16'd229, 16'd713, 
                            -16'd261, -16'd9, -16'd107, 16'd7, 16'd413, 16'd138, 16'd409, 16'd97, -16'd284, -16'd97, 
                            -16'd235, 16'd87, 16'd179, -16'd11, 16'd482, -16'd125, -16'd177, -16'd319, -16'd188, 16'd461, 
                            16'd169, -16'd380, 16'd287, 16'd299, -16'd135, 16'd200, -16'd259, 16'd52, 16'd276, 16'd147, 
                            -16'd354, 16'd284, -16'd432, -16'd122, 16'd245, 16'd353, 16'd478, 16'd231, 16'd344, 16'd498, 
                            16'd70, 16'd206, 16'd49, -16'd329, 16'd724, 16'd29, 16'd500, 16'd387, 16'd261, -16'd553, 
                            16'd155, 16'd726, 16'd159, -16'd233, -16'd152, 16'd208, 16'd267, -16'd119, 16'd370, -16'd420, 16'd148};
                            
    initial bias_matrix = {-16'd2, -16'd63, -16'd29, 16'd29, 16'd67, 16'd44, 16'd29, -16'd66, -16'd73, -16'd65, 
                            16'd16, -16'd17, -16'd218, 16'd386, 16'd217, 16'd280, 16'd140, 16'd131};

    
    always @(posedge i_clk) begin
        if (!i_rstn || i_seven_seg_done_rst) begin
            counter_input <= {($clog2(INPUT_SIZE)-1){1'b0}};
            counter_output <= {($clog2(OUTPUT_SIZE)-1){1'b0}};
            capture_done_flag <= 1'b0;
            mult_done_flag <= 1'b0;
            sum_done_flag <= 1'b0;
            r_valid <= 1'b0;
            
            r_data <= 15'b0;  //NEWLY ADDED 
            r_addr <= 1'b0;  //NEWLY ADDED 
            for(i=0; i<OUTPUT_SIZE; i=i+1) begin
                bias_matrix_32[i] <= bias_matrix[i] <<< 10;
            end
            for(j=0; j<INPUT_SIZE; j=j+1) begin
                input_matrix[j] <= 16'b0;  //NEWLY ADDED 
            end
            
            for(k=0; k<WEIGHT_SIZE; k=k+1) begin
                mult_matrix[k] <= 32'b0;  //NEWLY ADDED 
            end
        end
        else begin
            // capture valid data
            if (i_valid && !capture_done_flag) begin
                if (counter_input == INPUT_SIZE-1) begin
                    capture_done_flag <= 1'b1;
                end
                input_matrix[i_addr] <= {1'b0,i_data};
                counter_input <= counter_input + 1'b1;
            end
            // do multiplication of each term
            else if (capture_done_flag && !mult_done_flag) begin
                for (i=0; i<WEIGHT_SIZE; i=i+1) begin
                    mult_matrix[i] <= weight_matrix[i]*$signed(input_matrix[i/OUTPUT_SIZE]);
                end
                mult_done_flag <= 1'b1;
            end
            // do summation of each row of multiplications
            else if (mult_done_flag && !sum_done_flag) begin
                for (i=0; i<OUTPUT_SIZE; i=i+1) begin
                    result_matrix[i] <= mult_matrix[0+i]+mult_matrix[OUTPUT_SIZE+i]+mult_matrix[2*OUTPUT_SIZE+i]+mult_matrix[3*OUTPUT_SIZE+i]+mult_matrix[4*OUTPUT_SIZE+i]+mult_matrix[5*OUTPUT_SIZE+i]+mult_matrix[6*OUTPUT_SIZE+i]+mult_matrix[7*OUTPUT_SIZE+i]+mult_matrix[8*OUTPUT_SIZE+i]+bias_matrix_32[i];
                end
                sum_done_flag <= 1'b1;
            end
            else if (sum_done_flag) begin
                r_addr <= counter_output;
                //ReLU activitation function: f(x)=max(0,x)
                if (result_matrix[counter_output] < 32'sd0) begin
                    r_data <= 15'd0;
                end
                // check if max data then clip at max
                else if (result_matrix[counter_output] > 32'sd33554431) begin // 2^(5+20)
                    r_data <= 15'd32767; // max value
                end
                else begin
                    r_data <= result_matrix[counter_output][24:10]; //clip data from 11.20 -> 5.10
                end
                r_valid <= 1'b1;
                if (counter_output == OUTPUT_SIZE-1) begin
                    counter_output <= {($clog2(OUTPUT_SIZE)-1){1'b0}};
                end
                else begin
                    counter_output <= counter_output + 1'b1;
                end
            end
        end
    end
    
    assign o_addr = r_addr;
    assign o_data = r_data;
    assign o_valid = r_valid;
    
endmodule
