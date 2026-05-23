// ============================================================
//  i2c_master_tb_top.sv
// ============================================================
//`include "i2c_interface.sv"
//`include "i2c_pkg.sv"

module i2c_master_tb_top;

    import i2c_pkg::*;

    logic clk  ;
    logic clk_f;
    logic rst_n;

    initial clk   = 0;
    always  #10 clk   = ~clk;

    initial clk_f = 0;
    always  #5  clk_f = ~clk_f;

    logic slave_driving_w;

    logic [7:0] data_out_1, data_out_2, data_out_3;
    logic [6:0] addr_out_1, addr_out_2, addr_out_3;

    i2c_if dut_if (.clk(clk), .clk_f(clk_f), .rst_n(rst_n),
                   .slave_driving(slave_driving_w),
                   .data_out_1(data_out_1),
                   .data_out_2(data_out_2),
                   .data_out_3(data_out_3));

    I2C_controller DUT (
        .SCL           (dut_if.SCL)        ,
        .SDA           (dut_if.SDA)        ,
        .sda_m         (dut_if.sda_m)      ,
        .clk           (clk_f)             ,
        .rst_n         (rst_n)             ,
        .data_out_1    (data_out_1)        ,
        .data_out_2    (data_out_2)        ,
        .data_out_3    (data_out_3)        ,
        .addr_out_1    (addr_out_1)        ,
        .addr_out_2    (addr_out_2)        ,
        .addr_out_3    (addr_out_3)        ,
        .slave_driving (slave_driving_w)
    );

    initial begin
        $monitor("Time=%0t | data_out_1=0x%0h | data_out_2=0x%0h | data_out_3=0x%0h",
                  $time, data_out_1, data_out_2, data_out_3);
    end

    initial begin
        #100000;
        $display("TIMEOUT");
        $stop;
    end

    initial begin
        $dumpfile("i2c_tb.vcd");
        $dumpvars(0, i2c_master_tb_top);
    end

    i2c_env       env ;
    i2c_sequencer seqr;

    initial begin
        rst_n        = 0;
        dut_if.sda_m = 1;
        repeat (2) @(negedge clk);
        #2;
        rst_n = 1;

        env  = new(dut_if);
        seqr = env.get_sequencer();
        env.run();

        begin
            i2c_write_sequence wr;
            i2c_read_sequence  rd;

            // =========================================================
            // ROUND 1
            // =========================================================

            $display("\n========== ROUND 1 ==========\n");

            // ---------------- SLAVE 1 ----------------
            $display("=== WRITE slave 1 ===");
            wr = new(seqr, 7'b1100_110, 8'h56, 1'b1);
            wr.body();

            $display("=== READ slave 1 ===");
            rd = new(seqr, 7'b1100_110, 1'b1);
            rd.body();

            #100;

            // ---------------- SLAVE 2 ----------------
            $display("=== WRITE slave 2 ===");
            wr = new(seqr, 7'b1000_110, 8'hAA, 1'b1);
            wr.body();

            $display("=== READ slave 2 ===");
            rd = new(seqr, 7'b1000_110, 1'b1);
            rd.body();

            #100;

            // ---------------- SLAVE 3 ----------------
            $display("=== WRITE slave 3 ===");
            wr = new(seqr, 7'b1100_100, 8'hF0, 1'b1);
            wr.body();

            $display("=== READ slave 3 ===");
            rd = new(seqr, 7'b1100_100, 1'b1);
            rd.body();

            #200;


            // =========================================================
            // ROUND 2
            // =========================================================

            $display("\n========== ROUND 2 ==========\n");

            // ---------------- SLAVE 1 ----------------
            $display("=== WRITE slave 1 ===");
            wr = new(seqr, 7'b1100_110, 8'h11, 1'b1);
            wr.body();

            $display("=== READ slave 1 ===");
            rd = new(seqr, 7'b1100_110, 1'b1);
            rd.body();

            #100;

            // ---------------- SLAVE 2 ----------------
            $display("=== WRITE slave 2 ===");
            wr = new(seqr, 7'b1000_110, 8'h22, 1'b1);
            wr.body();

            $display("=== READ slave 2 ===");
            rd = new(seqr, 7'b1000_110, 1'b1);
            rd.body();

            #100;

            // ---------------- SLAVE 3 ----------------
            $display("=== WRITE slave 3 ===");
            wr = new(seqr, 7'b1100_100, 8'h33, 1'b1);
            wr.body();

            $display("=== READ slave 3 ===");
            rd = new(seqr, 7'b1100_100, 1'b1);
            rd.body();

            #200;


            // =========================================================
            // ROUND 3
            // =========================================================

            $display("\n========== ROUND 3 ==========\n");

            // ---------------- SLAVE 1 ----------------
            $display("=== WRITE slave 1 ===");
            wr = new(seqr, 7'b1100_110, 8'h77, 1'b1);
            wr.body();

            $display("=== READ slave 1 ===");
            rd = new(seqr, 7'b1100_110, 1'b1);
            rd.body();

            #100;

            // ---------------- SLAVE 2 ----------------
            $display("=== WRITE slave 2 ===");
            wr = new(seqr, 7'b1000_110, 8'h88, 1'b1);
            wr.body();

            $display("=== READ slave 2 ===");
            rd = new(seqr, 7'b1000_110, 1'b1);
            rd.body();

            #100;

            // ---------------- SLAVE 3 ----------------
            $display("=== WRITE slave 3 ===");
            wr = new(seqr, 7'b1100_100, 8'h99, 1'b1);
            wr.body();

            $display("=== READ slave 3 ===");
            rd = new(seqr, 7'b1100_100, 1'b1);
            rd.body();
    end

        #10000;   // enough time for all 6 transactions (~2500ns needed)
        env.report();
        $display("=== DONE ===");
        $stop;
    end

endmodule : i2c_master_tb_top