
`include "uvm_macros.svh"
import uvm_pkg::*;

// ============================================================
// 트랜잭션 클래스
// ============================================================
class axi_transaction extends uvm_sequence_item;
    `uvm_object_utils(axi_transaction)

    logic [3:0]  addr;
    logic [31:0] data;
    logic [31:0] rdata;
    logic        is_write;

    function new(string name = "axi_transaction");
        super.new(name);
    endfunction
endclass

class spi_transaction extends uvm_sequence_item;
    `uvm_object_utils(spi_transaction)

    logic [7:0] master_tx_data;
    logic [7:0] slave_rx_data;
    logic [7:0] slave_tx_data;
    logic [7:0] master_rx_data;

    function new(string name = "spi_transaction");
        super.new(name);
    endfunction
endclass

// ============================================================
// AXI 인터페이스
// ============================================================
interface axi_if(input logic clk, input logic reset);
    logic [3:0]  awaddr;
    logic [2:0]  awprot;
    logic        awvalid;
    logic        awready;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wvalid;
    logic        wready;
    logic [1:0]  bresp;
    logic        bvalid;
    logic        bready;
    logic [3:0]  araddr;
    logic [2:0]  arprot;
    logic        arvalid;
    logic        arready;
    logic [31:0] rdata;
    logic [1:0]  rresp;
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
        bready  = 0;
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
        rready  = 0;
    endtask
endinterface

// ============================================================
// SPI 모니터용 인터페이스
// ============================================================
interface spi_if(input logic clk);
    logic       sclk;
    logic       mosi;
    logic       miso;
    logic       ss_n;
    logic [7:0] slave_rx_data;
    logic       slave_rx_done;
    logic [7:0] slave_tx_data;
endinterface

// ============================================================
// Sequence
// ============================================================
class spi_axi_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(spi_axi_sequence)

    function new(string name = "spi_axi_sequence");
        super.new(name);
    endfunction

    task body();
        axi_transaction tx;
        logic [7:0] slave_tx;

        for (int i = 0; i < 256; i++) begin
            slave_tx = $urandom_range(0, 255);
            uvm_config_db #(logic [7:0])::set(null, "*", "slave_tx_data", slave_tx);

            // CTRL 설정
            tx = axi_transaction::type_id::create("tx");
            start_item(tx);
            tx.addr     = 4'h0;
            tx.data     = (8'd4 << 3);
            tx.is_write = 1;
            finish_item(tx);

            // TX 데이터
            tx = axi_transaction::type_id::create("tx");
            start_item(tx);
            tx.addr     = 4'h4;
            tx.data     = {24'h0, i[7:0]};
            tx.is_write = 1;
            finish_item(tx);

            // START
            tx = axi_transaction::type_id::create("tx");
            start_item(tx);
            tx.addr     = 4'h0;
            tx.data     = (8'd4 << 3) | (1 << 2);
            tx.is_write = 1;
            finish_item(tx);

            // BUSY 폴링
            tx = axi_transaction::type_id::create("tx");
            start_item(tx);
            tx.addr     = 4'hC;
            tx.is_write = 0;
            finish_item(tx);

            // START 클리어
            tx = axi_transaction::type_id::create("tx");
            start_item(tx);
            tx.addr     = 4'h0;
            tx.data     = (8'd4 << 3);
            tx.is_write = 1;
            finish_item(tx);

            // Master RX 읽기
            tx = axi_transaction::type_id::create("tx");
            start_item(tx);
            tx.addr     = 4'h8;
            tx.is_write = 0;
            finish_item(tx);
        end
    endtask
endclass

// ============================================================
// Driver
// ============================================================
class spi_axi_driver extends uvm_driver #(axi_transaction);
    `uvm_component_utils(spi_axi_driver)

    virtual axi_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual axi_if)::get(this, "", "axi_vif", vif))
            `uvm_fatal("NO_VIF", "axi_if not found")
    endfunction

    task run_phase(uvm_phase phase);
        axi_transaction tx;
        logic [31:0] rdata;
        forever begin
            seq_item_port.get_next_item(tx);
            if (tx.is_write) begin
                vif.axi_write(tx.addr, tx.data);
            end else begin
                vif.axi_read(tx.addr, rdata);
                tx.rdata = rdata;
                if (tx.addr == 4'hC) begin
                    while (rdata[1]) begin
                        vif.axi_read(tx.addr, rdata);
                    end
                end
            end
            seq_item_port.item_done();
        end
    endtask
endclass

// ============================================================
// Monitor
// ============================================================
class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    virtual axi_if axi_vif;
    virtual spi_if spi_vif;

    uvm_analysis_port #(spi_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual axi_if)::get(this, "", "axi_vif", axi_vif))
            `uvm_fatal("NO_VIF", "axi_if not found")
        if (!uvm_config_db #(virtual spi_if)::get(this, "", "spi_vif", spi_vif))
            `uvm_fatal("NO_VIF", "spi_if not found")
    endfunction

    task run_phase(uvm_phase phase);
        spi_transaction trans;
        logic [31:0] rdata;
        forever begin
            @(posedge spi_vif.clk iff spi_vif.slave_rx_done);
            trans = spi_transaction::type_id::create("trans");
            trans.slave_rx_data  = spi_vif.slave_rx_data;
            trans.slave_tx_data  = spi_vif.slave_tx_data;
            axi_vif.axi_read(4'h4, rdata);
            trans.master_tx_data = rdata[7:0];
            axi_vif.axi_read(4'h8, rdata);
            trans.master_rx_data = rdata[7:0];
            ap.write(trans);
        end
    endtask
endclass

// ============================================================
// Scoreboard
// ============================================================
class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)

    uvm_analysis_imp #(spi_transaction, spi_scoreboard) analysis_export;

    int pass_cnt;
    int fail_cnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
        pass_cnt = 0;
        fail_cnt = 0;
    endfunction

    function void write(spi_transaction trans);
        if (trans.master_tx_data === trans.slave_rx_data) begin
            `uvm_info("SB", $sformatf("PASS - Master TX: %0h == Slave RX: %0h",
                trans.master_tx_data, trans.slave_rx_data), UVM_LOW)
            pass_cnt++;
        end else begin
            `uvm_error("SB", $sformatf("FAIL - Master TX: %0h != Slave RX: %0h",
                trans.master_tx_data, trans.slave_rx_data))
            fail_cnt++;
        end

        if (trans.slave_tx_data === trans.master_rx_data) begin
            `uvm_info("SB", $sformatf("PASS - Slave TX: %0h == Master RX: %0h",
                trans.slave_tx_data, trans.master_rx_data), UVM_LOW)
            pass_cnt++;
        end else begin
            `uvm_error("SB", $sformatf("FAIL - Slave TX: %0h != Master RX: %0h",
                trans.slave_tx_data, trans.master_rx_data))
            fail_cnt++;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf("=== 결과: PASS %0d / FAIL %0d ===",
            pass_cnt, fail_cnt), UVM_LOW)
    endfunction
endclass

// ============================================================
// Agent
// ============================================================
class spi_agent extends uvm_agent;
    `uvm_component_utils(spi_agent)

    spi_axi_driver  driver;
    spi_monitor     monitor;
    uvm_sequencer #(axi_transaction) sequencer;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = spi_axi_driver::type_id::create("driver", this);
        monitor   = spi_monitor::type_id::create("monitor", this);
        sequencer = uvm_sequencer #(axi_transaction)::type_id::create("sequencer", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass

// ============================================================
// Env
// ============================================================
class spi_env extends uvm_env;
    `uvm_component_utils(spi_env)

    spi_agent      agent;
    spi_scoreboard scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = spi_agent::type_id::create("agent", this);
        scoreboard = spi_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.monitor.ap.connect(scoreboard.analysis_export);
    endfunction
endclass

// ============================================================
// Test
// ============================================================
class spi_test extends uvm_test;
    `uvm_component_utils(spi_test)

    spi_env          env;
    spi_axi_sequence seq;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = spi_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq = spi_axi_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        #1000;
        phase.drop_objection(this);
    endtask
endclass

// ============================================================
// tb_top
// ============================================================
module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    logic        clk;
    logic        reset;
    logic [7:0]  slave_tx_data;
    logic [7:0]  slave_rx_data;
    logic        slave_rx_done;

    axi_if axi_vif(.clk(clk), .reset(reset));
    spi_if spi_vif(.clk(clk));

    // DUT
    AXI_SPI_Master_v1_0 U_DUT (
        .s00_axi_aclk   (clk),
        .s00_axi_aresetn(~reset),
        .s00_axi_awaddr (axi_vif.awaddr),
        .s00_axi_awprot (axi_vif.awprot),
        .s00_axi_awvalid(axi_vif.awvalid),
        .s00_axi_awready(axi_vif.awready),
        .s00_axi_wdata  (axi_vif.wdata),
        .s00_axi_wstrb  (axi_vif.wstrb),
        .s00_axi_wvalid (axi_vif.wvalid),
        .s00_axi_wready (axi_vif.wready),
        .s00_axi_bresp  (axi_vif.bresp),
        .s00_axi_bvalid (axi_vif.bvalid),
        .s00_axi_bready (axi_vif.bready),
        .s00_axi_araddr (axi_vif.araddr),
        .s00_axi_arprot (axi_vif.arprot),
        .s00_axi_arvalid(axi_vif.arvalid),
        .s00_axi_arready(axi_vif.arready),
        .s00_axi_rdata  (axi_vif.rdata),
        .s00_axi_rresp  (axi_vif.rresp),
        .s00_axi_rvalid (axi_vif.rvalid),
        .s00_axi_rready (axi_vif.rready),
        .sclk           (spi_vif.sclk),
        .mosi           (spi_vif.mosi),
        .miso           (spi_vif.miso),
        .ss_n           (spi_vif.ss_n)
    );

    // SPI Slave
    spi_slave U_SPI_SLAVE (
        .clk    (clk),
        .reset  (reset),
        .sclk   (spi_vif.sclk),
        .mosi   (spi_vif.mosi),
        .ss     (spi_vif.ss_n),
        .tx_data(slave_tx_data),
        .miso   (spi_vif.miso),
        .rx_data(slave_rx_data),
        .rx_done(slave_rx_done),
        .busy   ()
    );

    // spi_if에 연결
    assign spi_vif.slave_rx_data = slave_rx_data;
    assign spi_vif.slave_rx_done = slave_rx_done;
    assign spi_vif.slave_tx_data = slave_tx_data;

    // slave_tx_data config_db에서 받기
    always @(posedge clk) begin
        void'(uvm_config_db #(logic [7:0])::get(null, "*", "slave_tx_data", slave_tx_data));
    end

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset
    initial begin
        reset           = 1;
        axi_vif.awvalid = 0;
        axi_vif.wvalid  = 0;
        axi_vif.bready  = 0;
        axi_vif.arvalid = 0;
        axi_vif.rready  = 0;
        axi_vif.awprot  = 0;
        axi_vif.arprot  = 0;
        axi_vif.wstrb   = 4'hF;
        slave_tx_data   = 0;
        repeat(5) @(posedge clk);
        reset = 0;
        repeat(3) @(posedge clk);
    end

    // UVM 시작
    initial begin
        uvm_config_db #(virtual axi_if)::set(null, "uvm_test_top.*", "axi_vif", axi_vif);
        uvm_config_db #(virtual spi_if)::set(null, "uvm_test_top.*", "spi_vif", spi_vif);
        run_test("spi_test");
    end

endmodule