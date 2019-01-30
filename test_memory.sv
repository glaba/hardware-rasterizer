//-------------------------------------------------------------------------
//      test_memory.sv                                                   --
//      Stephen Kempf                                                    --
//      Summer 2005                                                      --
//                                                                       --
//      Revised 3-15-2006                                                --
//              3-22-2007                                                --
//              7-26-2013                                                --
//              10-19-2017 by Anand Ramachandran and Po-Han Huang        --
//                        Spring 2018 Distribution                       --
//                                                                       --
//      For use with ECE 385 Experment 6                                 --
//      UIUC ECE Department                                              --
//-------------------------------------------------------------------------

// This memory has similar behavior to the SRAM IC on the DE2 board.  This
// file is for simulations only.  In simulation, this memory is guaranteed
// to work at least as well as the actual memory (that is, the actual
// memory may require more careful treatment than this test memory).
// At synthesis, this will be synthesized into a blank module.

module test_memory ( input          clock_100,
                     inout  [15:0]  Data,   // Data
                     input  [19:0]  ADDR,     // Address
                     input          CE,    // Chip enable
                                    UB,    // Upper byte enable
                                    LB,    // Lower byte enable
                                    OE,    // Output (read) enable
                                    WE     // Write enable
);
// synthesis translate_off
// This line turns off Quartus' synthesis tool because test memory is NOT synthesizable.

    logic[15:0] mem[1048575:0] = '{1048576{16'd0}};
    logic[15:0] mem_out;
    logic[15:0] data_bus;

    // Memory read logic
    always_ff @ (posedge clock_100)
    begin
        mem_out <= ADDR[15:0];//mem[ADDR]; // Read a specific memory cell. 
        // Flip-flop with negedge Clk is used to simulate the 10ns access time.
        // (Assuming address changes at rising clock edge)
    end
    always_comb
    begin
        // By default, do not drive the IO bus
        data_bus = 16'bZZZZZZZZZZZZZZZZ;
        
        // Drvie the IO bus when chip select and read enable are active, and write enable is inactive
        if (~CE && ~OE && WE) begin
            if (~UB)
                data_bus[15:8] = mem_out[15:8]; // Read upper byte
            
            if (~LB)
                data_bus[7:0] = mem_out[7:0];   // Read lower byte
        end
    end

    // Memory write logic
    always_ff @ (posedge clock_100)
    begin
        // By default, mem_array holds its values.

        if (~CE && ~WE) // Write to memory if chip select and write enable are active
        begin
            if(~UB)
                mem[ADDR][15:8] <= Data[15:8]; // Write upper byte
            if(~LB)
                mem[ADDR][7:0] <= Data[7:0];   // Write lower byte
        end
    end

    assign Data = data_bus;

// synthesis translate_on
endmodule