`ifndef APB_DEFINE_SV
`define APB_DEFINE_SV

// transfer enums
typedef enum {IDLE, WRITE, READ} apb_trans_kind_t;
typedef enum {OK, ERROR} apb_trans_status_t;
typedef enum {APB2, APB3, APB4} apb_verison_t;
typedef enum {BUS_WIDTH_8, BUS_WIDTH_16, BUS_WIDTH_32} apb_bus_width_t;
parameter bit[31:0] DEFAULT_READ_VALUE = 32'h0;


`endif