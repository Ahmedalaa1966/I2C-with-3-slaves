// Transaction class (included by i2c_pkg.sv)
class i2c_transaction;

    typedef enum logic { WRITE = 1'b0, READ = 1'b1 } i2c_op_e;

    rand i2c_op_e    op          ;
    rand logic [6:0] addr        ;
    rand logic [7:0] data        ;
    logic            ack_received;
    logic [7:0]      read_data   ;

    // ss: for WRITE → 1 = issue START before,  0 = no START
    //     for READ  → 1 = issue STOP  after,   0 = no STOP
    logic            ss          ;

    constraint valid_addr_c {
        addr inside {7'h66, 7'h46, 7'h64};
    }

    function new();
        op           = WRITE;
        addr         = 7'h00;
        data         = 8'h00;
        ack_received = 1'b0;
        read_data    = 8'h00;
        ss           = 1'b1;
    endfunction

    function void print(string tag = "TXN");
        $display("[%s] op=%s addr=0x%02h data=0x%02h ack=%b read_data=0x%02h ss=%b",
                  tag, op.name(), addr, data, ack_received, read_data, ss);
    endfunction

    function i2c_transaction copy();
        i2c_transaction t = new();
        t.op           = this.op;
        t.addr         = this.addr;
        t.data         = this.data;
        t.ack_received = this.ack_received;
        t.read_data    = this.read_data;
        t.ss           = this.ss;
        return t;
    endfunction

endclass : i2c_transaction

