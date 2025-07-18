module float2int ( // FCVT.WU.S
    input logic [31:0] floatIn,
    input logic [2:0] rm,
    output logic [31:0] result
);

    logic [7:0] exp;
    logic [7:0] shiftval;
    logic signed [7:0]  shiftExp;
    logic [22:0] man;
    logic [22:0] frac;
    logic [54:0] FP;
    logic [54:0] Fpres;
    logic [54:0] Fpres_norm;
    logic S ,G ,R, NaN, inf, overflow;

    assign exp = floatIn [30:23];
    assign man = floatIn[22:0];
    assign shiftExp = exp - 8'd127;    
    assign shiftval = (shiftExp<0) ? -shiftExp :shiftExp;    
    assign FP = {31'd0,(exp != 0),man};  // 1.0000 + man = 1.man  ->  subnormal 0.00
    assign S = (Fpres==0)? (|FP[23:0]) : (|Fpres[20:0]);   
    assign G = Fpres[22];
    assign R = Fpres[21];
    assign NaN = (man > 23'h000000 && exp == 8'b11111111);
    assign inf = (man == 23'd0 && exp == 8'b11111111);
    assign overflow = (exp >= 8'b10011111); //including Nan and inf
    // assign overflow = (exp >= 8'b10011111); //including Nan and inf

    always_comb begin

            if(shiftExp > 0) begin
                Fpres = FP << shiftval;
            end
            else if(shiftExp < 0) begin
                Fpres = FP >> shiftval;
            end
            else begin  
                Fpres = FP;
            end
            // if (inf || NaN) begin
            //     result = 32'hffffffff;
            // end

            if(inf || NaN || overflow) begin
                if(floatIn[31] & !NaN)
                result = 32'd0;//-flow -> no negative values in unsigned-integer
                else
                result = 32'hffffffff;//+flow
            end else if(floatIn[31]) begin
                result = 32'd0;
            end
            else begin
            case (rm)
                3'b000: begin // **RNE: Round to Nearest, Ties to Even**
                    if (G) begin
                        if (R || S || Fpres[23]) begin
                            result = Fpres[54:23] + 1; // Round up
                        end else begin
                            result = Fpres[54:23]; // Keep as is
                        end
                    end else begin
                        result = Fpres[54:23]; // No rounding needed
                    end
                end

                3'b001: begin // **RTZ: Round Toward Zero (Truncate)**
                    result = Fpres[54:23];
                end

                3'b010: begin // **RDN: Round Down (-∞)**
                    result = Fpres[54:23]; // Same as RTZ for unsigned integers
                end

                3'b011: begin // **RUP: Round Up (+∞)**
                    if (G || R || S) begin
                        result = Fpres[54:23] + 1; // Round up
                    end else begin
                        result = Fpres[54:23];
                    end
                end

                3'b100: begin
                    if (G) begin
                        result = Fpres[54:23] + 1;
                    end
                    else
                        result = Fpres[54:23];
                end
                default : 
                begin 
                        result = Fpres[54:23];
                end
                endcase
            end
    end

endmodule
