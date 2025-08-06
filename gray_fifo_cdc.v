`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.07.2025 21:16:41
// Design Name: 
// Module Name: gray_fifo_cdc
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


module gray_fifo_cdc(

input wr_en,rd_en,         // Write and Read Enable  
input clk_rd,clk_wr,        // Clock read and clock write
input wr_reset, rd_reset,  // Clock reset read and write
input [7:0] data_in,
output full, empty,    
output reg [7:0] data_out    
    );

// For pointers
parameter Count = 16;
parameter Address = $clog2(Count);

reg [7:0] mem [0:Count-1];
//Write Pointers
reg [Address:0] wr_pnt_bin =0;
wire [Address:0] wr_pnt_gray;
reg [Address:0] wr_pnt_gray_reg = 0;

// Read Pointers
reg [Address:0] rd_pnt_bin = 0;
wire [Address:0] rd_pnt_gray;
reg [Address:0] rd_pnt_gray_reg = 0;

assign wr_pnt_gray = (wr_pnt_bin>>1) ^ wr_pnt_bin;
assign rd_pnt_gray = (rd_pnt_bin>>1) ^ rd_pnt_bin;

// Write when Read Clock is activated
reg [Address:0] wr_pnt_gray_sync1, wr_pnt_gray_sync2;
always@(posedge clk_rd, posedge rd_reset) begin
    if(rd_reset) begin
        wr_pnt_gray_sync1 <= 0;
        wr_pnt_gray_sync2 <= 0;
        end
    else begin
        wr_pnt_gray_sync1 <= wr_pnt_gray_reg;
        wr_pnt_gray_sync2 <= wr_pnt_gray_sync1;
        end
end


//Read for Write CLock
reg [Address:0] rd_pnt_gray_sync1, rd_pnt_gray_sync2;
always@(posedge clk_wr, posedge wr_reset) begin
    if(wr_reset) begin
        rd_pnt_gray_sync1 <= 0;
        rd_pnt_gray_sync2 <= 0;
        end
    else begin
        rd_pnt_gray_sync1 <= rd_pnt_gray_reg;
        rd_pnt_gray_sync2 <= rd_pnt_gray_sync1;
        end
end


// Full and Empty Declaration
assign full = (wr_pnt_gray_reg == ({~rd_pnt_gray_sync2[Address:Address-1],
                                        rd_pnt_gray_sync2[Address-2:0]}));

assign empty = (rd_pnt_gray_reg == wr_pnt_gray_sync2);


//Read Configuration
always@(posedge clk_rd, posedge rd_reset) begin
    if(rd_reset) begin
        rd_pnt_bin <= 0;
        rd_pnt_gray_reg <=0;
        data_out <= 0;
        end
    else if(rd_en && (!empty)) begin
        rd_pnt_bin <= rd_pnt_bin + 1;
        rd_pnt_gray_reg <= rd_pnt_gray;
        data_out <= mem[rd_pnt_bin[Address-1:0]];
        end
end

//Write Declaration
always@(posedge clk_wr, posedge wr_reset) begin
    if(wr_reset) begin
        wr_pnt_bin <= 0;
        wr_pnt_gray_reg <=0;
        end
    else if(wr_en && (!full))begin
        wr_pnt_bin <= wr_pnt_bin + 1;
        wr_pnt_gray_reg <= wr_pnt_gray;
        mem[wr_pnt_bin[Address-1:0]] <= data_in;
        end
end

endmodule
