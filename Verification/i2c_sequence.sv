// Sequences (included by i2c_pkg.sv)

class i2c_base_sequence;
    i2c_sequencer seqr;
    function new(i2c_sequencer s); this.seqr = s; endfunction
    virtual task body(); endtask
endclass : i2c_base_sequence

// ss=1 → driver issues START before writing
// ss=0 → driver skips START (already inside a transaction)
class i2c_write_sequence extends i2c_base_sequence;
    logic [6:0] addr;
    logic [7:0] data;
    logic       ss  ;
    function new(i2c_sequencer s, logic [6:0] a, logic [7:0] d, logic ss_val = 1'b1);
        super.new(s);
        this.addr = a;
        this.data = d;
        this.ss   = ss_val;
    endfunction
    task body();
        i2c_transaction txn = new();
        txn.op   = i2c_transaction::WRITE;
        txn.addr = addr;
        txn.data = data;
        txn.ss   = ss;
        $display("[WRITE_SEQ] WRITE addr=0x%02h data=0x%02h ss=%b", addr, data, ss);
        seqr.send(txn);
    endtask
endclass : i2c_write_sequence

// ss=1 → driver issues STOP after reading
// ss=0 → driver skips STOP (more transactions follow)
class i2c_read_sequence extends i2c_base_sequence;
    logic [6:0] addr;
    logic       ss  ;
    function new(i2c_sequencer s, logic [6:0] a, logic ss_val = 1'b1);
        super.new(s);
        this.addr = a;
        this.ss   = ss_val;
    endfunction
    task body();
        i2c_transaction txn = new();
        txn.op   = i2c_transaction::READ;
        txn.addr = addr;
        txn.data = 8'h00;
        txn.ss   = ss;
        $display("[READ_SEQ] READ addr=0x%02h ss=%b", addr, ss);
        seqr.send(txn);
    endtask
endclass : i2c_read_sequence

class i2c_full_sequence extends i2c_base_sequence;
    function new(i2c_sequencer s); super.new(s); endfunction
    task body();
        i2c_write_sequence wr1, wr2, wr3;
        i2c_read_sequence  rd1, rd2, rd3;
        wr1 = new(seqr, 7'h66, 8'h56, 1'b1); wr1.body();
        wr2 = new(seqr, 7'h46, 8'hAA, 1'b1); wr2.body();
        wr3 = new(seqr, 7'h64, 8'hF0, 1'b1); wr3.body();
        rd1 = new(seqr, 7'h66,        1'b1); rd1.body();
        rd2 = new(seqr, 7'h46,        1'b1); rd2.body();
        rd3 = new(seqr, 7'h64,        1'b1); rd3.body();
    endtask
endclass : i2c_full_sequence

