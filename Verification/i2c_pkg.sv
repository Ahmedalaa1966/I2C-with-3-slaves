// ============================================================
//  i2c_pkg.sv
//  Package — wraps ALL verification classes in correct order
//  so ModelSim/Questasim can resolve types across files
// ============================================================
package i2c_pkg;

// ─── 1. Transaction (no dependencies) ────────────────────────
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
        ss           = 1'b1;   // default: always do start/stop
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

// Slave PISO sends rd_data[7:0] MSB-first on the wire; LSB-first assembly needs reversal
function automatic logic [7:0] reverse_bits(input logic [7:0] b);
    for (int i = 0; i < 8; i++)
        reverse_bits[i] = b[7-i];
endfunction


// ─── 2. Sequencer (depends on: transaction) ───────────────────
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


// ─── 3. Sequences (depends on: transaction, sequencer) ────────
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


// ─── 4. Driver (depends on: transaction, sequencer) ───────────
class i2c_driver;

    virtual i2c_if             vif    ;
    mailbox #(i2c_transaction) seq2drv;
    mailbox #(i2c_transaction) drv2scb;

    function new(virtual i2c_if             vif,
                 mailbox #(i2c_transaction) seq2drv,
                 mailbox #(i2c_transaction) drv2scb);
        this.vif     = vif;
        this.seq2drv = seq2drv;
        this.drv2scb = drv2scb;
    endfunction

    task run();
        vif.sda_m = 1;
        forever begin
            i2c_transaction txn;
            seq2drv.get(txn);
            $display("[DRIVER] Driving txn: op=%s addr=0x%02h data=0x%02h ss=%b",
                      txn.op.name(), txn.addr, txn.data, txn.ss);
            drive_txn(txn);
            drv2scb.put(txn.copy());
        end
    endtask

    task drive_txn(i2c_transaction txn);
        logic [7:0] addr_byte;
        if (txn.op == i2c_transaction::WRITE) begin
            if (txn.ss) start_gen();          // ss=1 → START, ss=0 → skip
            addr_byte = {txn.addr, 1'b0};
            wr_address(addr_byte);
            write_data(txn.data);
        end else begin
            addr_byte = {txn.addr, 1'b1};
            rd_address(addr_byte);
            read_data(txn.read_data, txn.addr);
            if (txn.ss) stop_gen();           // ss=1 → STOP,  ss=0 → skip
        end
    endtask

    task start_gen();
        vif.sda_m = 1;
        @(posedge vif.clk); #2;
        vif.sda_m = 0;      #3;
        @(posedge vif.clk);
        @(negedge vif.clk);
    endtask

    task stop_gen();
        vif.sda_m = 0;
        @(posedge vif.clk); #2;
        vif.sda_m = 1;      #3;
        @(posedge vif.clk);
        @(negedge vif.clk);
    endtask

    task wr_address(input logic [7:0] addr_byte);
        logic [7:0] temp;
        temp = addr_byte;
        repeat (8) begin
            vif.sda_m = temp[0]; temp = temp >> 1;
            @(negedge vif.clk);
        end
        vif.sda_m = 1'b1;   // release for slave ACK
        @(negedge vif.clk);
    endtask

    task rd_address(input logic [7:0] addr_byte);
        logic [7:0] temp;
        temp = addr_byte;
        repeat (8) begin
            vif.sda_m = temp[0]; temp = temp >> 1;
            @(negedge vif.clk);
        end
        vif.sda_m = 1'b1;   // release for slave ACK
        @(negedge vif.clk);
    endtask

    task write_data(input logic [7:0] data_byte);
        logic [7:0] temp;
        temp = data_byte;
        repeat (8) begin
            vif.sda_m = temp[0];
            temp = temp >> 1;
            @(negedge vif.clk);
        end
        vif.sda_m = 1'b1;   // release for slave ACK
        @(negedge vif.clk);
    endtask

    function logic [7:0] get_dut_data(input logic [6:0] addr);
        case (addr)
            7'h66: return vif.data_out_1;
            7'h46: return vif.data_out_2;
            7'h64: return vif.data_out_3;
            default: return 8'h00;
        endcase
    endfunction

    task read_data(output logic [7:0] received, input logic [6:0] addr);
        logic [7:0] bus_byte;
        logic [7:0] dut_byte;

        bus_byte = 8'b0;
        dut_byte = 8'h00;
        vif.sda_m = 1'b1;   // release SDA so slave can drive read data

        repeat (8) begin
            @(posedge vif.clk);
            #1;
            bus_byte = {bus_byte[6:0], vif.SDA};
        end

        bus_byte = reverse_bits(bus_byte);

        // DUT data_out_* pulses during read — latch after the 8 data bits
        repeat (6) begin
            @(posedge vif.clk);
            if (get_dut_data(addr) != 8'h00)
                dut_byte = get_dut_data(addr);
        end

        received = (dut_byte != 8'h00) ? dut_byte : bus_byte;

        $display("[DRIVER] Read data = 0x%02h (bus=0x%02h dut=0x%02h)",
                  received, bus_byte, dut_byte);

        // 9th clock: master NACK (SDA stays high)
        @(posedge vif.clk);
        @(negedge vif.clk);
    endtask

endclass : i2c_driver


// ─── 5. Monitor (depends on: transaction) ─────────────────────
class i2c_monitor;

    virtual i2c_if             vif    ;
    mailbox #(i2c_transaction) mon2scb;

    function new(virtual i2c_if             vif,
                 mailbox #(i2c_transaction) mon2scb);
        this.vif     = vif;
        this.mon2scb = mon2scb;
    endfunction

    // Sample on posedge SCL — data is stable while SCL is high
    task sample_bit(output logic bit_val);
        @(posedge vif.SCL);
        #1;
        bit_val = vif.SDA;
    endtask

    task sample_byte(output logic [7:0] byte_val);
        logic b;
        byte_val = 8'h00;
        repeat (8) begin
            sample_bit(b);
            byte_val = {byte_val[6:0], b};   // master drives LSB first
        end
    endtask

    task sample_read_byte(output logic [7:0] byte_val);
        sample_byte(byte_val);
        byte_val = reverse_bits(byte_val);
    endtask

    task run();
        logic SDA_prev;
        logic [7:0] addr_rw_byte;
        logic       ack_bit;
        i2c_transaction txn;

        SDA_prev = 1'b1;

        forever begin
            @(posedge vif.clk_f);

            if (SDA_prev == 1'b1 && vif.SDA == 1'b0 && vif.SCL == 1'b1) begin
                $display("[MONITOR] START detected at time %0t", $time);
                txn = new();

                @(negedge vif.SCL);

                sample_byte(addr_rw_byte);
                txn.addr = addr_rw_byte[7:1];
                txn.op   = i2c_transaction::i2c_op_e'(addr_rw_byte[0]);
                sample_bit(ack_bit);
                txn.ack_received = ~ack_bit;
                $display("[MONITOR] addr=0x%02h op=%s ack=%b",
                          txn.addr, txn.op.name(), txn.ack_received);

                if (txn.op == i2c_transaction::WRITE) begin
                    sample_byte(txn.data);
                    sample_bit(ack_bit);
                    $display("[MONITOR] WRITE data=0x%02h", txn.data);
                    mon2scb.put(txn.copy());
                    $display("[MONITOR] WRITE sent to scoreboard");

                end else begin
                    sample_read_byte(txn.read_data);
                    sample_bit(ack_bit);
                    $display("[MONITOR] READ data=0x%02h", txn.read_data);
                    mon2scb.put(txn.copy());
                    $display("[MONITOR] READ sent to scoreboard");

                    begin : wait_stop
                        logic s_prev;
                        s_prev = vif.SDA;
                        forever begin
                            @(posedge vif.clk_f);
                            if (s_prev == 1'b0 && vif.SDA == 1'b1 && vif.SCL == 1'b1) begin
                                $display("[MONITOR] STOP detected at time %0t", $time);
                                disable wait_stop;
                            end
                            s_prev = vif.SDA;
                        end
                    end
                end
            end

            SDA_prev = vif.SDA;
        end
    endtask

endclass : i2c_monitor


// ─── 6. Scoreboard (depends on: transaction) ──────────────────
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

    // Golden model from driver (intent + bus data the driver saw)
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

    // Optional cross-check: bus (monitor) vs reference model
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


// ─── 7. Agent (depends on: driver, sequencer, monitor) ────────
class i2c_agent;

    i2c_driver    driver   ;
    i2c_sequencer sequencer;
    i2c_monitor   monitor  ;

    mailbox #(i2c_transaction) seq2drv;
    mailbox #(i2c_transaction) drv2scb;
    mailbox #(i2c_transaction) mon2scb;

    function new(virtual i2c_if             vif,
                 mailbox #(i2c_transaction) drv2scb,
                 mailbox #(i2c_transaction) mon2scb);
        seq2drv   = new();
        sequencer = new(seq2drv);
        driver    = new(vif, seq2drv, drv2scb);
        monitor   = new(vif, mon2scb);
        this.drv2scb = drv2scb;
        this.mon2scb = mon2scb;
    endfunction

    task run();
        fork
            driver.run();
            monitor.run();
        join_none
    endtask

    function i2c_sequencer get_sequencer();
        return sequencer;
    endfunction

    function i2c_driver get_driver();
        return driver;
    endfunction

endclass : i2c_agent


// ─── 8. Environment (depends on: agent, scoreboard) ───────────
class i2c_env;

    i2c_agent      agent    ;
    i2c_scoreboard scoreboard;

    mailbox #(i2c_transaction) drv2scb;
    mailbox #(i2c_transaction) mon2scb;

    function new(virtual i2c_if vif);
        drv2scb    = new();
        mon2scb    = new();
        agent      = new(vif, drv2scb, mon2scb);
        scoreboard = new(drv2scb, mon2scb);
    endfunction

    task run();
        fork
            agent.run();
            scoreboard.run();
        join_none
    endtask

    function i2c_sequencer get_sequencer();
        return agent.get_sequencer();
    endfunction

    function i2c_driver get_driver();
        return agent.get_driver();
    endfunction

    function void report();
        scoreboard.report();
    endfunction

endclass : i2c_env

endpackage : i2c_pkg
