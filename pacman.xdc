set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports clk]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports rst]

set_property -dict {PACKAGE_PIN K22 IOSTANDARD LVCMOS33} [get_ports hs]
set_property -dict {PACKAGE_PIN K21 IOSTANDARD LVCMOS33} [get_ports vs]

set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVCMOS33} [get_ports btn_up]
set_property -dict {PACKAGE_PIN N20 IOSTANDARD LVCMOS33} [get_ports btn_left]
set_property -dict {PACKAGE_PIN M22 IOSTANDARD LVCMOS33} [get_ports btn_right]
set_property -dict {PACKAGE_PIN N22 IOSTANDARD LVCMOS33} [get_ports btn_down]


set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports rgb[11]]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports rgb[10]]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports rgb[9]]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports rgb[8]]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports rgb[7]]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS33} [get_ports rgb[6]]
set_property -dict {PACKAGE_PIN H20 IOSTANDARD LVCMOS33} [get_ports rgb[5]]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS33} [get_ports rgb[4]]
set_property -dict {PACKAGE_PIN J20 IOSTANDARD LVCMOS33} [get_ports rgb[3]]
set_property -dict {PACKAGE_PIN J21 IOSTANDARD LVCMOS33} [get_ports rgb[2]]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS33} [get_ports rgb[1]]
set_property -dict {PACKAGE_PIN J22 IOSTANDARD LVCMOS33} [get_ports rgb[0]]