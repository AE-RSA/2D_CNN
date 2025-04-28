module convolution #(
parameter IMG_SIZE = 6, // Image size (NxN)
parameter FILT_SIZE = 3, // Filter size (MxM)
parameter NUM_FILTERS = 3 // Number of filters
)(
input wire clk, // Clock signal
input wire reset, // Reset signal
output reg signed [15:0] result[(IMG_SIZE-FILT_SIZE+1)*(IMG_SIZE-FILT_SIZE+1)*NUM_FILTERS-1:0], // Flattened output
output reg done // Convolution done flag
);
// Local parameters
localparam RESULT_SIZE = IMG_SIZE - FILT_SIZE + 1;
// Image and filter memory
reg signed [7:0] img [0:IMG_SIZE*IMG_SIZE-1];
reg signed [7:0] filter [0:NUM_FILTERS*FILT_SIZE*FILT_SIZE-1];
// FSM states
localparam IDLE = 3'd0;
localparam LOAD = 3'd1;
localparam COMPUTE = 3'd2;
localparam STORE = 3'd3;
localparam FINISH = 3'd4;
// Internal registers
reg [2:0] state, next_state; // FSM states
reg signed [15:0] sum; // Accumulator for summation
reg [2:0] img_row, img_col; // Row and column for the image
reg [1:0] filt_row, filt_col; // Row and column for the filter
reg [15:0] result_idx; // Result index
reg [1:0] filter_idx; // Filter index
// State transitions
always @(posedge clk or posedge reset) begin
if (reset) begin
state <= IDLE;
end else begin
state <= next_state;
end
end
// FSM logic
always @(*) begin
case (state)
IDLE: begin
if (!reset) next_state = LOAD;
else next_state = IDLE;
end
LOAD: begin
next_state = COMPUTE;
end
COMPUTE: begin
if (filt_row == FILT_SIZE - 1 && filt_col == FILT_SIZE - 1)
next_state = STORE;
else
next_state = COMPUTE;
end
STORE: begin
if (img_row == RESULT_SIZE - 1 && img_col == RESULT_SIZE - 1 && filter_idx == NUM_FILTERS - 1)
next_state = FINISH;
else
next_state = LOAD;
end
FINISH: begin
next_state = IDLE;
end
default: next_state = IDLE;
endcase
end
// Output computation and control logic
always @(posedge clk or posedge reset) begin
if (reset) begin
img_row <= 0;
img_col <= 0;
filt_row <= 0;
filt_col <= 0;
sum <= 0;
result_idx <= 0;
done <= 0;
filter_idx <= 0;
end else begin
case (state)
IDLE: begin
done <= 0;
img_row <= 0;
img_col <= 0;
result_idx <= 0;
filter_idx <= 0;
end
LOAD: begin
sum <= 0;
end
COMPUTE: begin
sum <= sum + img[(img_row + filt_row) * IMG_SIZE + (img_col + filt_col)] * filter[filter_idx * FILT_SIZE * FILT_SIZE + filt_row * FILT_SIZE + filt_col];
if (filt_col < FILT_SIZE - 1) begin
filt_col <= filt_col + 1;
end else begin
filt_col <= 0;
if (filt_row < FILT_SIZE - 1) begin
filt_row <= filt_row + 1;
end else begin
filt_row <= 0;
end
end
end
STORE: begin
result[result_idx + filter_idx * RESULT_SIZE * RESULT_SIZE] <= sum;
result_idx <= result_idx + 1;
if (img_col < RESULT_SIZE - 1) begin
img_col <= img_col + 1;
end else begin
img_col <= 0;
if (img_row < RESULT_SIZE - 1) begin
img_row <= img_row + 1;
end else begin
img_row <= 0;
if (filter_idx < NUM_FILTERS - 1) begin
filter_idx <= filter_idx + 1;
result_idx <= 0;
end
end
end
end
FINISH: begin
done <= 1;
end
endcase
end
end
// Initialize memories (read from files)
initial begin
$readmemh("image.mem", img); // Assuming image data in hex format
$readmemh("filter.mem", filter); // Assuming filter data in hex format
end
endmodule


