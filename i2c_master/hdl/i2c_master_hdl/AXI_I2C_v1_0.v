
`timescale 1 ns / 1 ps

module AXI_I2C_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here

    output wire       scl,
    inout  wire       sda,

    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
    input  wire                                  s00_axi_aclk,
    input  wire                                  s00_axi_aresetn,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input  wire [                         2 : 0] s00_axi_awprot,
    input  wire                                  s00_axi_awvalid,
    output wire                                  s00_axi_awready,
    input  wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input  wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input  wire                                  s00_axi_wvalid,
    output wire                                  s00_axi_wready,
    output wire [                         1 : 0] s00_axi_bresp,
    output wire                                  s00_axi_bvalid,
    input  wire                                  s00_axi_bready,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input  wire [                         2 : 0] s00_axi_arprot,
    input  wire                                  s00_axi_arvalid,
    output wire                                  s00_axi_arready,
    output wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [                         1 : 0] s00_axi_rresp,
    output wire                                  s00_axi_rvalid,
    input  wire                                  s00_axi_rready
);

	wire       cmd_start;
    wire       cmd_write;
    wire       cmd_read;
    wire       cmd_stop;
    wire [7:0] tx_data;
    wire       ack_in;

    // Instantiation of Axi Bus Interface S00_AXI
    AXI_I2C_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) AXI_I2C_v1_0_S00_AXI_inst (
        .cmd_start    (cmd_start),
        .cmd_write    (cmd_write),
        .cmd_read     (cmd_read),
        .cmd_stop     (cmd_stop),
        .tx_data      (tx_data),
        .ack_in       (ack_in),
        .rx_data      (rx_data),
        .done         (done),
        .ack_out      (ack_out),
        .busy         (busy),
        .S_AXI_ACLK   (s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR (s00_axi_awaddr),
        .S_AXI_AWPROT (s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA  (s00_axi_wdata),
        .S_AXI_WSTRB  (s00_axi_wstrb),
        .S_AXI_WVALID (s00_axi_wvalid),
        .S_AXI_WREADY (s00_axi_wready),
        .S_AXI_BRESP  (s00_axi_bresp),
        .S_AXI_BVALID (s00_axi_bvalid),
        .S_AXI_BREADY (s00_axi_bready),
        .S_AXI_ARADDR (s00_axi_araddr),
        .S_AXI_ARPROT (s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA  (s00_axi_rdata),
        .S_AXI_RRESP  (s00_axi_rresp),
        .S_AXI_RVALID (s00_axi_rvalid),
        .S_AXI_RREADY (s00_axi_rready)
    );

    // Add user logic here
    I2C_Master U_I2C_MASTER (
        .clk      (s00_axi_aclk),
        .reset    (~s00_axi_aresetn),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (tx_data),
        .ack_in   (ack_in),
        .rx_data  (rx_data),
        .done     (done),
        .ack_out  (ack_out),
        .busy     (busy),
        .scl      (scl),
        .sda      (sda)
    );

    // User logic ends

endmodule

module I2C_Master (
    input  wire       clk,
    input  wire       reset,
    input  wire       cmd_start,
    input  wire       cmd_write,
    input  wire       cmd_read,
    input  wire       cmd_stop,
    input  wire [7:0] tx_data,
    input  wire       ack_in,
    output wire [7:0] rx_data,
    output wire       done,
    output wire       ack_out,
    output wire       busy,
    output wire       scl,
    inout  wire       sda
);

    //SDA port 연결
    wire sda_o, sda_i;

    assign sda_i = (sda === 1'bz) ? 1'b1 : sda;
    //assign sda_i = sda;
    //assign sda   = sda_o;
    assign sda   = sda_o ? 1'bz : 1'b0;

    i2c_master U_I2C_MASTER (
        .clk      (clk),
        .reset    (reset),
        .cmd_start(cmd_start),
        .cmd_write(cmd_write),
        .cmd_read (cmd_read),
        .cmd_stop (cmd_stop),
        .tx_data  (tx_data),
        .ack_in   (ack_in),
        .rx_data  (rx_data),
        .done     (done),
        .ack_out  (ack_out),
        .busy     (busy),
        .scl      (scl),
        .sda_o    (sda_o),
        .sda_i    (sda_i)
    );

endmodule

module i2c_master (
    input  wire       clk,
    input  wire       reset,
    input  wire       cmd_start,
    input  wire       cmd_write,
    input  wire       cmd_read,
    input  wire       cmd_stop,
    input  wire [7:0] tx_data,
    input  wire       ack_in,
    output reg  [7:0] rx_data,
    output reg        done,
    output reg        ack_out,
    output wire       busy,
    output wire       scl,
    output wire       sda_o,
    input  wire       sda_i
);

    parameter IDLE = 3'b000;
    parameter START = 3'b001;
    parameter WAIT_CMD = 3'b010;
    parameter DATA = 3'b011;
    parameter DATA_ACK = 3'b100;
    parameter STOP = 3'b101;

    reg [2:0] state;
    reg [7:0] div_cnt;  //0~249
    reg       qtr_tick;
    reg scl_r, sda_r;
    reg [1:0] step;
    reg [2:0] bit_cnt;
    reg [7:0] tx_shift_reg, rx_shift_reg;
    reg is_read, ack_in_r;


    //assign ack_in_r = ack_in;
    assign scl   = scl_r;
    assign sda_o = sda_r;
    assign busy  = (state != IDLE);  //IDLE에서만 busy 0

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_cnt  <= 0;
            qtr_tick <= 0;
        end else begin
            if (div_cnt == 249) begin  //scl : 100Khz
                div_cnt  <= 0;
                qtr_tick <= 1'b1;  //quarter tick
            end else begin
                div_cnt  <= div_cnt + 1;
                qtr_tick <= 1'b0;
            end
        end
    end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state        <= IDLE;
            scl_r        <= 1'b1;
            sda_r        <= 1'b1;
            //busy         <= 1'b0; //초기화는 해야 하는 거 아냐,?
            step         <= 0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            is_read      <= 0;
            bit_cnt      <= 0;  //default
            ack_in_r     <= 1'b1;  //nack 상태로 초기화(이유없음)
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    scl_r <= 1'b1;
                    sda_r <= 1'b1;
                    //busy  <= 1'b0;
                    if (cmd_start) begin
                        state <= START;
                        step  <= 0;
                        //busy  <= 1'b1;
                    end
                end
                START: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b1;
                                scl_r <= 1'b1;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                sda_r <= 1'b0;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                step <= 2'd0;
                                done  <= 1'b1;  //demo에서 done 값 받아 다음 상태 실행
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end
                WAIT_CMD: begin
                    step <= 0;
                    if (cmd_write) begin
                        tx_shift_reg <= tx_data;
                        bit_cnt <= 0;  //최상위 bit부터 출력하므로?
                        is_read <= 1'b0;  //write
                        state <= DATA;
                    end else if (cmd_read) begin
                        rx_shift_reg <= 0;
                        bit_cnt      <= 0;
                        is_read      <= 1'b1;  //read
                        state        <= DATA;
                    end else if (cmd_stop) begin
                        state <= STOP;
                    end else if (cmd_start) begin
                        state <= START;
                    end
                end
                DATA: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                //read일 때 1 출력해서 z 상태로 만듦.
                                sda_r <= is_read ? 1'b1 : tx_shift_reg[7];   //read이면 1, write이면 전송
                                //전송값으로 step 0~3 유지(0이면 0, 1이면 1)
                                step <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;
                                if(is_read) begin   //read 동작 시 step 3에서 sampling
                                    rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                if (!is_read) begin
                                    tx_shift_reg <= {
                                        tx_shift_reg[6:0], 1'b0
                                    };  //write일 때 shift
                                end
                                step <= 2'd0;
                                if (bit_cnt == 7) begin
                                    ack_in_r <= 1'b0;
                                    state <= DATA_ACK;
                                end else begin
                                    bit_cnt <= bit_cnt + 1;
                                end
                            end
                        endcase
                    end
                end
                DATA_ACK: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                scl_r <= 1'b0;
                                if (is_read) begin
                                    sda_r <= ack_in_r;  //read일 때 host로부터 받은 ack 값 출력
                                end else begin
                                    sda_r <= 1'b1;  //write인 경우 slave에서 ack 신호 받아야 하므로 끊어줌
                                end
                                step <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                scl_r <= 1'b1;
                                if (!is_read) begin  //write일 때
                                    ack_out <= sda_i;   //slave로부터 ack 신호 수신
                                end else begin   //read일 때 ack: 1byte 데이터 다 받았다는 의미이므로 rx_data 출력
                                    rx_data <= rx_shift_reg;
                                end
                                step <= 2'd3;
                            end
                            2'd3: begin
                                scl_r <= 1'b0;
                                done  <= 1'b1;
                                step  <= 2'd0;
                                state <= WAIT_CMD;
                            end
                        endcase
                    end
                end
                STOP: begin
                    if (qtr_tick) begin
                        case (step)
                            2'd0: begin
                                sda_r <= 1'b0;
                                scl_r <= 1'b0;
                                step  <= 2'd1;
                            end
                            2'd1: begin
                                scl_r <= 1'b1;
                                step  <= 2'd2;
                            end
                            2'd2: begin
                                sda_r <= 1'b1;
                                step  <= 2'd3;
                            end
                            2'd3: begin
                                step  <= 2'd0;
                                done  <= 1'b1;
                                state <= IDLE;
                            end
                        endcase
                    end
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
