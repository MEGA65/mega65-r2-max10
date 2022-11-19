#!/bin/bash

./version.sh

PATH=${PATH}:/opt/Quartus/18.1/quartus/bin

quartus_map --read_settings_files=on --write_settings_files=off mega65-r2-max10 -c mega65-r2-max10 && \
quartus_fit --read_settings_files=on --write_settings_files=off mega65-r2-max10 -c mega65-r2-max10 && \
quartus_asm --read_settings_files=off --write_settings_files=off mega65-r2-max10 -c mega65-r2-max10
quartus_sta --do_report_timing mega65-r2-max10 -c mega65-r2-max10 | tee timing_report.txt
