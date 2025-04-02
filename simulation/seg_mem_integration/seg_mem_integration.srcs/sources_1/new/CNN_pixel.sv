// This module implements 2D covolution between a 3x3 filter and a 512-pixel-wide image of any height.
// It is assumed that the input image is padded with zeros such that the input and output images have
// the same size. The filter coefficients are symmetric in the x-direction (i.e. f[0][0] = f[0][2], 
// f[1][0] = f[1][2], f[2][0] = f[2][2] for any filter f) and their values are limited to integers
// (but can still be positive of negative). The input image is grayscale with 8-bit pixel values ranging
// from 0 (black) to 255 (white).
module CNN_pixel 
#(
parameter TOTAL_PIX = 28*28, //TODO, change this to 30*30
parameter total_pix_out = 26*26, //TODO, change this to 28*28
parameter pix_out_size = 26 //TODO, change this to 28
)
(

	input wire clk,			// Operating clock
	input  wire reset,			// Active-high reset signal (reset when set to 1)
	//input  [71:0] i_f,		// Nine 8-bit signed convolution filter coefficients in row-major format (i.e. i_f[7:0] is f[0][0], i_f[15:8] is f[0][1], etc.)
	input wire i_valid,			// Set to 1 if input pixel is valid
	input wire i_ready,			// Set to 1 if consumer block is ready to receive a new pixel
	input wire [14:0] i_x,		// Input pixel value (8-bit unsigned value between 0 and 255)
//	input wire [$clog2(TOTAL_PIX)-1:0] image_addr,
    input wire [143:0]kernal_filter,
    input wire [15:0]bias, 
	output wire o_valid,			// Set to 1 if output pixel is valid
	output wire o_ready,			// Set to 1 if this block is ready to receive a new pixel
	output wire [$clog2(total_pix_out)-1:0]o_conv_data_addr, 
	output wire [14:0] o_y		// Output pixel value (8-bit unsigned value between 0 and 255)
//	output wire [$clog2(total_pix_out)-1:0] out_addr
);

localparam FILTER_SIZE = 3;	// Convolution filter dimension (i.e. 3x3)
localparam PIXEL_DATAW = 16;	// Bit width of image pixels and filter coefficients (i.e. 16 bits)

logic signed [15:0] i_bias_reg;
logic signed [31:0] i_bias_32;

assign i_bias_reg = $signed(bias);           // Make sure bias is correctly signed
assign i_bias_32 = i_bias_reg <<< 10;        // Left shift to convert Q5.10 -> Q11.20
//logic signed [31:0] i_bias_32 = bias <<<12;  //Q7.24

logic signed [PIXEL_DATAW-1:0] r_f [FILTER_SIZE-1:0][FILTER_SIZE-1:0]; // 2D array of registers for filter coefficients
integer col, row; // variables to use in the for loop
always_ff @ (posedge clk) begin
	// If reset signal is high, set all the filter coefficient registers to zeros
	// We're using a synchronous reset, which is recommended style for recent FPGA architectures
	if(reset)begin
		for(row = 0; row < FILTER_SIZE; row = row + 1) begin
			for(col = 0; col < FILTER_SIZE; col = col + 1) begin
				r_f[row][col] <= 0;
			end
		end
	// Otherwise, register the input filter coefficients into the 2D array signal
	end else begin
		for(row = 0; row < FILTER_SIZE; row = row + 1) begin
			for(col = 0; col < FILTER_SIZE; col = col + 1) begin
				// Rearrange the 72-bit input into a 3x3 array of 8-bit filter coefficients.
				// signal[a +: b] is equivalent to signal[a+b-1 : a]. You can try to plug in
				// values for col and row from 0 to 2, to understand how it operates.
				// For example at row=0 and col=0: r_f[0][0] = kernal_filter[0+:8] = kernal_filter[7:0]
				//	       at row=0 and col=1: r_f[0][1] = kernal_filter[8+:8] = kernal_filter[15:8]
				r_f[row][col] <= kernal_filter[(row * FILTER_SIZE * PIXEL_DATAW)+(col * PIXEL_DATAW) +: PIXEL_DATAW];
			end
		end
	end
end

/////////////////////////////////////////// Start of your code ///////////////////////////////////////////

localparam PIC_WIDTH = pix_out_size+2; // How wide is our picture


logic [PIXEL_DATAW-1:0] FIFO [PIC_WIDTH*2+FILTER_SIZE];			// FIFO, store the element in the current window 
																					
logic data_valid [PIC_WIDTH*2+FILTER_SIZE];							// Data valid propagate

// Intermediate outs
logic signed [31:0] mult_out [9];				// Output of multiplier
logic data_valid_mult;								// Valid bit for if multiplier output is valid

logic signed [31:0] reg_stage_1_out [4];		// Output of adders in stage 1, from 8 to 4
logic signed [31:0] reg_stage_2_out [2];		// Output of adders in stage 2, from 4 to 2
logic signed [31:0] reg_stage_3_out;			// Output of adder in stage 3, from 2 to 1
logic signed [31:0] reg_stage_4_out;			// Output of adder in stage 4, final o_y

// plline registers
logic signed [31:0] mult_out_pl [9];
logic data_valid_mult_pl;

logic signed [31:0] reg_stage_1_out_pl [5];
logic data_valid_reg_stage_1_pl;
logic signed [31:0] reg_stage_2_out_pl [3];
logic data_valid_reg_stage_2_pl;
logic signed [31:0] reg_stage_3_out_pl [2];
logic data_valid_reg_stage_3_pl;
logic unsigned [14:0] reg_stage_4_out_pl; //change from PIXEL_DATAW to 16
logic data_valid_reg_stage_4_pl; // Final, same level (in terms of pipeline) as o_valid


logic [15:0] count;

// Instantiating multipliers. All products are computed in one and the same clock cycle


genvar i_mult;
generate
   for (i_mult = 0; i_mult < 9; i_mult = i_mult + 1) begin : gen_mult
      mult8x8 convo_mult (
         .in_dataa(FIFO[((2 - (i_mult / 3)) * PIC_WIDTH) + (2 - (i_mult % 3))]),
         .in_datab(r_f[i_mult / 3][i_mult % 3]),
         .o_res(mult_out[i_mult])
      );
   end
endgenerate


// First adder stage: Sum 8 results into 4
genvar i_addr;
generate
   for (i_addr = 0; i_addr < 4; i_addr = i_addr + 1) begin : gen_adder_1
      reg32p32 adder_stage_1 (
         .in_dataa(mult_out_pl[i_addr * 2]),
         .in_datab(mult_out_pl[i_addr * 2 + 1]),
         .o_res(reg_stage_1_out[i_addr])
      );
   end
endgenerate



// Instantiating adders. Each grouping of adders in one clock cycle each


reg32p32 convo_reg_stage_2_0 (.in_dataa(reg_stage_1_out_pl[0]), .in_datab(reg_stage_1_out_pl[1]), .o_res(reg_stage_2_out[0]));
reg32p32 convo_reg_stage_2_1 (.in_dataa(reg_stage_1_out_pl[2]), .in_datab(reg_stage_1_out_pl[3]), .o_res(reg_stage_2_out[1]));

reg32p32 convo_reg_stage_3_0 (.in_dataa(reg_stage_2_out_pl[0]), .in_datab(reg_stage_2_out_pl[1]), .o_res(reg_stage_3_out));

reg32p32 convo_reg_stage_4_0 (.in_dataa(reg_stage_3_out_pl[0]), .in_datab(reg_stage_3_out_pl[1]), .o_res(reg_stage_4_out));

// Valid for computed values is only true if all inputs are valid
logic enable;
always_comb begin
	// Multiplier output only valid if all 9 data are valid
	data_valid_mult = data_valid[2+PIC_WIDTH*2] & data_valid[1+PIC_WIDTH*2] & data_valid[0+PIC_WIDTH*2] &
							data_valid[2+PIC_WIDTH*1] & data_valid[1+PIC_WIDTH*1] & data_valid[0+PIC_WIDTH*1] &
							data_valid[2]             & data_valid[1]             & data_valid[0] &
							(count >= FILTER_SIZE); // Need at least 3 element in the row before computing
	enable = i_ready & i_valid;
end


int i;

//reg addr_reset;   //new line
reg [$clog2(TOTAL_PIX)-1:0] pix_count; 
//reg [$clog2(TOTAL_PIX)-1:0] last_addr; 
//reg [$clog2(total_pix_out)-1:0] out_addr_reg; 
always_ff @ (posedge clk) begin

	if(reset)begin
		// Reset count
		count <= 16'b0;
	    pix_count <= 0;
		// Reset FIFO and valid propagation
		for(i = 0; i < $size(FIFO); i = i + 1) begin
			FIFO[i] <= 8'b0;	
			data_valid[i] <= 1'b0;
		end

		data_valid_reg_stage_1_pl <= 1'b0;
		data_valid_reg_stage_2_pl <= 1'b0;
		data_valid_reg_stage_3_pl <= 1'b0;
		data_valid_reg_stage_4_pl <= 1'b0;
        data_valid_mult_pl <= 1'b0;
		
		
	end else begin
		if(enable)begin	
			// count If count equal to 30 means current row finished, reset to 1 since move to the next row
			if (count == PIC_WIDTH) begin
				count <= 16'b1;
			end else begin
				count <= count + 1'b1;
			end
			
			
		
			FIFO[0] <= i_x; 					// If input is valid, load into FIFO[0]
			data_valid[0] <= i_valid;		// Similarly with valids
		//	last_addr <= image_addr;  //newline
			
	       if (pix_count != TOTAL_PIX) begin   //new line
			
                for(i = 1; i < $size(FIFO); i = i + 1) begin
                    FIFO[i] <= FIFO[i-1];					// Propagate signal in FIFO
                    data_valid[i] <= data_valid[i-1];	// Propagate valid data signal
                end
            
                // plline reg for multiplier out, adder stage 1 in
                mult_out_pl <= mult_out;
                data_valid_mult_pl <= data_valid_mult;
                
                            
                data_valid_reg_stage_1_pl <= data_valid_mult_pl;
                data_valid_reg_stage_2_pl <= data_valid_reg_stage_1_pl;
                data_valid_reg_stage_3_pl <= data_valid_reg_stage_2_pl;
                data_valid_reg_stage_4_pl <= data_valid_reg_stage_3_pl;
                
                // pipeline reg for addr 1
                reg_stage_1_out_pl[0] <= reg_stage_1_out[0];
                reg_stage_1_out_pl[1] <= reg_stage_1_out[1];
                reg_stage_1_out_pl[2] <= reg_stage_1_out[2];
                reg_stage_1_out_pl[3] <= reg_stage_1_out[3];
                reg_stage_1_out_pl[4] <= mult_out_pl[8];
                
                // pipeline reg for addr 2
                reg_stage_2_out_pl[0] <= reg_stage_2_out[0];
                reg_stage_2_out_pl[1] <= reg_stage_2_out[1];
                reg_stage_2_out_pl[2] <= reg_stage_1_out_pl[4];
                
                // pipeline reg for addr 3
                reg_stage_3_out_pl[0] <= reg_stage_3_out;
                reg_stage_3_out_pl[1] <= reg_stage_2_out_pl[2];
			
                // // pipeline reg for addr 4, final o_y, clipping results which make it in the range
                if ((reg_stage_4_out + i_bias_32) > 32'sd33554431 ) begin
                    reg_stage_4_out_pl <= 15'd32766;
                end else if ((reg_stage_4_out + i_bias_32) < 32'sd0) begin
                    reg_stage_4_out_pl <= 15'd0;
                end else begin
                    reg_stage_4_out_pl <= $signed({1'b0,reg_stage_4_out[24:10]}) + bias; //Q5.10 unisigned  ///something wrong here
                end
                if(o_valid)begin
                     pix_count = pix_count +1;
                end
			end 		
		end
	end
	
end



reg [$clog2(total_pix_out)-1:0]r_conv_data_addr;

//-----this is purely for debug prupose, we do not need to have them ---
reg [14:0] input_L1_conv_image [0 : TOTAL_PIX-1];
reg [14:0] output_L1_conv_image [0 : total_pix_out-1]; 
//-----this is purely for debug prupose, we do not need to have them ---

always @ (posedge clk ) begin
    if (reset) begin
        r_conv_data_addr <=0;
    end else begin
        if ( (r_conv_data_addr < total_pix_out -1) && (o_valid) && (i_valid)) begin
            r_conv_data_addr <= r_conv_data_addr + 1;
         end
         //-----this is purely for debug prupose, we do not need to have them ---
         output_L1_conv_image[r_conv_data_addr] <= o_y;
         //-----this is purely for debug prupose, we do not need to have them ---
     end 
 end

assign o_y = reg_stage_4_out_pl;
assign o_ready = i_ready;
assign o_valid = data_valid_reg_stage_4_pl & i_ready;	
assign o_conv_data_addr = r_conv_data_addr;



/////////////////////////////////////////// End of your code ///////////////////////////////////////////
//-----this is purely for debug prupose, we do not need to have them ---
reg [$clog2(TOTAL_PIX)-1:0]dummy_conv_input_data_addr;
always @ (posedge clk ) begin
    if (reset) begin
        dummy_conv_input_data_addr <=0;
    end else begin
        if ( (dummy_conv_input_data_addr < TOTAL_PIX -1) && (i_valid) ) begin
            dummy_conv_input_data_addr <= dummy_conv_input_data_addr + 1;
         end
         //-----this is purely for debug prupose, we do not need to have them ---
         input_L1_conv_image[dummy_conv_input_data_addr] <= i_x;
         //-----this is purely for debug prupose, we do not need to have them ---
     end 
 end


reg dummy_small_addr_reset;
integer a,b,c;
integer L1_input_file_mem,L2_input_file_mem,L3_input_file_mem; 
    always @ (*) begin
    
    if (TOTAL_PIX == 30*30) begin    
        L1_input_file_mem = $fopen("input_conv_L1.mem", "w"); // Open the file in write mode
            if (L1_input_file_mem) begin
                for (b = 0; b < TOTAL_PIX; b = b + 1) begin
                    $fdisplay(L1_input_file_mem, "%b", input_L1_conv_image[b]); // Write each bit on a new line
                end
                $fclose(L1_input_file_mem); // Close the file
            end
       end 
       
    if (TOTAL_PIX == 16*16) begin    
        L2_input_file_mem = $fopen("input_conv_L2.mem", "w"); // Open the file in write mode
            if (L2_input_file_mem) begin
                for (a = 0; a < TOTAL_PIX; a = a + 1) begin
                    $fdisplay(L2_input_file_mem, "%b", input_L1_conv_image[a]); // Write each bit on a new line
                end
                $fclose(L2_input_file_mem); // Close the file
            end
       end
           
     if (TOTAL_PIX == 9*9) begin    
        L3_input_file_mem = $fopen("input_conv_L3.mem", "w"); // Open the file in write mode
            if (L3_input_file_mem) begin
                for (c = 0; c < TOTAL_PIX; c = c + 1) begin
                    $fdisplay(L3_input_file_mem, "%b", input_L1_conv_image[c]); // Write each bit on a new line
                end
                $fclose(L3_input_file_mem); // Close the file
            end
       end
    end



integer k,L,J;
integer L1_output_file_mem,L2_output_file_mem,L3_output_file_mem; 
    always @ (*) begin
        if (total_pix_out == 28*28) begin    
        L1_output_file_mem = $fopen("output_conv_L1.mem", "w"); // Open the file in write mode
            if (L1_output_file_mem) begin
                for (L = 0; L < total_pix_out; L = L + 1) begin
                    $fdisplay(L1_output_file_mem, "%b", output_L1_conv_image[L]); // Write each bit on a new line
                end
                $fclose(L1_output_file_mem); // Close the file
            end
       end    
    
       if (total_pix_out == 14*14) begin    
            L2_output_file_mem = $fopen("output_conv_L2.mem", "w"); // Open the file in write mode
                if (L2_output_file_mem) begin
                    for (k = 0; k < total_pix_out; k = k + 1) begin
                        $fdisplay(L2_output_file_mem, "%b", output_L1_conv_image[k]); // Write each bit on a new line
                    end
                    $fclose(L2_output_file_mem); // Close the file
                end
           end  
        
        if (total_pix_out == 7*7) begin    
            L3_output_file_mem = $fopen("output_conv_L3.mem", "w"); // Open the file in write mode
                if (L3_output_file_mem) begin
                    for (J = 0; J < total_pix_out; J = J + 1) begin
                        $fdisplay(L3_output_file_mem, "%b", output_L1_conv_image[J]); // Write each bit on a new line
                    end
                    $fclose(L3_output_file_mem); // Close the file
                end
           end   
    end


endmodule

/*******************************************************************************************/

// Multiplier module for 8x8 multiplication
module mult8x8 ( /* synthesis multstyle = "dsp" */
	input wire unsigned [15:0] in_dataa,
	input wire signed [14:0] in_datab,
	output wire signed [31:0] o_res
);

logic signed [31:0] result;

always_comb begin
	result = in_datab * $signed({1'b0,in_dataa});
end

assign o_res = result;

endmodule

/*******************************************************************************************/


/*******************************************************************************************/

// Adder module for 32b+32b addition 
module reg32p32 (
	input wire signed [31:0] in_dataa,
	input wire signed [31:0] in_datab,
	output wire signed [31:0] o_res
);

assign o_res = in_dataa + in_datab;

endmodule

/*******************************************************************************************/

