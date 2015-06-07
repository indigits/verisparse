`include "verisparse.svh"
`include "verification/vv_logger.svh"

import vs_logger::*;
import vs_util::*;

module test_matrix_residual_sweeper;
    logic clock = 1;
    logic reset_n = 0;
    logic start;
    logic done;

    parameter ROWS = 4;
    parameter COLUMNS = 8;
    const int CELLS = ROWS * COLUMNS;

    logic prod_write_enable;
    logic [7:0] prod_read_addr;
    logic [7:0] prod_write_addr;
    logic[FP_DATA_BUS_WIDTH-1:0]  prod_in_data;
    logic[FP_DATA_BUS_WIDTH-1:0]  prod_out_data;

    vs_single_clock_synchronous_ram #(32, 8) products(
        .clock(clock),
        .write_enable(prod_write_enable),
        .read_addr(prod_read_addr),
        .write_addr(prod_write_addr),
        .in_data(prod_in_data),
        .out_data(prod_out_data));

    logic res_write_enable;
    logic [7:0] res_read_addr;
    logic [7:0] res_write_addr;
    logic[FP_DATA_BUS_WIDTH-1:0]  res_in_data;
    logic[FP_DATA_BUS_WIDTH-1:0]  res_out_data;

    vs_single_clock_synchronous_ram #(32, 8) residuals(
        .clock(clock),
        .write_enable(res_write_enable),
        .read_addr(res_read_addr),
        .write_addr(res_write_addr),
        .in_data(res_in_data),
        .out_data(res_out_data));

    logic phi_write_enable;
    logic [15:0] phi_read_addr;
    logic [15:0] phi_write_addr;
    logic[FP_DATA_BUS_WIDTH-1:0]  phi_in_data;
    logic[FP_DATA_BUS_WIDTH-1:0]  phi_out_data;
    bit batch_products_transferred;
    vs_sensing_matrix_command_t command;

    vs_single_clock_synchronous_ram #(32, 16) sensing_matrix(
        .clock(clock),
        .write_enable(phi_write_enable),
        .read_addr(phi_read_addr),
        .write_addr(phi_write_addr),
        .in_data(phi_in_data),
        .out_data(phi_out_data));


    logic[FP_DATA_BUS_WIDTH-1:0]  proc_read_data;
    logic proc_read_select = 0;
    vs_mux_2x1 #(FP_DATA_BUS_WIDTH) processor_read_data_mux(proc_read_select,
            res_out_data, phi_out_data,
            proc_read_data
        );

    vs_sensing_matrix_processor #(ROWS, COLUMNS, 0, 2) uut(
        clock, reset_n, 
        res_read_addr, proc_read_data,
        prod_write_enable, prod_write_addr, prod_in_data,
        command, start, done, batch_products_transferred);

    task automatic fill_matrix_and_residual();
        verisparse::int_arr_t phi_cw = {
        1, 1, 1, 1,
        1, 1, -1, -1,
        1, -1, -1, 1,
        1, -1, 1, -1,
        1, 1, 1, -1,
        1, 1, -1, 1,
        1, -1, 1, 1,
        -1, 1, 1, 1
        };
        verisparse::int_arr_t residual = {1, 2, 2, 1};
        int index = 0;
        for (int c=0; c<COLUMNS; ++c)
            for (int r=0; r< ROWS; ++r)  begin
                sensing_matrix.ram[index] = phi_cw[index];
                //uut.phi[r][c] = phi_cw[index++];
                ++index;
            end

        for (int r=0; r < ROWS; ++r) begin
            residuals.ram[r] = residual[r];
        end


    endtask : fill_matrix_and_residual

    task automatic verify_sweep();
        $display("Sweep started");
        // reset the chip
        reset_n = 0;
        // wait for next clock edge
        @(posedge clock);
        $display("Reset completed");
        // remove reset.
        reset_n = 1;

        // load the sensing matrix
        command = LOAD_SENSING_MATRIX;
        // we need to provide data from the sensing matrix
        proc_read_select = 1;
        phi_read_addr = 0;
        @(posedge clock);
        // initiate transfer of sensing matrix
        start = 1;
        // wait for next clock edge
        @(posedge clock);
        $display("Start signal sent for loading matrix");
        start = 0;
        while (!done) begin
            phi_read_addr = phi_read_addr + 1;
            // $display("read addr: %d, data: %d, %d", 
            //     phi_read_addr, phi_out_data, 
            //     proc_read_data);
            @(posedge clock);
        end
        // the computation must have started
        // wait for the computation to complete
        wait(done);
        // now verify everything.
        $display("Matrix load completed");
        print_phi();


        // start the computation
        command = COMPUTE_INNER_PRODUCTS;
        // we need to send data from residual memory
        proc_read_select = 0;
        start = 1;
        // wait for next clock edge
        @(posedge clock);
        $display("Start signal sent for sweeping");
        start = 0;
        // the computation must have started
        // wait for the computation to complete
        wait(done);
        // now verify everything.
        $display("Sweep completed");

    endtask : verify_sweep

    task automatic print_phi();
        for (int r=0; r< ROWS; ++r)  begin
            for (int c=0; c<COLUMNS; ++c) begin
                $write("%4d ", uut.phi[r][c]);
                //$write("%4d ", fp_32_t'(sensing_matrix.ram[c*ROWS + r]));
            end
            $display("");
        end
        $display("");
    endtask

    task automatic print_residual();
        for (int r=0; r< ROWS; ++r)  begin
            $write("%4d ", residuals.ram[r]);
        end
        $display("");
    endtask

    task automatic print_products();
        for (int i=0; i< COLUMNS; ++i)  begin
            $write("%4d ", fp_32_t'(products.ram[i]));
        end
        $display("");
    endtask

    initial begin
        // a fixed number of clock cycles
        repeat (2000) #50 clock = ~clock;
    end

    initial begin
        fill_matrix_and_residual();
        $display("Phi and Residual have been loaded");
        print_phi();
        print_residual();
        verify_sweep();
        $display("Inner products");
        print_products();
    end

    always @(posedge clock) begin
        //$display("uut state: %s", uut.state.name);
    end
endmodule
