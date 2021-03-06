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
// Date: 30.04.2017
// Description: mem_if Monitor, monitors the DUT's pins and writes out
//              appropriate sequence items as defined for this particular dut

class mem_if_monitor extends uvm_component;

    // UVM Factory Registration Macro
    `uvm_component_utils(mem_if_monitor)

    // analysis port
    uvm_analysis_port #(mem_if_seq_item) m_ap;

    // Virtual Interface
    virtual mem_if fu;

    //---------------------
    // Data Members
    //---------------------
    mem_if_agent_config m_cfg;

    // Standard UVM Methods:
    function new(string name = "mem_if_driver", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      if (!uvm_config_db #(mem_if_agent_config)::get(this, "", "mem_if_agent_config", m_cfg) )
         `uvm_fatal("CONFIG_LOAD", "Cannot get() configuration mem_if_agent_config from uvm_config_db. Have you set() it?")

        m_ap = new("m_ap", this);

    endfunction: build_phase

    function void connect_phase(uvm_phase phase);
        // connect virtual interface
        fu = m_cfg.fu;
    endfunction

    task run_phase(uvm_phase phase);
        logic[63:0] address [$];
        logic[7:0]  be [$];
    	mem_if_seq_item cmd =  mem_if_seq_item::type_id::create("cmd");
        // Monitor
        // we should also distinguish between slave and master here
        fork
            // detect a request
            forever begin
                mem_if_seq_item cloned_item;
                // wait until detecting a valid request -> store be and address
                @(fu.pck iff (fu.pck.data_gnt && fu.pck.data_req));

                if (!m_cfg.store_if) begin
                    // if (m_cfg.mem_if_config == MASTER)
                    // $display("Pushing Address: %0h", fu.pck.address);
                    address.push_back(fu.pck.address);
                    be.push_back(fu.pck.data_be);

                end else begin
                    $cast(cloned_item, cmd.clone());

                    cmd.address = fu.pck.address;
                    cmd.be = fu.pck.data_be;
                    cmd.data = fu.pck.data_wdata;
                    cmd.mode = WRITE;
                    // export the item via the analysis port
                    $cast(cloned_item, cmd.clone());
                    m_ap.write(cloned_item);
                end
            end
            // request finished send it to the monitor
            forever begin
                @(fu.pck iff fu.pck.data_rvalid);
                if (!m_cfg.store_if) begin
                    mem_if_seq_item cloned_item;
                    automatic logic [63:0] addr;
                    // wait for the rvalid minimum a cycle later
                    addr = address.pop_front();
                    // if (m_cfg.mem_if_config == MASTER)
                    // $display("Popping Address: %0h", addr);
                    cmd.address = addr;
                    cmd.be      = be.pop_front();
                    cmd.data    = fu.pck.data_rdata;
                    // was this from a master or slave agent monitor?
                    cmd.isSlaveAnswer = (m_cfg.mem_if_config inside {SLAVE, SLAVE_REPLAY, SLAVE_NO_RANDOM}) ? 1'b1 : 1'b0;
                    // export the item via the analysis port
                    $cast(cloned_item, cmd.clone());
                    m_ap.write(cloned_item);
                end
            end

        join_none

    endtask : run_phase
endclass : mem_if_monitor
