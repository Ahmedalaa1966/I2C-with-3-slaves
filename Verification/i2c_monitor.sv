// Monitor (included by i2c_pkg.sv)
class i2c_monitor;

    virtual i2c_if.monitor_mp   vif;
    mailbox #(i2c_transaction)  mon2scb;

    function new(virtual i2c_if.monitor_mp  vif,
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

    // Sample 8 bits as observed on bus into LSB-first assembly
    task sample_byte(output logic [7:0] byte_val);
        logic b;
        byte_val = 8'h00;
        repeat (8) begin
            sample_bit(b);
            byte_val = {byte_val[6:0], b};
        end
    endtask

    // Slave read data is MSB-first; this helper fixes ordering.
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
                end

                // Wait for STOP (for logging / alignment)
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

            SDA_prev = vif.SDA;
        end
    endtask

endclass : i2c_monitor
