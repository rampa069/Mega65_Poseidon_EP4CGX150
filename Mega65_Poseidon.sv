/* ZX Next MiST top-level */
/* by Gyorgy Szombathelyi */

module Mega65_Poseidon (
	input         CLOCK_27,

	output        LED,
	output [VGA_BITS-1:0] VGA_R,
	output [VGA_BITS-1:0] VGA_G,
	output [VGA_BITS-1:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,

`ifdef USE_HDMI
	output        HDMI_RST,
	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_PCLK,
	output        HDMI_DE,
	inout         HDMI_SDA,
	inout         HDMI_SCL,
	input         HDMI_INT,
`endif

	input         SPI_SCK,
	inout         SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,    // data_io
	input         SPI_SS3,    // OSD
	input         CONF_DATA0, // SPI_SS for user_io

`ifdef USE_QSPI
	input         QSCK,
	input         QCSn,
	inout   [3:0] QDAT,
`endif
`ifndef NO_DIRECT_UPLOAD
	input         SPI_SS4,
`endif

	output [12:0] SDRAM_A,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nWE,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nCS,
	output  [1:0] SDRAM_BA,
	output        SDRAM_CLK,
	output        SDRAM_CKE,

`ifdef DUAL_SDRAM
	output [12:0] SDRAM2_A,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_DQML,
	output        SDRAM2_DQMH,
	output        SDRAM2_nWE,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nCS,
	output  [1:0] SDRAM2_BA,
	output        SDRAM2_CLK,
	output        SDRAM2_CKE,
`endif

	output        AUDIO_L,
	output        AUDIO_R,
`ifdef I2S_AUDIO
	output        I2S_BCK,
	output        I2S_LRCK,
	output        I2S_DATA,
`endif
`ifdef I2S_AUDIO_HDMI
	output        HDMI_MCLK,
	output        HDMI_BCK,
	output        HDMI_LRCK,
	output        HDMI_SDATA,
`endif
`ifdef SPDIF_AUDIO
	output        SPDIF,
`endif
`ifdef USE_AUDIO_IN
	input         AUDIO_IN,
`endif
	input         UART_RX,
	output        UART_TX

);

`ifdef NO_DIRECT_UPLOAD
localparam bit DIRECT_UPLOAD = 0;
wire SPI_SS4 = 1;
`else
localparam bit DIRECT_UPLOAD = 1;
`endif

`ifdef USE_QSPI
localparam bit QSPI = 1;
assign QDAT = 4'hZ;
`else
localparam bit QSPI = 0;
`endif

`ifdef VGA_8BIT
localparam VGA_BITS = 8;
`else
localparam VGA_BITS = 6;
`endif

`ifdef USE_HDMI
localparam bit HDMI = 1;
assign HDMI_RST = 1'b1;
`else
localparam bit HDMI = 0;
`endif

`ifdef BIG_OSD
localparam bit BIG_OSD = 1;
`define SEP "-;",
`else
localparam bit BIG_OSD = 0;
`define SEP
`endif

// remove this if the 2nd chip is actually used
`ifdef DUAL_SDRAM
assign SDRAM2_A = 13'hZZZZ;
assign SDRAM2_BA = 0;
assign SDRAM2_DQML = 1;
assign SDRAM2_DQMH = 1;
assign SDRAM2_CKE = 0;
assign SDRAM2_CLK = 0;
assign SDRAM2_nCS = 1;
assign SDRAM2_DQ = 16'hZZZZ;
assign SDRAM2_nCAS = 1;
assign SDRAM2_nRAS = 1;
assign SDRAM2_nWE = 1;
`endif

`include "build_id.v"

localparam CONF_STR = {
	"Mega 65;;",
	"S0U,VHDIMG,Mount internal SD;",
	"S1U,VHDIMG,Mount external SD;",
	`SEP
	"O34,Scanlines,Off,25%,50%,75%;",
	"O5,Blend,Off,On;",
	"O6,Joystick Swap,Off,On;",
	`SEP
	"T0,Reset;",
	"V,v1.00.",`BUILD_DATE
};

wire  [1:0] scanlines = status[4:3];
wire        blend = status[5];
wire        joyswap = status[6];
wire        userport = status[7];
wire        pausetzx = status[1];
wire        invtapein = status[8];

//assign 		LED = ~ioctl_downl & (tzxplayer_pause | tape_motor_led);
assign 		LED = ~ioctl_downl;
assign 		SDRAM_CKE = 1;

// Clock generation
//wire sdclk, clk_112, clk_28, clk_28n = ~clk_28, clk_14, clk_7, pll_locked;
wire clock27, clock40_5, clock81, clock162, pll_locked;

pll pll(
	.inclk0(CLOCK_27),  // In Poseidon is 50 Mhz
	.c0(clock27),
	.c1(clock40_5),
	.c2(clock81),
	.c3(clock162),
	.locked(pll_locked)
	);

wire clock200, clock100, clock50, pll_locked2;

pll2	pll2 (
	.inclk0 (CLOCK_27),
	.c0 (clock200),
	.c1 (clock100),
	.c2 (clock50),
	.locked (pll_locked2)
	);

	

//// Reset
reg        reset = 1;
wire       zxn_reset_soft;
wire       zxn_reset_hard;
reg [27:0] reset_cnt;

always @(posedge clock27, negedge pll_locked) begin
	if (!pll_locked) begin
		reset <= 1;
		reset_cnt <= 28'hfffffff;
	end else begin
		if (status[0] | buttons[1] | zxn_reset_soft | zxn_reset_hard)
			reset_cnt <= 16'hffff;
		else if (reset_cnt != 0)
			reset_cnt <= reset_cnt - 1'd1;

		reset <= (reset_cnt != 0);
	end
end

// User IO
wire [63:0] status;
wire  [1:0] buttons;
wire  [1:0] switches;
wire [15:0] joy0;
wire [15:0] joy1;
wire        scandoublerD;
wire        ypbpr;
wire        no_csync;
wire [63:0] rtc;
wire [15:0] audio;
wire        key_strobe;
wire        key_pressed;
wire        key_extended;
wire  [7:0] key_code;
wire signed [8:0] mouse_x;
wire signed [8:0] mouse_y;
wire signed [3:0] mouse_z;
wire  [7:0] mouse_flags;
wire        mouse_strobe;

// conections between user_io (implementing the SPI communication 
// to the io controller) and the legacy SD Card wrapper
wire        sd_busy;
wire [31:0] sd_lba;
wire  [1:0] sd_rd;
wire  [1:0] sd_wr;
wire        sd_ack;
wire        sd_conf;
wire        sd_sdhc;
wire  [7:0] sd_dout;
wire        sd_dout_strobe;
wire  [7:0] sd_din;
wire  [8:0] sd_buff_addr;
wire        sd_ack_conf;
wire  [1:0] img_mounted;
wire [31:0] img_size;

`ifdef USE_HDMI
wire        i2c_start;
wire        i2c_read;
wire  [6:0] i2c_addr;
wire  [7:0] i2c_subaddr;
wire  [7:0] i2c_dout;
wire  [7:0] i2c_din;
wire        i2c_ack;
wire        i2c_end;
`endif

user_io #(.STRLEN(($size(CONF_STR)>>3)), .ROM_DIRECT_UPLOAD(DIRECT_UPLOAD), .FEATURES(32'h0 | (BIG_OSD << 13) | (HDMI << 14)))user_io(
	.clk_sys        ( clock27        ),
	.clk_sd         ( clock100       ),
	.conf_str       ( CONF_STR       ),
	.SPI_CLK        ( SPI_SCK        ),
	.SPI_SS_IO      ( CONF_DATA0     ),
	.SPI_MISO       ( SPI_DO         ),
	.SPI_MOSI       ( SPI_DI         ),
	.buttons        ( buttons        ),
	.switches       ( switches       ),
	.scandoubler_disable(scandoublerD),
	.ypbpr          ( ypbpr          ),
	.no_csync       ( no_csync       ),
	.core_mod       (                ),
	.rtc            ( rtc            ),
	.key_strobe     ( key_strobe     ),
	.key_pressed    ( key_pressed    ),
	.key_extended   ( key_extended   ),
	.key_code       ( key_code       ),
	.ps2_kbd_clk    ( ps2clk         ),
	.ps2_kbd_data   ( ps2data        ),
	.mouse_x        ( mouse_x        ),
	.mouse_y        ( mouse_y        ),
	.mouse_z        ( mouse_z        ),
	.mouse_flags    ( mouse_flags    ),
	.mouse_strobe   ( mouse_strobe   ),
	.joystick_0     ( joy0           ),
	.joystick_1     ( joy1           ),
	.status         ( status         ),
`ifdef USE_HDMI
	.i2c_start      ( i2c_start      ),
	.i2c_read       ( i2c_read       ),
	.i2c_addr       ( i2c_addr       ),
	.i2c_subaddr    ( i2c_subaddr    ),
	.i2c_dout       ( i2c_dout       ),
	.i2c_din        ( i2c_din        ),
	.i2c_ack        ( i2c_ack        ),
	.i2c_end        ( i2c_end        ),
`endif
   // interface to embedded legacy sd card wrapper
	.sd_lba     	  ( sd_lba         ),
	.sd_rd      	  ( sd_rd          ),
	.sd_wr      	  ( sd_wr          ),
	.sd_ack     	  ( sd_ack         ),
	.sd_conf    	  ( sd_conf        ),
	.sd_sdhc    	  ( sd_sdhc        ),
	.sd_dout    	  ( sd_dout        ),
	.sd_dout_strobe ( sd_dout_strobe ),
	.sd_din     	  ( sd_din         ),
	.sd_buff_addr   ( sd_buff_addr   ),
	.sd_ack_conf    ( sd_ack_conf    ),

	.img_mounted    ( img_mounted    ),
	.img_size       ( img_size       )
	);

//reg signed  [3:0] zxn_mouse_wheel;
//reg signed  [7:0] zxn_mouse_x;
//reg signed  [7:0] zxn_mouse_y;
//reg   [2:0] zxn_mouse_button;
//
//always @(posedge clk_28) begin
//	if (mouse_strobe) begin
//		zxn_mouse_x <= zxn_mouse_x + mouse_x;
//		zxn_mouse_y <= zxn_mouse_y + mouse_y;
//		zxn_mouse_wheel <= zxn_mouse_wheel + mouse_z;
//		zxn_mouse_button <= mouse_flags[2:0];
//	end
//end

wire [10:0] zxn_joy_left =  joyswap ? joy0[10:0] : joy1[10:0];
wire [10:0] zxn_joy_right = joyswap ? joy1[10:0] : joy0[10:0];
wire  [2:0] zxn_joy_left_type;
wire  [2:0] zxn_joy_right_type;
wire        zxn_joy_io_mode_en;

// SD Card
wire zxn_spi_ss_sd0_n;
wire zxn_spi_sck;
wire zxn_spi_mosi;
wire sd_miso_i;


wire sd_cs_n;
wire sd_sck;
wire sd_mosi;
wire sd_miso;
	
sd_card sd_card (
	// connection to io controller
	.clk_sys      ( clock100       ),
	.sd_lba       ( sd_lba         ),
	.sd_rd        ( sd_rd[0]       ),
	.sd_wr        ( sd_wr[0]       ),
	.sd_ack       ( sd_ack         ),
	.sd_ack_conf  ( sd_ack_conf    ),
	.sd_conf      ( sd_conf        ),
	.sd_sdhc      ( sd_sdhc        ),
	.sd_buff_dout ( sd_dout        ),
	.sd_buff_wr   ( sd_dout_strobe ),
	.sd_buff_din  ( sd_din         ),
	.sd_buff_addr ( sd_buff_addr   ),
	.img_mounted  ( img_mounted[0] ),
	.img_size     ( img_size       ),
	.allow_sdhc   ( 1'b1           ),
	.sd_busy      ( sd_busy        ),

	// connection to local CPU
	.sd_cs        ( sd_cs_n ),
	.sd_sck       ( sd_sck  ),
	.sd_sdi       ( sd_mosi ),
	.sd_sdo       ( sd_miso )
);

wire sd2_cs_n;
wire sd2_sck;
wire sd2_mosi;
wire sd2_miso;

sd_card sd_card2 (
	// connection to io controller
	.clk_sys      ( clock100       ),
	.sd_lba       ( sd_lba         ),
	.sd_rd        ( sd_rd[1]       ),
	.sd_wr        ( sd_wr[1]       ),
	.sd_ack       ( sd_ack         ),
	.sd_ack_conf  ( sd_ack_conf    ),
	.sd_conf      ( sd_conf        ),
	.sd_sdhc      ( sd_sdhc        ),
	.sd_buff_dout ( sd_dout        ),
	.sd_buff_wr   ( sd_dout_strobe ),
	.sd_buff_din  ( sd_din         ),
	.sd_buff_addr ( sd_buff_addr   ),
	.img_mounted  ( img_mounted[1] ),
	.img_size     ( img_size       ),
	.allow_sdhc   ( 1'b1           ),
	.sd_busy      ( sd_busy        ),

	// connection to local CPU
	.sd_cs        ( sd2_cs_n ),
	.sd_sck       ( sd2_sck  ),
	.sd_sdi       ( sd2_mosi ),
	.sd_sdo       ( sd2_miso )
);

// data io (TZX upload)
wire        ioctl_downl;
wire        ioctl_upl;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

data_io #(.ROM_DIRECT_UPLOAD(1)) data_io(
	.clk_sys       ( clock27       ),
	.SPI_SCK       ( SPI_SCK      ),
	.SPI_SS2       ( SPI_SS2      ),
	.SPI_SS4       ( SPI_SS4      ),
	.SPI_DI        ( SPI_DI       ),
	.SPI_DO        ( SPI_DO       ),
	.ioctl_download( ioctl_downl  ),
	.ioctl_upload  ( ioctl_upl    ),
	.ioctl_index   ( ioctl_index  ),
	.ioctl_wr      ( ioctl_wr     ),
	.ioctl_addr    ( ioctl_addr   ),
	.ioctl_dout    ( ioctl_dout   ),
	.ioctl_din     ( ioctl_din    )
);


// Wait generator
reg         sdram_cpuwaitD;
reg         cpu_mreqD;
reg         wait_t1t2;
reg         zxn_ram_a_req_reg;

//always @(posedge clk_112) zxn_ram_a_req_reg <= zxn_ram_a_req;
//
//always @(posedge clk_cpu)	sdram_cpuwaitD <= sdram_cpuwait;
//
//wire        zxn_ram_a_wait = (clk_select[2] & ((sdram_cpuwait & ~zxn_cpu_wr_n) | (sdram_cpuwaitD & ~zxn_cpu_rd_n))) | // for 14MHz (wait when necessary)
//                             (clk_select[3] & sdram_cpuwait2); // for 28MHz
//
//wire        zxn_ram_a_wait_n = ~(zxn_ram_a_wait & zxn_ram_a_req);
//
//reg         zxn_spi_miso;
//always @(posedge clk_cpu)	zxn_spi_miso <= sd_miso_i;
//
//// ZX Next instance
//
//wire        zxn_bus_wait_n = 1;
//wire        zxn_bus_nmi_n = 1;
//wire        zxn_bus_int_n = 1;
//wire        zxn_bus_busreq_n = 1;
//wire        zxn_bus_romcs_n = 1;
//wire        zxn_bus_iorqula_n = 1;
//wire        zxn_cpu_rfsh_n;
//wire        zxn_cpu_mreq_n;
//wire        zxn_cpu_iorq_n;
//wire        zxn_cpu_rd_n;
//wire        zxn_cpu_wr_n;
//
//wire  [8:0] zxn_rgb;
//wire        zxn_rgb_cs_n;
//wire        zxn_rgb_hs_n;
//wire        zxn_rgb_vs_n;
//wire  [1:0] zxn_video_scanlines;
//wire        zxn_rgb_vb_n;
//wire        zxn_rgb_hb_n;
//wire  [2:0] zxn_machine_timing;
//wire        zxn_video_scandouble_en;

wire			vdac_clk;
wire			vdac_blank_n;
wire			vsync;
wire			hsync;
wire  [7:0]	vgared;
wire  [7:0]	vgagreen;
wire  [7:0]	vgablue;

//wire led;
wire led2;
wire ps2clk;
wire ps2data;


container Mega65_instance (
	.clock27					(clock27),
	.cpuclock				(clock40_5),
	.pixelclock				(clock81),
	.clock162				(clock162),
	.clock200				(clock200),
	.clock100				(clock100),
	.ethclock				(clock50),
	
	.btnCpuReset			(~reset),
	
	.ps2clk 					(ps2clk),
	.ps2data					(ps2data),
	
	.fa_left					( 1'b1 ),
	.fa_right				( 1'b1 ),
   .fa_up					( 1'b1 ),
   .fa_down					( 1'b1 ),
   .fa_fire					( 1'b1 ),
   .fb_left					( 1'b1 ),
   .fb_right				( 1'b1 ),
   .fb_up					( 1'b1 ),
   .fb_down					( 1'b1 ),
   .fb_fire					( 1'b1 ),
	
	.QspiDB					(      ),
	.QspiCSn					(		 ),
	
	.vdac_clk				(vdac_clk),
	.vdac_blank_n			(vdac_blank_n),
	.vsync					(vsync ),
	.hsync					(hsync ),
	.vgared					(vgared),
	.vgagreen				(vgagreen),
	.vgablue					(vgablue),
	
	
	.audio_blck				(I2S_BCK),
   .audio_lrclk			(I2S_LRCK),
   .audio_sdata			(I2S_DATA),
	
	.sdReset				   (sd_cs_n),
   .sdClock				   (sd_sck ),
   .sdMOSI					(sd_mosi),
   .sdMISO					(sd_miso),
	
	.sd2Reset				(sd2_cs_n),
   .sd2Clock				(sd2_sck ),
   .sd2MOSI					(sd2_mosi),
   .sd2MISO					(sd2_miso),
	
	.led						(  ),
   .led2						(led2)

);




reg   [5:0] joy_kempston;
reg   [4:0] joy_sinclair1;
reg   [4:0] joy_sinclair2;
reg   [4:0] joy_cursor;


// Video out
mist_video #(.COLOR_DEPTH(8), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(VGA_BITS), .BIG_OSD(BIG_OSD)) mist_video(
	.clk_sys        ( clock27           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( vgared           ),
	.G              ( vgagreen         ),
	.B              ( vgablue          ),
	.HSync          ( hsync 		     ),
	.VSync          ( vsync     		  ),
	.VGA_R          ( VGA_R            ),
	.VGA_G          ( VGA_G            ),
	.VGA_B          ( VGA_B            ),
	.VGA_VS         ( VGA_VS           ),
	.VGA_HS         ( VGA_HS           ),
	.ce_divider     ( 1'b1             ),
	.rotate         ( 2'b00            ),
	.blend          ( blend            ),
	.scandoubler_disable( scandoublerD ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( 0            ),
	.no_csync       ( no_csync         )
	);

// Sound out
wire [12:0] zxn_audio_L_pre;
wire [12:0] zxn_audio_R_pre;



`ifdef I2S_AUDIO
//mist_i2s_master i2s (
//	.reset(1'b0),
//	.clk(clock27),
//	.clk_rate(32'd27_000_000),
//
//	.sclk(I2S_BCK),
//	.lrclk(I2S_LRCK),
//	.sdata(I2S_DATA),
//
//	.left_chan({~zxn_audio_L_pre[12], zxn_audio_L_pre[11:0], 3'd0}),
//	.right_chan({~zxn_audio_R_pre[12], zxn_audio_R_pre[11:0], 3'd0})
//);
`ifdef I2S_AUDIO_HDMI
assign HDMI_MCLK = 0;
always @(posedge clock27) begin
	HDMI_BCK <= I2S_BCK;
	HDMI_LRCK <= I2S_LRCK;
	HDMI_SDATA <= I2S_DATA;
end
`endif
`endif

`ifdef SPDIF_AUDIO
spdif spdif
(
	.clk_i(clk_28),
	.rst_i(1'b0),
	.clk_rate_i(32'd28_000_000),
	.spdif_o(SPDIF),
	.sample_i({~zxn_audio_R_pre[12], zxn_audio_R_pre[11:0], 3'd0, ~zxn_audio_L_pre[12], zxn_audio_L_pre[11:0], 3'd0})
);
`endif

`ifdef USE_HDMI
i2c_master #(28_000_000) i2c_master (
	.CLK         (clock27),
	.I2C_START   (i2c_start),
	.I2C_READ    (i2c_read),
	.I2C_ADDR    (i2c_addr),
	.I2C_SUBADDR (i2c_subaddr),
	.I2C_WDATA   (i2c_dout),
	.I2C_RDATA   (i2c_din),
	.I2C_END     (i2c_end),
	.I2C_ACK     (i2c_ack),

	//I2C bus
	.I2C_SCL     (HDMI_SCL),
	.I2C_SDA     (HDMI_SDA)
);

mist_video #(.COLOR_DEPTH(3), .SD_HCNT_WIDTH(10), .OUT_COLOR_DEPTH(6), .BIG_OSD(BIG_OSD), .USE_BLANKS(1'b1), .VIDEO_CLEANER(1'b1)) hdmi_video(
	.clk_sys        ( clock27           ),
	.SPI_SCK        ( SPI_SCK          ),
	.SPI_SS3        ( SPI_SS3          ),
	.SPI_DI         ( SPI_DI           ),
	.R              ( zxn_rgb[8:6]     ),
	.G              ( zxn_rgb[5:3]     ),
	.B              ( zxn_rgb[2:0]     ),
	.HSync          ( zxn_rgb_hs_n     ),
	.VSync          ( zxn_rgb_vs_n     ),
	.HBlank         ( ~zxn_rgb_hb_n    ),
	.VBlank         ( ~zxn_rgb_vb_n    ),
	.VGA_R          ( HDMI_R           ),
	.VGA_G          ( HDMI_G           ),
	.VGA_B          ( HDMI_B           ),
	.VGA_VS         ( HDMI_VS          ),
	.VGA_HS         ( HDMI_HS          ),
	.VGA_DE         ( HDMI_DE          ),
	.ce_divider     ( 3'd1             ),
	.rotate         ( 2'b00            ),
	.blend          ( blend            ),
	.scandoubler_disable( 1'b0         ),
	.scanlines      ( scanlines        ),
	.ypbpr          ( 1'b0             ),
	.no_csync       ( 1'b1             )
	);

assign HDMI_PCLK = clk_28;

`endif


// Userport
wire        zxn_uart0_rx;
wire        zxn_uart0_tx;
wire        ear_port_i_qq;

reg UART_RXd, UART_RXd2;
always @(posedge clock27) { UART_RXd2, UART_RXd } <= { UART_RXd, UART_RX };

`ifdef USE_AUDIO_IN
//assign      ear_port_i_qq = tzxplayer_running ? ~tzxplayer_audio : (invtapein ^ AUDIO_IN);
//assign      zxn_uart0_rx  = UART_RXd2;
//assign      UART_TX       = zxn_uart0_tx;
//`else
//assign      ear_port_i_qq = tzxplayer_running ? ~tzxplayer_audio : userport ? 1'b0 : (invtapein ^ UART_RXd2);
//assign      zxn_uart0_rx  = userport ? UART_RXd2 : 1'b0;
//assign      UART_TX       = userport ? zxn_uart0_tx : 1'b1;
`endif

endmodule

// From Recommended HDL Coding Styles, Quartus II 8.0 Handbook
module clock_mux (clk,clk_select,clk_out);
	parameter num_clocks = 4;
	input [num_clocks-1:0] clk;
	input [num_clocks-1:0] clk_select; // one hot
	output clk_out;
	genvar i;
	reg [num_clocks-1:0] ena_r0;
	reg [num_clocks-1:0] ena_r1;
	reg [num_clocks-1:0] ena_r2;
	wire [num_clocks-1:0] qualified_sel;
	// A look-up-table (LUT) can glitch when multiple inputs
	// change simultaneously. Use the keep attribute to
	// insert a hard logic cell buffer and prevent
	// the unrelated clocks from appearing on the same LUT.
	wire [num_clocks-1:0] gated_clks /* synthesis keep */;
	initial begin
		ena_r0 = 0;
		ena_r1 = 0;
		ena_r2 = 0;
	end
	generate
	for (i=0; i<num_clocks; i=i+1)
	begin : lp0
		wire [num_clocks-1:0] tmp_mask;

		assign qualified_sel[i] = clk_select[i] & (~|(ena_r2 & tmp_mask));
		always @(posedge clk[i]) begin
			ena_r0[i] <= qualified_sel[i];
			ena_r1[i] <= ena_r0[i];
		end
		always @(negedge clk[i]) begin
			ena_r2[i] <= ena_r1[i];
		end
		assign gated_clks[i] = clk[i] & ena_r2[i];
	end
	endgenerate
	// These will not exhibit simultaneous toggle by construction
	assign clk_out = |gated_clks;
endmodule

`ifdef I2S_AUDIO
module mist_i2s_master
(
	input        reset,
	input        clk,
	input [31:0] clk_rate,

	output reg sclk,
	output reg lrclk,
	output reg sdata,

	input [AUDIO_DW-1:0]	left_chan,
	input [AUDIO_DW-1:0]	right_chan
);

// Clock Setting
parameter I2S_Freq = 48_000;     // 48 KHz
parameter AUDIO_DW = 16;

localparam I2S_FreqX2 = I2S_Freq*2*AUDIO_DW*2;

reg  [31:0] cnt;
wire [31:0] cnt_next = cnt + I2S_FreqX2;

reg         ce;

always @(posedge clk) begin
	ce <= 0;
	cnt <= cnt_next;
	if(cnt_next >= clk_rate) begin
		cnt <= cnt_next - clk_rate;
		ce <= 1;
	end
end


always @(posedge clk) begin
	reg  [4:0] bit_cnt = 1;

	reg [AUDIO_DW-1:0] left;
	reg [AUDIO_DW-1:0] right;

	if (reset) begin
		bit_cnt <= 1;
		lrclk   <= 1;
		sclk    <= 1;
		sdata   <= 1;
		sclk    <= 1;
	end
	else begin
		if(ce) begin
			sclk <= ~sclk;
			if(sclk) begin
				if(bit_cnt == AUDIO_DW) begin
					bit_cnt <= 1;
					lrclk <= ~lrclk;
					if(lrclk) begin
						left  <= left_chan;
						right <= right_chan;
					end
				end
				else begin
					bit_cnt <= bit_cnt + 1'd1;
				end
				sdata <= lrclk ? right[AUDIO_DW - bit_cnt] : left[AUDIO_DW - bit_cnt];
			end
		end
	end
end

endmodule
`endif