`include "uvm_macros.svh"
import uvm_pkg::*;

// ============================================================
// AXI Interface
// ============================================================
interface aif (
    input logic clk,
    input logic reset
);
    logic [ 3:0] awaddr;
    logic [ 2:0] awprot;
    logic        awvalid;
    logic        awready;
    logic [31:0] wdata;
    logic [ 3:0] wstrb;
    logic        wvalid;
    logic        wready;
    logic [ 1:0] bresp;
    logic        bvalid;
    logic        bready;
    logic [ 3:0] araddr;
    logic [ 2:0] arprot;
    logic        arvalid;
    logic        arready;
    logic [31:0] rdata;
    logic [ 1:0] rresp;
    logic        rvalid;
    logic        rready;

    task automatic axi_write(input [3:0] addr, input [31:0] data);
        @(negedge clk);
        awaddr  = addr;
        awvalid = 1;
        wdata   = data;
        wstrb   = 4'hF;
        wvalid  = 1;
        @(posedge clk iff (awready && wready));
        @(negedge clk);
        awvalid = 0;
        wvalid  = 0;
        bready  = 1;
        @(posedge clk iff bvalid);
        @(negedge clk);
        bready = 0;
    endtask

    task automatic axi_read(input [3:0] addr, output [31:0] data);
        @(negedge clk);
        araddr  = addr;
        arvalid = 1;
        @(posedge clk iff arready);
        @(negedge clk);
        arvalid = 0;
        rready  = 1;
        @(posedge clk iff rvalid);
        data = rdata;
        @(negedge clk);
        rready = 0;
    endtask
endinterface

// ============================================================
// SPI Interface
// ============================================================
interface sif (
    input logic clk
);
    logic       sclk;
    logic       mosi;
    logic       miso;
    logic       ss_n;
    logic [7:0] s_tx_data;
    logic [7:0] s_rx_data;
    logic       s_rx_done;

    clocking mon_cb @(posedge clk);
        default input #1step;
        input s_tx_data;
        input s_rx_data;
        input s_rx_done;
    endclocking
endinterface

// ============================================================
// Sequence Item
// ============================================================
class axi_spi_seq_item extends uvm_sequence_item;
    `uvm_object_utils(axi_spi_seq_item)

    rand logic [7:0] m_tx_data;
    rand logic [7:0] s_tx_data;
    logic      [7:0] m_rx_data;
    logic      [7:0] s_rx_data;

    function new(string name = "axi_spi_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "m_tx=0x%02h s_tx=0x%02h m_rx=0x%02h s_rx=0x%02h",
            m_tx_data, s_tx_data, m_rx_data, s_rx_data
        );
    endfunction
endclass

// ============================================================
// Sequence
// ============================================================
class axi_spi_wr_seq extends uvm_sequence #(axi_spi_seq_item);
    `uvm_object_utils(axi_spi_wr_seq)

    int num_item = 256;

    function new(string name = "axi_spi_wr_seq");
        super.new(name);
    endfunction

    task body();
        axi_spi_seq_item item;
        repeat (num_item) begin
            item = axi_spi_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_fatal(get_type_name(), "randomize() fail!")
            `uvm_info(get_type_name(), item.convert2string(), UVM_MEDIUM)
            finish_item(item);
        end
    endtask
endclass

// ============================================================
// Coverage
// ============================================================
class axi_spi_coverage extends uvm_subscriber #(axi_spi_seq_item);
    `uvm_component_utils(axi_spi_coverage)

    axi_spi_seq_item item;

    covergroup axi_spi_cg;
        cp_m_tx: coverpoint item.m_tx_data {
            bins zeroTo4F = {[8'h00 : 8'h4F]};
            bins to8F     = {[8'h50 : 8'h8F]};
            bins toCF     = {[8'h90 : 8'hCF]};
            bins toMax    = {[8'hD0 : 8'hFF]};
        }
        cp_s_tx: coverpoint item.s_tx_data {
            bins zeroTo4F = {[8'h00 : 8'h4F]};
            bins to8F     = {[8'h50 : 8'h8F]};
            bins toCF     = {[8'h90 : 8'hCF]};
            bins toMax    = {[8'hD0 : 8'hFF]};
        }
        cp_m_rx: coverpoint item.m_rx_data {
            bins zeroTo4F = {[8'h00 : 8'h4F]};
            bins to8F     = {[8'h50 : 8'h8F]};
            bins toCF     = {[8'h90 : 8'hCF]};
            bins toMax    = {[8'hD0 : 8'hFF]};
        }
        cp_s_rx: coverpoint item.s_rx_data {
            bins zeroTo4F = {[8'h00 : 8'h4F]};
            bins to8F     = {[8'h50 : 8'h8F]};
            bins toCF     = {[8'h90 : 8'hCF]};
            bins toMax    = {[8'hD0 : 8'hFF]};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        axi_spi_cg = new();
    endfunction

    function void write(axi_spi_seq_item t);
        item = t;
        axi_spi_cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "\n\n ===== Coverage Summary =====", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "Overall : %.1f%%", axi_spi_cg.get_coverage()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "cp_m_tx : %.1f%%", axi_spi_cg.cp_m_tx.get_coverage()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "cp_s_tx : %.1f%%", axi_spi_cg.cp_s_tx.get_coverage()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "cp_m_rx : %.1f%%", axi_spi_cg.cp_m_rx.get_coverage()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf(
                  "cp_s_rx : %.1f%%", axi_spi_cg.cp_s_rx.get_coverage()), UVM_LOW)
        `uvm_info(get_type_name(), " ===== Coverage Summary =====\n\n", UVM_LOW)
    endfunction
endclass

// ============================================================
// Scoreboard
// ============================================================
class axi_spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_spi_scoreboard)

    uvm_analysis_imp #(axi_spi_seq_item, axi_spi_scoreboard) analysis_imp;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_imp = new("analysis_imp", this);
    endfunction

    function void write(axi_spi_seq_item item);
        // Master TX == Slave RX
        if (item.m_tx_data === item.s_rx_data) begin
            `uvm_info("SB", $sformatf("PASS - M_TX:0x%02h == S_RX:0x%02h",
                item.m_tx_data, item.s_rx_data), UVM_LOW)
            pass_cnt++;
        end else begin
            `uvm_error("SB", $sformatf("FAIL - M_TX:0x%02h != S_RX:0x%02h",
                item.m_tx_data, item.s_rx_data))
            fail_cnt++;
        end
        // Slave TX == Master RX
        if (item.s_tx_data === item.m_rx_data) begin
            `uvm_info("SB", $sformatf("PASS - S_TX:0x%02h == M_RX:0x%02h",
                item.s_tx_data, item.m_rx_data), UVM_LOW)
            pass_cnt++;
        end else begin
            `uvm_error("SB", $sformatf("FAIL - S_TX:0x%02h != M_RX:0x%02h",
                item.s_tx_data, item.m_rx_data))
            fail_cnt++;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf("=== 결과: PASS %0d / FAIL %0d ===",
            pass_cnt, fail_cnt), UVM_LOW)
    endfunction
endclass

// ============================================================
// Monitor
// ============================================================
class axi_spi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_spi_monitor)

    virtual aif aif;
    virtual sif sif;

    uvm_analysis_port #(axi_spi_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual aif)::get(this, "", "aif", aif))
            `uvm_fatal("NO_AIF", "aif not found")
        if (!uvm_config_db#(virtual sif)::get(this, "", "sif", sif))
            `uvm_fatal("NO_SIF", "sif not found")
    endfunction

    task run_phase(uvm_phase phase);
        axi_spi_seq_item item;
        logic [31:0] rdata;

        forever begin
            @(posedge sif.clk iff sif.s_rx_done);
            repeat(10) @(posedge sif.clk);
            item = axi_spi_seq_item::type_id::create("item");
            item.s_rx_data = sif.s_rx_data;
            item.s_tx_data = sif.s_tx_data;
            aif.axi_read(4'h4, rdata);
            item.m_tx_data = rdata[7:0];
            aif.axi_read(4'h8, rdata);
            item.m_rx_data = rdata[7:0];
            `uvm_info(get_type_name(), item.convert2string(), UVM_MEDIUM)
            ap.write(item);
        end
    endtask
endclass

// ============================================================
// Driver
// ============================================================
class axi_spi_driver extends uvm_driver #(axi_spi_seq_item);
    `uvm_component_utils(axi_spi_driver)

    virtual aif aif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual aif)::get(this, "", "aif", aif))
            `uvm_fatal("NO_VIF", "aif not found")
    endfunction

    task run_phase(uvm_phase phase);
        axi_spi_seq_item item;
        logic [31:0] rdata;

        forever begin
            seq_item_port.get_next_item(item);

            // s_tx_data config_db 설정
            uvm_config_db #(logic [7:0])::set(null, "*", "s_tx_data", item.s_tx_data);

            // 1. CTRL 설정 (clk_div=4, cpol=0, cpha=0)
            aif.axi_write(4'h0, (8'd4 << 3));

            // 2. TX 데이터
            aif.axi_write(4'h4, {24'h0, item.m_tx_data});

            // 3. START
            aif.axi_write(4'h0, (8'd4 << 3) | 32'h4);

            // 4. BUSY 폴링
            aif.axi_read(4'hC, rdata);
            while (rdata[1]) begin
                aif.axi_read(4'hC, rdata);
            end

            // 5. START 클리어
            aif.axi_write(4'h0, (8'd4 << 3));

            seq_item_port.item_done();
        end
    endtask
endclass

// ============================================================
// Agent
// ============================================================
class axi_spi_agent extends uvm_agent;
    `uvm_component_utils(axi_spi_agent)

    axi_spi_driver  driver;
    axi_spi_monitor monitor;
    uvm_sequencer #(axi_spi_seq_item) sequencer;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = axi_spi_driver::type_id::create("driver", this);
        monitor   = axi_spi_monitor::type_id::create("monitor", this);
        sequencer = uvm_sequencer#(axi_spi_seq_item)::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass

// ============================================================
// Env
// ============================================================
class axi_spi_env extends uvm_env;
    `uvm_component_utils(axi_spi_env)

    axi_spi_agent      agent;
    axi_spi_scoreboard scoreboard;
    axi_spi_coverage   coverage;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = axi_spi_agent::type_id::create("agent", this);
        scoreboard = axi_spi_scoreboard::type_id::create("scoreboard", this);
        coverage   = axi_spi_coverage::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.monitor.ap.connect(scoreboard.analysis_imp);
        agent.monitor.ap.connect(coverage.analysis_export);
    endfunction
endclass

// ============================================================
// Test
// ============================================================
class axi_spi_wr_test extends uvm_test;
    `uvm_component_utils(axi_spi_wr_test)

    axi_spi_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_spi_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        axi_spi_wr_seq seq;
        phase.raise_objection(this);
        seq = axi_spi_wr_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
        #10000;
        phase.drop_objection(this);
    endtask
endclass

// ============================================================
// tb_top
// ============================================================
module tb_axi_spi ();
    logic       clk;
    logic       reset;
    logic [7:0] s_tx_data;
    logic [7:0] s_rx_data;
    logic       s_rx_done;

    aif aif (.clk(clk), .reset(reset));
    sif sif (.clk(clk));

    // DUT
    AXI_SPI_Master_v1_0 U_DUT (
        .s00_axi_aclk   (clk),
        .s00_axi_aresetn(~reset),
        .s00_axi_awaddr (aif.awaddr),
        .s00_axi_awprot (aif.awprot),
        .s00_axi_awvalid(aif.awvalid),
        .s00_axi_awready(aif.awready),
        .s00_axi_wdata  (aif.wdata),
        .s00_axi_wstrb  (aif.wstrb),
        .s00_axi_wvalid (aif.wvalid),
        .s00_axi_wready (aif.wready),
        .s00_axi_bresp  (aif.bresp),
        .s00_axi_bvalid (aif.bvalid),
        .s00_axi_bready (aif.bready),
        .s00_axi_araddr (aif.araddr),
        .s00_axi_arprot (aif.arprot),
        .s00_axi_arvalid(aif.arvalid),
        .s00_axi_arready(aif.arready),
        .s00_axi_rdata  (aif.rdata),
        .s00_axi_rresp  (aif.rresp),
        .s00_axi_rvalid (aif.rvalid),
        .s00_axi_rready (aif.rready),
        .sclk           (sif.sclk),
        .mosi           (sif.mosi),
        .miso           (sif.miso),
        .ss_n           (sif.ss_n)
    );

    // SPI Slave
    spi_slave U_SPI_SLAVE (
        .clk    (clk),
        .reset  (reset),
        .sclk   (sif.sclk),
        .mosi   (sif.mosi),
        .ss     (sif.ss_n),
        .tx_data(s_tx_data),
        .miso   (sif.miso),
        .rx_data(s_rx_data),
        .rx_done(s_rx_done),
        .busy   ()
    );

    // sif 연결
    assign sif.s_rx_data = s_rx_data;
    assign sif.s_rx_done = s_rx_done;
    assign sif.s_tx_data = s_tx_data;

    // s_tx_data config_db에서 받기
    always @(posedge clk) begin
        void'(uvm_config_db #(logic [7:0])::get(null, "*", "s_tx_data", s_tx_data));
    end

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset
    initial begin
        reset       = 1;
        aif.awvalid = 0;
        aif.wvalid  = 0;
        aif.bready  = 0;
        aif.arvalid = 0;
        aif.rready  = 0;
        aif.awprot  = 0;
        aif.arprot  = 0;
        aif.wstrb   = 4'hF;
        s_tx_data   = 0;
        repeat (5) @(posedge clk);
        reset = 0;
        repeat (3) @(posedge clk);
    end

    // UVM 시작
    initial begin
        uvm_config_db #(virtual aif)::set(null, "uvm_test_top.*", "aif", aif);
        uvm_config_db #(virtual sif)::set(null, "uvm_test_top.*", "sif", sif);
        run_test("axi_spi_wr_test");
    end
endmodule