#!/bin/env python3

from vunit import VUnit

# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()

# Create library 'lib'
lib = vu.add_library("lib")

# Add all files ending in .vhd in current working directory to library
lib.add_source_files("tests/tb_*.vhdl")
lib.add_source_files("*.vhdl")
lib.add_source_files("*.vhd")
lib.add_source_files("mega65kbd_to_matrix.vhdl")
lib.add_source_files("i2c_slave/rtl/vhdl/*.vhdl")

vu.set_compile_option("ghdl.a_flags", ["-frelaxed-rules"])
vu.set_compile_option("ghdl.flags", ["-frelaxed-rules"])
vu.set_sim_option("ghdl.elab_flags", ["-frelaxed-rules"])

# Run vunit function
vu.main()
