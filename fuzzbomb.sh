#!/usr/bin/env bash

set -e

cd `dirname $0`
source libfuzzbomb.sh

case "$1" in
    "")
        (
            date
            time main 2>&1
        ) | tee -a ~/log-backup ;;
    "mount") mount_disk ;;
    "umount") umount_disk ;;
esac
