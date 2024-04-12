## Generated SDC file "vectrex_MiST.out.sdc"

## Copyright (C) 1991-2013 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 13.1.0 Build 162 10/23/2013 SJ Web Edition"

## DATE    "Sun Jun 24 12:53:00 2018"

##
## DEVICE  "EP3C25E144C8"
##

# Clock constraints

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

# tsu/th constraints

# tco constraints

# tpd constraints

#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {SPI_SCK}  -period 41.666 -waveform { 20.8 41.666 } [get_ports {SPI_SCK}]

set sdram_clk "pll|altpll_component|auto_generated|pll1|clk[0]"
set mem_clk   "pll|altpll_component|auto_generated|pll1|clk[1]"
set vid_clk   "pll|altpll_component|auto_generated|pll1|clk[2]"
set aud_clk   "pll|altpll_component|auto_generated|pll1|clk[2]"
set clk_28    "pll|altpll_component|auto_generated|pll1|clk[2]"
set clk_14    "pll|altpll_component|auto_generated|pll1|clk[3]"
set clk_7     "pll|altpll_component|auto_generated|pll1|clk[4]"

#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name clk_3m5 -source $clk_7 -divide_by 2 [get_registers clk_3m5_cont]


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay  -clock_fall -clock [get_clocks {CLOCK_27}]  1.000 [get_ports {CLOCK_27}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {CONF_DATA0}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_DI}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SCK}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SS2}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SS3}]

set_input_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports {SDRAM_CLK}] -max 6.6 [get_ports SDRAM_DQ[*]]
set_input_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports {SDRAM_CLK}] -min 3.5 [get_ports SDRAM_DQ[*]]

#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -clock [get_clocks {SPI_SCK}] 1.000 [get_ports {SPI_DO}]
set_output_delay -clock [get_clocks $clk_28]  1.000 [get_ports {AUDIO_L}]
set_output_delay -clock [get_clocks $clk_28]  1.000 [get_ports {AUDIO_R}]
set_output_delay -clock [get_clocks $clk_28]  1.000 [get_ports {LED}]
set_output_delay -clock [get_clocks $clk_28]  1.000 [get_ports {VGA_*}]

set_output_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports {SDRAM_CLK}] -max 1.5 [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]
set_output_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports {SDRAM_CLK}] -min -0.8 [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]

#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {SPI_SCK}] -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[*]}]
set_clock_groups -asynchronous -group [get_clocks {SPI_SCK}] -group [get_clocks {clk_3m5}]


#**************************************************************
# Set False Path
#**************************************************************

set_false_path -from {sdram:sdram|cpuwait} -to [get_clocks {clk_3m5}]
set_false_path -from {sdram:sdram|cpuwait} -to [get_clocks $clk_7]
set_false_path -from {sdram:sdram|cpuwait2} -to [get_clocks {clk_3m5}]
set_false_path -from {sdram:sdram|cpuwait2} -to [get_clocks $clk_7]

#**************************************************************
# Set Multicycle Path
#**************************************************************

set_multicycle_path -from [get_clocks $sdram_clk] -to [get_clocks $mem_clk] -setup -end 2

set_multicycle_path -from $clk_28 -to $mem_clk -setup 2
set_multicycle_path -from $clk_28 -to $mem_clk -hold 1

set_multicycle_path -from $clk_14 -to $mem_clk -setup 2
set_multicycle_path -from $clk_14 -to $mem_clk -hold 1
set_multicycle_path -from $clk_7  -to $mem_clk -setup 2
set_multicycle_path -from $clk_7  -to $mem_clk -hold 1
set_multicycle_path -from [get_clocks {clk_3m5}] -to $clk_28 -setup 2
set_multicycle_path -from [get_clocks {clk_3m5}] -to $clk_28 -hold 1
set_multicycle_path -from [get_clocks {clk_3m5}] -to $mem_clk -setup 3
set_multicycle_path -from [get_clocks {clk_3m5}] -to $mem_clk -hold 2
set_multicycle_path -from $sdram_clk -to [get_clocks {clk_3m5}] -setup 2 -start
set_multicycle_path -from $sdram_clk -to [get_clocks {clk_3m5}] -hold 1 -start

set_multicycle_path -to {VGA_*[*]} -setup 2
set_multicycle_path -to {VGA_*[*]} -hold 1

#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

