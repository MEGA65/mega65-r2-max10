#!/bin/bash

# ###############################
# get branch name
#
branch=`git rev-parse --abbrev-ref HEAD`
#echo ${branch}
#
# if branchname is long, just use the first X-chars and last X-chars, ie "abcde...vwxyz"
branchlen=$(( ${#branch} ))
#echo ${branchlen}
#
if [ ${branchlen} -gt 13 ] ; then
  branch_abcde=${branch:0:5}
  branch_v_pos=$(( ${branchlen}-5 ))
  branch_vwxyz=${branch:${branch_v_pos}:5}
  echo "${branch_abcde} ${branch_v_pos} ${branch_vwxyz}"
  branch="${branch_abcde}...${branch_vwxyz}"
fi
echo ${branch}


# ###############################
# get git-commit and the dirty-flag
#
commit_id=`git describe --always --abbrev=7 --dirty=~`
version32=`git describe --always --abbrev=8`
datestamp=$(expr $(expr $(date +%Y) - 2020) \* 366 + `date +%j`)


# ###############################
# get timestamp
#
datetime=`date +%Y%m%d.%H`


# ###############################
# get incrememting number (number of commits since branching from branch "ghdl-crash-20200604")
num_commits="$(git log --oneline | wc -l)"
#echo ${num_commits}


# ###############################
# and put it all together
#
stringout="${branch},${num_commits},${datetime},${commit_id}"
echo $stringout


# ###############################
# generate the source file(s)
#
cat > version.vhdl <<ENDTEMPLATE
library ieee;
use Std.TextIO.all;
use ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package version is

  constant gitcommit : string := "${stringout}";
  constant fpga_commit : unsigned(31 downto 0) := x"${version32}";
  constant fpga_datestamp : unsigned(15 downto 0) := to_unsigned(${datestamp},16);

end version;
ENDTEMPLATE
echo "wrote: version.vhdl"


