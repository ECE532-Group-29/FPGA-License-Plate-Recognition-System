# 
# Synthesis run script generated by Vivado
# 

set TIME_start [clock seconds] 
proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
set_param xicom.use_bs_reader 1
create_project -in_memory -part xc7a100tcsg324-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_msg_config -source 4 -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property webtalk.parent_dir C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.cache/wt [current_project]
set_property parent.project_path C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.xpr [current_project]
set_property XPM_LIBRARIES XPM_CDC [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
set_property board_part digilentinc.com:nexys4_ddr:part0:1.1 [current_project]
set_property ip_output_repo c:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
read_mem {
  C:/Users/Administrator/Desktop/final_merge/cam_0/dense_layer_weights/dense_1_weights_dec.mem
  C:/Users/Administrator/Desktop/final_merge/cam_0/dense_layer_weights/dense_1_biases_dec.mem
  C:/Users/Administrator/Desktop/final_merge/cam_0/dense_layer_weights/dense_biases_dec.mem
  C:/Users/Administrator/Desktop/final_merge/cam_0/dense_layer_weights/dense_weights_dec.mem
}
read_verilog -library xil_defaultlib -sv {
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/CNN_pixel.sv
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/dense_layer_1.sv
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/dense_layer_2.sv
}
read_verilog -library xil_defaultlib {
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/imports/rtl/cam_capture.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/imports/rtl/cam_config.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/imports/rtl/cam_init.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/imports/rtl/cam_rom.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/imports/rtl/cam_top.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/cnn_interface.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/custom_clk_gen.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/data_flow_loop_control.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/imports/rtl/debounce.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/grayscale.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/maxpooling.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/imports/rtl/mem_bram.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/mem_control.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/padding_zeros.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/rescaling.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/imports/rtl/sccb_master.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/segmentation.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/seven_seg_display_interface.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/new/size_trim.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/imports/rtl/vga_driver.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/imports/rtl/vga_top.v
  C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/imports/rtl/top.v
}
read_ip -quiet C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci
set_property used_in_implementation false [get_files -all c:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_board.xdc]
set_property used_in_implementation false [get_files -all c:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xdc]
set_property used_in_implementation false [get_files -all c:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_ooc.xdc]

# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/constrs_1/imports/OV7670-camera-main/Nexys-A7-100T-Master.xdc
set_property used_in_implementation false [get_files C:/Users/Administrator/Desktop/final_merge/cam_0/cam_0.srcs/constrs_1/imports/OV7670-camera-main/Nexys-A7-100T-Master.xdc]

set_param ips.enableIPCacheLiteLoad 1
close [open __synthesis_is_running__ w]

synth_design -top top -part xc7a100tcsg324-1


# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef top.dcp
create_report "synth_1_synth_report_utilization_0" "report_utilization -file top_utilization_synth.rpt -pb top_utilization_synth.pb"
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]
