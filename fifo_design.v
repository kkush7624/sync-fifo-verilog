// Synchronous FIFO with almost full/empty and count signals
module fifo_sync #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 8,
    parameter ADDR_WIDTH = $clog2(FIFO_DEPTH),
    parameter ALMOST_FULL_THRESHOLD = FIFO_DEPTH - 1,
    parameter ALMOST_EMPTY_THRESHOLD = 1
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   wr_en,
    input  wire                   rd_en,
    input  wire [DATA_WIDTH-1:0]  data_in,
    output reg  [DATA_WIDTH-1:0]  data_out,
    output wire                   full,
    output wire                   empty,
    output reg  [ADDR_WIDTH:0]    fifo_count,
    output wire                   almost_full,
    output wire                   almost_empty
);

    // Internal registers
    reg [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    reg [ADDR_WIDTH:0]   wr_ptr, rd_ptr;

    // Write pointer and data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read pointer and data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            data_out <= 0;
        end else begin
            if (rd_en && !empty) begin
                data_out <= mem[rd_ptr[ADDR_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1;
            end else if (rd_en && empty) begin
                data_out <= 0; // Underflow protection
            end
            // Simultaneous read/write
            if (wr_en && rd_en && !full && !empty) begin
                data_out <= mem[rd_ptr[ADDR_WIDTH-1:0]];
                rd_ptr <= rd_ptr + 1;
            end
        end
    end

    // FIFO count logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_count <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: fifo_count <= fifo_count + 1; // Write only
                2'b01: fifo_count <= fifo_count - 1; // Read only
                2'b11: fifo_count <= fifo_count;     // Simultaneous read/write
                default: fifo_count <= fifo_count;   // No operation or invalid
            endcase
        end
    end

    // Status flags
    assign empty = (fifo_count == 0);
    assign full = (fifo_count == FIFO_DEPTH);
    assign almost_empty = (fifo_count <= ALMOST_EMPTY_THRESHOLD);
    assign almost_full = (fifo_count >= ALMOST_FULL_THRESHOLD);

endmodule