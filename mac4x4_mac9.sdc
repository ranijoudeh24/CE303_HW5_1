# mac4x4_mac9.sdc
create_clock -name clk -period 1.000 [get_ports clk]

# Inputs (except clk, rstb) have max 0.5 ns setup budget, min -0.2 ns hold margin
set_input_delay  -max 0.5 -clock clk [get_ports {IN[*] W[*]}]
set_input_delay  -min -0.2 -clock clk [get_ports {IN[*] W[*]}]

# Output meets max 0.5 ns, min -0.2 ns w.r.t. clk
set_output_delay -max 0.5 -clock clk [get_ports {OUT[*]}]
set_output_delay -min -0.2 -clock clk [get_ports {OUT[*]}]
