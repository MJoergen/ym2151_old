SRC_DIR    = ../src

SRC     = $(SRC_DIR)/ym2151_package.vhd
SRC    += $(SRC_DIR)/rambe.vhd
SRC    += $(SRC_DIR)/get_config.vhd
SRC    += $(SRC_DIR)/rom_phase_inc.vhd
SRC    += $(SRC_DIR)/rom_delay.vhd
SRC    += $(SRC_DIR)/calc_phase_inc.vhd
SRC    += $(SRC_DIR)/calc_product.vhd
SRC    += $(SRC_DIR)/calc_phase.vhd
SRC    += $(SRC_DIR)/calc_waveform.vhd
SRC    += $(SRC_DIR)/calc_delay.vhd
SRC    += $(SRC_DIR)/calc_output.vhd
SRC    += $(SRC_DIR)/update_state.vhd
SRC    += $(SRC_DIR)/ym2151.vhd

TB      = ym2151_tb
TB_SRC  = ../nexys4ddr/rom_ctrl.vhd
TB_SRC += ../nexys4ddr/ctrl.vhd
TB_SRC += output2wav.vhd
TB_SRC += $(TB).vhd
WAVE    = build/$(TB).ghw
SAVE    = $(TB).gtkw
SIM_LIB = /opt/ghdl/lib/ghdl/vendors/xilinx-vivado/


#####################################
# Simulation.
# Speed is roughly 6 minutes for each 10 ms.
#####################################

show: $(WAVE) $(SAVE)
	gtkwave $(WAVE) $(SAVE)

$(WAVE): $(SRC) $(TB_SRC) build rom.txt
	ghdl -i --ieee=synopsys --std=08 --workdir=build --work=work $(SRC) $(TB_SRC)
	ghdl -m --ieee=synopsys --std=08 --workdir=build -frelaxed-rules -P$(SIM_LIB) $(TB)
	ghdl -r $(TB) --assert-level=error --wave=$(WAVE) --stop-time=8000us

#rom.txt: test/Ievan_Polkka.bin
rom.txt: test/mode6.bin
	./bin2hex.py $< $@
	# Possibly use xxd instead of bin2hex.py?

build:
	mkdir -p build


#####################################
# Cleanup
#####################################

clean:
	rm -rf build
	rm -rf *.o
	rm -rf $(TB)
	rm -rf rom.txt
	rm -rf music.wav

