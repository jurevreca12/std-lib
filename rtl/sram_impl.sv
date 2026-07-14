module sram_impl #(
  parameter   int     WORD_SIZE=32,
  parameter           MEM_INIT_FILE="",
  parameter   int     INIT_FILE_BIN=1,
  parameter   int     MEM_SIZE_WORDS = 2**12,
  // Dependent parameters, do not overwrite
  localparam  int     AddrWidth = $clog2(MEM_SIZE_WORDS),
  localparam  int     NBytes = (WORD_SIZE / 8)
) (
  input                        clk,
  input  logic [NBytes-1:0]    strobe,
  input  logic                 write,
  input  logic                 valid,
  input  logic [AddrWidth-1:0] addr,
  input  logic [WORD_SIZE-1:0] din,
  output logic [WORD_SIZE-1:0] dout
);

  // Generate bit mask for interleaving 2*32'b into 64'b
  logic [WORD_SIZE-1:0] bm;

  for(genvar i = 0; i < WORD_SIZE; ++i) begin: gen_bm_ports
    assign bm[i] = strobe[i/8];
  end

  // Generate desired SRAM with IHP primitives
  if(MEM_SIZE_WORDS == 2048 && WORD_SIZE == 32) begin: gen_2048x64xBx1
    logic [63:0] wdata64, rdata64, bm64;
    // logic sram_sel_d, sram_sel_q;
    logic [63:0] bm_q;

    always_comb begin : gen_bit_interleaving
      for(int i = 0; i < WORD_SIZE; i++) begin
        // duplicate each bit
        bm64[2*i]        = bm[i] & ~addr[0];
        bm64[2*i+1]      = bm[i] & addr[0];
        wdata64[2*i]     = din[i] & bm64[2*i]; // even bits (active if addr LSB is 0)
        wdata64[2*i+1]   = din[i] & bm64[2*i+1]; // odd bits  (active if addr LSB is 1)

        if(~addr[0]) begin
          dout[i] = rdata64[2*i] & bm_q[2*i];   // even bits
        end else begin
          dout[i] = rdata64[2*i+1] & bm_q[2*i+1]; // odd bits
        end
      end
    end

    

    always_ff @(posedge clk) begin: bm_assign
      if(valid & ~write) bm_q <= bm64;
    end

    // LSB needed for read in next cycle
    // assign sram_sel_d = addr[0];

    // always_ff @(posedge clk) begin : proc_mem_sel_q
    //   if(valid & ~write) sram_sel_q <= sram_sel_d;
    //   //else               sram_sel_q <= '0;
    // end

    RM_IHPSG13_1P_1024x64_c2_bm_bist mem_inst (
      .A_CLK        (clk),
      .A_DLY        (1'b1),
      .A_ADDR       (addr[10:1]),
      .A_BM         (bm64),
      .A_MEN        (valid),
      .A_WEN        (write),
      .A_REN        (~write),
      .A_DIN        (wdata64),
      .A_DOUT       (rdata64),
      .A_BIST_CLK   (1'b0),
      .A_BIST_ADDR  (11'd0),
      .A_BIST_DIN   (64'd0),
      .A_BIST_BM    (64'b0),
      .A_BIST_MEN   (1'b0),
      .A_BIST_WEN   (1'b0),
      .A_BIST_REN   (1'b0),
      .A_BIST_EN    (1'b0)
    );
  end
endmodule

