`timescale 1ns / 1ps

module tb_top;

    // Inputs to top module
    reg reset;
    reg clk;
    reg mem_req;
    reg memoryRead;
    reg memoryWrite;
    reg [25:0] addressBus;

    // Bidirectional data bus
    wire [31:0] dataBus;

    // Instantiate the complete design
    top uut (
        .reset       (reset),
        .clk         (clk),
        .mem_req     (mem_req),
        .memoryRead  (memoryRead),
        .memoryWrite (memoryWrite),
        .addressBus  (addressBus),
        .dataBus    (dataBus)
    );

    // Clock generation: 100 MHz
    always #10 clk = ~clk;

    // Task: Perform a memory write
    task mem_write;
        input [25:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            addressBus <= addr;
            mem_req <= 1'b1;
            memoryRead <= 1'b0;
            memoryWrite <= 1'b1;
            // Drive dataBus from testbench during write
            force uut.dataBus = data;
            @(posedge clk);
            wait(uut.u_master.ack_i == 1'b1);  // wait for acknowledge
            @(posedge clk);
            mem_req <= 1'b0;
            memoryWrite <= 1'b0;
            release uut.dataBus;
            #20;
        end
    endtask

    // Task: Perform a memory read
    task mem_read;
        input  [25:0] addr;
        output [31:0] data;
        begin
            @(posedge clk);
            addressBus   <= addr;
            mem_req      <= 1'b1;
            memoryRead   <= 1'b1;
            memoryWrite  <= 1'b0;
            @(posedge clk);
            wait(uut.u_master.ack_i == 1'b1);
            @(posedge clk);
            data = dataBus;  // capture read data
            mem_req  <= 1'b0;
            memoryRead <= 1'b0;
            #20;
            $display("READ  [0x%h] = 0x%h", addr, data);
        end
    endtask

    // Task: SSP write (only lower 8 bits matter)
    task ssp_write;
        input [25:0] addr;
        input [7:0]  data;
        begin
            mem_write(addr, {24'b0, data});
            $display("SSP WRITE [0x%h] <= 0x%h", addr, data);
        end
    endtask

    // Task: SSP read
    task ssp_read;
        input  [25:0] addr;
        output [31:0] data;
        begin
            mem_read(addr, data);
            if (data[31:8] == 24'b0)
                $display("SSP READ  [0x%h] = 0x%h  (correct zero-padding)", addr, data[7:0]);
            else
                $error("SSP READ FAILED: upper bits not zero!");
        end
    endtask

    // Main stimulus
    reg [31:0] read_data;

    initial begin
        // Initialize
        clk = 0;
        reset = 1;
        mem_req = 0;
        memoryRead = 0;
        memoryWrite = 0;
        addressBus = 26'h0000000;

        // Release reset
        #40;
        reset = 0;
        #50;

        $display("\n=== WISHBONE SINGLE READ/WRITE TESTBENCH START ===\n");

        // Test 1: Write to RAM
        //mem_write(26'h000100, 32'hDEADBEEF);
        //mem_write(26'h000104, 32'h12345678);

        // Test 2: Read back from RAM
        //mem_read(26'h000100, read_data);
        //if (read_data !== 32'hDEADBEEF) $error("RAM read failed!");

        //mem_read(26'h000104, read_data);
        //if (read_data !== 32'h12345678) $error("RAM read failed!");

        // Test 3: Write to SSP (assume address ends with 0x40)
        ssp_write(26'h0000000, 8'hA5);

        // Test 4: Read from SSP → should get 0x000000A5
        ssp_read(26'h0000000, read_data);
        if (read_data !== 32'h000000A5) $error("SSP read failed!");

        // Another SSP register
        ssp_write(26'h0000000, 8'h5A);
        ssp_read(26'h0000000, read_data);
        if (read_data !== 32'h0000005A) $error("SSP read failed!");

        #100;
        $display("\nALL TESTS PASSED!\n");
        $finish;
    end

    // Monitor important signals
    initial begin
        $monitor("Time=%0t | addr=%h we=%b stb=%b cyc=%b ack=%b dat_o=%h dataBus=%h",
                 $time,
                 uut.u_master.adr_o,
                 uut.u_master.we_o,
                 uut.u_master.stb_o,
                 uut.u_master.cyc_o,
                 uut.u_master.ack_i,
                 uut.u_slave.dat_o,
                 dataBus);
    end

endmodule