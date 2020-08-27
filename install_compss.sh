#!/bin/bash -eu
topdir=`dirname $0`
compss_version=${1:-TrunkSHMA}
clonedir=${2:-${topdir}/compss}
target_branch=${3:-add-shared-memory-arrays}
rm -rf ${clonedir}
git clone --single-branch --branch ${target_branch} git@github.com:bsc-wdc/compss.git "${clonedir}"
cd "${clonedir}"
./submodules_get.sh
./submodules_patch.sh
GIT_DIR=dependencies/shared-array/.git git describe --tags --always --dirty > dependencies/shared-array/.version

# jenv exec builders/scs/nord/buildNord userlogin home_dir_remote/tmp install_dir_remote/"${compss_version}"
