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
      device = "/dev/disk/by-uuid/2860-11F4";
      fsType = "vfat";
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };

    "/nix" = required-dataset "rpool/encrypt/nix";
    "/persist" = required-dataset "rpool/encrypt/persist";
  };

  swapDevices = [
  ];
}
