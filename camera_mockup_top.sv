module i2c_controller_test (
    //output clk,
    //inout   sda,
    output scl,
    input  slv_sda_in,
    output slv_sda_oe,
    output slv_sda_out,
    input  slv_scl,
    output user_led1,
    input  pll_inst1_CLKOUT0, //100
    input pll_inst1_CLKOUT1, //10 Mhz
    input pll_inst1_CLKOUT2, //1 Mhz
    input  user_button0,
    input  user_button1,
    
    /* Signals used by the MIPI TX Interface Designer instance */
	input         tx_pixel_clk,    
	output        MIPI_TX1_DPHY_RSTN,
	output        MIPI_TX1_RSTN,
	output        MIPI_TX1_VALID,
	output        MIPI_TX1_HSYNC,
	output        MIPI_TX1_VSYNC,
	output [63:0] MIPI_TX1_DATA,
	output [5:0]  MIPI_TX1_TYPE,
	output [1:0]  MIPI_TX1_LANES,
	output        MIPI_TX1_FRAME_MODE,
	output [15:0] MIPI_TX1_HRES,
	output [1:0]  MIPI_TX1_VC,
	output [3:0]  MIPI_TX1_ULPS_ENTER,
	output [3:0]  MIPI_TX1_ULPS_EXIT,
	output        MIPI_TX1_ULPS_CLK_ENTER,
	output        MIPI_TX1_ULPS_CLK_EXIT
);

reg rst;


i2c u_i2c(
    .SCL(slv_scl),
    .SDA_o(slv_sda_out),
    .SDA_oe(slv_sda_oe),
    .SDA_i(slv_sda_in),
    .RST(rst)
    );

reg [31:0] cnt;
reg user_led1;
initial
begin
    cnt <= 0;
    user_led1 <= 1;
    rst <= 1;
end

always @(posedge pll_inst1_CLKOUT1)
begin
    cnt <= cnt + 32'b1;
    if (cnt > 1000) begin
        user_led1 <= 0;
        rst <= 0;
    end
end


reg [31:0] cnt_100_msec;
always @(posedge pll_inst1_CLKOUT0)
begin
    cnt_100_msec <= cnt_100_msec + 32'b1;
    if (cnt_100_msec == 10000000) begin
        cnt_100_msec <= 0;
    end
end

assign scl = cnt[27];

parameter [3:0] STATE_IDLE      = 4'h0,
                STATE_FS        = 4'h1,
                STATE_HLINE     = 4'h2,
                STATE_HLINE_D   = 4'h3,
                STATE_FE        = 4'h4,
                STATE_HLINE_END = 4'h5;

assign rst_n = !rst;
reg [2:0]       mipi_tx_state;
reg vsync;
reg hsync;
reg valid_h;
reg [63:0] tx_pixel_data; 

reg [31:0] tx_cnt;
reg [9:0] px_cnt;
always @(posedge tx_pixel_clk) begin
  if (~rst_n) begin
     tx_pixel_data <= 64'b0;
     vsync <= 0;
     hsync <= 0;
     valid_h <= 0;
     mipi_tx_state <= STATE_IDLE;
     tx_cnt <= 0;
     px_cnt <= 0;
  end
  else begin
     tx_cnt++;
     case (mipi_tx_state)
        STATE_IDLE:
                begin
                    vsync <= 0;
                    if (tx_cnt == 1000) mipi_tx_state <= STATE_FS;
                end
        STATE_FS:
                begin
                    vsync <= 1;
                    if (tx_cnt == 1002)  mipi_tx_state <= STATE_HLINE;
                end
        STATE_HLINE:
                begin
                    hsync <= 1;
                    px_cnt <= 0;
                    if (tx_cnt == 1100)  mipi_tx_state <= STATE_HLINE_D;
                end
        STATE_HLINE_D:
                begin
                    px_cnt++;
                    tx_pixel_data <= {px_cnt, px_cnt, px_cnt, px_cnt, px_cnt, px_cnt};
                    valid_h <= 1;
                    if (tx_cnt == 1100+(600/6))  mipi_tx_state <= STATE_HLINE_END;
                end
        STATE_HLINE_END:
                begin
                    valid_h <= 0;
                    if (tx_cnt == 1100+(600/6)+100)  mipi_tx_state <= STATE_FE;
                end
        STATE_FE:
                begin
                    hsync <= 0;
                    if (tx_cnt == 1100+(600/6)+100+10000) begin
                        mipi_tx_state <= STATE_IDLE;
                        tx_cnt <= 0;
                    end
                end
     endcase
  end
end

//***************
// MIPI TX HOOKUP
//***************

assign MIPI_TX1_DPHY_RSTN = rst_n;
assign MIPI_TX1_RSTN = rst_n;
assign MIPI_TX1_VALID = valid_h;
assign MIPI_TX1_HSYNC = hsync;
assign MIPI_TX1_VSYNC = vsync;
assign MIPI_TX1_DATA = tx_pixel_data;
assign MIPI_TX1_TYPE =  6'h2B;// raw10 6'h2A;// raw8
assign MIPI_TX1_LANES = 2'b01;                // 2 lanes
assign MIPI_TX1_FRAME_MODE = 1'b0;            // Generic Frame Mode
assign MIPI_TX1_HRES = 600;         // Number of pixels per line
assign MIPI_TX1_VC = 2'b00;                   // Virtual Channel select
assign MIPI_TX1_ULPS_ENTER = 4'b0000;
assign MIPI_TX1_ULPS_EXIT = 4'b0000;
assign MIPI_TX1_ULPS_CLK_ENTER = 1'b0;
assign MIPI_TX1_ULPS_CLK_EXIT = 1'b0;


endmodule
