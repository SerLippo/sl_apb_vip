`ifndef REG2APB_ADAPTER_SV
`define REG2APB_ADAPTER_SV

class reg2apb_adapter extends uvm_reg_adapter;

  `uvm_object_utils_begin(reg2apb_adapter)
  `uvm_object_utils_end

  function new(string name = "reg2apb_adapter");
    super.new(name);
  endfunction: new

  function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    apb_transaction t = apb_transaction::type_id::create("t");
    t.trans_kind = (rw.kind == UVM_WRITE) ? WRITE : READ;
    t.addr = rw.addr;
    t.data = rw.data;
    t.idle_cycles = 1;
    return t;
  endfunction: reg2bus

  function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    apb_transaction t;
    if(!$cast(t, bus_item)) begin
      `uvm_fatal("CastFail", "provided bus_item is not of the correct type")
      return;
    end
    rw.kind = t.trans_kind == WRITE ? UVM_WRITE : UVM_READ;
    rw.addr = t.addr;
    rw.data = t.data;
    rw.status = t.trans_status == OK ? UVM_IS_OK : UVM_NOT_OK;
  endfunction: bus2reg

endclass: reg2apb_adapter

`endif