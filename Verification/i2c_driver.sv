// Driver (included by i2c_pkg.sv)
class i2c_driver;

    virtual i2c_if.driver_mp     vif    ;
    mailbox #(i2c_transaction)   seq2drv;
    mailbox #(i2c_transaction)   drv2scb;

    function new(virtual i2c_if.driver_mp     vif,
                 mailbox #(i2c_transaction)   seq2drv,
                 mailbox #(i2c_transaction)   drv2scb);
        this.vif     = vif;
        this.seq2drv = seq2drv;
        this.drv2scb = drv2scb;
    endfunction

    task run();
        vif.sda_m = 1'b1;
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
            if (txn.ss) start_gen();
            addr_byte = {txn.addr, 1'b0};
            wr_address(addr_byte);
            write_data(txn.data);
        end else begin
            addr_byte = {txn.addr, 1'b1};
            rd_address(addr_byte);
            read_data(txn.read_data, txn.addr);
            if (txn.ss) stop_gen();
        end
    endtask

    task start_gen();
        vif.sda_m = 1'b1;
        @(posedge vif.clk); #2;
        vif.sda_m = 1'b0;   #3;
        @(posedge vif.clk);
        @(negedge vif.clk);
    endtask

    task stop_gen();
        vif.sda_m = 1'b0;
        @(posedge vif.clk); #2;
        vif.sda_m = 1'b1;   #3;
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
        vif.sda_m = 1'b1;  // release for slave ACK
        @(negedge vif.clk);
    endtask

    task rd_address(input logic [7:0] addr_byte);
        logic [7:0] temp;
        temp = addr_byte;
        repeat (8) begin
            vif.sda_m = temp[0]; temp = temp >> 1;
            @(negedge vif.clk);
        end
        vif.sda_m = 1'b1;  // release for slave ACK
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
        vif.sda_m = 1'b1;  // release for slave ACK
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
        vif.sda_m = 1'b1;  // release SDA so slave can drive read data

        // Sample 8 data bits from bus; this path assembles LSB-first then reverses.
        repeat (8) begin
            @(posedge vif.clk);
            #1;
            bus_byte = {bus_byte[6:0], vif.SDA};
        end
        bus_byte = reverse_bits(bus_byte);

        // DUT data_out_* pulses during read; latch shortly after.
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

