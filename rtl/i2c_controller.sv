    module I2C_controller (
        input  logic        SCL        ,
        inout  wire         SDA        ,
        input  logic        rst_n      ,
        input  logic        clk        ,
        input  logic        sda_m      ,                           // the SDA of the master itself   

        // each slave has its own outputs
        output logic [7:0]  data_out_1 ,
        output logic [7:0]  data_out_2 ,
        output logic [7:0]  data_out_3 ,
        output logic [6:0]  addr_out_1 ,
        output logic [6:0]  addr_out_2 ,
        output logic [6:0]  addr_out_3 ,
        output logic        slave_driving 
    );

        logic SDA_1, SDA_2, SDA_3, SDA_bus          ;
        logic dir1, dir2, dir3                      ;
        assign SDA_bus = SDA_1 && SDA_2 && SDA_3    ;               // the finak SDA is combination if te and of all the SDA outputs of the slaves following the Arbitation process
        assign SDA = slave_driving ? SDA_bus : 1'bz ;
        assign slave_driving = dir1 || dir2 || dir3 ;


        // intantiation of the first slave
        I2C_slave1 #(.SLAVE_ADDRESS(7'h66)) 
        slave_1 (
            .SCL        (SCL)              ,
            .SDA_in     (SDA)              ,
            .SDA_out    (SDA_1)            ,
            .sda_m      (sda_m)            ,   
            .rst_n      (rst_n)            ,
            .data_out   (data_out_1)       ,
            .adress_out (addr_out_1)       ,
            .dir        (dir1)
        ); 

        // instantiation of the second slave 
        I2C_slave2 #(.SLAVE_ADDRESS(7'h46)) 
        slave_2 (
            .SCL        (SCL)              ,
            .SDA_in     (SDA)              ,
            .SDA_out    (SDA_2)            ,
            .sda_m      (sda_m)            , 
            .rst_n      (rst_n)            ,
            .data_out   (data_out_2)       ,
            .adress_out (addr_out_2)       ,
            .dir        (dir2) 
        );

        // instantiation of the third slave 
        I2C_slave3 #(.SLAVE_ADDRESS(7'h64)) 
        slave_3 (
            .SCL        (SCL)             ,
            .SDA_in     (SDA)             ,
            .SDA_out    (SDA_3)           ,
            .sda_m      (sda_m)           ,
            .rst_n      (rst_n)           ,
            .data_out   (data_out_3)      ,
            .adress_out (addr_out_3)      ,
            .dir        (dir3)    
        );




    endmodule