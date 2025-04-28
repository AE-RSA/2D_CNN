module project_cnn #(
parameter IMG_SIZE = 6, // Image size (NxN)
parameter FILT_SIZE = 3, // Filter size (MxM)
parameter NUM_FILTERS = 3 // Number of filters
)(
input wire clk, // Clock signal
input wire reset, // Reset signal
output reg signed [15:0] pool_result[(IMG_SIZE-FILT_SIZE+1)/2*(IMG_SIZE-FILT_SIZE+1)/2*NUM_FILTERS-1:0], // Flattened output after pooling
output reg done // Processing done flag
);
wire signed [15:0] conv_result[(IMG_SIZE-FILT_SIZE+1)*(IMG_SIZE-FILT_SIZE+1)*NUM_FILTERS-1:0]; // Convolution output
wire conv_done; // Convolution done flag
wire pool_done; // Pooling done flag
// Instantiate the convolution module
convolution #(
.IMG_SIZE(IMG_SIZE),
.FILT_SIZE(FILT_SIZE),
.NUM_FILTERS(NUM_FILTERS)
) conv (
.clk(clk),
.reset(reset),
.result(conv_result),
.done(conv_done)
);
// Instantiate the max pooling module
max_pooling #(
.IMG_SIZE(IMG_SIZE-FILT_SIZE+1), // Adjusted size after convolution
.NUM_FILTERS(NUM_FILTERS)
) pool (
.clk(clk),
.reset(reset),
.conv_result(conv_result),
.pool_result(pool_result),
.done(pool_done)
);
// Done flag logic
always @(posedge clk or posedge reset) begin
if (reset) begin
done <= 0;
end else begin
done <= conv_done && pool_done;
end
end
endmodule
