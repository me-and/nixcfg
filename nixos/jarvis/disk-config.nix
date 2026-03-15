{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/scsi-36075c31f952e4ace88ac55097dd52799";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            lvm = {
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "vgjarvis";
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      vgjarvis = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "btrfs";
              mountpoint = "/";
              mountOptions = [ "subvol=/@root" ];
            };
          };
          swap = {
            size = "16G";
            content.type = "swap";
          };
        };
      };
    };
  };
}
