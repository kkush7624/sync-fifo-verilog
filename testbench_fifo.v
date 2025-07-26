`timescale 1ns / 1ns
module fifo_tb;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 8;
    parameter ADDR_WIDTH = $clog2(FIFO_DEPTH);
    parameter CLK_PERIOD = 10;

    // Signals
    reg                  clk = 0;
    reg                  rst_n = 0;
    reg                  wr_en = 0;
    reg                  rd_en = 0;
    reg [DATA_WIDTH-1:0] data_in;
    wire [DATA_WIDTH-1:0] data_out;
    wire                 full, empty, almost_full, almost_empty;
    wire [ADDR_WIDTH:0]  fifo_count;

    // DUT instantiation
    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .rd_en(rd_en),
        .data_in(data_in), .data_out(data_out),
        .full(full), .empty(empty),
        .almost_full(almost_full), .almost_empty(almost_empty),
        .fifo_count(fifo_count)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        $dumpfile("fifo_tb.vcd");
        $dumpvars(0, fifo_tb);
        $display("===================================");
        $display("=== FIFO SIMULATION STARTED ===");
        $display("===================================");

        // Initialize signals
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;

        // Test Case 1: Reset FIFO
        $display("\n=== TEST CASE 1: RESET FIFO ===");
        #20 rst_n = 1;
        @(posedge clk);
        $display("Status at Time=%0t ns:", $time);
        $display("-----------------------------------");
        $display("rst_n=%b | wr_en=%b | rd_en=%b | data_in=%h | data_out=%h | fifo_count=%d",
                rst_n, wr_en, rd_en, data_in, data_out, fifo_count);
        $display("Flags: empty=%b | full=%b | almost_empty=%b | almost_full=%b",
                empty, full, almost_empty, almost_full);
        $display("Expected: *empty=1, full=0, almost_empty=1, almost_full=0, fifo_count=0*");
        $display("Actual:   empty=%b, full=%b, almost_empty=%b, almost_full=%b, fifo_count=%d",
                empty, full, almost_empty, almost_full, fifo_count);
        $display("-----------------------------------");

        // Test Case 2: Write until almost full
        $display("\n=== TEST CASE 2: WRITE UNTIL ALMOST FULL ===");
        repeat(FIFO_DEPTH-1) begin
            @(posedge clk);
            wr_en = 1;
            data_in = data_in + 1;
            $display("Time=%0t ns: WRITE - data_in=%h | fifo_count=%d",
                    $time, data_in, fifo_count);
        end
        @(posedge clk) wr_en = 0;
        $display("-----------------------------------");
        $display("Status at Time=%0t ns:", $time);
        $display("rst_n=%b | wr_en=%b | rd_en=%b | data_in=%h | data_out=%h | fifo_count=%d",
                rst_n, wr_en, rd_en, data_in, data_out, fifo_count);
        $display("Flags: empty=%b | full=%b | almost_empty=%b | almost_full=%b",
                empty, full, almost_empty, almost_full);
        $display("Expected: *empty=0, full=0, almost_empty=0, almost_full=1, fifo_count=7*");
        $display("Actual:   empty=%b, full=%b, almost_empty=%b, almost_full=%b, fifo_count=%d",
                empty, full, almost_empty, almost_full, fifo_count);
        $display("-----------------------------------");

        // Test Case 3: Write to full and attempt overflow
        $display("\n=== TEST CASE 3: WRITE TO FULL AND ATTEMPT OVERFLOW ===");
        @(posedge clk);
        wr_en = 1;
        data_in = data_in + 1;
        $display("Time=%0t ns: WRITE - data_in=%h | fifo_count=%d",
                $time, data_in, fifo_count);
        @(posedge clk);
        wr_en = 1; // Overflow attempt
        data_in = 8'hFF;
        $display("Time=%0t ns: *OVERFLOW ATTEMPT* - data_in=%h | fifo_count=%d",
                $time, data_in, fifo_count);
        @(posedge clk) wr_en = 0;
        $display("-----------------------------------");
        $display("Status at Time=%0t ns:", $time);
        $display("rst_n=%b | wr_en=%b | rd_en=%b | data_in=%h | data_out=%h | fifo_count=%d",
                rst_n, wr_en, rd_en, data_in, data_out, fifo_count);
        $display("Flags: empty=%b | full=%b | almost_empty=%b | almost_full=%b",
                empty, full, almost_empty, almost_full);
        $display("Expected: *empty=0, full=1, almost_empty=0, almost_full=1, fifo_count=8*");
        $display("Actual:   empty=%b, full=%b, almost_empty=%b, almost_full=%b, fifo_count=%d",
                empty, full, almost_empty, almost_full, fifo_count);
        $display("-----------------------------------");

        // Test Case 4: Read until almost empty
        $display("\n=== TEST CASE 4: READ UNTIL ALMOST EMPTY ===");
        repeat(FIFO_DEPTH-1) begin
            @(posedge clk);
            rd_en = 1;
            @(posedge clk);
            $display("Time=%0t ns: READ - data_out=%h | fifo_count=%d",
                    $time, data_out, fifo_count);
            rd_en = 0;
        end
        $display("-----------------------------------");
        $display("Status at Time=%0t ns:", $time);
        $display("rst_n=%b | wr_en=%b | rd_en=%b | data_in=%h | data_out=%h | fifo_count=%d",
                rst_n, wr_en, rd_en, data_in, data_out, fifo_count);
        $display("Flags: empty=%b | full=%b | almost_empty=%b | almost_full=%b",
                empty, full, almost_empty, almost_full);
        $display("Expected: *empty=0, full=0, almost_empty=1, almost_full=0, fifo_count=1*");
        $display("Actual:   empty=%b, full=%b, almost_empty=%b, almost_full=%b, fifo_count=%d",
                empty, full, almost_empty, almost_full, fifo_count);
        $display("-----------------------------------");

        // Test Case 5: Read to empty and attempt underflow
        $display("\n=== TEST CASE 5: READ TO EMPTY AND ATTEMPT UNDERFLOW ===");
        @(posedge clk);
        rd_en = 1;
        @(posedge clk);
        $display("Time=%0t ns: READ - data_out=%h | fifo_count=%d",
                $time, data_out, fifo_count);
        rd_en = 0;
        @(posedge clk);
        rd_en = 1; // Underflow attempt
        @(posedge clk);
        $display("Time=%0t ns: *UNDERFLOW ATTEMPT* - data_out=%h | fifo_count=%d",
                $time, data_out, fifo_count);
        @(posedge clk) rd_en = 0;
        $display("-----------------------------------");
        $display("Status at Time=%0t ns:", $time);
        $display("rst_n=%b | wr_en=%b | rd_en=%b | data_in=%h | data_out=%h | fifo_count=%d",
                rst_n, wr_en, rd_en, data_in, data_out, fifo_count);
        $display("Flags: empty=%b | full=%b | almost_empty=%b | almost_full=%b",
                empty, full, almost_empty, almost_full);
        $display("Expected: *empty=1, full=0, almost_empty=1, almost_full=0, fifo_count=0*");
        $display("Actual:   empty=%b, full=%b, almost_empty=%b, almost_full=%b, fifo_count=%d",
                empty, full, almost_empty, almost_full, fifo_count);
        $display("-----------------------------------");

        // Test Case 6: Simultaneous read and write
        $display("\n=== TEST CASE 6: SIMULTANEOUS READ AND WRITE ===");
        // Write one element first
        @(posedge clk);
        wr_en = 1;
        data_in = 8'h10;
        $display("Time=%0t ns: WRITE - data_in=%h | fifo_count=%d",
                $time, data_in, fifo_count);
        @(posedge clk) wr_en = 0;
        repeat(3) begin
            @(posedge clk);
            wr_en = 1;
            rd_en = 1;
            data_in = data_in + 1;
            @(posedge clk);
            $display("Time=%0t ns: SIM R/W - data_in=%h | data_out=%h | fifo_count=%d",
                    $time, data_in, data_out, fifo_count);
            wr_en = 0;
            rd_en = 0;
        end
        $display("-----------------------------------");
        $display("Status at Time=%0t ns:", $time);
        $display("rst_n=%b | wr_en=%b | rd_en=%b | data_in=%h | data_out=%h | fifo_count=%d",
                rst_n, wr_en, rd_en, data_in, data_out, fifo_count);
        $display("Flags: empty=%b | full=%b | almost_empty=%b | almost_full=%b",
                empty, full, almost_empty, almost_full);
        $display("Expected: *fifo_count remains stable during simultaneous read/write*");
        $display("Actual:   fifo_count=%d", fifo_count);
        $display("-----------------------------------");

        // End simulation
        #20 $display("===================================");
        $display("=== SIMULATION COMPLETE ===");
        $display("===================================");
        $finish;
    end

    // Monitor for debugging 
    initial begin
        $monitor("Time=%0t ns | rst_n=%b | wr_en=%b | rd_en=%b | data_in=%h | data_out=%h | fifo_count=%d",
                 $time, rst_n, wr_en, rd_en, data_in, data_out, fifo_count);
    end

endmodule