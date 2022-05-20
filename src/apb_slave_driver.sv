`ifndef APB_SLAVE_DRIVER_SV
`define APB_SLAVE_DRIVER_SV

class apb_slave_driver extends uvm_driver#(apb_transaction);

  virtual apb_if vif;
  apb_config cfg;

  bit[31:0] mem [bit[31:0]];

  `uvm_component_utils(apb_slave_driver)

  function new(string name = "apb_slave_driver", uvm_component parent);
    super.new(name, parent);
  endfunction: new

  task run_phase(uvm_phase phase);
    @(negedge vif.rstn)
      do @(posedge vif.clk);
      while(vif.rstn != 1);

    fork
      get_and_drive();
      drive_response();
    join_none
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
          if(rst_mon_thread) rst_mon_thread.kill();
        end
        begin
          rst_mon_thread = process::self();
          @(negedge vif.rstn) begin
            if(main_thread) main_thread.kill();
            this.reset_signals();
            this.reset_driver();
          end
        end
      join_any
      void'($cast(rsp, req.clone()));
      rsp.set_sequence_id(req.get_sequence_id());
      rsp.set_transaction_id(req.get_transaction_id());
      seq_item_port.item_done(rsp);
    end
  endtask: get_and_drive

  task reset_signals();
    `uvm_info("APB_SLV_DRV", "Reset signals", UVM_HIGH)
    case(cfg.apb_verison)
      APB2: begin
        vif.prdata <= 0;
      end
      APB3: begin
        vif.prdata <= 0;
        vif.pslverr <= 0;
        vif.pready <= cfg.slave_pready_default_value;
      end
      APB4: begin
        vif.prdata <= 0;
        vif.pslverr <= 0;
        vif.pready <= cfg.slave_pready_default_value;
      end
    endcase
  endtask: reset_signals

  protected task reset_driver();
    `uvm_info("APB_SLV_DRV", "Reset driver", UVM_HIGH)
    this.mem.delete();
  endtask: reset_driver

  protected task drive_response();
    `uvm_info("APB_SLV_DRV", "drive response", UVM_HIGH)
    forever begin
      @(vif.cb_slv);
      if(vif.cb_slv.psel == 1 && vif.cb_slv.penable == 0) begin
        case(vif.cb_slv.pwrite)
          1: this.do_write();
          0: this.do_read();
          default: `uvm_error("APB_SLV_DRV", "pwrite is x or z")
        endcase
      end
      else begin
        this.do_idle();
      end
    end
  endtask: drive_response

  protected task do_idle();
    `uvm_info("APB_SLV_DRV", "do idle", UVM_HIGH)
    vif.cb_slv.prdata <= 0;
    if(cfg.apb_verison == APB3 | cfg.apb_verison == APB4) begin
      vif.cb_slv.pready <= cfg.slave_pready_default_value;
      vif.cb_slv.pslverr <= 0;
    end
  endtask: do_idle

  protected task do_write();
    bit[31:0] addr;
    bit[31:0] data;
    bit[3:0]  strb;
    bit[2:0]  prot;
    int pready_add_cycles = cfg.get_pready_additional_cycles();
    bit pslverr_status = cfg.get_pslverr_status();
    `uvm_info("APB_SLV_DRV", "do write", UVM_HIGH)
    wait(vif.penable == 1);
    addr = vif.cb_slv.paddr;
    case(cfg.apb_verison)
      APB2: begin
        data = vif.cb_slv.pwdata;
        mem[addr] = data;
        #1ps;
      end
      APB3: begin
        data = vif.cb_slv.pwdata;
        mem[addr] = data;
        if(pready_add_cycles > 0) begin
          #1ps;
          vif.pready <= 0;
          repeat(pready_add_cycles) @(vif.cb_slv);
        end
        #1ps;
        vif.pready <= 1;
        vif.pslverr <= pslverr_status;
        fork
          begin
            @(vif.cb_slv);
            vif.cb_slv.pready <= cfg.slave_pready_default_value;
            vif.cb_slv.pslverr <= 0;
          end
        join_none
      end
      APB4: begin
        strb = vif.cb_slv.pstrb;
        prot = vif.cb_slv.pprot;
        for(int i=0; i<4; i++) begin
          if(strb[i]) data[8*i+7-:8] = vif.cb_slv.pwdata[8*i+7-:8];
          else data[8*i+7-:8] = 8'b0;
        end
        mem[addr] = data;
        if(pready_add_cycles > 0) begin
          #1ps;
          vif.pready <= 0;
          repeat(pready_add_cycles) @(vif.cb_slv);
        end
        #1ps;
        vif.pready <= 1;
        vif.pslverr <= pslverr_status;
        fork
          begin
            @(vif.cb_slv);
            vif.cb_slv.pready <= cfg.slave_pready_default_value;
            vif.cb_slv.pslverr <= 0;
          end
        join_none
      end
    endcase
  endtask: do_write

  protected task do_read();
    bit[31:0] addr;
    bit[31:0] data;
    bit[2:0]  prot;
    int pready_add_cycles = cfg.get_pready_additional_cycles();
    bit pslverr_status = cfg.get_pslverr_status();
    `uvm_info("APB_SLV_DRV", "do read", UVM_HIGH)
    wait(vif.penable == 1);
    addr = vif.cb_slv.paddr;
    case(cfg.apb_verison)
      APB2: begin
        if(mem.exists(addr))
          data = mem[addr];
        else
          data = DEFAULT_READ_VALUE;
        #1ps;
        vif.prdata <= data;
      end
      APB3: begin
        if(mem.exists(addr))
          data = mem[addr];
        else
          data = DEFAULT_READ_VALUE;
        if(pready_add_cycles > 0) begin
          #1ps;
          vif.pready <= 0;
          repeat(pready_add_cycles) @(vif.cb_slv);
        end
        #1ps;
        vif.pready <= 1;
        vif.pslverr <= pslverr_status;
        vif.prdata <= data;
        fork
          begin
            @(vif.cb_slv);
            vif.cb_slv.pready <= cfg.slave_pready_default_value;
            vif.cb_slv.pslverr <= 0;
          end
        join_none
      end
      APB4: begin
        prot = vif.cb_slv.pprot;
        if(mem.exists(addr))
          data = mem[addr];
        else
          data = DEFAULT_READ_VALUE;
        if(pready_add_cycles > 0) begin
          #1ps;
          vif.pready <= 0;
          repeat(pready_add_cycles) @(vif.cb_slv);
        end
        #1ps;
        vif.pready <= 1;
        vif.pslverr <= pslverr_status;
        vif.prdata <= data;
        fork
          begin
            @(vif.cb_slv);
            vif.cb_slv.pready <= cfg.slave_pready_default_value;
            vif.cb_slv.pslverr <= 0;
          end
        join_none
      end
    endcase
  endtask: do_read

endclass: apb_slave_driver

`endif