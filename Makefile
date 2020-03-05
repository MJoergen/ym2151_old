# Specify install location of the Xilinx Vivado tool
XILINX_DIR = /opt/Xilinx/Vivado/2019.2

SRC    = src/ym2151_package.vhd
SRC   += src/rambe.vhd
SRC   += src/get_config.vhd
SRC   += src/rom_phase_inc.vhd
SRC   += src/rom_delay.vhd
SRC   += src/calc_phase_inc.vhd
SRC   += src/calc_product.vhd
SRC   += src/calc_waveform.vhd
SRC   += src/calc_delay.vhd
SRC   += src/update_state.vhd
SRC   += src/ym2151.vhd
TB     = ym2151_tb
TB_SRC = sim/$(TB).vhd
WAVE   = build/$(TB).ghw
SAVE   = sim/$(TB).gtkw
SIM_LIB = /opt/ghdl/lib/ghdl/vendors/xilinx-vivado/


#####################################
# Simulation
#####################################

sim: $(SRC) $(TB_SRC) build
	ghdl -i --ieee=synopsys --std=08 --workdir=build --work=work $(SRC) $(TB_SRC)
	ghdl -m --ieee=synopsys --std=08 --workdir=build -frelaxed-rules -P$(SIM_LIB) $(TB)
	ghdl -r $(TB) --assert-level=error --wave=$(WAVE) --stop-time=1000ms
	gtkwave $(WAVE) $(SAVE)

build:
	mkdir -p build


#####################################
# Synthesis
#####################################

# Generate the bit-file used to configure the FPGA
nexys4ddr.bit: nexys4ddr/nexys4ddr.tcl $(SRC) nexys4ddr/nexys4ddr.xdc nexys4ddr/ctrl.txt
	bash -c "source $(XILINX_DIR)/settings64.sh ; vivado -mode tcl -source $<"

nexys4ddr/ctrl.txt: sim/test1.bin
	nexys4ddr/bin2hex.py $< $@


#####################################
# Cleanup
#####################################

clean:
	rm -rf build
	rm -rf *.o
	rm -rf $(TB)
	rm -rf nexys4ddr.bit
	rm -rf nexys4ddr.dcp
	rm -rf nexys4ddr/ctrl.txt

