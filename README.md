
# FPGA License Plate Recognition System

License plate recognition (LPR) is a crucial technology in modern automated vehicle identification systems, widely used in parking management, toll collection, and traffic monitoring. This project is interesting because it leverages FPGA technology for real-time processing, ensuring high-speed and efficient performance. The motivation behind this project is to create a robust and fast system that can be deployed in security-sensitive environments, such as gated communities and restricted areas, to enhance access control mechanisms.


for more infomation, please read our final project report under document
## Block Diagram

![App Screenshot](https://github.com/ECE532-Group-29/FPGA-License-Plate-Recognition-System/blob/main/documentation/image/diagram.png)


The block diagram above illustrates the complete architecture of our FPGA-based Automatic License Plate Recognition (LPR) system. The system begins with image capture from an OV7670 VGA camera, feeding data into the FPGA through a VGA input interface. The captured image is stored in RAM_0 (input buffer) and then processed through a custom image processing pipeline, which includes grayscale conversion and contrast enhancement. The output is sent both to the VGA output for visualization and to the character segmentation module, which isolates individual characters from the license plate. These segmented characters are passed to the rescaling module to resize them to 56x56 pixels, with the output stored in RAM_1. The CNN accelerator, which comprises custom RTL modules such as padding, convolution, max pooling, and a dense layer, reads from RAM_1 and accesses weights and intermediate data stored in RAM_2. The recognized character result is displayed via a seven-segment output. All processing and recognition modules are custom IP, while the VGA input/output and RAM components are adapted from external IP sources. This architecture demonstrates a fully hardware-accelerated, real-time LPR pipeline implemented on FPGA.


## Data Flow Diagram

![App Screenshot](https://github.com/ECE532-Group-29/FPGA-License-Plate-Recognition-System/blob/main/documentation/image/data_flow.png)

The control flow of the License Plate Recognition System is centered around real-time interaction and modular processing. The process begins with the user pressing a hardware push button (BTNR) to trigger image capture from the OV7670 VGA camera. 
The image is written into on-chip BRAM and immediately displayed on a VGA monitor via the VGA_Top module. Users have the option to apply preprocessing filters—such as grayscale, contrast enhancement, and color inversion—by toggling switches (SW1 to SW3). 
Once an image is captured, the center button (BTNC) initiates the segmentation process, extracting and rescaling each character to a fixed 56×56 pixel size. These segmented characters are fed sequentially into the RTL-implemented CNN accelerator, which processes the image in a pipelined manner. 
The CNN predicts the top three possible characters, and the results are displayed using the on-board seven-segment display. A timing controller synchronizes this entire data flow, tracking the current character index and managing reset and done signals for smooth operation. By toggling an additional switch, users can cycle through the CNN’s top-3 predictions for each character, enhancing observability and testing. This interactive control loop enables real-time image recognition while also supporting debugging and step-by-step observation of the processing pipeline.

## Srouce Structure

│   src_structure.txt
│   
├───constrs_1
│   └───imports
│       └───OV7670-camera-main
│               Nexys-A7-100T-Master.xdc
│               
├───sim_1
│   ├───imports
│   │   └───cam_0
│   │           tb_top_behav.wcfg
│   │           
│   └───new
│           test_7_seg.v
│           
└───sources_1
    │   verilog_structure.txt
    │   
    ├───imports
    │   ├───cam_0
    │   │       archive_project_summary.txt
    │   │       
    │   └───rtl
    │           cam_capture.v
    │           cam_config.v
    │           cam_init.v
    │           cam_rom.v
    │           cam_top.v
    │           debounce.v
    │           mem_bram.v
    │           sccb_master.v
    │           top.v
    │           vga_driver.v
    │           vga_top.v
    │           
    ├───ip
    │   └───clk_wiz_0
    │       │   clk_wiz_0.dcp
    │       │   clk_wiz_0.v
    │       │   clk_wiz_0.veo
    │       │   clk_wiz_0.xci
    │       │   clk_wiz_0.xdc
    │       │   clk_wiz_0.xml
    │       │   clk_wiz_0_board.xdc
    │       │   clk_wiz_0_clk_wiz.v
    │       │   clk_wiz_0_ooc.xdc
    │       │   clk_wiz_0_sim_netlist.v
    │       │   clk_wiz_0_sim_netlist.vhdl
    │       │   clk_wiz_0_stub.v
    │       │   clk_wiz_0_stub.vhdl
    │       │   mmcm_pll_drp_func_7s_mmcm.vh
    │       │   mmcm_pll_drp_func_7s_pll.vh
    │       │   mmcm_pll_drp_func_us_mmcm.vh
    │       │   mmcm_pll_drp_func_us_pll.vh
    │       │   mmcm_pll_drp_func_us_plus_mmcm.vh
    │       │   mmcm_pll_drp_func_us_plus_pll.vh
    │       │   
    │       └───doc
    │               clk_wiz_v6_0_changelog.txt
    │               
    └───new
            cnn_interface.v
            CNN_pixel.sv
            custom_clk_gen.v
            data_flow_loop_control.v
            dense_layer_1.sv
            dense_layer_2.sv
            grayscale.v
            maxpooling.v
            mem_control.v
            padding_zeros.v
            rescaling.v
            segmentation.v
            seven_seg_display_interface.v
            size_trim.v

The above tree shows the locations of our project's primary files and folders.  Only the important and custom folders are discussed here.
