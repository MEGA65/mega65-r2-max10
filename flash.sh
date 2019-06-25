#!/bin/bash

PATH=${PATH}:/opt/Quartus/18.1/quartus/bin

quartus_pgm -m jtag -o "p;output_files/mega65-r2-max10.pof"
