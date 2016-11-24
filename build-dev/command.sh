#!/bin/bash

function goto() {
    local dst_dir=$1
    local dst_dir_index=0

    if [ -n "$dst_dir" -a -d "$dst_dir" ] ; then
        cd $dst_dir
        return 
    fi

    echo "select goto dir :"
    for((i=0;i<${#ALL_DIRS[@]};i++));do
        echo "$i: ${ALL_DIRS[$i]}"
    done

    read dst_dir_index

    #delete \n and input index display
    echo -n -e "\b"

    echo goto dir  ${ALL_DIRS[$dst_dir_index]}
    cd ${ALL_DIRS[$dst_dir_index]}
}

function goto_helper() {
    echo "  goto [ dir ]: enter dir"
    echo "     if dir is null, list all available dirs, and you can select one to enter."
}

function list_helper() {
    echo "  list: list command helper"
}

function list() {
    list_helper
    goto_helper
    mm_helper
    mmm_helper
}

