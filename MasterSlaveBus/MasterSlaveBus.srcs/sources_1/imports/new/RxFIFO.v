module RxFIFO (
    input PSEL,
    input rx_write,
    input rx_read, //read when ~PWRITE
    input CLEAR_B,
    input PCLK,
    input wire [7:0] RxData,
    output wire [7:0] PRDATA,
    output wire full,   
    output wire empty, 
    output wire SSPRXINTR
);

    //local wires
    wire CLEAR = ~CLEAR_B;

    
    reg [7:0] fifo [3:0];
    reg [1:0] wptr, rptr;
    reg [2:0] count;
    
    assign full = (count == 4);
    assign empty = (count == 0);
    assign PRDATA = fifo[rptr];
    reg read_new;
    wire read_rising;
    reg write_new;
    wire write_rising;
    
    assign SSPRXINR = full;
    assign read_rising = ~rx_read && read_new;
    assign write_rising = ~rx_write && write_new;
    
    always @(posedge PCLK) begin
        if (CLEAR == 1'b1) begin
            wptr <= 2'd0;
            rptr <= 2'd0;
            count <= 3'd0;
            read_new <= 0;
        end
        else begin
            read_new <= rx_read;
            write_new <= rx_write;
        end
        
        if (write_rising == 1'b1 && full == 1'b0) begin //write signal high
            fifo[wptr] <= RxData;
            wptr <= wptr + 1;
            count <= count + 1;
        end
        else if (read_rising == 1'b1 && empty == 1'b0) begin //read signal high
            rptr <= rptr + 1;
            count <= count - 1;
        end
    end    
endmodule