// Simple testbench for UART modules
module uart_tb();
  
  // Testbench uses a 50 MHz clock
  // UART at 115200 baud: 50,000,000 / 115,200 = 434 clocks per bit
  parameter c_CLOCK_PERIOD_NS = 20;  // 50MHz clock
  parameter c_CLKS_PER_BIT    = 434;
  parameter c_BIT_PERIOD      = 8680; // 434 * 20ns = 8680ns
  
  reg r_clk = 0;
  reg r_tx_dv = 0;
  wire w_tx_done;
  reg [127:0] r_tx_byte = 0;
  wire w_tx_serial;
  wire w_rx_dv;
  wire [127:0] w_rx_byte;
  
  // Take care of the clock
  always #(c_CLOCK_PERIOD_NS/2) r_clk <= !r_clk;
  
  // Instantiate UART transmitter
  uart_tx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) uart_tx_inst
    (
     .i_clk(r_clk),
     .i_tx_dv(r_tx_dv),
     .i_tx_byte(r_tx_byte),
     .o_tx_active(),
     .o_tx_serial(w_tx_serial),
     .o_tx_done(w_tx_done)
     );
  
  // Instantiate UART Receiver (connected to transmitter for loopback testing)
  uart_rx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) uart_rx_inst
    (
     .i_clk(r_clk),
     .i_rx_serial(w_tx_serial),
     .o_rx_dv(w_rx_dv),
     .o_rx_byte(w_rx_byte)
     );
  
  // Main Testing Logic
  initial
    begin
      // Send a single byte
      @(posedge r_clk);
      @(posedge r_clk);
      r_tx_dv   <= 1'b1;
      r_tx_byte <= 128'h00112233445566778899AABBCCDDEEFF;
      @(posedge r_clk);
      r_tx_dv   <= 1'b0;
      
      // Wait for transmit to be done
      @(posedge w_tx_done);
      
      // Check that the correct byte was received
      if (w_rx_byte == 128'h00112233445566778899AABBCCDDEEFF)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
      
        
      #10000;
      $finish;
    end
  
endmodule

