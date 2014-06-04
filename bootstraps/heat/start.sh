#!/bin/bash

set -x

DVER=D7
PVER=H
REL=1.0.0
VERS=${DVER}-${PVER}.${REL}
BUILT_ROLES=/var/lib/sf

key_name="enovance fbo pub key"
prefix="tests"
temp_ssh_pwd="heat"
params="key_name=$key_name;prefix=$prefix;temp_ssh_pwd=$temp_ssh_pwd"

function register_images {
    for img in install-server-vm mysql ldap softwarefactory; do
        checksum=`glance image-show $img | grep checksum | awk '{print $4}'`
        if [ -z "$checksum" ]; then
            glance image-create --name $img --disk-format qcow2 --container-format bare \
                --progress --file $BUILT_ROLES/roles/install/$VERS/$img-$DVER-$PVER.$REL.img
        fi
    done
}

function unregister_images {
    for img in install-server-vm mysql ldap softwarefactory; do
        checksum=`glance image-show $img | grep checksum | awk '{print $4}'`
        newchecksum=`cat $BUILT_ROLES/roles/install/$VERS/$img-$DVER-$PVER.$REL.img.md5 | cut -d" " -f1`
        [ "$newchecksum" != "$checksum" ] && glance image-delete $img
    done
}

function start_stack {
    puppetmaster_image_id=`glance image-show install-server-vm | grep "^| id" | awk '{print $4}'`
    params="$params;puppetmaster_image_id=$puppetmaster_image_id"
    sf_image_id=`glance image-show softwarefactory | grep "^| id" | awk '{print $4}'`
    params="$params;sf_image_id=$sf_image_id"
    ldap_image_id=`glance image-show ldap | grep "^| id" | awk '{print $4}'`
    params="$params;ldap_image_id=$ldap_image_id"
    mysql_image_id=`glance image-show mysql | grep "^| id" | awk '{print $4}'`
    params="$params;mysql_image_id=$mysql_image_id"
    heat stack-create --template-file sf.hot -P "$params" SoftwareFactory
}

function delete_stack {
    heat stack-delete SoftwareFactory
}

function restart_stack {
    delete_stack || true
    while true; do
        heat stack-list | grep "SoftwareFactory" 
        [ "$?" != "0" ] && break
        sleep 2
    done
    start_stack
}

function full_restart_stack {
    unregister_images
    sleep 10
    register_images
    restart_stack
}

[ -z "$1" ] && {
    echo "$0 register_images|unregister_images|start_stack|delete_stack|restart_stack|full_restart_stack"
}
[ -n "$1" ] && {
    case "$1" in
        register_images )
            register_images ;;
        unregister_images )
            unregister_images ;;
        start_stack )
            start_stack ;;
        delete_stack )
            delete_stack ;;
        restart_stack )
            restart_stack ;;
        full_restart_stack )
            full_restart_stack ;;
        * )
           echo "Not available option" ;;
    esac
}