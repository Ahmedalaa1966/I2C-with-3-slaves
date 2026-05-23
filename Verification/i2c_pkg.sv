// ============================================================
//  i2c_pkg.sv
//  Package wrapper — includes TB classes in dependency order
// ============================================================
package i2c_pkg;

`include "i2c_utils.sv"
`include "i2c_transaction.sv"
`include "i2c_sequencer.sv"
`include "i2c_sequence.sv"
`include "i2c_driver.sv"
`include "i2c_monitor.sv"
`include "i2c_scoreboard.sv"
`include "i2c_agent.sv"
`include "i2c_env.sv"

endpackage : i2c_pkg
