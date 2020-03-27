# do-backups
Scripts for backing up my shiz

## Requirements

* My disks (UUIDs are hard-coded)
* bup

## Features (of fuzzbomb.sh)

* Unlocks a LUKS-encrypted backup medium
* Creates a LVM snapshot of the filesystem being saved
* Uses bup

## Features (of bryan-laptop.sh)

* Uses btrfs snapshots
* Uses bup
