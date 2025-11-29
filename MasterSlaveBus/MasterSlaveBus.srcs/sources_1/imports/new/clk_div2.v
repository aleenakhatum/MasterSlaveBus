module clk_div2(input PCLK, input reset, output reg SSPCLKOUT);
    always @(posedge PCLK) begin
        if (reset) begin
            SSPCLKOUT <= 1'b0;
        end
        else begin
            SSPCLKOUT <= ~SSPCLKOUT;
        end
    end 
endmodule
