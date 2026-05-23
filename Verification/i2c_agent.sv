// Agent (included by i2c_pkg.sv)
class i2c_agent;

    i2c_driver       driver;
    i2c_sequencer    sequencer;
    i2c_monitor      monitor;

    mailbox #(i2c_transaction) seq2drv;

    function new(virtual i2c_if.driver_mp     drv_vif,
                 virtual i2c_if.monitor_mp    mon_vif,
                 mailbox #(i2c_transaction)   drv2scb,
                 mailbox #(i2c_transaction)   mon2scb);
        seq2drv    = new();
        sequencer  = new(seq2drv);
        driver     = new(drv_vif, seq2drv, drv2scb);
        monitor    = new(mon_vif, mon2scb);
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

endclass : i2c_agent

