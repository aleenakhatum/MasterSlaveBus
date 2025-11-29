module TxFIFO (
    input PSEL,
    input PWRITE,
    input tx_read,
    input CLEAR_B,
    input PCLK,
    input wire [7:0] PWDATA,
    output wire [7:0] TxData,
    output wire full, //SSPTXINTR   
    output wire empty,
    output wire SSPTXINTR
);

    //local wires
    wire CLEAR = ~CLEAR_B;
    
    reg [7:0] fifo [3:0];
    reg [1:0] wptr, rptr;
    reg [2:0] count;
    
    assign full = (count == 4);
    assign empty = (count == 0);
    assign TxData = fifo[rptr];
    reg read_new;
    wire read_rising;
    
    assign read_rising = ~tx_read && read_new;
    assign SSPTXINTR = full;
    
    always @(posedge PCLK) begin
        if (CLEAR == 1'b1) begin
            wptr <= 2'd0;
            rptr <= 2'd0;
            count <= 3'd0;
            read_new <= 0;
            fifo[3] <= 8'd0;
            fifo[2] <= 8'd0;
            fifo[1] <= 8'd0;
            fifo[0] <= 8'd0;
        end
        else begin
            read_new <= tx_read;
        end
        
        if (PWRITE == 1'b1 && full == 1'b0 && PSEL == 1'b1) begin //write signal high
            fifo[wptr] <= PWDATA;
            wptr <= wptr + 1;
            count <= count + 1;
        end
        else if (read_rising == 1'b1 && empty == 1'b0) begin //read signal high
            rptr <= rptr + 1;
            count <= count - 1;
        end
    end
endmodule