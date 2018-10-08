`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/02/2018 06:44:26 PM
// Design Name: 
// Module Name: mfp_ahb_display
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mfp_ahb_display(
    input                        HCLK,
    input                        HRESETn,
    input      [ 31          :0] HADDR,
    input      [  1          :0] HTRANS,
    input      [ 31          :0] HWDATA,
    input                        HWRITE,
    input                        HSEL,
    output reg [ 31          :0] HRDATA,
    
    // memory-mapped I/O
    output [7:0] disenout,
    output [7:0] disout
    );
    
    reg  [31:0]  HADDR_d;
    reg         HWRITE_d;
    reg         HSEL_d;
    reg  [1:0]  HTRANS_d;
    wire        we;            // write enable

    reg [7:0] en;
    reg [63:0] digits;
    reg [7:0] dp;
    
    // delay HADDR, HWRITE, HSEL, and HTRANS to align with HWDATA for writing
    always @ (posedge HCLK) 
    begin
      HADDR_d  <= HADDR;
      HWRITE_d <= HWRITE;
      HSEL_d   <= HSEL;
      HTRANS_d <= HTRANS;
    end

//assign registers en, dp, and digits based on LT-LITE DATA-BUS here

// overall write enable signal
  assign we = (HTRANS_d != `HTRANS_IDLE) & HSEL_d & HWRITE_d;
    always @(posedge HCLK or negedge HRESETn)
       
       if (~HRESETn) begin
         en <= 8'hff; //enable low, defaults to off
         digits <= 64'hffffffffffffffff; //all blanks
         dp <= 8'hff; 
       end else if (we)
         case (HADDR_d)
           `H_DIS_EN_ADDR: en <= HWDATA[7:0];
           `H_DIS_DIGL_ADDR: digits[31:0] <= HWDATA;
           `H_DIS_DIGH_ADDR: digits[63:32] <= HWDATA;
           `H_DIS_DP_ADDR: dp <= HWDATA[7:0];
           default: begin
            en <= en;
            digits <= digits;
            dp <= dp;
           end
         endcase

mfp_ahb_sevensegtimer sevensegtimer(.clk(HCLK),     
       .resetn(HRESETn),  
       .EN(en),      
       .DIGITS(digits),  
       .dp(dp),      
       .DISPENOUT(disenout),
       .DISPOUT(disout));

endmodule
