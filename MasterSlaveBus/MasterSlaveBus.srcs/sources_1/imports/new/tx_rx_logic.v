`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2025 09:43:55 PM
// Design Name: 
// Module Name: tx_rx_logic
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


module tx_rx_logic(
        input CLEAR_B,
        input PCLK,
        input SSPCLKOUT,
        output reg SSPOE_B,
        
        //Tx
        input [7:0] TxData,//Tx parallel data in
        input tx_empty,
        input tx_full, //unused (should be used by processor)
        output reg SSPTXD,
        output reg SSPFSSOUT,
        output reg tx_read,
        
        //Rx
        input SSPFSSIN,
        input SSPRXD, //Rx serial data in
        input rx_empty,//unused (should be used by processor)
        input rx_full,
        output reg rx_write,
        output reg [7:0] rx_out
    );
    
    //tx
    localparam tx_IDLE = 2'b00;
    localparam tx_LOAD = 2'b01;
    localparam tx_SHIFT = 2'b10;
    reg [1:0] tx_state;
    reg [7:0] shift_reg;
    reg[3:0] bit_count_tx;
    
    //rx
    reg [3:0] bit_count_rx;
    localparam rx_IDLE = 2'b00;
    localparam rx_WAIT = 2'b01;
    localparam rx_SHIFT = 2'b10;
    reg [1:0] rx_state;
    reg [7:0] parallel_reg;
    
    wire CLEAR = ~CLEAR_B;
    
    always@(negedge SSPCLKOUT) begin
        if (tx_state == tx_SHIFT)begin
            SSPOE_B <= 1'b0;
        end
        else if (tx_state == tx_IDLE) begin 
            SSPOE_B <= 1'b1;
        end
    end
    
    //tx logic
    always@(posedge SSPCLKOUT) begin
        case (tx_state)
            tx_IDLE: begin
                SSPTXD <= 0;
                SSPFSSOUT <= 0;
                bit_count_tx <= 0;
                tx_read <= 0;     
                shift_reg <= 8'd0;      
                if (tx_empty == 0) begin //otherwise stay at IDLE state if tx_emtpy = 1
                    tx_state <= tx_LOAD;
                end
            end
            tx_LOAD: begin
                shift_reg <= TxData;
                SSPFSSOUT <= 1; //high for bit before msb
                bit_count_tx <= -1;
                tx_state <= tx_SHIFT;
                if (tx_empty == 0) begin
                    tx_read <= 1; //read next data from fifo if next data is available
                end
            end
            tx_SHIFT: begin
                tx_read <= 0;
                SSPFSSOUT <= 0; //low for all bits
                SSPTXD <= shift_reg[7]; //send 1 bit serially 
                shift_reg <= {shift_reg[6:0],1'b0};
                bit_count_tx <= bit_count_tx + 1;
                
                if (bit_count_tx == 6) begin
                    bit_count_tx <= 7;
                    if (tx_empty == 0) begin //more data to transmit
                        tx_read <= 1;
                        shift_reg <= TxData;
                        SSPFSSOUT <= 1; //high for lsb if there is a next data
                    end
                    else if (tx_empty == 1) begin //nothing else to read
                        SSPFSSOUT <= 0;
                    end
                end
                else if (bit_count_tx == 7) begin
                    bit_count_tx <= 0;
                    if (tx_empty == 0) begin //more data to transmit
                        tx_read <= 0;
                        tx_state <= tx_SHIFT;
                        SSPFSSOUT <= 0; 
                    end
                    else if (tx_empty == 1) begin //nothing else to read
                        tx_state <= tx_IDLE;
                    end
                end
            end
            default: begin
                tx_state <= tx_IDLE; 
            end
        endcase
    end
    
    //rx logic
    always@(posedge SSPCLKOUT) begin 
        case (rx_state)
            rx_IDLE: begin
                bit_count_rx <= 4'd8;   
                parallel_reg <= 8'd0; 
                rx_out <= 8'd0; 
                rx_write <= 1'b0;      
                if (rx_full == 0 && SSPFSSIN == 1) begin //otherwise stay at IDLE state if rx_full = 1
                    rx_state <= rx_SHIFT;
                    bit_count_rx <= 4'd7;
                end
                if (bit_count_rx == 4'd7)begin
                    rx_out <= parallel_reg;
                end
            end
            rx_WAIT: begin
                if (SSPFSSIN == 1) begin
                    bit_count_rx <= 4'd7;
                    rx_state <= rx_SHIFT;
                end
            end
            rx_SHIFT: begin
                bit_count_rx <= bit_count_rx - 1;
                parallel_reg[bit_count_rx] <= SSPRXD; //save 1 serial bit
                rx_write <= 0;
                if (bit_count_rx == 0) begin //done collecting all bits
                    rx_write <= 1; //write incoming parallel register to fifo
                    if (rx_full == 0 && SSPFSSIN == 1) begin //more data to transmit
                        rx_state <= rx_SHIFT;
                        bit_count_rx <= 4'd7;
                    end
                    else if (rx_full == 1 || SSPFSSIN == 0) begin //no more data to transmit
                        rx_state <= rx_IDLE;
                        rx_write <= 1;
                        bit_count_rx <= 4'd7;
                    end
                end
                else if (bit_count_rx == 7) begin
                    rx_out <= parallel_reg;
                end
            end
            default: begin
                rx_state <= rx_IDLE;
            end
        endcase
    end
endmodule