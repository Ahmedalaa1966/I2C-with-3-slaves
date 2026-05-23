// Environment (included by i2c_pkg.sv)
class i2c_env;

    // ─── components ───────────────────────────────────────────
    i2c_agent      agent    ;
    i2c_scoreboard scoreboard;

    // ─── shared mailboxes ─────────────────────────────────────
    mailbox #(i2c_transaction) drv2scb;
    mailbox #(i2c_transaction) mon2scb;

    // ─── constructor ──────────────────────────────────────────
    function new(virtual i2c_if.driver_mp  drv_vif,
                 virtual i2c_if.monitor_mp mon_vif);

        // create mailboxes
        drv2scb = new();
        mon2scb = new();

        // create agent (connects mailboxes internally)
        agent     = new(drv_vif, mon_vif, drv2scb, mon2scb);

        // create scoreboard (receives from both mailboxes)
        scoreboard = new(drv2scb, mon2scb);
    endfunction

    // ─── run environment ──────────────────────────────────────
    task run();
        fork
            agent.run();
            scoreboard.run();
        join_none
    endtask

    // ─── expose sequencer for test ────────────────────────────
    function i2c_sequencer get_sequencer();
        return agent.get_sequencer();
    endfunction

    // ─── call at end of test ──────────────────────────────────
    function void report();
        scoreboard.report();
    endfunction

endclass : i2c_env
