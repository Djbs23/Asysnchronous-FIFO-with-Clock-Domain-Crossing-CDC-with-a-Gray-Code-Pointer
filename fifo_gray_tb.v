`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.08.2025 21:00:31
// Design Name: 
// Module Name: fifo_gray_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo_gray_tb();

parameter FIFO_DEPTH = 16;    // Must be power of 2
parameter WR_CLK_PERIOD = 10; // 100 mHz write clock
parameter RD_CLK_PERIOD = 15; // almost 66.67 MHz read clock (frequency different from write

reg wr_en, rd_en;
reg clk_wr, clk_rd;
reg wr_reset, rd_reset;
reg [7:0] data_in;
wire full, empty;
wire [7:0] data_out;


// Test variables

integer i, error_count;
reg[7:0]test_data[0:FIFO_DEPTH-1];
reg[7:0]received_data[0:FIFO_DEPTH-1];

// Instantiation

gray_fifo_cdc #(.Count(FIFO_DEPTH)) dut (.wr_en(wr_en),.rd_en(rd_en),
    .clk_wr(clk_wr),.clk_rd(clk_rd),.wr_reset(wr_reset),.reset_rd(reset_rd),
    .data_in(data_in),.full(full),.empty(empty),.data_out(data_out));

//Clock Generation
initial begin
clk_wr = 0;
# 5
forever #(WR_CLK_PERIOD/2) clk_wr = ~clk_wr;
end


initial begin
clk_rd = 0;
forever #(RD_CLK_PERIOD/2) clk_rd = ~clk_rd;
end


//Initialize test data

initial begin
    for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
        test_data[i] = $random;
        end
end   

// Main test sequence
  initial begin
    // Initialize
    error_count = 0;
    wr_en = 0;
    rd_en = 0;
    data_in = 0;
    
    // Reset sequence
    wr_reset = 1;
    rd_reset = 1;
    #100;
    wr_reset = 0;
    rd_reset = 0;
    #100;

    // Test 1: Basic write and read
    $display("Test 1: Basic write and read");
    for (i = 0; i < FIFO_DEPTH/2; i = i + 1) begin
      @(posedge clk_wr);
      wr_en = 1;
      data_in = test_data[i];
    end
    @(posedge clk_wr) wr_en = 0;
    
    for (i = 0; i < FIFO_DEPTH/2; i = i + 1) begin
      @(posedge clk_rd);
      rd_en = 1;
      received_data[i] = data_out;
      if (data_out !== test_data[i]) begin
        $display("Error: Expected %h, Got %h", test_data[i], dout);
        error_count = error_count + 1;
      end
    end
    @(posedge clk_rd) rd_en = 0;
    #100;

    // Test 2: Full condition
    $display("Test 2: Full condition");
    for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
      @(posedge clk_wr);
      wr_en = 1;
      data_in = test_data[i];
      if (full && i < FIFO_DEPTH-1) begin
        $display("Error: Full flag asserted too early");
        error_count = error_count + 1;
      end
    end
    if (!full) begin
      $display("Error: Full flag not asserted");
      error_count = error_count + 1;
    end
    @(posedge clk_wr) wr_en = 0;
    #100;

    // Test 3: Empty condition
    $display("Test 3: Empty condition");
    for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
      @(posedge clk_wr);
      rd_en = 1;
      received_data[i] = data_out;
      if (empty && i < FIFO_DEPTH-1) begin
        $display("Error: Empty flag asserted too early");
        error_count = error_count + 1;
      end
    end
    if (!empty) begin
      $display("Error: Empty flag not asserted");
      error_count = error_count + 1;
    end
    @(posedge clk_rd) rd_en = 0;
    #100;

    // Test 4: Simultaneous read and write
    $display("Test 4: Simultaneous read and write");
    fork
      begin // Writer
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
          @(posedge clk_wr);
          wr_en = 1;
          data_in = test_data[i];
        end
        @(posedge clk_wr) wr_en = 0;
      end
      begin // Reader
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
          @(posedge clk_rd);
          rd_en = 1;
          received_data[i] = data_out;
          #1; // Small delay for checking
          if (data_out !== test_data[i]) begin
            $display("Error: Expected %h, Got %h", test_data[i], dout);
            error_count = error_count + 1;
          end
        end
        @(posedge clk_rd) rd_en = 0;
      end
    join
    #100;

    // Test 5: Reset during operation
    $display("Test 5: Reset during operation");
    fork
      begin // Writer
        for (i = 0; i < FIFO_DEPTH/2; i = i + 1) begin
          @(posedge clk_wr);
          wr_en = 1;
          data_in = test_data[i];
        end
      end
      begin // Reset after delay
        #(WR_CLK_PERIOD * 5);
        wr_reset = 1;
        rd_reset = 1;
        #100;
        wr_reset = 0;
        rd_reset = 0;
      end
    join
    #100;

    // Check if FIFO is empty after reset
    if (!empty) begin
      $display("Error: FIFO not empty after reset");
      error_count = error_count + 1;
    end

    // Summary
    if (error_count == 0) begin
      $display("TEST PASSED - All tests completed successfully");
    end else begin
      $display("TEST FAILED - %0d errors found", error_count);
    end
    $finish;
  end

  // Monitor
  initial begin
    $monitor("Time = %0t: wr_en=%b, din=%h, full=%b | rd_en=%b, dout=%h, empty=%b",
             $time, wr_en, din, full, rd_en, data_out, empty);
  end

endmodule
