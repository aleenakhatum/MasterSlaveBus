module fifo4_8(
    input reset,
    input clk,
    input select,
    input write,
    input read,
    input wire [7:0] data_in,
    output wire full,
    output wire empty, //unused
    output wire [7:0] data_out
    );
    
    reg [7:0] fifo [3:0];
    reg [1:0] wptr, rptr;
    reg [2:0] count;
    
    assign full = (count == 4);
    assign empty = (count == 0);
    assign data_out = fifo[rptr];
    reg read_new;
    wire read_rising;
    //reg write_new;
    //wire write_rising;
    
    assign read_rising = ~read && read_new;
    //assign write_rising = ~write && write_new;
    
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            wptr <= 2'd0;
            rptr <= 2'd0;
            count <= 3'd0;
            read_new <= 0;
        end
        else begin
            read_new <= read;
            //write_new <= write;
        end
        
        if (write == 1'b1 && full == 1'b0) begin //write signal high
            fifo[wptr] <= data_in;
            wptr <= wptr + 1;
            count <= count + 1;
        end
        else if (read_rising == 1'b1 && empty == 1'b0) begin //read signal high
            rptr <= rptr + 1;
            count <= count - 1;
        end
    end
endmodule 