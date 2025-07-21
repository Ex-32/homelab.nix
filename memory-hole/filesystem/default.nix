{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  imports = [
    ./impermanence.nix
  ];

  fileSystems = let
    required-dataset = name: {
      device = name;
      fsType = "zfs";
      neededForBoot = true;
    };
    optional-dataset = name: {
      device = name;
      fsType = "zfs";
      options = ["nofail"];
    };
  in {
    "/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "size=100%"
        "huge=within_size"
        "mode=755"
        "noatime"
      ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/12CE-A600";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };

    "/nix" = required-dataset "rpool/encrypt/nix";
    "/persist" = required-dataset "rpool/encrypt/persist";

    "/mnt/immich" = optional-dataset "tank/encrypt/immich";
    "/mnt/immich-postgres" = optional-dataset "tank/encrypt/immich/postgres";
    "/mnt/jellyfin" = optional-dataset "tanklet/encrypt/jellyfin";
    "/mnt/nextcloud/home" = optional-dataset "tank/encrypt/nextcloud";
    "/mnt/nextcloud/logs" = optional-dataset "tank/encrypt/nextcloud/logs";
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/69afd819-05df-46f2-9f31-08d56b805210";}
  ];
}
