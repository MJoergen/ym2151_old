SRC    = src/ym2151_package.vhd
SRC   += src/ym2151_config.vhd
SRC   += src/ym2151_phase_increment_rom.vhd
SRC   += src/ym2151_decay.vhd
SRC   += src/calc_phase_inc.vhd
SRC   += src/calc_cur_phase.vhd
SRC   += src/calc_product.vhd
SRC   += src/calc_waveform.vhd
SRC   += src/calc_delay.vhd
SRC   += src/calc_envelope.vhd
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
	ghdl -r $(TB) --assert-level=error --wave=$(WAVE) --stop-time=7000us
	gtkwave $(WAVE) $(SAVE)

build:
	mkdir -p build


#####################################
# Cleanup
#####################################

clean:
	rm -rf build
	rm -rf *.o
	rm -rf $(TB)

