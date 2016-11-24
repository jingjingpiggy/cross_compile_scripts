#!/bin/bash

################ Dir define #####################
export ROOT_DIR=$PWD
export ICAMERASRC_DIR=$ROOT_DIR/icamerasrc
export LIBCAMHAL_DIR=$ROOT_DIR/libcamhal
export KERNEL_HEADER_DIR=$ROOT_DIR/kernel
export LIBIACSS_DIR=$ROOT_DIR/libiacss
export RPM_DIR=$ROOT_DIR/build
export AIQ_DIR=$ROOT_DIR/libmfldadvci
export AIQB_DIR=$ROOT_DIR/cameralibs/
export AIQB_RPM_DIR=$ROOT_DIR/cameralibs/rpm/
export OUTPUT_DIR=$ROOT_DIR/out

export AIQB_INSTALL_DIR=$ROOT_DIR/out/aiqb
export AIQ_INSTALL_DIR=$ROOT_DIR/out/libiaaiq
export IACSS_INSTALL_DIR=$ROOT_DIR/out/libiacss
export LIBCAMHAL_INSTALL_DIR=$ROOT_DIR/out/libcamhal
export ICAMERASRC_INSTALL_DIR=$ROOT_DIR/out/icamerasrc
export RPMS_INSTALL_DIR=$ROOT_DIR/out/rpms
export TEST_INSTALL_DIR=$ROOT_DIR/out/test

export BUILD_LOG=$OUTPUT_DIR/build.log

ALL_DIRS=($ROOT_DIR $ICAMERASRC_DIR $LIBCAMHAL_DIR $KERNEL_HEADER_DIR $LIBIACSS_DIR $RPM_DIR $AIQ_DIR $OUTPUT_DIR)

source $RPM_DIR/build-dev/command.sh
source $RPM_DIR/build-dev/make.sh


function check_dir() {
    if [ ! -d "$1" ] ; then
        mkdir -p $1 2>/dev/null
    fi
}


function check_output_dir() {
    check_dir $OUTPUT_DIR
    check_dir $AIQB_INSTALL_DIR
    check_dir $AIQ_INSTALL_DIR
    check_dir $IACSS_INSTALL_DIR
    check_dir $LIBCAMHAL_INSTALL_DIR
    check_dir $RPMS_INSTALL_DIR
    check_dir $TEST_INSTALL_DIR
}

function check_cross_compile() {
    export PRE_BUILD_DIR=$RPM_DIR/pre-build/host
}

check_output_dir
check_cross_compile

list
