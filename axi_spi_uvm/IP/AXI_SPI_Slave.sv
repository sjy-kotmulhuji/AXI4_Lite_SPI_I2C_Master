`timescale 1ns / 1ps

module spi_slave (
    input  logic       clk,
    input  logic       reset,
    input  logic       sclk,
    input  logic       mosi,
    input  logic       ss,
    input  logic [7:0] tx_data,
    output logic       miso,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       busy
);

    logic sclk_sync1, sclk_sync2, sclk_sync_d;
    logic sclk_rising_edge;
    logic sclk_falling_edge;

    logic ss_sync1, ss_sync2, ss_sync_d;
    logic ss_falling_edge;
    logic [7:0] rx_shift_reg;
    logic [7:0] tx_shift_reg;
    logic [2:0] bit_cnt;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            {sclk_sync2, sclk_sync1} <= 0;
            sclk_sync_d <= 0;

            {ss_sync2, ss_sync1} <= 2'b11;
            ss_sync_d <= 1;
        end else begin
            {sclk_sync2, sclk_sync1} <= {sclk_sync1, sclk};
            sclk_sync_d <= sclk_sync2;

            {ss_sync2, ss_sync1} <= {ss_sync1, ss};
            ss_sync_d <= ss_sync2;
        end
    end

    assign sclk_rising_edge  = sclk_sync2 & ~sclk_sync_d;
    assign sclk_falling_edge = ~sclk_sync2 & sclk_sync_d;
    assign ss_falling_edge   = ~ss_sync2 & ss_sync_d;
    assign miso              = (!ss) ? tx_shift_reg[7] : 1'bz;

    // mode 0
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            bit_cnt      <= 0;
            rx_shift_reg <= 0;
            tx_shift_reg <= 0;
            rx_data      <= 0;
            rx_done      <= 0;
            busy         <= 0;
        end else begin
            rx_done <= 0;
            if (ss_falling_edge) begin
                tx_shift_reg <= tx_data;
            end
            rx_done <= 0;
            if (!ss) begin
                busy <= 1;
                if (sclk_rising_edge) begin
                    rx_shift_reg <= {rx_shift_reg[6:0], mosi};

                    if (bit_cnt == 7) begin
                        rx_data <= {rx_shift_reg[6:0], mosi};
                        bit_cnt <= 0;
                        rx_done <= 1;
                    end else begin
                        bit_cnt <= bit_cnt + 1;
                    end
                end else if (sclk_falling_edge) begin
                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                end

            end else begin
                bit_cnt <= 0;
                busy <= 0;
            end
        end
    end

endmodule
