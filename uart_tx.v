// UART Transmitter Module
module uart_tx 
  #(parameter CLKS_PER_BIT = 434) // Default: 50MHz/115200baud
  (
   input       i_clk,         // Input clock
   input       i_tx_dv,       // Data Valid signal (start transmitting)
   input [127:0] i_tx_byte,     // Byte to transmit
   output      o_tx_active,   // Transmission in progress
   output reg  o_tx_serial,   // Serial output bit
   output      o_tx_done      // Transmission complete
   );
  
  // State machine states
  parameter IDLE         = 3'b000;
  parameter TX_START_BIT = 3'b001;
  parameter TX_DATA_BITS = 3'b010;
  parameter TX_STOP_BIT  = 3'b011;
  parameter CLEANUP      = 3'b100;
  
  reg [2:0]    r_state     = IDLE;
  reg [15:0]   r_clk_count = 0;
  reg [6:0]    r_bit_index = 0;
  reg [127:0]    r_tx_data   = 0;
  reg          r_tx_done   = 0;
  reg          r_tx_active = 0;
  
  // Assign output wires
  assign o_tx_active = r_tx_active;
  assign o_tx_done   = r_tx_done;
  
  always @(posedge i_clk)
    begin
      case (r_state)
        IDLE :
          begin
            o_tx_serial   <= 1'b1;  // Drive high when idle
            r_tx_done     <= 1'b0;
            r_clk_count   <= 0;
            r_bit_index   <= 0;
            
            if (i_tx_dv == 1'b1)
              begin
                r_tx_active <= 1'b1;
                r_tx_data   <= i_tx_byte;
                r_state     <= TX_START_BIT;
              end
            else
              r_state <= IDLE;
          end 
        
        // Send start bit (always 0)
        TX_START_BIT :
          begin
            o_tx_serial <= 1'b0;
            
            // Wait for one bit period
            if (r_clk_count < CLKS_PER_BIT-1)
              begin
                r_clk_count <= r_clk_count + 1;
                r_state     <= TX_START_BIT;
              end
            else
              begin
                r_clk_count <= 0;
                r_state     <= TX_DATA_BITS;
              end
          end 
        
        // Send data bits, LSB first
        TX_DATA_BITS :
          begin
            o_tx_serial <= r_tx_data[r_bit_index];
            
            if (r_clk_count < CLKS_PER_BIT-1)
              begin
                r_clk_count <= r_clk_count + 1;
                r_state     <= TX_DATA_BITS;
              end
            else
              begin
                r_clk_count <= 0;
                
                // Send next bit
                if (r_bit_index < 127)
                  begin
                    r_bit_index <= r_bit_index + 1;
                    r_state     <= TX_DATA_BITS;
                  end
                else
                  begin
                    r_bit_index <= 0;
                    r_state     <= TX_STOP_BIT;
                  end
              end
          end 
        
        // Send stop bit (always 1)
        TX_STOP_BIT :
          begin
            o_tx_serial <= 1'b1;
            
            // Wait for stop bit to finish
            if (r_clk_count < CLKS_PER_BIT-1)
              begin
                r_clk_count <= r_clk_count + 1;
                r_state     <= TX_STOP_BIT;
              end
            else
              begin
                r_tx_done   <= 1'b1;
                r_clk_count <= 0;
                r_state     <= CLEANUP;
                r_tx_active <= 1'b0;
              end
          end 
        
        // Stay here for one clock cycle
        CLEANUP :
          begin
            r_tx_done <= 1'b0;
            r_state   <= IDLE;
          end
        
        default :
          r_state <= IDLE;
        
      endcase
    end
endmodule 
