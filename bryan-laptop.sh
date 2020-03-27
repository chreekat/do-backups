# TODO: Subvolume for /home/b

set -Eeuo pipefail

device_id=bryan-laptop

snapshot_dir=/mnt/snapshot/root
bup_target=$snapshot_dir/home/b

create_snapshot () {
    mkdir -p $(dirname $snapshot_dir)
    btrfs subvolume snapshot -r / $snapshot_dir
}

teardown_snapshot () {
    btrfs subvolume delete $snapshot_dir
}

make_backup () {
    # ignore that snapshot volumes change names
    # TODO: May not apply to btrfs? This was a lvm thing.
    sudo -u $SUDO_USER bup index \
        --no-check-device \
        --exclude=$bup_target/.bup \
        --exclude=$bup_target/GoogleDrive \
        --exclude=$bup_target/keybase \
        --exclude=$bup_target/.cache \
        --exclude=$bup_target/"VirtualBox VMs" \
        --exclude=$bup_target/.minikube \
        --exclude=$bup_target/.cabal \
        --exclude=$bup_target/.stack \
        --exclude=$bup_target/.vagrant.d \
        --exclude=$bup_target/.nox \
        $bup_target
    sudo -u $SUDO_USER bup save -n $device_id --strip $bup_target
}

report_sizes () {
    local before
    local after
    before=$1
    after=$2
    echo -e "Size before:\t$before"
    echo -e "Size after:\t$after"
    echo -en "Increase:\t"
    echo $((after - before))
}

main () {
    if [[ -z "$SUDO_USER" ]]; then
        >&2 echo "Run via sudo"
        exit 1
    fi
    local home
    home=$(getent passwd $SUDO_USER | cut -d: -f6)
    (
        trap teardown_snapshot EXIT
        create_snapshot
        sudo -u $SUDO_USER bup init
        local size_before
        size_before=$(du -s $home/.bup | cut -f1)
        make_backup
        local size_after
        size_after=$(du -s $home/.bup | cut -f1)
        report_sizes $size_before $size_after
    )
}

if [[ ${BASH_SOURCE[0]} == $0 ]]; then
    main
fi
