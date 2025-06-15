# System Signals
set_property -dict {PACKAGE_PIN E3  IOSTANDARD LVCMOS33} [get_ports CLK]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports RST_N]


# VGA Output Ports
set_property -dict {PACKAGE_PIN A4  IOSTANDARD LVCMOS33} [get_ports {R[3]}]
set_property -dict {PACKAGE_PIN C5  IOSTANDARD LVCMOS33} [get_ports {R[2]}]
set_property -dict {PACKAGE_PIN B4  IOSTANDARD LVCMOS33} [get_ports {R[1]}]
set_property -dict {PACKAGE_PIN A3  IOSTANDARD LVCMOS33} [get_ports {R[0]}]

set_property -dict {PACKAGE_PIN A6  IOSTANDARD LVCMOS33} [get_ports {G[3]}]
set_property -dict {PACKAGE_PIN B6  IOSTANDARD LVCMOS33} [get_ports {G[2]}]
set_property -dict {PACKAGE_PIN A5  IOSTANDARD LVCMOS33} [get_ports {G[1]}]
set_property -dict {PACKAGE_PIN C6  IOSTANDARD LVCMOS33} [get_ports {G[0]}]

set_property -dict {PACKAGE_PIN D8  IOSTANDARD LVCMOS33} [get_ports {B[3]}]
set_property -dict {PACKAGE_PIN D7  IOSTANDARD LVCMOS33} [get_ports {B[2]}]
set_property -dict {PACKAGE_PIN C7  IOSTANDARD LVCMOS33} [get_ports {B[1]}]
set_property -dict {PACKAGE_PIN B7  IOSTANDARD LVCMOS33} [get_ports {B[0]}]

set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports H_SYNC]
set_property -dict {PACKAGE_PIN B12 IOSTANDARD LVCMOS33} [get_ports V_SYNC]


# Controller Signals
set_property -dict {PACKAGE_PIN G3  IOSTANDARD LVCMOS33} [get_ports NES_CLK]
set_property -dict {PACKAGE_PIN H1  IOSTANDARD LVCMOS33} [get_ports NES_DATA]
set_property -dict {PACKAGE_PIN G1  IOSTANDARD LVCMOS33} [get_ports NES_LATCH]

set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {CONTROLLER_LED[0]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {CONTROLLER_LED[1]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {CONTROLLER_LED[2]}]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {CONTROLLER_LED[3]}]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {CONTROLLER_LED[4]}]


# Audio Output
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports {PWM}]
