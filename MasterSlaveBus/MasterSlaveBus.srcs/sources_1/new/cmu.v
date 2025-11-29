module  cmu (
        input clear_i,
        input clk_i,
        input [1:0] ssp_intr_i,
        output reg phi1,
        output reg phi2,
        output wire clk_o,
        output wire clear_o
);
        reg [1:0] count;
        wire stall;
        assign clear_o = clear_i;
        assign clk_o = clk_i;
        assign stall = ssp_intr_i[1]; //bit 1 = SSPTXINTR, bit 0 = SSPRXINTR

        always@(posedge clk_i or posedge clear_i) begin
                if (clear_i == 1'b1) begin
                        phi1 <= 1'b0;
                        phi2 <= 1'b0;
                        count <= 2'b00;
                end
                else begin
                        if (!stall) begin
                                count <= count + 1;
                        end
                        else begin //otherwise, stall signal is on (must stop phi1 and phi2)
                                phi1 <= 1'b0;
                                phi2 <= 1'b0;
                        end

                        //Generate phi1 and phi2 depending on the count
                        case (count)
                                2'b00: begin
                                        phi1 <= 1'b1;
                                        phi2 <= 1'b0;
                                end

                                2'b01: begin
                                        phi1 <= 1'b0;
                                        phi2 <= 1'b0;
                                end

                                2'b10: begin
                                        phi1 <= 1'b0;
                                        phi2 <= 1'b1;
                                end

                                2'b11: begin
                                        phi1 <= 1'b0;
                                        phi2 <= 1'b0;
                                end

                                default: begin
                                        phi1 <= 1'b0;
                                        phi2 <= 1'b0;
                                end
                        endcase
                end
        end
endmodule
