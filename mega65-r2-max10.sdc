
create_clock -period 10.000 -name cpld_clk [get_ports {cpld_clk}]
create_clock -period 10.000 -name xilinx_sync [get_ports {xilinx_sync}]

