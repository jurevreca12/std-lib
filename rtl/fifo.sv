module fifo #(
    parameter type         dtype  = logic [7:0],
    parameter int unsigned DEPTH  = 4,
		parameter int unsigned ALMOST_FULL_DEPTH = 3

)(
    input  logic  clk_i,           
    input  logic  rstn_i,         
    
		input  dtype  input_data_i,
		input  logic  input_valid_i,
		output logic  input_ready_o,
    
		output dtype  output_data_o,
		output logic  output_valid_o,
		input  logic  output_ready_i,  
		
		output logic  full_o,
		output logic  almost_full_o,
    output logic  empty_o
);
		//$STATIC_ASSERT(DEPTH > 0);
    localparam int unsigned AddrWidth = $clog2(DEPTH);
		localparam type MemType = dtype [DEPTH-1:0];

		function automatic dtype incr(dtype cnt);
    		if (cnt == (DEPTH - 1))
    		    return '0;
    		else
    		    return cnt + 1;
		endfunction
		
		logic input_fire, output_fire;    

    logic mem_ce, counter_ce;

		logic [AddrWidth-1:0] readp, readp_next;
		logic [AddrWidth-1:0] writep, writep_next;    
		logic [AddrWidth:0]   counter, counter_next;
    
		MemType mem, mem_next;

    assign full_o        = (counter == DEPTH);
		assign almost_full_o = (counter == ALMOST_FULL_DEPTH);
    assign empty_o       = (counter == 0);

    assign input_ready_o  = !full_o;
    assign output_valid_o = !empty_o;

		assign input_fire  = input_valid_i && input_ready_o;
		assign output_fire = output_valid_o && output_ready_i;

		assign output_data_o = mem[readp];
		
    always_comb begin
        readp_next   = readp;
        writep_next  = writep;
        counter_next = counter;
        mem_next     = mem;
				mem_ce       = 1'b0;
				counter_ce   = 1'b0;
        if (input_fire) begin
            mem_next[writep] = input_data_i;
            mem_ce           = 1'b1;
            counter_next     = counter + 1;
						counter_ce       = 1'b1;
						writep_next      = incr(writep);
        end

				if (output_fire) begin
						readp_next   = incr(readp);
						counter_next = counter - 1;
						counter_ce   = 1'b1;
				end

				if (input_fire && output_fire) begin
						counter_next = counter;
						counter_ce   = 1'b0;
				end

    end

		register #(.DTYPE(logic [AddrWidth-1:0])) readp_reg (
			.clk(clk_i), .rstn(rstn_i), .ce(output_fire), .in(readp_next), .out(readp)
		);
		register #(.DTYPE(logic [AddrWidth-1:0])) writep_reg (
			.clk(clk_i), .rstn(rstn_i), .ce(input_fire), .in(writep_next), .out(writep)
		);
		register #(.DTYPE(logic [AddrWidth:0])) counter_reg (
			.clk(clk_i), .rstn(rstn_i), .ce(counter_ce), .in(counter_next), .out(counter)
		);

		register #(.DTYPE(MemType)) mem_reg (
			.clk(clk_i), .rstn(rstn_i), .ce(mem_ce), .in(mem_next), .out(mem)
		);
endmodule
