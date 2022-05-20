`ifndef APB_MASTER_DRIVER_SV
`define APB_MASTER_DRIVER_SV

class apb_master_driver extends uvm_driver#(apb_transaction);

  virtual apb_if vif;
  apb_config cfg;

  `uvm_component_utils(apb_master_driver)

  function new(string name = "apb_master_driver", uvm_component parent);
    super.new(name, parent);
  endfunction: new

  task run_phase(uvm_phase phase);
    @(negedge vif.rstn)
      do @(posedge vif.clk);
      while(vif.rstn != 1);
    this.get_and_drive();
  endtask: run_phase

  protected task get_and_drive();
    process main_thread;
    process rst_mon_thread;

    forever begin
      while(vif.rstn != 1) @(posedge vif.clk);
      seq_item_port.get_next_item(req);
      fork
        begin
          main_thread = process::self();
          this.drive_transaction(req);
          if(rst_mon_thread) rst_mon_thread.kill();
        end
        begin
          rst_mon_thread = process::self();
          @(negedge vif.rstn) begin
            if(main_thread) main_thread.kill();
            this.reset_signals();
          end
        end
      join_any
      void'($cast(rsp, req.clone()));
      rsp.set_sequence_id(req.get_sequence_id());
      rsp.set_transaction_id(req.get_transaction_id());
      seq_item_port.item_done(rsp);
    end
  endtask: get_and_drive

  protected task drive_transaction(apb_transaction t);
    case(t.trans_kind)
      IDLE		: this.do_idle();
      WRITE 	: this.do_write(t);
      READ 		: this.do_read(t);
      default : `uvm_error("APB_MST_DRV", "unrecognized transaction type")
    endcase
  endtask: drive_transaction

  protected task do_write(apb_transaction t);
    `uvm_info("APB_MST_DRV", "do write", UVM_HIGH)
    case(cfg.apb_verison)
      APB2: begin
        @(vif.cb_mst);
        vif.cb_mst.paddr <= t.addr;
        vif.cb_mst.pwrite <= 1;
        vif.cb_mst.psel <= 1;
        vif.cb_mst.penable <= 0;
        vif.cb_mst.pwdata <= t.data;
        @(vif.cb_mst);
        vif.cb_mst.penable <= 1;
        #1ps;
        t.trans_status = OK;
        repeat(t.idle_cycles) this.do_idle();
      end
      APB3: begin
        @(vif.cb_mst);
        vif.cb_mst.paddr <= t.addr;
        vif.cb_mst.pwrite <= 1;
        vif.cb_mst.psel <= 1;
        vif.cb_mst.penable <= 0;
        vif.cb_mst.pwdata <= t.data;
        @(vif.cb_mst);
        vif.cb_mst.penable <= 1;
        #1ps;
        wait(vif.pready == 1);
        #1ps;
        if(vif.pslverr == 1) begin
          t.trans_status = ERROR;
          if(cfg.master_pslverr_status_severity == UVM_ERROR)
            `uvm_error("APB_MST_DRV", "write failed, pslverr")
          else
            `uvm_warning("APB_MST_DRV", "write failed, pslverr")
        end
        else begin
          t.trans_status = OK;
        end
        repeat(t.idle_cycles) this.do_idle();
      end
      APB4: begin
        @(vif.cb_mst);
        vif.cb_mst.paddr <= t.addr;
        vif.cb_mst.pwrite <= 1;
        vif.cb_mst.psel <= 1;
        vif.cb_mst.penable <= 0;
        vif.cb_mst.pwdata <= t.data;
        vif.cb_mst.pprot <= t.prot;
        vif.cb_mst.pstrb <= t.strb;
        @(vif.cb_mst);
        vif.cb_mst.penable <= 1;
        #1ps;
        wait(vif.pready == 1);
        #1ps;
        if(vif.pslverr == 1) begin
          t.trans_status = ERROR;
          if(cfg.master_pslverr_status_severity == UVM_ERROR)
            `uvm_error("APB_MST_DRV", "write failed, pslverr")
          else
            `uvm_warning("APB_MST_DRV", "write failed, pslverr")
        end
        else begin
          t.trans_status = OK;
        end
        repeat(t.idle_cycles) this.do_idle();
      end
      default: `uvm_error("APB_MST_DRV", "Error apb_verison found, please check the apb_config!")
    endcase
  endtask: do_write

  protected task do_read(apb_transaction t);
    `uvm_info("APB_MST_DRV", "do read", UVM_HIGH)
    case(cfg.apb_verison)
      APB2: begin
        @(vif.cb_mst);
        vif.cb_mst.paddr <= t.addr;
        vif.cb_mst.pwrite <= 0;
        vif.cb_mst.psel <= 1;
        vif.cb_mst.penable <= 0;
        @(vif.cb_mst);
        vif.cb_mst.penable <= 1;
        #1ps;
        t.trans_status = OK;
        t.data = vif.prdata;
        repeat(t.idle_cycles) this.do_idle();
      end
      APB3: begin
        @(vif.cb_mst);
        vif.cb_mst.paddr <= t.addr;
        vif.cb_mst.pwrite <= 0;
        vif.cb_mst.psel <= 1;
        vif.cb_mst.penable <= 0;
        @(vif.cb_mst);
        vif.cb_mst.penable <= 1;
        #1ps;
        wait(vif.pready == 1);
        #1ps;
        if(vif.pslverr == 1) begin
          t.trans_status = ERROR;
          if(cfg.master_pslverr_status_severity == UVM_ERROR)
            `uvm_error("APB_MST_DRV", "read failed, pslverr")
          else
            `uvm_warning("APB_MST_DRV", "read failed, pslverr")
        end
        else begin
          t.trans_status = OK;
        end
        t.data = vif.prdata;
        repeat(t.idle_cycles) this.do_idle();
      end
      APB4: begin
        @(vif.cb_mst);
        vif.cb_mst.paddr <= t.addr;
        vif.cb_mst.pwrite <= 0;
        vif.cb_mst.psel <= 1;
        vif.cb_mst.penable <= 0;
        vif.cb_mst.pstrb <= 4'b0;
        vif.cb_mst.pprot <= t.prot;
        @(vif.cb_mst);
        vif.cb_mst.penable <= 1;
        #1ps;
        wait(vif.pready == 1);
        #1ps;
        if(vif.pslverr == 1) begin
          t.trans_status = ERROR;
          if(cfg.master_pslverr_status_severity == UVM_ERROR)
            `uvm_error("APB_MST_DRV", "read failed, pslverr")
          else
            `uvm_warning("APB_MST_DRV", "read failed, pslverr")
        end
        else begin
          t.trans_status = OK;
        end
        t.data = vif.prdata;
        repeat(t.idle_cycles) this.do_idle();
      end
    endcase
  endtask: do_read

  protected task do_idle();
    `uvm_info("APB_MST_DRV", "do idle", UVM_HIGH)
    @(vif.cb_mst);
    vif.cb_mst.psel <= 0;
    vif.cb_mst.penable <= 0;
    vif.cb_mst.pwdata <= 0;
    if(cfg.apb_verison == APB4) begin
      vif.cb_mst.pstrb <= 0;
      vif.cb_mst.pprot <= 0;
    end
  endtask: do_idle

  protected task reset_signals();
    `uvm_info("APB_MST_DRV", "Reset signals", UVM_HIGH)
    vif.paddr <= 0;
    vif.pwrite <= 0;
    vif.psel <= 0;
    vif.penable <= 0;
    vif.pwdata <= 0;
    if(cfg.apb_verison == APB4) begin
      vif.pprot <= 0;
      vif.pstrb <= 0;
    end
  endtask: reset_signals

endclass: apb_master_driver

`endif