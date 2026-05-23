module i2c_master_tb ();

    logic       SCL           ;
    wire        SDA           ;        
    logic       rst_n         ;
    logic       clk           ;
    logic       sda_m         ;
    logic       slave_driving ;
    logic       clk_f         ;

    // controller outputs
    logic [7:0] data_out_1, data_out_2, data_out_3 ;
    logic [6:0] addr_out_1, addr_out_2, addr_out_3 ;

    // ----------------------------------------------------------------
    // DUT: controller (3 slaves inside)
    // ----------------------------------------------------------------
    I2C_controller DUT (
        .SCL           (SCL)           ,
        .SDA           (SDA)           ,
        .sda_m         (sda_m)         ,
        .clk           (clk_f)         ,
        .rst_n         (rst_n)         ,
        .data_out_1    (data_out_1)    ,
        .data_out_2    (data_out_2)    ,
        .data_out_3    (data_out_3)    ,
        .addr_out_1    (addr_out_1)    ,
        .addr_out_2    (addr_out_2)    ,
        .addr_out_3    (addr_out_3)    ,
        .slave_driving (slave_driving)
    );

    assign SCL = clk ;
    assign SDA = slave_driving ? 1'bz : sda_m ;

    // ----------------------------------------------------------------
    // clock generation
    // ----------------------------------------------------------------
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end
    
    initial begin
        clk_f = 0;
        forever #5 clk_f = ~clk_f;
    end


    // ----------------------------------------------------------------
    // watchdog
    // ----------------------------------------------------------------
    initial begin
        #10000;
        $display("TIMEOUT: simulation took too long");
        $stop;
    end

    // ----------------------------------------------------------------
    // monitor
    // ----------------------------------------------------------------
    initial begin
        $monitor("Time=%0t | data_out_1=0x%0h | data_out_2=0x%0h | data_out_3=0x%0h",
                  $time, data_out_1, data_out_2, data_out_3);
    end

    // ----------------------------------------------------------------
    // main stimulus
    // ----------------------------------------------------------------
    initial begin
        sda_m = 1 ;     
        rst_n = 1 ;
        rst_task();

        // ---- WRITE to slave 1 (addr 0x66) ----
        $display("=== WRITE to slave 1 (addr 0x66) ===");
        start_gen  ();
        wr_address (8'b1100_1100);   // 0x66 << 1 + write(0) = 0xCC
        write_data (8'b0101_0110);
       
        
        // ---- READ BACK from slave 1 (addr 0x66) ----
        //start_gen() ;
        $display("=== READ from slave 1 (addr 0x66) ===");
        rd_address (8'b1100_1101);   // 0x66 << 1 + read(1) = 0xCD            
        read_data  ();
        
        #100;
    
    
       
        // ---- WRITE to slave 2 (addr 0x46) ----
        $display("=== WRITE to slave 2 (addr 0x46) ===");
        start_gen  ();
        wr_address (8'b1000_1100);   // 0x46 << 1 + write(0) = 0x8C
        write_data (8'b1010_1010);
        
        
        
        
        // ---- WRITE to slave 3 (addr 0x64) ----
        $display("=== WRITE to slave 3 (addr 0x64) ===");
        start_gen  ();
        wr_address (8'b1100_1000);   // 0x64 << 1 + write(0) = 0xC8
        write_data (8'b1111_0000);
        
        #100;
        

        
        
        // ---- READ BACK from slave 2 (addr 0x46) ----
        $display("=== READ from slave 2 (addr 0x46) ===");
        start_gen  ();
        rd_address (8'b1000_1101);   // 0x46 << 1 + read(1) = 0x8D
        read_data  ();
        

        // ---- READ BACK from slave 3 (addr 0x64) ----
        $display("=== READ from slave 3 (addr 0x64) ===");
        start_gen  ();
        rd_address (8'b1100_1001);   // 0x64 << 1 + read(1) = 0xC9
        read_data  ();
        stop_gen   ();
        #200;
        

        $display("=== DONE ===");
        $stop;
    end

    // ----------------------------------------------------------------
    // tasks
    // ----------------------------------------------------------------

    task rst_task;
    begin
        rst_n = 0;
        repeat (2) @(negedge clk);
        #2;
        rst_n = 1;
    end
    endtask

    // SDA falls while SCL high → START condition
    task start_gen;
    begin
        sda_m = 1 ;
        @(posedge clk) ;
        #2 
        sda_m = 0 ;
        #3
        @(posedge clk) ;
        @(negedge clk) ;
    end
    endtask

    // SDA rises while SCL high → STOP condition
    task stop_gen;
    begin
        sda_m = 0 ;
        @(posedge clk) ;
        #2 ;
        sda_m = 1 ;
        #3 ;
        @(posedge clk) ;
        @(negedge clk) ;
    end
    endtask

    // send address byte MSB-first + wait for slave ACK
    task wr_address;
    input [7:0] addr_byte;
    reg   [7:0] temp;
    begin
        temp = addr_byte;

        repeat (8) begin              // 8 bits: 7 addr + 1 R/W
            sda_m = temp[0];          // ✅ send MSB only
            temp  = temp >> 1;        // ✅ shift LEFT to bring next bit to MSB
            @(negedge clk);
        end

        // ACK cycle — release SDA and wait for slave to pull low
        @(negedge clk);
    end
    endtask

   // send read address byte MSB-first + wait for slave ACK
    task rd_address;
    input [7:0] addr_byte;
    reg   [7:0] temp;
    begin
        temp = addr_byte;
        repeat (8) begin
            sda_m = temp[0];       // MSB first
            temp  = temp >> 1 ;
            @(negedge clk) ;
        end
        @(negedge clk) ;        // read acknowledgement 
    end
    endtask

    // task to generate write data values
    task write_data;
        input [7:0] data_byte;
        reg   [7:0] temp;
        begin
            temp = data_byte;
            repeat (8) begin
                sda_m  = temp[0];       // MSB first
                temp = temp >> 1;       // Shift left to bring next MSB into position
                @(negedge clk);
            end
        end
        @(negedge clk)   ;            // wait for the write acknowlegment  state 
        //@(negedge clk) ;          
    endtask


    // release SDA and sample 8 bits from slave, then send NACK
    task read_data;
    reg [7:0] received;
        begin
            sda_m = 1 ;                 
            received = 8'b0;
            repeat (8) begin
                @(negedge clk)                  ;
                #1                              ;
                received = {received[6:0], SDA} ;   // shift in MSB first
            end
            $display("INFO: Read data = 0x%0h", received);
            // NACK from master (SDA=1) → signals end of read
            @(negedge clk) ;
            sda_m = 1 ;
            @(negedge clk) ;
            @(negedge clk) ;
        end
    endtask


endmodule