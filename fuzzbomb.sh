backup_mount=/mnt/backup
bup_dir=$backup_mount/bup-2019
backup_disk=/dev/disk/by-uuid/30f8caae-9266-4f24-b990-0d5390d3accf

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
        $backup_disk crypt-backup
    doo vgchange -ay
    doo mount /dev/vgbackup/lvbackup $backup_mount
}

make_backup () {
    # ignore that snapshot volumes change names
    doo bup -d $bup_dir index \
        --no-check-device \
        --exclude=/mnt/root-snapshot/nix \
        --exclude=/mnt/root-snapshot/home/b/Annex \
        --exclude=/var/lib/transmission/Downloads \
        /mnt/root-snapshot
    doo bup -d $bup_dir save -n fuzzbomb --strip /mnt/root-snapshot
}

teardown_snapshot () {
    doo umount /mnt/root-snapshot
    doo lvremove -f ubuntu-vg/lvsnapshot
}

umount_disk () {
    doo umount $backup_mount
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

unsafe_destroy_bup_dir () {
    doo rm -r $bup_dir
}

initialize_bup_dir () {
    set -ex
    if [[ ! -d $bup_dir ]]; then
        (
            trap "unsafe_destroy_bup_dir" ERR
            doo mkdir $bup_dir
            doo env BUP_DIR=$bup_dir bup init
        )
    fi
}

main () {
    (
        trap teardown_snapshot EXIT
        create_snapshot
        (
            # Don't mount/umount the backup disk if it's already online.
            if ! findmnt $backup_mount > /dev/null
            then
                trap umount_disk EXIT
                mount_disk
            fi
            initialize_bup_dir
            size_before=$(du -s $bup_dir|cut -f1)
            make_backup
            size_after=$(du -s $bup_dir|cut -f1)
            report_sizes $size_before $size_after
        )
    )
}
if [[ ${BASH_SOURCE[0]} == $0 ]]; then
    case "$1" in
        "")
            (
                date
                time main 2>&1
            ) | tee -a ~/log-backup ;;
        "mount") mount_disk ;;
        "umount") umount_disk ;;
    esac
fi
