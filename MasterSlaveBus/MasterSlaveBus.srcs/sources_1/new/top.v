`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2025 10:24:53 PM
// Design Name: 
// Module Name: top
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


module top(
      input reset,
      input clk,
      input mem_req,
      input memoryRead,
      input memoryWrite,
      input [25:0] addressBus,           
      inout [31:0] dataBus,
      output SSPOE_B
    );
    
    wire dat_o_m;
    wire adr_o_m;
    wire we_o_m;
    wire stb_o_m;
    wire cyc_o_m;
    
    master u_master(
        //General
        .rst_i(clear_o),
        .clk_i(clk),
    
        //From ARM
        .mem_req(mem_req),
        .memoryRead(memoryRead),
        .memoryWrite(memoryWrite),
        .addressBus(addressBus),
    
        //From Slave
        .dat_i(dat_o_s),
        .ack_i(ack_o_s),
        .tagn_i(),
    
        //Output
        .adr_o(adr_o_m), 
        .dat_o(data_o_m), 
        .we_o(we_o_m), 
        .stb_o(stb_o_m), 
        .cyc_o(cyc_o_m),
        .tagn_o(),
    
        //Bidirectional 
        .dataBus(dataBus)
    );
    
    wire mem_adr_o_s;
    wire dataBus_s;
    wire mem_r_o_s;
    wire mem_w_o_s;
    wire ssp_sel_o_s;
    wire ssp_w_o_s; 
    wire ack_o_s;   
    wire dat_o_s;
    
    slave u_slave(
        .rst_i(clear_o), 
        .clk_i(clk), 
        .dat_i(dat_o_m), 
        .adr_i(adr_o_m),
        .tagn_i(), 
        .we_i(we_o_m), 
        .stb_i(stb_o_m), 
        .cyc_i(cyc_o_m),
        
        //Output
        .mem_adr_o(mem_adr_o_s), 
        .mem_r_o(mem_r_o_s), 
        .mem_w_o(mem_w_o_s), 
        .ssp_sel_o(ssp_sel_o_s), 
        .ssp_w_o(ssp_w_o_s), 
        .dat_o(dat_o_s), 
        .tagn_o(), 
        .ack_o(ack_o_s),
        
        //Bidirectional
        .dataBus(dataBus_s)
    );
    
    wire phi1; //output of cmu
    wire phi2; //output of cmu
    wire pclk; //output of cmu 
    wire clear_o;
    
    cmu u_cmu(
        .clear_i(reset),
        .clk_i(clk),
        .ssp_intr_i(),
        .phi1(phi1),
        .phi2(phi2),
        .clk_o(pclk),
        .clear_o(clear_o)
    );
    
    memory u_memory(
        .dataBus(dataBus_s), 
        .addressBus(mem_adr_o_s), 
        .r(mem_r_o_s), 
        .w(mem_w_o_s), 
        .phi1(phi1), 
        .phi2(phi2)
    );
    
    wire SSPCLKIN_OUT;
    wire SSPFSSIN_OUT;
    wire SSPTXD_RXD;
    wire SSPTXINTR;
    wire SSPRXINTR;
    
    ssp u_ssp(
        .PCLK(pclk), 
        .CLEAR_B(~clear_o), 
        .PSEL(ssp_sel_o_s),
        .PWRITE(ssp_w_o_s),
        .PWDATA(dataBus_s),
        .SSPCLKIN(SSPCLKIN_OUT),
        .SSPFSSIN(SSPFSSIN_OUT),
        .SSPRXD(SSPTXD_RXD),
        .PRDATA(dataBus_s),
        .SSPTXINTR(SSPTXINTR),
        .SSPRXINTR(SSPRXINTR),
        .SSPOE_B(SSPOE_B),
        .SSPTXD(SSPTXD_RXD),
        .SSPFSSOUT(SSPFSSIN_OUT),
        .SSPCLKOUT(SSPCLKIN_OUT)
    );
endmodule
