// mfp_nexys4_ddr.v
// January 1, 2017
//
// Instantiate the mipsfpga system and rename signals to
// match the GPIO, LEDs and switches on Digilent's (Xilinx)
// Nexys4 DDR board

// Outputs:
// 16 LEDs (IO_LED) 
// Inputs:
// 16 Slide switches (IO_Switch),
// 5 Pushbuttons (IO_PB): {BTNU, BTND, BTNL, BTNC, BTNR}
//

`include "mfp_ahb_const.vh"

module mfp_nexys4_ddr( 
                        input                   CLK100MHZ,
                        input                   CPU_RESETN,
                        input                   BTNU, BTND, BTNL, BTNC, BTNR, 
                        input  [`MFP_N_SW-1 :0] SW,         
                        output [`MFP_N_LED-1:0] LED,
                        inout  [ 8          :1] JB,
                        input                   UART_TXD_IN,
                        output                  CA,CB,CC,CD,CE,CF,CG,DP,
                        output [7:0]            AN);

  // Press btnCpuReset to reset the processor. 
        
  wire clk_out; 
  wire tck_in, tck;
  
  clk_wiz_0 clk_wiz_0(.clk_in1(CLK100MHZ), .clk_out1(clk_out));
  IBUF IBUF1(.O(tck_in),.I(JB[4]));
  BUFG BUFG1(.O(tck), .I(tck_in));
     
  wire [5:0] pbtn_db;
  wire [15:0] switch_db;
  wire [7:0] dispenout;
  wire [7:0] dispout;
  wire [31:0] haddr;
  wire [31:0] hrdata;
  wire [31:0] hwdata;
  wire hwrite;
  wire [5:0] pbtn_in;
  
  assign pbtn_in[5] = CPU_RESETN;
  assign pbtn_in[4] = BTNC;
  assign pbtn_in[3] = BTNU;
  assign pbtn_in[2] = BTND;
  assign pbtn_in[1] = BTNL;
  assign pbtn_in[0] = BTNR;
  
  assign CA = dispout[7];
  assign CB = dispout[6];
  assign CC = dispout[5];
  assign CD = dispout[4];
  assign CE = dispout[3];
  assign CF = dispout[2];
  assign CG = dispout[1];
  assign DP = dispout[0];
  
  assign AN = dispenout;
  //assign AN = dispout;
                                        
  debounce debounce(
                                 .clk(clk_out),
                                 .pbtn_in(pbtn_in),
                                 .switch_in(SW),
                                 .pbtn_db(pbtn_db),
                                 .swtch_db(switch_db));
                                                                                 
  mfp_sys mfp_sys(
                                                            .SI_Reset_N(pbtn_db[5]),
                                                            .SI_ClkIn(clk_out),
                                                            .HADDR(haddr),
                                                            .HRDATA(hrdata),
                                                            .HWDATA(hwdata),
                                                            .HWRITE(hwrite),
                                                            .HSIZE(),
                                                            .EJ_TRST_N_probe(JB[7]),
                                                            .EJ_TDI(JB[2]),
                                                            .EJ_TDO(JB[3]),
                                                            .EJ_TMS(JB[1]),
                                                            .EJ_TCK(tck),
                                                            .SI_ColdReset_N(JB[8]),
                                                            .EJ_DINT(1'b0),
                                                            .IO_Switch(switch_db),
                                                            .IO_PB(pbtn_db[4:0]),
                                                            .IO_LED(LED),
                                                            .disenout(dispenout),
                                                            .disout(dispout),
                                                            .UART_RX(UART_TXD_IN));

endmodule
