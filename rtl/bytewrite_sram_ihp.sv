// Single-Port BRAM with Byte-wide Write Enable
// Read-First mode
// Single-process description
// Compact description of the write with a generate-for 
//   statement
// Column width and number of columns easily configurable
//
// bytewrite_ram_1b.v
//

module bytewrite_sram #(
    parameter  int    WORD_SIZE=32,
    parameter         MEM_INIT_FILE="",
    parameter  int    INIT_FILE_BIN=1,
    parameter  int    MEM_SIZE_WORDS = 2048,
    localparam int    AddrWidth = $clog2(MEM_SIZE_WORDS),
    localparam int    NBytes = (WORD_SIZE / 8)
)(
    input                        clk,
    input  logic [NBytes-1:0]    strobe,
    input  logic                 write,
    input  logic                 valid,
    input  logic [AddrWidth-1:0] addr,
    input  logic [WORD_SIZE-1:0] din,
    output logic [WORD_SIZE-1:0] dout
);

logic [WORD_SIZE-1:0] RAM [MEM_SIZE_WORDS];

  sram_impl #(
    .WORD_SIZE     (WORD_SIZE),
    .MEM_INIT_FILE (MEM_INIT_FILE),
    .INIT_FILE_BIN (INIT_FILE_BIN),
    .MEM_SIZE_WORDS(MEM_SIZE_WORDS)
  ) sram_impl_i (
    .clk   (clk),
    .strobe(strobe),
    .write (write),
    .valid (valid),
    .addr  (addr),
    .din   (din),
    .dout  (dout)
  );

endmodule

