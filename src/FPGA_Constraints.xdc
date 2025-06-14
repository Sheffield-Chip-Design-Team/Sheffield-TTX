# System Signals
set_property IOSTANDARD LVCMOS33 [get_ports CLK]
set_property PACKAGE_PIN E3 [get_ports CLK]

set_property IOSTANDARD LVCMOS33 [get_ports RST_N]
set_property PACKAGE_PIN J15 [get_ports RST_N]

# VGA Output Ports
set_property IOSTANDARD LVCMOS33 [get_ports {R[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {R[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {R[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {R[0]}]

set_property PACKAGE_PIN A4 [get_ports {R[3]}]
set_property PACKAGE_PIN C5 [get_ports {R[2]}]
set_property PACKAGE_PIN B4 [get_ports {R[1]}]
set_property PACKAGE_PIN A3 [get_ports {R[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {G[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {G[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {G[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {G[0]}]

set_property PACKAGE_PIN A6 [get_ports {G[3]}]
set_property PACKAGE_PIN B6 [get_ports {G[2]}]
set_property PACKAGE_PIN A5 [get_ports {G[1]}]
set_property PACKAGE_PIN C6 [get_ports {G[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {B[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {B[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {B[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {B[0]}]

set_property PACKAGE_PIN D8 [get_ports {B[3]}]
set_property PACKAGE_PIN D7 [get_ports {B[2]}]
set_property PACKAGE_PIN C7 [get_ports {B[1]}]
set_property PACKAGE_PIN B7 [get_ports {B[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports H_SYNC]
set_property PACKAGE_PIN B11 [get_ports H_SYNC]

set_property IOSTANDARD LVCMOS33 [get_ports V_SYNC]
set_property PACKAGE_PIN B12 [get_ports V_SYNC]

# Controller Signals
set_property IOSTANDARD LVCMOS33 [get_ports NES_CLK]
set_property PACKAGE_PIN G3 [get_ports NES_CLK]

set_property IOSTANDARD LVCMOS33 [get_ports NES_DATA]
set_property PACKAGE_PIN H1 [get_ports NES_DATA]

set_property IOSTANDARD LVCMOS33 [get_ports NES_LATCH]
set_property PACKAGE_PIN G1 [get_ports NES_LATCH]

set_property IOSTANDARD LVCMOS33 [get_ports {CONTROLLER_LED[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {CONTROLLER_LED[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {CONTROLLER_LED[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {CONTROLLER_LED[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {CONTROLLER_LED[0]}]

set_property PACKAGE_PIN T16 [get_ports {CONTROLLER_LED[4]}]
set_property PACKAGE_PIN V15 [get_ports {CONTROLLER_LED[3]}]
set_property PACKAGE_PIN V14 [get_ports {CONTROLLER_LED[2]}]
set_property PACKAGE_PIN V12 [get_ports {CONTROLLER_LED[1]}]
set_property PACKAGE_PIN V11 [get_ports {CONTROLLER_LED[0]}]

# Audio Output 
set_property IOSTANDARD LVCMOS33 [get_ports {PWM}]
set_property PACKAGE_PIN A11 [get_ports {PWM}]
                                                            
