module register_wclear
#(
    parameter type DTYPE = logic,
    parameter DTYPE RESET_VALUE = 0
)
(
    input  logic clk,
    input  logic rstn,
    input  logic clear,
    input  logic ce,   // clock-enable
    input  DTYPE in,
    output DTYPE out
);

    always_ff @(posedge clk or negedge rstn) begin
        if (~rstn)
            out <= RESET_VALUE;
        else if (ce)
            out <= in;
    	else if (clear)
	    out <= '0;
    end
endmodule
