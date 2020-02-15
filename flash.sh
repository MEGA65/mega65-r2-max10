#!/bin/bash

PATH=${PATH}:/opt/Quartus/18.1/quartus/bin

sudo pkill jtagd
sudo /opt/Quartus/18.1/quartus/bin/jtagd
sudo /opt/Quartus/18.1/quartus/bin/jtagconfig

quartus_pgm -m jtag -o "p;output_files/mega65-r2-max10.pof"
