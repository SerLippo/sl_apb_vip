`ifndef APB_MASTER_MONITOR_SV
`define APB_MASTER_MONITOR_SV

class apb_master_monitor extends uvm_monitor;

  virtual apb_if vif;
  apb_config cfg;
  apb_transaction trans_collected;

  uvm_analysis_port#(apb_transaction) item_mst_mon_ana_port;

  `uvm_component_utils(apb_master_monitor)

  function new(string name = "apb_master_monitor", uvm_component parent);
    super.new(name, parent);
    item_mst_mon_ana_port = new("item_mst_mon_ana_port", this);
  endfunction: new

  task run_phase(uvm_phase phase);
    @(negedge vif.rstn)
      do @(posedge vif.clk);
      while(vif.rstn != 1);

    this.monitor_trans();
  endtask: run_phase

  protected task monitor_trans();
    process main_thread;
    process rst_mon_thread;

    forever begin
      fork
        begin
          main_thread = process::self();
          this.collect_trans();
          item_mst_mon_ana_port.write(trans_collected);
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

  protected task collect_trans();
    @(vif.cb_mon iff(vif.cb_mon.psel == 1'b1 && vif.cb_mon.penable == 1'b0));
    trans_collected = apb_transaction::type_id::create("trans_collected");
    case(vif.cb_mon.pwrite)
      1: begin
        case(cfg.apb_verison)
          APB2: begin
            @(vif.cb_mon iff vif.cb_mon.penable == 1);
            trans_collected.addr = vif.cb_mon.paddr;
            trans_collected.data = vif.cb_mon.pwdata;
            trans_collected.trans_kind = WRITE;
            trans_collected.trans_status = OK;
          end
          APB3: begin
            @(vif.cb_mon iff vif.cb_mon.pready == 1);
            trans_collected.addr = vif.cb_mon.paddr;
            trans_collected.data = vif.cb_mon.pwdata;
            trans_collected.trans_kind = WRITE;
            trans_collected.trans_status = vif.cb_mon.pslverr === 1'b0 ? OK : ERROR;
          end
          APB4: begin
            @(vif.cb_mon iff vif.cb_mon.pready == 1);
            trans_collected.addr = vif.cb_mon.paddr;
            for(int i=0; i<4; i++) begin
              if(vif.cb_mon.pstrb[i])
                trans_collected.data[8*i+7-:8] = vif.cb_mon.pwdata[8*i+7-:8];
              else
                trans_collected.data[8*i+7-:8] = 8'b0;
            end
            trans_collected.strb = vif.cb_mon.pstrb;
            trans_collected.prot = vif.cb_mon.pprot;
            trans_collected.trans_kind = WRITE;
            trans_collected.trans_status = vif.cb_mon.pslverr === 1'b0 ? OK : ERROR;
          end
          default: `uvm_error("APB_MST_MON", "Error apb_verison found, please check the apb_config!")
        endcase
      end
      0: begin
        case(cfg.apb_verison)
          APB2: begin
            @(vif.cb_mon iff vif.cb_mon.penable == 1);
            trans_collected.addr = vif.cb_mon.paddr;
            trans_collected.data = vif.cb_mon.prdata;
            trans_collected.trans_kind = READ;
            trans_collected.trans_status = OK;
          end
          APB3: begin
            @(vif.cb_mon iff vif.cb_mon.pready == 1);
            trans_collected.addr = vif.cb_mon.paddr;
            trans_collected.data = vif.cb_mon.prdata;
            trans_collected.trans_kind = READ;
            trans_collected.trans_status = vif.cb_mon.pslverr === 1'b0 ? OK : ERROR;
          end
          APB4: begin
            @(vif.cb_mon iff vif.cb_mon.pready == 1);
            trans_collected.addr = vif.cb_mon.paddr;
            trans_collected.data = vif.cb_mon.prdata;
            trans_collected.strb = 4'b0;
            trans_collected.prot = vif.cb_mon.pprot;
            trans_collected.trans_kind = READ;
            trans_collected.trans_status = vif.cb_mon.pslverr === 1'b0 ? OK : ERROR;
          end
          default: `uvm_error("APB_MST_MON", "Error apb_verison found, please check the apb_config!")
        endcase
      end
      default: `uvm_error("APB_MST_MON", "pwrite is x or z")
    endcase
  endtask: collect_trans

endclass: apb_master_monitor

`endif