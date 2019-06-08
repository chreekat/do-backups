backupMount=/mnt/backup
bupDir=$backupMount/bup-2019

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
    doo mount /dev/vgbackup/lvbackup $backupMount
}

make_backup () {
    # ignore that snapshot volumes change names
    doo bup -d $bupDir index \
        --no-check-device \
        --exclude=/mnt/root-snapshot/nix \
        --exclude=/mnt/root-snapshot/home/b/Annex \
        --exclude=/mnt/root-snapshot/home/b/Torrents \
        /mnt/root-snapshot
    doo bup -d $bupDir save -n fuzzbomb --strip /mnt/root-snapshot
}

teardown_snapshot () {
    set +e
    doo umount /mnt/root-snapshot
    doo lvremove -f ubuntu-vg/lvsnapshot
}

umount_disk () {
    set +e
    doo umount $backupMount
    doo lvchange -an vgbackup/lvbackup
    doo dmsetup remove crypt-backup
}

report_sizes () {
    before=$1
    after=$2
    echo -e "Size before:\t$before"
    echo -e "Size after:\t$after"
    echo -en "Increase:\t"
    echo $((after - before))
}

main () {
    (
        trap teardown_snapshot EXIT
        create_snapshot
        (
            trap umount_disk EXIT
            mount_disk
            size_before=$(du -s $bupDir|cut -f1)
            make_backup
            size_after=$(du -s $bupDir|cut -f1)
            report_sizes $size_before $size_after
        )
    )
}
