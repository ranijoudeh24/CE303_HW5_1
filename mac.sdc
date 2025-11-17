# mac.sdc  -- SDC constraints for MAC design

# 1 GHz clock (period = 1.0 ns)
create_clock -name clk -period 1.0 [get_ports clk]

# Input delay constraints for IN and W (and rstb if you like)
set_input_delay -max 0.5 -clock clk [get_ports {IN[*] W[*]}]
set_input_delay -min -0.2 -clock clk [get_ports {IN[*] W[*]}]

# Output delay constraints for OUT
set_output_delay -max 0.5 -clock clk [get_ports {OUT[*]}]
set_output_delay -min -0.2 -clock clk [get_ports {OUT[*]}]
