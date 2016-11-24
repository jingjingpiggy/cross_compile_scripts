#!/bin/bash

################ Configure options define #####################
REBUILD=0
MAKE_DEPENDENCE=0
MAKE_OPTION=

function check_result() {
    local res=$1
    local func=$2

    if [ $res -eq 0 ] ; then
        echo "###############" "  $func  OK  " "#############"
    else
        echo "###############" "  $func  FAIL  " "#############"
        exit 1
    fi
}

function check_fail() {
    local res=$1
    local func=$2

    if [ $res -ne 0 ] ; then
        echo "###############" "  $func  FAIL  " "#############"
        exit 1
    fi
}

function aiq_build() {
    echo "###############" "  $FUNCNAME  " "#############"

    cd $AIQ_DIR/
    autoreconf -i
    check_result $? "Autoreconf"

    ./configure ${CONFIGURE_FLAGS} --with-project=dss --prefix $AIQ_INSTALL_DIR
    check_result $? "AIQ configure"

    make install
    find ${AIQ_INSTALL_DIR}/ -name "*.la" -exec rm -f "{}" \;

    #remove useless header files and libraries
    rm -v $AIQ_INSTALL_DIR/include/ia_imaging/ia_isp_1_*
    rm -v $AIQ_INSTALL_DIR/include/ia_imaging/ia_isp_2_*
    rm -v $AIQ_INSTALL_DIR/include/ia_imaging/pvl_*
    check_result $? $FUNCNAME
}

function aiq_rpm_install() {
    echo "###############" "  $FUNCNAME  " "#############"

    goto $AIQ_DIR
    rm -f rpm/libiaaiq*.rpm
    make rpm
    check_fail $? $FUNCNAME

    cp -fv rpm/libiaaiq*.rpm $RPMS_INSTALL_DIR

    check_result $? $FUNCNAME
}

function aiqb_configure() {
    echo "###############" "  $FUNCNAME  " "#############"

    if [ -n "$SDKTARGETSYSROOT" ]; then
        export PKG_CONFIG_SYSROOT_DIR=
    fi
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$AIQ_INSTALL_DIR/lib/pkgconfig
    if [ $REBUILD -eq 1 -o ! -f configure ] ; then
        rm -fr config/  config.h.in autom4te.cache/ aclocal.m4 m4 *-libtool
        autoreconf --install
        ./configure ${CONFIGURE_FLAGS} --prefix=$AIQB_INSTALL_DIR
    fi
    check_result $? $FUNCNAME
}

function aiqb_build() {
    echo "###############" "  $FUNCNAME  " "#############"

    if [ $REBUILD -eq 1 ] ; then
        make clean
    fi

    make $MAKE_OPTION
    check_fail $? $FUNCNAME

    make install
    check_result $? $FUNCNAME
    find ${IACSS_INSTALL_DIR}/ -name "*.la" -exec rm -f "{}" \;

    check_dir $AIQB_INSTALL_DIR/etc/camera
    cp -frv $AIQB_DIR/cpf/aiq/ov13860.aiqb $AIQB_INSTALL_DIR/etc/camera/
    cp -frv $AIQB_DIR/cpf/aiq/imx185.aiqb $AIQB_INSTALL_DIR/etc/camera/
    cp -frv $AIQB_DIR/cpf/aiq/imx185-hdr.aiqb $AIQB_INSTALL_DIR/etc/camera/
    check_result $? $FUNCNAME
}

function aiqb_rpm_install() {
    echo "###############" "  $FUNCNAME  " "#############"

    goto $AIQB_RPM_DIR
    rm -f aiqb*.rpm
    ./build_rpm.sh
    check_fail $? $FUNCNAME

    cp -fv aiqb*.rpm $RPMS_INSTALL_DIR

    check_result $? $FUNCNAME
}

function iacss_configure() {
    echo "###############" "  $FUNCNAME  " "#############"

    if [ -n "$SDKTARGETSYSROOT" ]; then
        export PKG_CONFIG_SYSROOT_DIR=
    fi
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$AIQ_INSTALL_DIR/lib/pkgconfig:$AIQB_INSTALL_DIR/lib/pkgconfig
    if [ $REBUILD -eq 1 -o ! -f configure ] ; then
        rm -fr config/  config.h.in autom4te.cache/ aclocal.m4 m4 *-libtool
        autoreconf --install
        ./configure ${CONFIGURE_FLAGS} --with-kernel-sources=$KERNEL_HEADER_DIR --with-B0=yes --with-aiq=yes --prefix=$IACSS_INSTALL_DIR
    fi
    check_result $? $FUNCNAME
}

function iacss_build() {
    echo "###############" "  $FUNCNAME  " "#############"

    if [ $REBUILD -eq 1 ] ; then
        make clean
    fi

    make $MAKE_OPTION
    check_fail $? $FUNCNAME

    make install
    check_result $? $FUNCNAME
    find ${IACSS_INSTALL_DIR}/ -name "*.la" -exec rm -f "{}" \;
}

function iacss_rpm_install() {
    echo "###############" "  $FUNCNAME  " "#############"

    goto $LIBIACSS_DIR
    rm -f rpm/libiacss*.rpm
    make rpm
    check_fail $? $FUNCNAME

    cp -fv rpm/libiacss*.rpm $RPMS_INSTALL_DIR

    check_result $? $FUNCNAME
}

function libcamhal_configure() {
    echo "###############" "  $FUNCNAME  " "#############"

    if [ -n "$SDKTARGETSYSROOT" ]; then
        export PKG_CONFIG_SYSROOT_DIR=
    fi
    # Add the dependencies to the path of package configure
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$AIQ_INSTALL_DIR/lib/pkgconfig:$AIQB_INSTALL_DIR/lib/pkgconfig:$IACSS_INSTALL_DIR/lib/pkgconfig
    if [ $REBUILD -eq 1 -o ! -f configure ] ; then
        rm -fr config.h.in autom4te.cache/ aclocal.m4 *-libtool config.guess compile config.sub configure depcomp install-sh ltmain.sh m4
        autoreconf --install
        CFLAGS="-O2" CXXFLAGS="-O2" ./configure ${CONFIGURE_FLAGS} --prefix=$LIBCAMHAL_INSTALL_DIR
    fi

    check_result $? $FUNCNAME
}

function libcamhal_build() {
    echo "###############" "  $FUNCNAME  " "#############"

    if [ $REBUILD -eq 1 ] ; then
        make clean
    fi

    make $MAKE_OPTION
    check_fail $? $FUNCNAME

    make install
    check_fail $? $FUNCNAME
    find ${LIBCAMHAL_INSTALL_DIR}/ -name "*.la" -exec rm -f "{}" \;

    check_dir $LIBCAMHAL_INSTALL_DIR/include
    cp -frv include/* $LIBCAMHAL_INSTALL_DIR/include

    check_dir $LIBCAMHAL_INSTALL_DIR/lib
    cp -frv .libs/*.so* $LIBCAMHAL_INSTALL_DIR/lib
    cp -frv .libs/*.a $LIBCAMHAL_INSTALL_DIR/lib

    check_dir $LIBCAMHAL_INSTALL_DIR/etc/camera
    cp -frv config/*.xml $LIBCAMHAL_INSTALL_DIR/etc/camera

    check_result $? $FUNCNAME
}

function libcamhal_rpm_install() {
    echo "###############" "  $FUNCNAME  " "#############"

    goto $LIBCAMHAL_DIR
    rm -f rpm/libcamhal*.rpm
    make rpm
    check_fail $? $FUNCNAME

    cp -fv rpm/libcamhal*.rpm $RPMS_INSTALL_DIR

    check_result $? $FUNCNAME
}

function libcamhal_build_test() {
    echo "###############" "  $FUNCNAME  " "#############"

    goto $LIBCAMHAL_DIR
    cd test

    if [ -n "$SDKTARGETSYSROOT" ]; then
        export PKG_CONFIG_SYSROOT_DIR=
    fi
    # Add the dependencies to the path of package configure
    export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$AIQ_INSTALL_DIR/lib/pkgconfig:$IACSS_INSTALL_DIR/lib/pkgconfig
    if [ $REBUILD -eq 1 ] ; then
        make clean
    fi

    make $MAKE_OPTION
    check_fail $? $FUNCNAME
    cd -
    cp -frv test $TEST_INSTALL_DIR/libcamhal-test

    check_result $? $FUNCNAME
}

function icamerasrc_configure() {
    echo "###############" "  $FUNCNAME  " "#############"

    if [ -n "$SDKTARGETSYSROOT" ]; then
        export GST_LIBS="-L$SDKTARGETSYSROOT/usr/lib -lgstvideo-1.0 -lgstbase-1.0 -lgstreamer-1.0 -lgobject-2.0 -lglib-2.0"
        export GST_CFLAGS="-I$SDKTARGETSYSROOT/usr/include/gstreamer-1.0 -I$SDKTARGETSYSROOT/usr/lib/gstreamer-1.0/include \
            -I$SDKTARGETSYSROOT/usr/include/glib-2.0 -I$SDKTARGETSYSROOT/usr/lib/glib-2.0/include"
    fi

    if [ $REBUILD -eq 1 -o ! -f configure ] ; then
        rm -fr config.h.in autom4te.cache/ aclocal.m4 *-libtool config.guess compile config.sub configure depcomp install-sh ltmain.sh m4
        autoreconf --install
        CPPFLAGS="-I$LIBCAMHAL_INSTALL_DIR/include/ -I$LIBCAMHAL_INSTALL_DIR/include/api -I$LIBCAMHAL_INSTALL_DIR/include/utils " LDFLAGS="-L$LIBCAMHAL_INSTALL_DIR/lib/" CFLAGS="-O2" CXXFLAGS="-O2" ./configure ${CONFIGURE_FLAGS} --prefix=$ICAMERASRC_INSTALL_DIR DEFAULT_CAMERA=13
    fi

    check_result $? $FUNCNAME
}

function icamerasrc_build() {
    echo "###############" "  $FUNCNAME  " "#############"

    if [ $REBUILD -eq 1 ] ; then
        make clean
    fi

    make $MAKE_OPTION
    check_result $? $FUNCNAME

    make install
    check_result $? $FUNCNAME
    find ${ICAMERASRC_INSTALL_DIR}/ -name "*.la" -exec rm -f "{}" \;
}

function icamerasrc_rpm_install() {
    echo "###############" "  $FUNCNAME  " "#############"

    goto $ICAMERASRC_DIR
    rm -f rpm/icamerasrc*.rpm
    make rpm
    check_fail $? $FUNCNAME
    cp -fv rpm/icamerasrc*.rpm $RPMS_INSTALL_DIR

    check_result $? $FUNCNAME
}

function icamerasrc_build_test() {
    echo "###############" "  $FUNCNAME  " "#############"

    goto $ICAMERASRC_DIR

    if [ -n "$SDKTARGETSYSROOT" ]; then
        export GST_LIBS="-L$SDKTARGETSYSROOT/usr/lib -lgstvideo-1.0 -lgstbase-1.0 -lgstreamer-1.0 -lgobject-2.0 -lglib-2.0"
        export GST_CFLAGS="-I$SDKTARGETSYSROOT/usr/include/gstreamer-1.0 -I$SDKTARGETSYSROOT/usr/lib/gstreamer-1.0/include \
            -I$SDKTARGETSYSROOT/usr/include/glib-2.0 -I$SDKTARGETSYSROOT/usr/lib/glib-2.0/include"
    fi
    cd test
    if [ $REBUILD -eq 1 ] ; then
        make clean
    fi
    make $MAKE_OPTION
    check_fail $? $FUNCNAME

    cd utils
    make $MAKE_OPTION

    goto $ICAMERASRC_DIR
    cp -frv test $TEST_INSTALL_DIR/icamera-test
    check_result $? $FUNCNAME
}

inodes=()
function get_build_inodes() {
    for((i=0;i<${#BUILD_DIRS[@]};i++));do
        #echo "$i: ${BUILD_DIRS[$i]}"
        inodes[$i]=`ls -di ${BUILD_DIRS[$i]} | awk '{print $1}'`
    done
}

function find_build_inode() {
    local lookup_dir=$1
    local parent=$1
    local lookup_inode=`ls -di $lookup_dir | awk '{print $1}' `

    build_root_inode=${inodes[0]}

    while [ $build_root_inode != $lookup_inode ] ; do
        for((i=1;i<${#inodes[@]};i++));do
            if [ $lookup_inode = ${inodes[$i]} ] ; then
                return $i
            fi
        done

        parent=`dirname $parent`
        lookup_inode=`ls -di $parent | awk '{print $1}' `
    done

    if [ $build_root_inode = $lookup_inode ] ; then
       return 0
    else
        # Not found #
        return 10000
    fi
}

function mm() {
    local build_root_inode
    REBUILD=0
    MAKE_DEPENDENCE=0
    MAKE_OPTION=

    check_output_dir
    get_build_inodes

    find_build_inode $PWD
    build_index=$?

    if [ $build_index -eq 10000 ] ; then
        echo $PWD is not build directory
        return 
    fi

    while [ -n "$1" ] ; do
        case $1 in
          -B) REBUILD=1 ;;
          -D) MAKE_DEPENDENCE=1;;
          -j) MAKE_OPTION="-j";;
        esac
        shift 1
    done

    rm -f $BUILD_LOG
    if [ $MAKE_DEPENDENCE -eq 1 ] ; then
        REBUILD=1
        for((i=1;i<$build_index;i++));do
            ${build_steps[$i]} 2>&1 | tee $BUILD_LOG
        done
    fi

    ${build_steps[$build_index]} 2>&1 | tee -a $BUILD_LOG

    handle_log
}

function mmm() {
    check_output_dir

    goto ${BUILD_DIRS[0]}

    REBUILD=1
    MAKE_OPTION="-j"
    rm -f $BUILD_LOG
    ${build_steps[0]} 2>&1 | tee -a $BUILD_LOG

    handle_log
}

function handle_log() {
    grep "FAIL" $BUILD_LOG
    ret=$?
    cp -fr $BUILD_LOG `dirname $BUILD_LOG`/build-`date +%m%H%M`.log
    mv $BUILD_LOG `dirname $BUILD_LOG`/build-latest.log

    if [ $ret -eq 0 ]; then
        return 1
    fi
}

function mm_helper() {
    echo "  mm [-B|-D|-j]: build command"
    echo "     -B: rebuild this project, include reconfigure/build/install"
    echo "     -D: rebuild this project & its dependence"
    echo "     -j: make option, use multi-jobs to do make"
}

function mmm_helper() {
    echo "  mmm : build all projects, you can run this at anywhere under repo"
}

aiq_build_steps () {
    pushd ${AIQ_DIR}
    aiq_build
    aiq_rpm_install
    popd
}

aiqb_build_steps () {
    pushd ${AIQB_DIR}
    aiqb_configure
    aiqb_build
    aiqb_rpm_install
    popd
}

iacss_build_steps() {
    pushd ${LIBIACSS_DIR}
    iacss_configure
    iacss_build
    iacss_rpm_install
    popd
}

libcamhal_build_steps() {
    pushd ${LIBCAMHAL_DIR}
    libcamhal_configure
    libcamhal_build
    libcamhal_rpm_install
    libcamhal_build_test
    popd
}

icamerasrc_build_steps() {
    cd ${ICAMERASRC_DIR}
    icamerasrc_configure
    icamerasrc_build
    icamerasrc_rpm_install
    icamerasrc_build_test
    popd
}

all_build_steps() {
    cd ${ROOT_DIR}
    unset PKG_CONFIG_SYSROOT_DIR
    aiq_build_steps
    aiqb_build_steps
    iacss_build_steps
    libcamhal_build_steps
    icamerasrc_build_steps
}

build_steps=(all_build_steps aiq_build_steps aiqb_build_steps iacss_build_steps libcamhal_build_steps icamerasrc_build_steps)
BUILD_DIRS=($ROOT_DIR $AIQ_DIR $AIQB_DIR $LIBIACSS_DIR $LIBCAMHAL_DIR $ICAMERASRC_DIR)
