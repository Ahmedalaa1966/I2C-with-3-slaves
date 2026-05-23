// Scoreboard (included by i2c_pkg.sv)
class i2c_scoreboard;

    mailbox #(i2c_transaction) drv2scb;
    mailbox #(i2c_transaction) mon2scb;

    logic [7:0] mem [logic [6:0]];
    int pass_count = 0;
    int fail_count = 0;

    function new(mailbox #(i2c_transaction) drv2scb,
                 mailbox #(i2c_transaction) mon2scb);
        this.drv2scb = drv2scb;
        this.mon2scb = mon2scb;
    endfunction

    task run();
        fork
            forever begin
                i2c_transaction drv_txn;
                drv2scb.get(drv_txn);
                check_driver(drv_txn);
            end
            forever begin
                i2c_transaction mon_txn;
                mon2scb.get(mon_txn);
                check_dut(mon_txn);
            end
        join_none
    endtask

    // Golden model from driver (intent + what the TB driver observed)
    task check_driver(i2c_transaction txn);
        if (txn.op == i2c_transaction::WRITE) begin
            mem[txn.addr] = txn.data;
            $display("[SCB] PASS: WRITE addr=0x%02h data=0x%02h (stored)", txn.addr, txn.data);
            pass_count++;
        end else begin
            if (!mem.exists(txn.addr)) begin
                $display("[SCB] FAIL: READ addr=0x%02h — no prior WRITE in model", txn.addr);
                fail_count++;
            end else if (mem[txn.addr] !== txn.read_data) begin
                $display("[SCB] FAIL: READ addr=0x%02h expected=0x%02h got=0x%02h",
                          txn.addr, mem[txn.addr], txn.read_data);
                fail_count++;
            end else begin
                $display("[SCB] PASS: READ addr=0x%02h data=0x%02h", txn.addr, txn.read_data);
                pass_count++;
            end
        end
    endtask

    // Optional cross-check: what monitor reconstructed on the bus vs model
    task check_dut(i2c_transaction mon_txn);
        if (mon_txn.op == i2c_transaction::WRITE) begin
            if (mem.exists(mon_txn.addr) && mem[mon_txn.addr] !== mon_txn.data)
                $display("[SCB] DUT WARN: WRITE addr=0x%02h bus=0x%02h model=0x%02h",
                          mon_txn.addr, mon_txn.data, mem[mon_txn.addr]);
        end else if (mem.exists(mon_txn.addr) && mem[mon_txn.addr] !== mon_txn.read_data)
            $display("[SCB] DUT WARN: READ addr=0x%02h bus=0x%02h model=0x%02h",
                      mon_txn.addr, mon_txn.read_data, mem[mon_txn.addr]);
    endtask

    function void report();
        $display("========================================");
        $display("[SCB] FINAL REPORT");
        $display("[SCB] PASS: %0d | FAIL: %0d", pass_count, fail_count);
        if (fail_count == 0) $display("[SCB] ALL TESTS PASSED");
        else                 $display("[SCB] SOME TESTS FAILED");
        $display("========================================");
    endfunction

endclass : i2c_scoreboard

