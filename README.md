# I2C-with-3-slaves
This project implements a complete I2C system consisting of one master and three slave devices connected on a shared SDA/SCL bus. The design follows the standard I2C protocol, where the master initiates all communication and controls data transfer using start/stop conditions, 7-bit slave addressing, and read/write control.
The master module generates the clock, sends the target slave address, and handles data transmission while checking acknowledgment (ACK/NACK) after each byte to ensure reliable communication. It supports both write operations (sending data to a slave) and read operations (receiving data from a selected slave).

Three independent slave modules are implemented, each assigned a unique address. Every slave continuously monitors the bus and only responds when its address matches the transmitted one. During write operations, the selected slave stores received data internally, while during read operations it drives stored data onto the bus. Unselected slaves remain inactive to avoid bus contention.

The architecture is designed to be scalable, allowing additional slaves to be added easily by assigning new addresses without modifying the core bus logic. Internal buffering within each slave ensures correct data handling during transactions.

A testbench is used to validate the system by performing repeated write-then-read operations for each slave multiple times, ensuring correct addressing, data integrity, and stable bus behavior under repeated access.

Overall, this design demonstrates a functional and scalable I2C multi-slave system suitable for FPGA/ASIC implementation and provides a solid foundation for further expansion or verification enhancements.

## System Block Diagram Description
<img width="1209" height="535" alt="image" src="https://github.com/user-attachments/assets/3fefc3d7-1c4e-41ea-b19e-b2094c1654a5" />


The figure illustrates the complete architecture of the implemented I2C system, consisting of one master, three slave devices, and an intermediate I2C slave controller connected to a shared SDA and SCL bus.

The master block is responsible for initiating all I2C transactions. It generates the clock signal (SCL), controls the bidirectional data line (SDA), and manages the communication sequence including start condition, slave addressing, data transfer, and stop condition. It also receives feedback from the bus indicating whether a slave is actively driving the line.

On the slave side, three independent slave modules (Slave 1, Slave 2, Slave 3) are connected to the same I2C bus. Each slave has dedicated outputs such as address_out and data_out, and an internal interface (SDA_out) used to communicate with the shared bus. Every slave monitors incoming addresses and only responds when its assigned address matches the master request.

An I2C_Slave_Controller block is introduced to manage and coordinate the interaction between multiple slaves and the shared bus. It handles signal direction control (dir), routes the correct slave response to the SDA line, and ensures that only one slave drives the bus at a time to avoid contention. It also generates internal control signals such as slave_driving to indicate active slave transmission.

The SDA and SCL lines form the shared communication medium, enabling synchronized serial data exchange between master and slaves.

Overall, this architecture ensures correct arbitration, clean bus control, and scalable multi-slave communication.

## I2C Slave FSM Description

<img width="1012" height="765" alt="image" src="https://github.com/user-attachments/assets/79e196ee-207e-4ece-addd-3319d832d04a" />


The figure illustrates the finite state machine (FSM) of the I2C slave module, which controls the slave’s behavior during different stages of communication with the master on the I2C bus.

The FSM starts in the IDLE state, where the slave continuously monitors the SDA line for a valid start condition (start = 1). Once detected, the slave transitions to the start_state, where it prepares to receive the incoming address from the master.

In the register_address state, the slave shifts in the 7-bit address and compares it with its own assigned address. If the address does not match (address_match = 0), the FSM returns to IDLE. If a match is detected, the slave proceeds to the address_ack state to acknowledge the master.

After acknowledgment, the direction of the operation is determined. If it is a write operation (wr = 1), the FSM enters the data_write_state, where it receives data from the master and stores it internally. Once a full byte is received (counter >= 7), it transitions to write_ack to acknowledge successful reception before returning for additional data or stopping.

If it is a read operation (wr = 0), the FSM enters the data_read_state, where it transmits stored data onto the SDA line. After sending one byte (counter >= 7), it moves to read_ack to wait for acknowledgment from the master.

The communication ends when a stop condition (stop = 1) is detected, transitioning the FSM to stop_state and then returning to IDLE.

## Simulation results

### 1. Start Condition
<img width="901" height="469" alt="image" src="https://github.com/user-attachments/assets/018fd222-4fc6-415d-8400-c0a32cbdeba9" />
he figure above illustrates the successful initiation of an I2C transaction, captured during simulation. As dictated by the I2C protocol, a valid start condition is recognized when the SDA (Serial Data) line transitions from HIGH to LOW while the SCL (Serial Clock) line is held HIGH.
In this waveform, the SDA_in signal is pulled LOW while SCL remains HIGH. Upon detecting this specific bus sequence, the slave device's internal state machine reacts exactly as designed. The next state (ns) immediately transitions from the IDLE_state to the start_state, confirming that the slave has correctly identified the start of the transaction and is ready to begin receiving the register address.


### 2. Slave 1 Write and Read Data Verification
<img width="1554" height="647" alt="image" src="https://github.com/user-attachments/assets/50f17cb1-c090-485f-849d-8cb2c1820b4c" />

The figure above demonstrates complete write and read cycles for the first slave device. Upon a valid address match in the register_address state, the FSM enters data_write_state for the write operation, where the internal counter increments from 0 to 7 as data is received via the sipo register. In the subsequent transaction, the FSM detects a read request and transitions to data_read_state, transmitting the stored data (56 in hex from rd_data) back to the master. The sequence concludes when a stop condition transitions the FSM through the stop state and back to IDLE.

### 3. Stop Condition
<img width="1438" height="380" alt="image" src="https://github.com/user-attachments/assets/1d43c0b7-10fc-4bc0-b6de-5c385cb08f63" />
The figure above captures the successful detection of the I2C stop condition, which terminates the communication cycle. After completing the data phase and moving through the acknowledgment states, a stop condition is recognized when the SDA line transitions from LOW to HIGH while the SCL line remains held HIGH. Upon detecting this protocol sequence, the slave FSM transitions into stop_state before resetting back to IDLE_state, placing the module back into a listening mode for the next start sequence.



### 4. Slave 2 Write and Read Data Verification
<img width="1864" height="665" alt="image" src="https://github.com/user-attachments/assets/c08e8586-be80-4cd8-abc0-1df33dfb570f" />

The figure above validates data integrity for the second slave device by confirming that the retrieved data matches the written data. During the write operations, the FSM receives data payloads (such as aa and 22 in hex) via the sipo register and stores them internally. When the master subsequently addresses Slave 2 with read requests, the FSM transitions to the read phases and drives those exact stored values back onto the bus via rd_data. The alignment of the written input and readback data across multiple transaction blocks confirms the correct implementation of the slave's internal registers and memory tracking logic.


### 5. Slave 3 Write and Read Data Verification
<img width="1856" height="618" alt="image" src="https://github.com/user-attachments/assets/1ce12d97-edc7-4d50-b1e3-f53ea430aad9" />

The figure above validates the data integrity and multi-device address decoding for the third slave module. Similar to the previous tests, when Slave 3 is correctly targeted by its unique address, the FSM handles independent write sequences to capture input payloads (such as f0 and 33 in hex). The subsequent read requests show the FSM shifting to read states and mirroring those exact bytes back to the master through rd_data. This successful validation across all three separate modules proves that your I2C bus system handles multi-slave addressing, state transitions, and distinct data tracking flawlessly.

### 6. Multi-Slave System Integration Verification
<img width="1866" height="243" alt="image" src="https://github.com/user-attachments/assets/1b869544-200b-4555-995b-2acf9b2dc2a7" />

The figure above showcases the top-level testbench simulation, verifying the concurrent operation and address decoding across all three I2C slave devices on the shared bus. The waveform tracks the independent data outputs (data_out_1, data_out_2, data_out_3) alongside their respective target addresses (addr_out_1, addr_out_2, addr_out_3). It clearly demonstrates the system's ability to selectively route transactions: Slave 1 processes data packets like 56 and 11, Slave 2 handles aa and 22, and Slave 3 manages f0 and 33. This complete bus-level overview confirms that address collision is avoided and each module strictly responds only when its unique hardware address is matched.



