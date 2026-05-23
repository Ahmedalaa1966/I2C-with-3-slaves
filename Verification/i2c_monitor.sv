// ============================================================
//  i2c_monitor.sv
//  Monitor — passively observes SDA/SCL using fast clock (clk_f)
//            detects START, STOP, data bits, and sends to scoreboard
// ============================================================
class i2c_monitor;

    // ─── virtual interface ────────────────────────────────────
    virtual i2c_if.monitor_mp vif;

    // ─── mailbox to scoreboard ────────────────────────────────
    mailbox #(i2c_transaction) mon2scb;

    // ─── internal state ───────────────────────────────────────
    logic SDA_d;   // delayed SDA for edge detection

    // ─── constructor ──────────────────────────────────────────
    function new(virtual i2c_if.monitor_mp vif,
                 mailbox #(i2c_transaction) mon2scb);
        this.vif     = vif;
        this.mon2scb = mon2scb;
        this.SDA_d   = 1'b1;
    endfunction

    // ─── main run task ────────────────────────────────────────
    task run();
        forever begin
            // wait for START condition using fast clock
            wait_for_start();
            // once START detected, capture full transaction
            capture_transaction();
        end
    endtask

    // ─── wait for START: SDA falls while SCL HIGH ─────────────
    task wait_for_start();
        logic SDA_prev;
        SDA_prev = 1'b1;
        forever begin
            @(vif.monitor_cb);
            if (SDA_prev == 1'b1 && vif.monitor_cb.SDA == 1'b0 && vif.monitor_cb.SCL == 1'b1) begin
                $display("[MONITOR] START condition detected at time %0t", $time);
                break;
            end
            SDA_prev = vif.monitor_cb.SDA;
        end
    endtask

    // ─── wait for STOP: SDA rises while SCL HIGH ──────────────
    task wait_for_stop();
        logic SDA_prev;
        SDA_prev = 1'b0;
        forever begin
            @(vif.monitor_cb);
            if (SDA_prev == 1'b0 && vif.monitor_cb.SDA == 1'b1 && vif.monitor_cb.SCL == 1'b1) begin
                $display("[MONITOR] STOP condition detected at time %0t", $time);
                break;
            end
            SDA_prev = vif.monitor_cb.SDA;
        end
    endtask

    // ─── sample one bit on posedge SCL ────────────────────────
    task sample_bit(output logic bit_val);
        // wait for SCL to go high (posedge)
        @(posedge vif.SCL);
        #1;
        bit_val = vif.SDA;
    endtask

    // ─── sample 8 bits MSB first ──────────────────────────────
    task sample_byte(output logic [7:0] byte_val);
        logic b;
        byte_val = 8'h00;
        repeat (8) begin
            sample_bit(b);
            byte_val = {byte_val[6:0], b};
        end
    endtask

    // ─── capture full I2C transaction ─────────────────────────
    task capture_transaction();
        i2c_transaction txn = new();
        logic [7:0] addr_rw_byte;
        logic       ack_bit;

        // sample address + R/W byte
        sample_byte(addr_rw_byte);
        txn.addr = addr_rw_byte[7:1];
        txn.op   = i2c_transaction::i2c_op_e'(addr_rw_byte[0]);

        // sample ACK after address
        sample_bit(ack_bit);
        txn.ack_received = ~ack_bit;  // ACK = SDA pulled LOW by slave

        $display("[MONITOR] addr=0x%02h op=%s ack=%b",
                  txn.addr, txn.op.name(), txn.ack_received);

        if (txn.op == i2c_transaction::WRITE) begin
            // sample data byte
            sample_byte(txn.data);
            sample_bit(ack_bit);  // ACK after data
            $display("[MONITOR] WRITE data=0x%02h", txn.data);
        end else begin
            // sample data sent by slave
            sample_byte(txn.read_data);
            sample_bit(ack_bit);  // NACK from master
            $display("[MONITOR] READ data=0x%02h", txn.read_data);
        end

        // wait for STOP
        wait_for_stop();

        // send to scoreboard
        mon2scb.put(txn.copy());
        $display("[MONITOR] Transaction sent to scoreboard");
    endtask

endclass : i2c_monitor
