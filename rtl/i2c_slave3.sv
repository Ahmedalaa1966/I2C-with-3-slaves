    module I2C_slave3 #(parameter logic [6:0] SLAVE_ADDRESS = 7'b1100_100  /*8'h66*/ ) 
(
    input   logic               SCL               ,
    input   logic               SDA_in            ,
    input   logic               sda_m             ,
    input   logic               rst_n             ,
    output  logic               SDA_out           , 
    output  logic       [7:0]   data_out          ,
    output  logic       [6:0]   adress_out        ,
    output  logic               dir               
);

// state definition
    typedef enum logic [3:0] {
        IDLE_state             ,
        start_state            ,
        register_adress        ,
        adress_ack             ,
        data_write_state       ,
        write_ack              ,
        data_read_state        ,
        read_ack               ,
        stop_m                 ,
        stop_state
    } state_t;


// declaration of the next state and current state logic  
    state_t cs , ns ;

// internal signals 
    logic       sda_out            ;         // serial data out_bus form the slave 
    logic       wr_rd              ;         // signal to indicate read or write operation 1: read ,  0: write
    logic [7:0] wr_data            ;         // write data used when the master writes in the slave 
    logic [7:0] rd_data            ;         // used when the master read data from the slave 
    logic [7:0] adress_in          ;         // the adress of the data to be written or read from the slave
    logic [7:0] sipo               ;         // register to convert data form serial to parralel
    logic [3:0] counter            ;         // counter whcih counts from 0 to 7 ( 8 clock cyles)
    logic       piso               ;         // parralel in serial out 
    logic       start              ;         // signal that indicate the staert condition
    logic       start_en           ;         // Enable signal thta is asserted only in the start state 
    logic       stop_en            ;         // Enable signal thta is asserted only in the stop state 
    logic       stop               ;         // Signal that indicate the STOP condiotion
    logic       piso_en            ;         // Enable signla for parralel in serial out operation 
    logic       sipo_en            ;         // Enable for serial in parralel out 
    logic       wr_en              ;         // Enable for write operation
    logic       rd_en              ;         // Enable for read operation
    logic       count_en           ;         // Enable for counting operation
    logic       address_match      ;         // signal indicates the that the address of the slave is matched 
    logic [7:0] out_bus            ;         // concatenation of the outputs 
    logic [7:0] mem [255:0]        ;         // memory for the salve \
    logic       address_match_reg  ;
    logic       add_en             ;         // enable signal for the address out and wr_rd
    logic       data_out_en        ;         // enable signal to pass the wr_data to the fata out only in th eread state 
    integer     i                  ;         // intger for the for loop counter to intialize the slave memory with zeros        
    logic       master_sda         ;

    assign SDA_out                                                       = dir ? sda_out : 1'b1                ;                                             // bidirectional port 
    assign data_out                                                      = (data_out_en) ?  rd_data : 'b0      ;
    assign {dir,count_en,piso_en,sipo_en,wr_en,rd_en,stop_en,start_en}   = out_bus                             ;
    assign address_match                                                 = ( sipo[7:1] == SLAVE_ADDRESS )      ;
    assign master_sda                                                    = sda_m || SDA_in                     ;

    always @(posedge SCL or negedge rst_n) begin
        if(! rst_n )
            {adress_out , wr_rd} <= 0;
        else if( !(cs == data_read_state || cs ==data_write_state ) ) 
            {adress_out , wr_rd} <= adress_in ;
    end

always @(posedge SCL or negedge rst_n) begin
    if (!rst_n)
        address_match_reg <= 1'b0 ;
    else if (address_match)
        address_match_reg <= 1'b1 ;
    else if (cs == IDLE_state || cs == stop_state || cs == data_write_state)
        address_match_reg <= 1'b0 ;
end


// code for serial in parralel out 
    always @(posedge SCL ) begin
        if(!rst_n) 
            sipo       <= 'b0 ;
        else if(sipo_en) 
            sipo       <= {SDA_in,sipo[7:1]} ;
    end

// coode for parallel in serial out
    always @(negedge SCL) begin
        if(!rst_n)
            piso <= 0;
        else if (piso_en && counter <= 7)
            piso <= rd_data[7-counter] ;
        else 
            piso <= 0;
    end


// always block for the counter 
    always @(negedge SCL or negedge rst_n) begin         // we always check at th negative edge as any change happens when the clock is low 
        if(!rst_n)
            counter <= 'b0 ;
        else if(count_en)
            counter <= counter + 1 ;
        else 
            counter <= 'b0 ;
        if(counter == 'd7 && !(cs == data_read_state))
            counter <= 'b0 ;
    end

    // always block for storing the in the memory 
    always @(posedge SCL or negedge rst_n or negedge SCL) begin
        if(!rst_n) begin
            rd_data <= 'b0;
            // Initialize memory to zero
            for(i = 0; i < 256; i = i + 1)
                mem[i] <= 'b0;
        end
        else begin
            if(wr_en)
                mem[adress_out] <= wr_data;

            if(rd_en)
                rd_data <= mem[adress_out];
        end
    end

// start condition always block
    always @(negedge master_sda or negedge rst_n ) begin
        if(!rst_n)
            start<= 'b0 ;
        else if(start_en && SCL)
            start <='b1 ;
        else 
            start <='b0 ;
    end

// stop condition always block
    always @(posedge master_sda) begin
        if(stop_en && master_sda == 1)
            stop <= 1 ;
        else 
            stop <= 0 ;
    end

// state transition always block 
    always @(negedge SCL or negedge rst_n ) begin
        if(!rst_n) 
            cs <= IDLE_state ;
        else 
            cs <= ns         ;
    end
    
// next state transition always block 
    always @(*) begin
        case (cs)

            IDLE_state: begin
                if(start) 
                    ns = start_state ;
                else 
                    ns = IDLE_state  ;
            end

            start_state: begin
                    ns = register_adress ;
            end

            register_adress : begin
                if( counter>= 0 && counter <  7 )
                    ns = register_adress  ;
                else 
                    ns = adress_ack       ;
            end

            adress_ack : begin
                if(address_match_reg) begin
                    if(!SDA_in) begin                            // SDA = 0 means acknowlegment
                        if(wr_rd)                                // 0 : write , 1 : read 
                            ns = data_read_state  ;           
                        else 
                            ns = data_write_state ;
                    end
                    else 
                        ns = stop_state           ;
                end
                else 
                    ns = IDLE_state ;

            end

            data_write_state : begin
                if(counter>= 0 && counter < 7) 
                    ns = data_write_state ;
                else 
                    ns = write_ack ;
            end

            write_ack: begin
            if(SDA_in == 0) begin
                if(stop)
                    ns = stop_state ;       // master ACK'd but then issued STOP
                else
                    ns = register_adress ;  // master wants to write more
            end
            else 
                ns = stop_m ;               // NACK → wait for STOP or repeated START
            end

            data_read_state : begin
                if(counter>= 0 && counter <= 7) 
                    ns = data_read_state ;
                else 
                    ns = read_ack ;
            end

            read_ack : begin
                if(SDA_in  == 0)
                    ns = register_adress ;         // SDA = 0 mean positive acknowlegement
                else 
                    ns = stop_m ; 
            end

            stop_m : begin
                if(stop)
                    ns = stop_state  ;
                else if(start)
                    ns = start_state ;
                else 
                    ns = stop_m ;
            end

            stop_state : begin
                if(start)
                    ns = start_state ;
                else 
                    ns = stop_state  ;
            end
            
            default: ns = IDLE_state ;
        endcase
    end


    // always block for ouutput 
    always @(*) begin
        out_bus     = 8'b00000000 ; 
        data_out_en = 1'b0        ; 
        
        case (cs)

            IDLE_state: begin
               out_bus    = 8'b00000001 ;
               adress_in  = 'b0 ;
               wr_data    = 'b0 ; 
               sda_out    = 'b0 ;
            end 

            start_state: begin
                out_bus   = 8'b00010000 ;
                adress_in = 'b0 ;
                wr_data   = 'b0 ; 
                sda_out   = 'b0 ;
            end

            register_adress: begin
                if( counter>= 0 && counter <=  7 )
                    out_bus = 8'b01010000 ;
                else
                    out_bus = 8'b01000000 ;
                adress_in   = 'b0 ;
                wr_data     = 'b0 ; 
                sda_out     = 'b0 ;
                if(ns == adress_ack) 
                    out_bus = 8'b01010100 ;
                else    
                    out_bus = 8'b01010000 ;
                
            end

            adress_ack : begin
                if(address_match_reg) begin
                    if(!SDA_in)
                        if(ns == data_read_state)
                            out_bus = 8'b11110100  ;
                        else
                            out_bus = 8'b10000100  ;
                    else
                        out_bus = 8'b10000000  ;
                   sda_out = 'b0          ;
                end
                else begin
                   out_bus = 8'b00000000  ; 
                   sda_out = 'b1          ; 
                end
                adress_in = sipo ;
                wr_data   = 'b0 ;
            end

            data_write_state : begin
                if(counter>= 0 && counter <= 7) 
                    out_bus = 8'b01010000 ;
                else
                    out_bus = 8'b01000000 ; 
                adress_in    = 'b0 ;
                wr_data     = 'b0 ; 
                sda_out     = 'b0 ;
            end

            write_ack : begin
                if(SDA_in == 0) 
                    out_bus = 8'b10001010 ;
                else
                    out_bus = 8'b10001010 ;
                adress_in = 'b0        ;
                wr_data   = sipo       ;
                sda_out = 'b0 ;
            end

            data_read_state : begin
                out_bus = 8'b11100100 ;
                adress_in = 'b0 ;
                wr_data = 'b0 ; 
                sda_out = piso ;
                data_out_en = 1'b1        ;
            end

            read_ack : begin
                if(SDA_in  == 0)
                    out_bus = 8'b00000010 ;
                else 
                    out_bus = 8'b00010010 ;
                adress_in = 'b0 ;
                wr_data = 'b0 ; 
                sda_out = 'b0 ;
            end

            stop_m: begin
                out_bus = 8'b00000010 ;
                adress_in = 'b0 ;
                wr_data = 'b0 ;
                sda_out = 'b0 ;

            end

            stop_state: begin
                out_bus = 8'b00000001 ; 
                adress_in = 'b0 ;
                wr_data = 'b0   ;
                sda_out = 'b0 ;
            end

            default: begin
                out_bus = 8'b00000000 ; 
                adress_in = 'b0 ;
                wr_data = 'b0   ;
                sda_out = 'b0 ;
            end 
        endcase

    end

endmodule