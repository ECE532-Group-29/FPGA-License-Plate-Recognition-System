`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/26/2025 11:43:27 AM
// Design Name: 
// Module Name: dense_layer_2
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


module dense_layer_2
#(
parameter US_DATA_WIDTH = 15,
parameter DATA_WIDTH = 16,
parameter INPUT_SIZE = 18,
parameter OUTPUT_SIZE = 36,
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
    output wire [7:0] o_index1,
    output wire [7:0] o_index2,
    output wire [7:0] o_index3
    );
    reg [DATA_WIDTH-1:0] input_matrix [INPUT_SIZE-1:0];
    reg [$clog2(INPUT_SIZE)-1:0] counter_input;
    reg capture_done_flag, mult1_flag, mult2_flag, mult3_flag, mult4_flag, mult5_flag, mult_done_flag, sum1_flag, sum2_flag, sum3_flag, sum4_flag, sum5_flag, sum_done_flag, r_valid;
    reg [7:0] r_index1, r_index2, r_index3;
    reg [31:0] r_max1, r_max2, r_max3;
    
    (* ram_style = "block" *) logic signed [DATA_WIDTH-1:0] weight_matrix [0:(WEIGHT_SIZE/6)-1];
    logic signed [(2*DATA_WIDTH)-1:0] mult_matrix [(WEIGHT_SIZE/6)-1:0]; //use 32 bits for intermediate results
    logic signed [DATA_WIDTH-1:0] bias_matrix [0:OUTPUT_SIZE-1];
    logic signed [(2*DATA_WIDTH)-1:0] bias_matrix_32 [0:OUTPUT_SIZE-1];
    logic signed [(2*DATA_WIDTH)-1:0] result_matrix [OUTPUT_SIZE-1:0];
    integer i,j, k ,l;

    initial bias_matrix = {16'd26,16'd22,-16'd151,-16'd107,16'd13,16'd43,-16'd53,16'd15,-16'd117,16'd22,-16'd16,16'd6,-16'd159,16'd170,-16'd77,-16'd37,-16'd130,-16'd19,16'd36,16'd69,-16'd244,16'd24,16'd18,-16'd125,-16'd58,16'd59,-16'd135,-16'd134,-16'd324,-16'd40,16'd45,16'd178,16'd325,-16'd115,-16'd81,16'd3};
    
    always @(posedge i_clk) begin
        if (!i_rstn || i_seven_seg_done_rst) begin
            counter_input <= {($clog2(INPUT_SIZE)-1){1'b0}};
            capture_done_flag <= 1'b0;
            mult1_flag <= 1'b0;
            mult2_flag <= 1'b0;
            mult3_flag <= 1'b0;
            mult4_flag <= 1'b0;
            mult5_flag <= 1'b0;
            mult_done_flag <= 1'b0;
            sum1_flag <= 1'b0;
            sum2_flag <= 1'b0;
            sum3_flag <= 1'b0;
            sum4_flag <= 1'b0;
            sum5_flag <= 1'b0;
            sum_done_flag <= 1'b0;
            r_valid <= 1'b0;
            for(i=0; i<OUTPUT_SIZE; i=i+1) begin
                bias_matrix_32[i] <= bias_matrix[i] <<< 10;    
            end

            for(j=0; j<INPUT_SIZE; j=j+1) begin
                input_matrix[j] <= 16'b0;  //NEWLY ADDED 
            end
            
            for(l=0; l<WEIGHT_SIZE/6; l=l+1) begin
                mult_matrix[l] <= 32'b0;  //NEWLY ADDED 
            end
                  
        end
        else begin
            // capture valid data
            if (i_valid && !capture_done_flag) begin
                if (counter_input == INPUT_SIZE-1) begin
                    capture_done_flag <= 1'b1;
                    weight_matrix <= {-16'd26,-16'd833,-16'd399,16'd111,-16'd191,16'd223,-16'd153,-16'd145,16'd196,-16'd104,-16'd89,-16'd191,-16'd268,-16'd536,-16'd201,16'd177,-16'd205,
    16'd54,-16'd1318,-16'd1201,-16'd136,-16'd2199,-16'd29,-16'd503,16'd26,16'd194,-16'd395,-16'd64,16'd301,-16'd562,-16'd860,-16'd532,-16'd761,-16'd939,-16'd327,-16'd864,-16'd198,
    -16'd134,-16'd47,-16'd193,-16'd250,-16'd116,-16'd306,-16'd677,-16'd257,16'd195,16'd167,16'd110,-16'd27,16'd114,16'd238,-16'd259,-16'd14,-16'd298,16'd55,-16'd1219,16'd76,-16'd385,
    -16'd216,-16'd141,-16'd410,-16'd435,16'd357,16'd131,16'd20,-16'd17,-16'd1298,-16'd400,-16'd79,16'd356,16'd11,-16'd207,-16'd301,16'd133,-16'd43,16'd339,-16'd1051,-16'd172,-16'd566,
    16'd264,16'd141,-16'd514,-16'd394,16'd158,-16'd518,16'd220,-16'd211,-16'd331,-16'd236,-16'd344,-16'd452,-16'd292,-16'd990,-16'd134,-16'd509,-16'd255,-16'd211,16'd41,-16'd330,16'd118,
    -16'd247,-16'd834,-16'd678,-16'd386,-16'd1088,-16'd44,-16'd423,16'd109};
                end
                input_matrix[i_addr] <= {1'b0,i_data};
                counter_input <= counter_input + 1'b1;
            end
            // First sixth
            // do multiplication of each term
            else if (capture_done_flag && !mult1_flag) begin
                for (i=0; i<(WEIGHT_SIZE/6); i=i+1) begin
                    mult_matrix[i] <= weight_matrix[i]*$signed(input_matrix[i/OUTPUT_SIZE]);
                end
                mult1_flag <= 1'b1;
                weight_matrix <= {-16'd320,16'd297,-16'd83,-16'd356,-16'd224,-16'd57,-16'd148,-16'd210,-16'd363,-16'd515,16'd42,-16'd475,-16'd148,
    16'd205,-16'd229,-16'd429,-16'd28,-16'd314,16'd424,-16'd55,16'd38,-16'd180,16'd266,-16'd159,-16'd200,-16'd726,-16'd91,-16'd88,-16'd295,16'd372,-16'd132,-16'd30,-16'd135,16'd92,16'd233,
    -16'd200,16'd60,-16'd71,16'd60,16'd0,16'd5,16'd141,-16'd525,-16'd214,-16'd301,-16'd234,-16'd369,-16'd161,-16'd488,-16'd400,-16'd230,-16'd330,-16'd139,16'd234,16'd198,16'd190,-16'd419,16'd156,
    -16'd143,16'd284,16'd16,-16'd98,-16'd121,-16'd352,-16'd298,-16'd200,-16'd41,16'd156,16'd33,16'd109,16'd261,-16'd150,-16'd669,-16'd894,-16'd226,-16'd141,16'd46,16'd190,16'd179,-16'd175,-16'd119,
    16'd390,16'd157,16'd102,-16'd778,-16'd894,-16'd121,16'd43,-16'd300,16'd232,-16'd1583,-16'd464,16'd106,-16'd766,16'd108,16'd450,-16'd539,16'd79,-16'd223,16'd61,16'd196,-16'd747,-16'd185,-16'd995,
    -16'd6,-16'd74,-16'd705,-16'd462};
            end
            // do summation of each row of multiplications
            else if (mult1_flag && !sum1_flag) begin
                for (i=0; i<OUTPUT_SIZE; i=i+1) begin
                    result_matrix[i] <= mult_matrix[0+i]+mult_matrix[OUTPUT_SIZE+i]+mult_matrix[2*OUTPUT_SIZE+i];
                end
                sum1_flag <= 1'b1;
            end
            // Second sixth
            else if (sum1_flag && !mult2_flag) begin
                for (i=0; i<(WEIGHT_SIZE/6); i=i+1) begin
                    mult_matrix[i] <= weight_matrix[i]*$signed(input_matrix[(i+(WEIGHT_SIZE/6))/OUTPUT_SIZE]);
                end
                mult2_flag <= 1'b1;
                weight_matrix <= {-16'd218,-16'd715,16'd94,-16'd51,-16'd389,-16'd224,16'd224,16'd170,16'd384,16'd6,-16'd115,16'd262,16'd41,16'd132,-16'd239,16'd87,-16'd234,-16'd694,-16'd544,16'd248,
    -16'd717,-16'd654,-16'd302,-16'd328,-16'd250,16'd239,-16'd516,-16'd279,-16'd205,16'd166,-16'd299,-16'd12,-16'd449,-16'd259,16'd384,16'd67,16'd217,-16'd636,16'd253,16'd41,-16'd585,16'd97,-16'd40,-16'd173,
    -16'd185,-16'd104,-16'd132,-16'd346,16'd105,-16'd71,-16'd26,16'd68,-16'd164,16'd45,16'd89,16'd241,-16'd141,16'd33,-16'd485,-16'd375,16'd171,16'd29,-16'd17,16'd113,-16'd203,16'd72,-16'd46,-16'd1399,16'd120,
    -16'd74,-16'd715,-16'd95,-16'd586,16'd212,-16'd435,-16'd42,16'd139,-16'd170,-16'd48,-16'd1880,-16'd123,-16'd414,16'd66,16'd145,-16'd292,-16'd472,16'd249,-16'd613,16'd50,-16'd174,-16'd239,-16'd339,16'd453,16'd127,
    -16'd256,16'd117,-16'd806,-16'd995,-16'd153,16'd331,-16'd149,-16'd545,-16'd355,-16'd367,-16'd135,16'd185,-16'd603,16'd42};
            end
            // do summation of each row of multiplications
            else if (mult2_flag && !sum2_flag) begin
                for (i=0; i<OUTPUT_SIZE; i=i+1) begin
                    result_matrix[i] <= result_matrix[i]+mult_matrix[0+i]+mult_matrix[OUTPUT_SIZE+i]+mult_matrix[2*OUTPUT_SIZE+i];
                end
                sum2_flag <= 1'b1;
            end
            // Third sixth
            else if (sum2_flag && !mult3_flag) begin
                for (i=0; i<(WEIGHT_SIZE/6); i=i+1) begin
                    mult_matrix[i] <= weight_matrix[i]*$signed(input_matrix[(i+(2*(WEIGHT_SIZE/6)))/OUTPUT_SIZE]);
                end
                mult3_flag <= 1'b1;
                weight_matrix <= {16'd68,-16'd325,16'd4,-16'd336,-16'd225,-16'd391,16'd6,16'd75,-16'd179,-16'd667,-16'd163,
    16'd128,-16'd31,-16'd91,16'd0,16'd48,-16'd2,-16'd293,-16'd129,-16'd94,16'd26,-16'd287,-16'd76,-16'd62,-16'd56,16'd121,16'd128,-16'd2,-16'd206,-16'd99,-16'd149,-16'd290,16'd131,-16'd194,16'd106,16'd203,-16'd811,
    -16'd90,-16'd88,-16'd51,-16'd156,-16'd146,-16'd385,16'd290,-16'd358,-16'd439,-16'd888,-16'd415,16'd268,-16'd295,16'd194,16'd339,-16'd45,-16'd938,16'd274,-16'd468,-16'd326,-16'd846,-16'd680,-16'd440,-16'd432,-16'd210,
    -16'd392,-16'd431,16'd255,16'd633,-16'd425,16'd323,-16'd357,16'd182,16'd350,16'd240,16'd57,-16'd376,-16'd61,-16'd583,-16'd197,-16'd45,16'd144,-16'd319,-16'd414,16'd201,-16'd486,-16'd366,16'd225,-16'd17,-16'd290,
    -16'd497,16'd133,-16'd798,-16'd3,-16'd229,-16'd69,-16'd173,-16'd259,-16'd726,16'd25,-16'd486,16'd349,-16'd595,-16'd183,16'd157,-16'd45,16'd416,-16'd304,-16'd319,-16'd137,-16'd305};
            end
            // do summation of each row of multiplications
            else if (mult3_flag && !sum3_flag) begin
                for (i=0; i<OUTPUT_SIZE; i=i+1) begin
                    result_matrix[i] <= result_matrix[i]+mult_matrix[0+i]+mult_matrix[OUTPUT_SIZE+i]+mult_matrix[2*OUTPUT_SIZE+i];
                end
                sum3_flag <= 1'b1;
            end
            // Fourth sixth
            else if (sum3_flag && !mult4_flag) begin
                for (i=0; i<(WEIGHT_SIZE/6); i=i+1) begin
                    mult_matrix[i] <= weight_matrix[i]*$signed(input_matrix[(i+(3*(WEIGHT_SIZE/6)))/OUTPUT_SIZE]);
                end
                mult4_flag <= 1'b1;
                weight_matrix <= {16'd84,-16'd236,-16'd249,-16'd285,
    -16'd298,-16'd74,16'd146,-16'd130,16'd24,16'd178,-16'd367,16'd109,16'd231,16'd230,16'd60,-16'd16,16'd284,16'd66,-16'd173,16'd139,16'd65,16'd97,-16'd364,16'd45,16'd336,16'd35,-16'd15,16'd60,16'd68,-16'd222,16'd344,
    16'd11,-16'd202,-16'd299,-16'd435,16'd93,-16'd150,16'd261,-16'd334,-16'd94,16'd202,-16'd869,-16'd784,-16'd9,-16'd336,-16'd47,16'd130,-16'd654,-16'd419,-16'd503,-16'd920,-16'd1266,-16'd896,-16'd507,-16'd149,16'd57,
    -16'd330,16'd192,16'd315,-16'd26,-16'd258,-16'd898,-16'd109,-16'd228,-16'd673,-16'd401,16'd194,16'd175,16'd211,-16'd128,16'd26,-16'd268,-16'd286,16'd27,-16'd193,-16'd467,-16'd152,-16'd398,-16'd563,16'd75,-16'd543,
    -16'd360,-16'd895,-16'd81,-16'd808,16'd72,-16'd713,-16'd430,-16'd492,-16'd257,-16'd505,-16'd217,-16'd617,-16'd20,-16'd409,-16'd581,-16'd91,16'd43,-16'd37,-16'd11,-16'd734,16'd60,16'd3,-16'd37,-16'd276,-16'd1053,
    -16'd690,-16'd646};
            end
            // do summation of each row of multiplications
            else if (mult4_flag && !sum4_flag) begin
                for (i=0; i<OUTPUT_SIZE; i=i+1) begin
                    result_matrix[i] <= result_matrix[i]+mult_matrix[0+i]+mult_matrix[OUTPUT_SIZE+i]+mult_matrix[2*OUTPUT_SIZE+i];
                end
                sum4_flag <= 1'b1;
            end
            // Fifth sixth
            else if (sum4_flag && !mult5_flag) begin
                for (i=0; i<(WEIGHT_SIZE/6); i=i+1) begin
                    mult_matrix[i] <= weight_matrix[i]*$signed(input_matrix[(i+(4*(WEIGHT_SIZE/6)))/OUTPUT_SIZE]);
                end
                mult5_flag <= 1'b1;
                weight_matrix <= {-16'd12,-16'd464,-16'd142,-16'd366,16'd382,-16'd499,-16'd47,-16'd1087,16'd1,-16'd1081,16'd369,-16'd254,-16'd187,-16'd264,-16'd193,-16'd137,-16'd339,16'd331,-16'd205,-16'd22,16'd14,16'd31,16'd305,
    -16'd296,-16'd568,-16'd166,-16'd377,-16'd392,-16'd1041,-16'd626,-16'd94,-16'd302,16'd19,-16'd328,-16'd838,16'd2,-16'd22,-16'd1218,-16'd365,16'd11,-16'd783,-16'd33,16'd262,16'd153,16'd67,-16'd318,-16'd358,-16'd117,
    -16'd311,16'd116,16'd15,16'd53,16'd76,-16'd510,-16'd542,-16'd145,-16'd474,16'd44,-16'd249,-16'd306,-16'd61,16'd82,-16'd735,-16'd773,-16'd99,-16'd547,16'd162,16'd93,-16'd150,-16'd445,-16'd62,-16'd290,-16'd328,16'd398,
    16'd400,-16'd36,16'd65,-16'd471,-16'd615,16'd36,-16'd223,-16'd57,-16'd168,16'd18,-16'd660,-16'd149,-16'd181,-16'd349,-16'd468,16'd45,-16'd711,-16'd251,-16'd760,-16'd462,-16'd313,-16'd199,-16'd356,16'd51,-16'd24,
    -16'd146,-16'd494,-16'd444,-16'd559,-16'd163,-16'd33,-16'd36,16'd120,16'd230};
            end
            // do summation of each row of multiplications
            else if (mult5_flag && !sum5_flag) begin
                for (i=0; i<OUTPUT_SIZE; i=i+1) begin
                    result_matrix[i] <= result_matrix[i]+mult_matrix[0+i]+mult_matrix[OUTPUT_SIZE+i]+mult_matrix[2*OUTPUT_SIZE+i];
                end
                sum5_flag <= 1'b1;
            end
            // Last sixth
            else if (sum5_flag && !mult_done_flag) begin
                for (i=0; i<(WEIGHT_SIZE/6); i=i+1) begin
                    mult_matrix[i] <= weight_matrix[i]*$signed(input_matrix[(i+(5*(WEIGHT_SIZE/6)))/OUTPUT_SIZE]);
                end
                mult_done_flag <= 1'b1;
            end
            // do summation of each row of multiplications
            else if (mult_done_flag && !sum_done_flag) begin
                for (i=0; i<OUTPUT_SIZE; i=i+1) begin
                    result_matrix[i] <= result_matrix[i]+mult_matrix[0+i]+mult_matrix[OUTPUT_SIZE+i]+mult_matrix[2*OUTPUT_SIZE+i]+bias_matrix_32[i];
                end
                sum_done_flag <= 1'b1;
            end
            // TODO: could remove, using an extra clock cycle to make sure valid max and index values have propagated
            else if (sum_done_flag) begin              
                r_valid <= 1'b1;
            end
        end
    end
    
    always_comb begin
        r_max1 = result_matrix[0];
        r_max2 = result_matrix[0];
        r_max3 = result_matrix[0];
        
        r_index1 = 8'd0;
        r_index2 = 8'd0;
        r_index3 = 8'd0;
        
        // finding max
        for (k=0; k<OUTPUT_SIZE; k=k+1) begin
            if (result_matrix[k] > r_max1) begin
                r_max1  = result_matrix[k];
                r_index1 = k;
            end
        end
        // finding second max
        for (k=0; k<OUTPUT_SIZE; k=k+1) begin
            if ((result_matrix[k] > r_max2)&&(result_matrix[k] <= r_max1)&&(k!=r_index1)) begin
                r_max2  = result_matrix[k];
                r_index2 = k;
            end
        end
        // finding third max
        for (k=0; k<OUTPUT_SIZE; k=k+1) begin
            if ((result_matrix[k] > r_max3)&&(result_matrix[k] <= r_max2)&&(k!=r_index2)) begin
                r_max3  = result_matrix[k];
                r_index3 = k;
            end
        end
    end
    
    assign o_valid = r_valid;
    assign o_index1 = r_index1;
    assign o_index2 = r_index2;
    assign o_index3 = r_index3;   
 /*   
integer a;
integer L1_dense_output_file_mem;
    always @ (*) begin
    
        L1_dense_output_file_mem = $fopen("output_dense_L1.mem", "w"); // Open the file in write mode
            if (L1_dense_output_file_mem) begin
                for (a = 0; a < INPUT_SIZE; a = a + 1) begin
                    $fdisplay(L1_dense_output_file_mem, "%b", input_matrix[a]); // Write each bit on a new line
                end
                $fclose(L1_dense_output_file_mem); // Close the file
            end
       end
 
    
integer b;
integer L2_dense_output_file_mem;
    always @ (*) begin
   // if (mult_done_flag && !sum_done_flag) begin
        L2_dense_output_file_mem = $fopen("output_dense_L2.mem", "w"); // Open the file in write mode
            if (L2_dense_output_file_mem) begin
                for (b = 0; b < OUTPUT_SIZE; b = b + 1) begin
                    $fdisplay(L2_dense_output_file_mem, "%b", result_matrix[b]); // Write each bit on a new line
                end
                $fclose(L2_dense_output_file_mem); // Close the file
             //   end
            end
       end
       */
endmodule
