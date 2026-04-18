`ifndef STD_LIB_ASSERTIONS_SVH
`define STD_LIB_ASSERTIONS_SVH

    `define STATIC_ASSERT(__cond, __msg = "")     \
    `ifdef __slang__                              \
	    $static_assert(__cond, __msg);        \
    `endif

`endif // STD_LIB_ASSERTIONS_SVH
