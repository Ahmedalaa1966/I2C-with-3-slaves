# I2C-with-3-Slaves

A complete I2C system implemented in RTL, consisting of one master and three independent slave devices connected on a shared SDA/SCL bus. The design follows the standard I2C protocol, with the master controlling all transactions via start/stop conditions, 7-bit slave addressing, and read/write control.

---

## Repository Structure

```
├── Architecture/        # Block diagram and Slave FSM diagrams
├── Simulation/          # Simulation waveform snapshots
├── Script/              # QuestaSim .do scripts
├── rtl/                 # RTL source files (master, slaves, controller)
└── Verification/        # Testbench files
```

---

## System Overview

The master generates the SCL clock, drives the SDA line, and manages the full transaction sequence — start condition, address phase, data transfer, ACK handling, and stop condition — for both write and read operations.

Three slave modules are each assigned a unique 7-bit address. Every slave monitors the bus continuously and responds only when its address is matched. An `I2C_Slave_Controller` block sits between the slaves and the shared bus, managing signal direction and ensuring only one slave drives SDA at a time to prevent bus contention.

The architecture is designed to be scalable: additional slaves can be integrated by assigning new addresses without modifying the core bus logic.

For a full visual overview of the system architecture and the slave FSM, refer to the diagrams in the [`Architecture/`](./Architecture/) folder.

---

## Slave FSM

Each slave is controlled by a finite state machine with the following states:

- **IDLE** — monitors SDA for a start condition
- **start_state** — prepares to receive the incoming address
- **register_address** — shifts in the 7-bit address and checks for a match; returns to IDLE on mismatch
- **address_ack** — acknowledges the master after a successful address match
- **data_write_state** — receives data from the master and stores it internally (write path)
- **write_ack** — acknowledges a successfully received byte
- **data_read_state** — transmits stored data onto SDA (read path)
- **read_ack** — waits for master acknowledgment after sending a byte
- **stop_state** — detects the stop condition and resets to IDLE

FSM diagrams are available in [`Architecture/`](./Architecture/).

---

## Simulation Results

All simulation waveforms are located in the [`Simulation/`](./Simulation/) folder. The testbench performs repeated write-then-read operations targeting each slave to verify correct addressing, data integrity, and stable bus behavior.

### Verified scenarios

**1. Start Condition** — confirms SDA goes LOW while SCL is HIGH, triggering the slave FSM transition from IDLE to start_state.

**2. Stop Condition** — confirms SDA goes HIGH while SCL is HIGH after a transaction, returning the FSM to IDLE.

**3. Slave 1 Write & Read** — verifies that data written to Slave 1 (e.g., `0x56`) is correctly read back in a subsequent transaction.

**4. Slave 2 Write & Read** — validates data integrity for Slave 2 across multiple payloads (e.g., `0xAA`, `0x22`).

**5. Slave 3 Write & Read** — validates data integrity for Slave 3 across multiple payloads (e.g., `0xF0`, `0x33`).

**6. Multi-Slave Integration** — top-level simulation confirming that all three slaves operate concurrently on the shared bus without address collision, each independently tracking its own data (`data_out_1`, `data_out_2`, `data_out_3`).

---

## Running the Simulation

ModelSim/QuestaSim `.do` scripts are provided in the [`script/`](./script/) folder. Load the appropriate script to compile sources and run the testbench automatically.
