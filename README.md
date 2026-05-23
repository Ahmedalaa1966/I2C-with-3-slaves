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

