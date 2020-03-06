# Specify install location of the Xilinx Vivado tool
XILINX_DIR = /opt/Xilinx/Vivado/2019.2
SIM_LIB    = /opt/ghdl/lib/ghdl/vendors/xilinx-vivado/
SRC_DIR    = ../src

SRC    = $(SRC_DIR)/ym2151_package.vhd
SRC   += $(SRC_DIR)/rambe.vhd
SRC   += $(SRC_DIR)/get_config.vhd
SRC   += $(SRC_DIR)/rom_phase_inc.vhd
SRC   += $(SRC_DIR)/rom_delay.vhd
SRC   += $(SRC_DIR)/calc_phase_inc.vhd
SRC   += $(SRC_DIR)/calc_product.vhd
SRC   += $(SRC_DIR)/calc_waveform.vhd
SRC   += $(SRC_DIR)/calc_delay.vhd
SRC   += $(SRC_DIR)/update_state.vhd
SRC   += $(SRC_DIR)/ym2151.vhd
SRC   += nexys4ddr.vhd
SRC   += clk.vhd
SRC   += ctrl.vhd
SRC   += rom_ctrl.vhd
SRC   += cdc.vhd
SRC   += pwm.vhd
TB     = nexys4ddr_tb
TB_SRC = $(TB).vhd
WAVE   = $(TB).ghw
SAVE   = $(TB).gtkw

#GENERICS = -gG_INIT_FILE="nexys4ddr/ctrl.txt"

#####################################
# Simulation
#####################################

sim: $(SRC) $(TB_SRC) ctrl.txt
	ghdl -i --ieee=synopsys --std=08 --work=work $(SRC) $(TB_SRC)
	ghdl -m --ieee=synopsys --std=08 -frelaxed-rules -P$(SIM_LIB) $(TB)
	ghdl -r $(TB) $(GENERICS) --assert-level=error --wave=$(WAVE) --stop-time=10us
	gtkwave $(WAVE) $(SAVE)


#####################################
# Synthesis
#####################################

# Generate the bit-file used to configure the FPGA
nexys4ddr.bit: nexys4ddr.tcl $(SRC) nexys4ddr.xdc ctrl.txt
	bash -c "source $(XILINX_DIR)/settings64.sh ; vivado -mode tcl -source $<"

ctrl.txt: ../sim/test1.bin
	./bin2hex.py $< $@


#####################################
# Cleanup
#####################################

clean:
	rm -rf *.o
	rm -rf $(TB)
	rm -rf nexys4ddr.bit
	rm -rf nexys4ddr.dcp
	rm -rf ctrl.txt
	rm -rf nexys4ddr_tb.ghw
