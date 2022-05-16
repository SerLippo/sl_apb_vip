`ifndef APB_SLAVE_MONITOR_SV
`define APB_SLAVE_MONITOR_SV

class apb_slave_monitor extends uvm_monitor;

  virtual apb_if vif;
  apb_config cfg;
  apb_transaction trans_collected;

  uvm_analysis_port#(apb_transaction) item_slv_mon_ana_port;

  `uvm_component_utils(apb_slave_monitor)

  function new(string name = "apb_slave_monitor", uvm_component parent);
    super.new(name, parent);
    item_slv_mon_ana_port = new("item_slv_mon_ana_port", this);
    trans_collected = new("trans_collected");
  endfunction: new

  task run_phase(uvm_phase phase);
    @(negedge vif.rstn)
      do @(posedge vif.clk);
      while(vif.rstn != 1);

    monitor_trans();
  endtask: run_phase

  task monitor_trans();
    process main_thread;
    process rst_mon_thread;

    forever begin
      fork
        begin
          main_thread = process::self();
          this.collect_trans();
          item_slv_mon_ana_port.write(trans_collected);
          if(rst_mon_thread) rst_mon_thread.kill();
        end
        begin
          rst_mon_thread = process::self();
          @(negedge vif.rstn)
            if(main_thread) main_thread.kill();
        end
      join_any
    end
  endtask: monitor_trans

  task collect_trans();
    void'(this.begin_tr(trans_collected));
    @(vif.cb_mon);
    void'(this.begin_tr(trans_collected));
    this.end_tr(trans_collected);
  endtask: collect_trans

endclass: apb_slave_monitor

`endif