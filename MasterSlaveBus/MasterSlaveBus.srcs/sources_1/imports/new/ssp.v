`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2025 09:26:00 PM
// Design Name: 
// Module Name: ssp
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


module ssp(
    input PCLK, 
    input CLEAR_B, 
    input PSEL,
    input PWRITE,
    input [7:0] PWDATA,
    input SSPCLKIN,
    input SSPFSSIN,
    input SSPRXD,
    output wire [7:0] PRDATA,
    output wire SSPTXINTR,
    output wire SSPRXINTR,
    output wire SSPOE_B,
    output wire SSPTXD,
    output wire SSPFSSOUT,
    output wire SSPCLKOUT
    );
    
    //Internal Wires
    wire [7:0] TxData;   // output of TxFIFO -> tx_rx_logic
    wire tx_read;        //from tx_rx_logic -> TxFIFO
    wire tx_empty;
    wire tx_full;
    
    wire [7:0] RxData;   // from tx_rx_logic → RxFIFO
    wire rx_write;       // from tx_rx_logic → RxFIFO
    wire rx_full;
    wire rx_empty;
    
    wire ssp_clk;        // PCLK divided by 2
    
    
    // Clock divider (PCLK → SSPCLKOUT = PCLK/2)
    clk_div2 u_clkdiv (
        .PCLK(PCLK),
        .reset(~CLEAR_B),
        .SSPCLKOUT(ssp_clk)
    );
    assign SSPCLKOUT = ssp_clk;

    //Instantiate tx fifo
    TxFIFO u_TxFIFO(
        .PSEL(PSEL),
        .PWRITE(PWRITE && ~tx_full),
        .tx_read(tx_read),
        .CLEAR_B(CLEAR_B),
        .PCLK(PCLK),
        .PWDATA(PWDATA),
        .TxData(TxData),
        .full(tx_full),
        .empty(tx_empty),
        .SSPTXINTR(SSPTXINTR)  
    );
    
    //Instantiate rx fifo
    RxFIFO u_RxFIFO (
        .PCLK(PCLK),
        .CLEAR_B(CLEAR_B),
        .PSEL(PSEL),
        .rx_read(~PWRITE),
        .PRDATA(PRDATA),
        .rx_write(rx_write),
        .RxData(RxData),
        .empty(rx_empty),
        .full(rx_full),
        .SSPRXINTR(SSPRXINTR)
    );
    
    //Instantiate tx_rx_logic
    tx_rx_logic u_tx_rx (
        .CLEAR_B    (CLEAR_B),
        .PCLK       (PCLK),
        .SSPCLKOUT  (ssp_clk),
        .SSPOE_B    (SSPOE_B),

        // Tx
        .TxData     (TxData),      
        .tx_empty   (tx_empty),
        .tx_full    (tx_full),
        .SSPTXD     (SSPTXD),
        .SSPFSSOUT  (SSPFSSOUT),
        .tx_read    (tx_read),

        // Rx
        .SSPFSSIN   (SSPFSSIN),
        .SSPRXD     (SSPRXD),
        .rx_empty   (rx_empty),    
        .rx_full    (rx_full),
        .rx_write   (rx_write),
        .rx_out     (RxData)
    );
    
endmodule
