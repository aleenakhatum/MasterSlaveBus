`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/28/2025 03:19:04 PM
// Design Name: 
// Module Name: master
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
nput ports (from ARM except clk, clear): rst_i, clk_i, mem_req, mwr_arm, memoryRead, memoryWrite, addressBus[25:0]

Input ports (from WISHBONE slave module): dat_i[31:0], ack_i, tagn_i

Output ports (to WISHBONE slave module except phi1, phi2): adr_o[25:0], dat_o[31:0], we_o, stb_o, cyc_o, tagn_o

bidirectional ports: dataBus[31:0]

*/

module master(
    //General
    input rst_i,
    input clk_i,
    
    //From ARM
    input mem_req, 
    input memoryRead,
    input memoryWrite,
    input [25:0] addressBus,
    
    //From Slave
    input [31:0] dat_i,
    input ack_i,
    input tagn_i,
    
    //Output
    output wire [25:0] adr_o, 
    output wire [31:0] dat_o, 
    output reg we_o, 
    output reg stb_o, 
    output reg cyc_o, 
    output wire tagn_o,
    
    //Bidirectional 
    inout wire [31:0] dataBus
    );
    
    //Internal variables
    reg [1:0] state;
    reg [1:0] next_state;
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam WAIT = 2'b10;
    localparam DONE = 2'b11;
    
    //Read 
    assign adr_o = addressBus;
    assign dat_o = dataBus;
    assign dataBus = (memoryRead && mem_req) ? 32'bz : dataBus;
    assign tagn_o = 1'b0;
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            stb_o <= 1'b0;
            cyc_o <= 1'b0;
            we_o <= 1'b0;
        end
        else begin
            state <= next_state;
        end
        
        //States
        case (state)
            IDLE: begin
                if (mem_req == 1) begin
                    next_state = SETUP;
                end
            end

            SETUP: begin
                stb_o <= 1'b1;
                 cyc_o <= 1'b1;
                 next_state = WAIT; // always go to WAIT next cycle
                
                if (memoryRead == 1) begin
                    we_o <= 1'b0;
                end
                else if (memoryWrite == 1) begin
                    we_o <= 1'b1;
                end                
            end

            WAIT: begin
                stb_o = 1'b1;
                cyc_o = 1'b1;

                if (ack_i) begin
                    next_state = DONE;
                end
                else begin //wait until slave acknowledges
                    next_state = WAIT;
                end
            end

            DONE: begin
                //if (memoryRead == 1) begin
                //    dataBus <= dat_i;
                //end

                next_state = IDLE;
                stb_o <= 1'b0;
                cyc_o <= 1'b0;
            end

            default: begin
                next_state = IDLE;
                stb_o  <= 1'b0;
                cyc_o  <= 1'b0;
            end
        endcase
    end
endmodule
