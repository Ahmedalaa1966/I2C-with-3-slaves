// Sequencer (included by i2c_pkg.sv)
class i2c_sequencer;

    mailbox #(i2c_transaction) seq2drv;

    function new(mailbox #(i2c_transaction) mbx);
        this.seq2drv = mbx;
    endfunction

    task send(i2c_transaction txn);
        seq2drv.put(txn);
        $display("[SEQUENCER] Sent txn: op=%s addr=0x%02h data=0x%02h ss=%b",
                  txn.op.name(), txn.addr, txn.data, txn.ss);
    endtask

endclass : i2c_sequencer

