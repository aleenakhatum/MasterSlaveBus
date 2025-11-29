`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2025 07:13:11 PM
// Design Name: 
// Module Name: slave
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
/* 
Input ports: rst_i, clk_i, dat_i[31:0], adr_i[25:0], tagn_i, we_i, stb_i, cyc_i
Output ports: mem_adr_o[25:0], mem_r_o, mem_w_o, ssp_sel_o, ssp_w_o, dat_o[31:0], tagn_o, ack_o
bidirectional ports: dataBus[31:0]
*/

module slave(
    //Input
    input rst_i, 
    input clk_i, 
    input [31:0] dat_i, 
    input [25:0] adr_i, 
    input tagn_i, 
    input we_i, 
    input stb_i, 
    input cyc_i,
    
    //Output
    output wire [25:0] mem_adr_o, 
    output wire mem_r_o, 
    output wire mem_w_o, 
    output wire ssp_sel_o, 
    output wire ssp_w_o, 
    output wire [31:0] dat_o, 
    output wire tagn_o, 
    output wire ack_o,
    
    //Bidirectional
    inout wire [31:0] dataBus
    );
    
    assign mem_adr_o = adr_i;
    assign dataBus = (we_i) ? dat_i : 32'bz; 
    assign dat_o = dataBus;
    assign ack_o = (stb_i == 1 && cyc_i == 1) ? 1'b1 : 1'b0;
    
    // SSP select
    wire is_ssp = (adr_i == 26'h0010001) || (adr_i == 26'h0010000);
    wire w = (adr_i == 26'h0010000);
    wire r = (adr_i == 26'h0010001);
    wire master_transmit = (stb_i == 1 && cyc_i == 1);
    
    //Access SSP
    assign ssp_sel_o = is_ssp && master_transmit ? 1'b1 : 1'b0;
    assign ssp_w_o = w & !r ? 1'b1 : 1'b0;
    
    //Access Mem
    assign mem_r_o = !is_ssp && master_transmit && !we_i ? 1'b1 : 1'b0;
    assign mem_w_o = 1'b0; //never write to memory
    
    
    /*
    always@(posedge clk_i) begin
        if (rst_i == 1) begin
            mem_r_o <= 1'b0;
            mem_w_o <= 1'b0;
        end
        else begin
            if (stb_i == 1 && cyc_i == 1) begin
            
                //Access SSP
                if (is_ssp == 1) begin
                    if (we_i == 1) begin //write
                        mem_w_o <= 1'b0; //don't access mem
                        ssp_sel_o <= 1'b1; //goes to PSEL in SSP
                        ssp_w_o <= 1'b1; //goes to PWRITE in SSP (write)
                    end
                    else if (we_i == 0) begin //read
                        mem_r_o <= 1'b0; //don't access mem
                        ssp_sel_o <= 1'b1; //goes to PSEL in SSP
                        ssp_w_o <= 1'b0; //goes to PWRITE in SSP (read)
                    end 
                end
                
                //Access Memory
                else begin
                    //we never write to mem
                    if (we_i == 1) begin //write
                        mem_w_o <= 1'b1;
                        mem_r_o <= 1'b0;
                        ssp_sel_o <= 1'b0; //goes to PSEL in SSP
                    end
                    else if (we_i == 0) begin //read
                        mem_r_o <= 1'b1;
                        mem_w_o <= 1'b0;
                        ssp_sel_o <= 1'b0; //goes to PSEL in SSP
                    end 
                end
            end
        end
    end
    */
endmodule
