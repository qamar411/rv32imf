module program_counter #(
    parameter MAX_LIMIT = 800 // ignored in the current implementation
)(
    input logic clk, 
    input logic reset_n, 
    input logic en,
    input logic [31:0] next_pc_if1, 
    output logic [31:0] current_pc_if1
);

    always_ff @(posedge clk, negedge reset_n) 
    begin 
        if(~reset_n)
`ifdef BOOT
                    current_pc_if1 <= 32'h00000000; // base address ROM
`elsif PD_BUILD
                    current_pc_if1 <= 32'h00000000; // base address ROM
`elsif VIVADO_SIM
                    current_pc_if1 <= 32'h80000000; // base address ROM
`elsif VCS_SIM
                    current_pc_if1 <= 32'h80000000; // base address ROM
`else
                    current_pc_if1 <= 32'h00000000; // base address ROM
`endif
        else if (en)
            current_pc_if1 <=  next_pc_if1;
            else 
            current_pc_if1 <= current_pc_if1; 
    end
    
endmodule