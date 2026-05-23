vsim -voptargs="+acc" work.i2c_master_tb 
onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group TB /i2c_master_tb/SCL
add wave -noupdate -group TB /i2c_master_tb/SDA
add wave -noupdate -group TB /i2c_master_tb/rst_n
add wave -noupdate -group TB /i2c_master_tb/clk
add wave -noupdate -group TB /i2c_master_tb/sda_m
add wave -noupdate -group TB /i2c_master_tb/slave_driving
add wave -noupdate -group TB /i2c_master_tb/data_out_1
add wave -noupdate -group TB /i2c_master_tb/data_out_2
add wave -noupdate -group TB /i2c_master_tb/data_out_3
add wave -noupdate -group TB /i2c_master_tb/addr_out_1
add wave -noupdate -group TB /i2c_master_tb/addr_out_2
add wave -noupdate -group TB /i2c_master_tb/addr_out_3
add wave -noupdate -group DUT /i2c_master_tb/DUT/SCL
add wave -noupdate -group DUT /i2c_master_tb/DUT/SDA
add wave -noupdate -group DUT /i2c_master_tb/DUT/rst_n
add wave -noupdate -group DUT /i2c_master_tb/DUT/data_out_1
add wave -noupdate -group DUT /i2c_master_tb/DUT/data_out_2
add wave -noupdate -group DUT /i2c_master_tb/DUT/data_out_3
add wave -noupdate -group DUT /i2c_master_tb/DUT/addr_out_1
add wave -noupdate -group DUT /i2c_master_tb/DUT/addr_out_2
add wave -noupdate -group DUT /i2c_master_tb/DUT/addr_out_3
add wave -noupdate -group DUT /i2c_master_tb/DUT/slave_driving
add wave -noupdate -group DUT /i2c_master_tb/DUT/SDA_1
add wave -noupdate -group DUT /i2c_master_tb/DUT/SDA_2
add wave -noupdate -group DUT /i2c_master_tb/DUT/SDA_3
add wave -noupdate -group DUT /i2c_master_tb/DUT/SDA_bus
add wave -noupdate -group DUT /i2c_master_tb/DUT/dir1
add wave -noupdate -group DUT /i2c_master_tb/DUT/dir2
add wave -noupdate -group DUT /i2c_master_tb/DUT/dir3
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/SCL
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/SDA_in
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/rst_n
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/SDA_out
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/data_out
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/adress_out
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/dir
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/cs
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/ns
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/sda_out
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/wr_rd
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/wr_data
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/rd_data
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/adress_in
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/sipo
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/counter
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/piso
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/start
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/start_en
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/stop_en
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/stop
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/piso_en
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/sipo_en
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/wr_en
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/rd_en
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/count_en
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/address_match
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/out_bus
add wave -noupdate -group Slave1 /i2c_master_tb/DUT/slave_1/wr_dr_test
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/SCL
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/SDA_in
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/rst_n
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/SDA_out
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/data_out
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/adress_out
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/dir
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/cs
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/ns
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/sda_out
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/wr_rd
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/wr_data
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/rd_data
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/adress_in
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/sipo
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/counter
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/piso
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/start
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/start_en
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/stop_en
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/stop
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/piso_en
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/sipo_en
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/wr_en
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/rd_en
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/count_en
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/address_match
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/out_bus
add wave -noupdate -group Slave2 /i2c_master_tb/DUT/slave_2/wr_dr_test
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/SCL
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/SDA_in
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/rst_n
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/SDA_out
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/data_out
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/adress_out
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/dir
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/cs
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/ns
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/sda_out
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/wr_rd
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/wr_data
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/rd_data
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/adress_in
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/sipo
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/counter
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/piso
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/start
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/start_en
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/stop_en
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/stop
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/piso_en
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/sipo_en
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/wr_en
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/rd_en
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/count_en
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/address_match
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/out_bus
add wave -noupdate -group slave3 /i2c_master_tb/DUT/slave_3/wr_dr_test
add wave -position insertpoint sim:/i2c_master_tb/write_data/temp
add wave -position insertpoint sim:/i2c_master_tb/rd_address/temp
add wave -position insertpoint sim:/i2c_master_tb/wr_address/temp
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1 us}
