# This is a tcl command script for the Vivado tool chain
read_vhdl -vhdl2008 { \
   nexys4ddr/nexys4ddr.vhd  \
   nexys4ddr/clk.vhd  \
   nexys4ddr/ctrl.vhd  \
   nexys4ddr/rom_ctrl.vhd  \
   src/ym2151.vhd \
   src/calc_delay.vhd \
   src/calc_phase_inc.vhd \
   src/calc_product.vhd \
   src/calc_waveform.vhd \
   src/get_config.vhd \
   src/rambe.vhd \
   src/rom_delay.vhd \
   src/rom_phase_inc.vhd \
   src/update_state.vhd \
   src/ym2151.vhd \
   src/ym2151_package.vhd \
   nexys4ddr/cdc.vhd \
   nexys4ddr/pwm.vhd }
read_xdc nexys4ddr/nexys4ddr.xdc
synth_design -top nexys4ddr -part xc7a100tcsg324-1 -flatten_hierarchy none
source nexys4ddr/debug.tcl
opt_design
place_design
route_design
write_bitstream -force nexys4ddr.bit
write_checkpoint -force nexys4ddr.dcp
exit
