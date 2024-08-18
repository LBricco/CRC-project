vlib work
echo "compiling..."
vcom clock_edge.vhd
vcom command.vhd
vcom contatore.vhd
vcom counter.vhd
vcom dflipflop.vhd
vcom mux_1_bit2to1.vhd
vcom mux_n_bits2to1.vhd
vcom mux_n_bits4to1.vhd
vcom mux_z.vhd
vcom PISO.vhd
vcom reg.vhd
vcom SIPO.vhd
vcom lfsr_crc16ccitt.vhd
vcom spi.vhd
vcom register_interface.vhd
vcom crc.vhd
vcom top_level.vhd
vcom tb_crc_complete.vhd

vsim -c work.tb_crc_complete

run 0ns
run 20ms

#write list counter.lst
quit -f