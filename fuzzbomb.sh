#!/usr/bin/env bash

set -e

cd `dirname $0`
source libfuzzbomb.sh

case "$1" in
    "") main ;;
    "mount") mount_disk ;;
    "umount") umount_disk ;;
esac
