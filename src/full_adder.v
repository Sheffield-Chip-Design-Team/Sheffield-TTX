//Module: Full Adder Verilog Code
//Author(s): James Ashie Kotey 
//Last Updated:  8/5/24

module FullAdder(a,b,c, sum, carry);
    
    //Ports
    input a,b,c;
    output sum,carry;
    
    //Implimentation
    assign sum = (a^b)^ c;
    assign carry = (((a^b)&c) | (a&b)); // Use | for Or Not +

endmodule

