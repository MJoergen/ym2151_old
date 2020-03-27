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
SRC   += $(SRC_DIR)/calc_output.vhd
SRC   += $(SRC_DIR)/update_state.vhd
SRC   += $(SRC_DIR)/ym2151.vhd

TB     = ym2151_tb
TB_SRC = $(TB).vhd
WAVE   = build/$(TB).ghw
SAVE   = $(TB).gtkw
SIM_LIB = /opt/ghdl/lib/ghdl/vendors/xilinx-vivado/


#####################################
# Simulation
#####################################

sim: $(SRC) $(TB_SRC) build
	ghdl -i --ieee=synopsys --std=08 --workdir=build --work=work $(SRC) $(TB_SRC)
	ghdl -m --ieee=synopsys --std=08 --workdir=build -frelaxed-rules -P$(SIM_LIB) $(TB)
	ghdl -r $(TB) --assert-level=error --wave=$(WAVE) --stop-time=6000us
	#gtkwave $(WAVE) $(SAVE)

build:
	mkdir -p build


#####################################
# Cleanup
#####################################

clean:
	rm -rf build
	rm -rf *.o
	rm -rf $(TB)
