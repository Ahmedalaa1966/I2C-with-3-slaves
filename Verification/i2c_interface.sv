// ============================================================
//  i2c_interface.sv
//  I2C Interface with clocking blocks for driver and monitor
// ============================================================
interface i2c_if (input logic clk, input logic clk_f, input logic rst_n,
                  input logic slave_driving,   // DUT: slave drives SDA
                  input logic [7:0] data_out_1,
                  input logic [7:0] data_out_2,
                  input logic [7:0] data_out_3);

    // ─── I2C signals ─────────────────────────────────────────
    logic       SCL  ;
    wire        SDA  ;
    logic       sda_m;       // master drives SDA

    // ─── SDA tri-state ────────────────────────────────────────
    assign SDA = slave_driving ? 1'bz : sda_m;
    assign SCL = clk;

    // ─── Driver clocking block (drives on negedge SCL) ────────
    clocking driver_cb @(negedge clk);
        output sda_m;
    endclocking

    // ─── Monitor clocking block (samples on posedge clk_f) ────
    clocking monitor_cb @(posedge clk_f);
        input SCL;
        input SDA;
        input sda_m;
        input slave_driving;
    endclocking

    // ─── Modports ─────────────────────────────────────────────
    modport driver_mp  (clocking driver_cb,
                        input  clk, clk_f, rst_n,
                        output sda_m, slave_driving,
                        input  SDA, SCL,
                        input  data_out_1, data_out_2, data_out_3);

    modport monitor_mp (clocking monitor_cb,
                        input  clk, clk_f, rst_n,
                        input  SDA, SCL, sda_m, slave_driving,
                        input  data_out_1, data_out_2, data_out_3);

endinterface : i2c_if