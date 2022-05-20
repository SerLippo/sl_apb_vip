`ifndef APB_TRANSACTION_SV
`define APB_TRANSACTION_SV

class apb_transaction extends uvm_sequence_item;

  rand bit [`ADDR_WIDTH-1:0]   addr;
  rand bit [`DATA_WIDTH-1:0]   data;
  rand bit [`DATA_WIDTH/8-1:0] strb;
  rand bit [2:0]               prot;
  rand apb_trans_kind_t        trans_kind;
  rand apb_trans_status_t      trans_status;

  rand int idle_cycles;

  constraint cstr{
    soft idle_cycles == 1;
  };

  `uvm_object_utils_begin(apb_transaction)
    `uvm_field_enum(apb_trans_kind_t, trans_kind, UVM_ALL_ON)
    `uvm_field_enum(apb_trans_status_t, trans_status, UVM_ALL_ON)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(strb, UVM_ALL_ON)
    `uvm_field_int(prot, UVM_ALL_ON)
    `uvm_field_int(idle_cycles, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "apb_transaction");
    super.new(name);
  endfunction: new

endclass: apb_transaction

`endif