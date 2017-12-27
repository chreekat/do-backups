doo () {
    sudo $@
}

create_snapshot () {
    doo modprobe dm-snapshot
    doo lvcreate -L1G -n lvsnapshot -s ubuntu-vg/root
    doo mount /dev/ubuntu-vg/lvsnapshot /mnt/root-snapshot
}

mount_disk () {
    doo cryptsetup luksOpen \
        /dev/disk/by-uuid/30f8caae-9266-4f24-b990-0d5390d3accf crypt-backup
    doo vgchange -ay
    doo mount /dev/vgbackup/lvbackup /mnt/backup
}

make_backup () {
    # ignore that snapshot volumes change names
    doo bup -d /mnt/backup/bup index \
        --no-check-device \
        --exclude=/mnt/root-snapshot/nix \
        --exclude=/mnt/root-snapshot/home/b/Annex \
        /mnt/root-snapshot
    doo bup -d /mnt/backup/bup save -n fuzzbomb --strip /mnt/root-snapshot
}

teardown_snapshot () {
    set +e
    doo umount /mnt/root-snapshot
    doo lvremove -f ubuntu-vg/lvsnapshot
}

umount_disk () {
    set +e
    doo umount /mnt/backup
    doo lvchange -an vgbackup/lvbackup
    doo dmsetup remove crypt-backup
}

main () {
    (
        trap teardown_snapshot EXIT
        create_snapshot
        (
            trap umount_disk EXIT
            mount_disk
            make_backup
        )
    )
}
