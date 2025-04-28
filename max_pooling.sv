module max_pooling #(
parameter IMG_SIZE = 4, // Image size after convolution (NxN)
parameter POOL_SIZE = 2, // Pooling window size (PxP)
parameter NUM_FILTERS = 3 // Number of filters
)(
input wire clk, // Clock signal
input wire reset, // Reset signal
input wire signed [15:0] conv_result[(IMG_SIZE)*(IMG_SIZE)*NUM_FILTERS-1:0], // Flattened convolution output
output reg signed [15:0] pool_result[(IMG_SIZE/POOL_SIZE)*(IMG_SIZE/POOL_SIZE)*NUM_FILTERS-1:0], // Flattened pooling output
output reg done // Pooling done flag
);
// Local parameters
localparam RESULT_SIZE = IMG_SIZE / POOL_SIZE;
// FSM states
localparam IDLE = 3'd0;
localparam LOAD = 3'd1;
localparam MAXPOOL = 3'd2;
localparam STORE = 3'd3;
localparam FINISH = 3'd4;
// Internal registers
reg [2:0] state, next_state; // FSM states
reg signed [15:0] max_val; // Accumulator for max pooling
reg [2:0] img_row, img_col; // Row and column for the image
reg [1:0] pool_row, pool_col; // Row and column for the pooling window
reg [15:0] pool_result_idx; // Pooling result index
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
next_state = MAXPOOL;
end
MAXPOOL: begin
if (pool_row == POOL_SIZE - 1 && pool_col == POOL_SIZE - 1)
next_state = STORE;
else
next_state = MAXPOOL;
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
pool_row <= 0;
pool_col <= 0;
max_val <= 0;
pool_result_idx <= 0;
done <= 0;
filter_idx <= 0;
end else begin
case (state)
IDLE: begin
done <= 0;
img_row <= 0;
img_col <= 0;
pool_result_idx <= 0;
filter_idx <= 0;
end
LOAD: begin
max_val <= -32768; // Minimum 16-bit signed value
end
MAXPOOL: begin
if (conv_result[(img_row * POOL_SIZE + pool_row) * IMG_SIZE + (img_col * POOL_SIZE + pool_col) + filter_idx * IMG_SIZE * IMG_SIZE] > max_val) begin
max_val <= conv_result[(img_row * POOL_SIZE + pool_row) * IMG_SIZE + (img_col * POOL_SIZE + pool_col) + filter_idx * IMG_SIZE * IMG_SIZE];
end
if (pool_col < POOL_SIZE - 1) begin
pool_col <= pool_col + 1;
end else begin
pool_col <= 0;
if (pool_row < POOL_SIZE - 1) begin
pool_row <= pool_row + 1;
end else begin
pool_row <= 0;
end
end
end
STORE: begin
pool_result[pool_result_idx + filter_idx * RESULT_SIZE * RESULT_SIZE] <= max_val;
pool_result_idx <= pool_result_idx + 1;
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
pool_result_idx <= 0;
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
endmodule



