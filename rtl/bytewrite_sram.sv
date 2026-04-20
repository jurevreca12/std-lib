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
    parameter  string MEM_INIT_FILE="",
    parameter  int    INIT_FILE_BIN=1,
    parameter  int    MEM_SIZE_WORDS = 2**12,
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

initial begin
    string mem_init_file;
    if (MEM_INIT_FILE != "") begin
        if   (INIT_FILE_BIN==1) $readmemb(MEM_INIT_FILE, RAM, 0);
        else                    $readmemh(MEM_INIT_FILE, RAM, 0);
    end else begin
        $value$plusargs("MEM_INIT_FILE=%s", mem_init_file);
        if (mem_init_file != "") begin
            $display("Initializing memory with: %s", mem_init_file);
            if   (INIT_FILE_BIN==1) $readmemb(mem_init_file, RAM, 0);
            else                    $readmemh(mem_init_file, RAM, 0);
        end
    end
end


always @(posedge clk) begin
    if (valid)
        dout <= RAM[addr];
end

generate genvar i;
for (i = 0; i < NBytes; i = i+1)
begin: gen_per_byte_we
  always @(posedge clk) begin
      if (strobe[i] & write & valid)
          RAM[addr][8 * (i + 1) - 1 : i * 8] <= din[8 * (i + 1) - 1 : i * 8];
      end
  end
endgenerate
endmodule
