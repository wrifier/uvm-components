// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author: Florian Zaruba, ETH Zurich
// Date: 24.4.2017
// Description: Memory Arbiter Testbench


module dcache_arbiter_tb;

    import uvm_pkg::*;
    // import the main test class
    import mem_arbiter_lib_pkg::*;

    logic rst_ni, clk;

    dcache_if master[3](clk);
    dcache_if slave(clk);
    // super hack in assigning the wire a value
    // we need to keep all interface signals as wire as
    // the simulator does not now if this interface will be used
    // as an active or passive device
    // only helpful thread so far:
    // https://verificationacademy.com/forums/uvm/getting-multiply-driven-warnings-vsim-passive-agent
    // logic data_gnt_driver = 'z;
    // assign data_gnt = data_gnt_driver & data_req;

    dcache_arbiter dut (
        .clk_i             ( clk                             ),
        .rst_ni            ( rst_ni                          ),

        .address_index_o   ( slave.address_index             ),
        .address_tag_o     ( slave.address_tag               ),
        .data_wdata_o      ( slave.data_wdata                ),
        .data_req_o        ( slave.data_req                  ),
        .data_we_o         ( slave.data_we                   ),
        .data_be_o         ( slave.data_be                   ),
        .tag_valid_o       ( slave.tag_valid                 ),
        .kill_req_o        ( slave.kill_req                  ),
        .data_gnt_i        ( slave.data_req & slave.data_gnt ),
        .data_rvalid_i     ( slave.data_rvalid               ),
        .data_rdata_i      ( slave.data_rdata                ),

        .address_index_i   ( {master[2].address_index, master[1].address_index,  master[0].address_index} ),
        .address_tag_i     ( {master[2].address_tag,   master[1].address_tag,    master[0].address_tag}   ),
        .data_wdata_i      ( {master[2].data_wdata,    master[1].data_wdata,     master[0].data_wdata}    ),
        .data_req_i        ( {master[2].data_req,      master[1].data_req,       master[0].data_req}      ),
        .data_we_i         ( {master[2].data_we,       master[1].data_we,        master[0].data_we}       ),
        .data_be_i         ( {master[2].data_be,       master[1].data_be,        master[0].data_be}       ),
        .tag_valid_i       ( {master[2].tag_valid,     master[1].tag_valid,      master[0].tag_valid}     ),
        .kill_req_i        ( {master[2].kill_req,      master[1].kill_req,       master[0].kill_req}      ),
        .data_gnt_o        ( {master[2].data_gnt,      master[1].data_gnt,       master[0].data_gnt}      ),
        .data_rvalid_o     ( {master[2].data_rvalid,   master[1].data_rvalid,    master[0].data_rvalid}   ),
        .data_rdata_o      ( {master[2].data_rdata,    master[1].data_rdata,     master[0].data_rdata}    )
    );

    initial begin
        clk = 1'b0;
        rst_ni = 1'b0;
        repeat(8)
            #10ns clk = ~clk;

        rst_ni = 1'b1;
        forever
            #10ns clk = ~clk;
    end

    program testbench (dcache_if master[3], dcache_if slave);
        initial begin
            // register the memory interface
            uvm_config_db #(virtual dcache_if)::set(null, "uvm_test_top", "dcache_if_slave", slave);
            uvm_config_db #(virtual dcache_if)::set(null, "uvm_test_top", "dcache_if_master0", master[0]);
            uvm_config_db #(virtual dcache_if)::set(null, "uvm_test_top", "dcache_if_master1", master[1]);
            uvm_config_db #(virtual dcache_if)::set(null, "uvm_test_top", "dcache_if_master2", master[2]);
            // print the topology
            uvm_top.enable_print_topology = 1;
            // Start UVM test
            run_test();
        end
    endprogram

    testbench tb (master, slave);
endmodule
