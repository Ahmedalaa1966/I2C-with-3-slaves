// Common helpers used across TB classes (included by i2c_pkg.sv)

// Slave PISO sends rd_data[7:0] MSB-first on the wire; some sampling paths
// assemble LSB-first and need bit reversal.
function automatic logic [7:0] reverse_bits(input logic [7:0] b);
    for (int i = 0; i < 8; i++)
        reverse_bits[i] = b[7-i];
endfunction

