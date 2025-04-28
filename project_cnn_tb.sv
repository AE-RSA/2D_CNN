module project_cnn_tb;
// Parameters
localparam IMG_SIZE = 6;
localparam FILT_SIZE = 3;
localparam NUM_FILTERS = 3;
// Clock and reset signals
reg clk;
reg reset;
// Output signals
wire signed [15:0] pool_result[(IMG_SIZE-FILT_SIZE+1)/2*(IMG_SIZE-FILT_SIZE+1)/2*NUM_FILTERS-1:0];
wire done;
// Instantiate the top module
project_cnn #(
.IMG_SIZE(IMG_SIZE),
.FILT_SIZE(FILT_SIZE),
.NUM_FILTERS(NUM_FILTERS)
) uut (
.clk(clk),
.reset(reset),
.pool_result(pool_result),
.done(done)
);
// Clock generation
always #5 clk = ~clk; // 100MHz clock
// Testbench logic
initial begin
// Initialize signals
clk = 0;
reset = 1;
// Reset the system
#10;
reset = 0;
// Wait for done signal
wait(done);
// Display the results in matrix form
$display("Pooling Result:");
for (int f = 0; f < NUM_FILTERS; f = f + 1) begin
$display("Filter %0d:", f);
for (int i = 0; i < (IMG_SIZE-FILT_SIZE+1)/2; i = i + 1) begin
for (int j = 0; j < (IMG_SIZE-FILT_SIZE+1)/2; j = j + 1) begin
$write("%d ", pool_result[f*((IMG_SIZE-FILT_SIZE+1)/2)*((IMG_SIZE-FILT_SIZE+1)/2) + i*((IMG_SIZE-FILT_SIZE+1)/2) + j]);
end
$display(""); // New line for each row
end
end
$stop;
end
endmodule
