{
  name,
  nodes,
  pkgs,
  lib,
  ...
}: {
  deployment.targetHost = "memory-hole";

  allowedUnfree = [
    "nvidia-x11"
  ];

  imports = [
    ../common/base.nix
    ./boot
    ./filesystem
    ./immich
    ./jellyfin
    ./networking
    ./samba
    ./stash
    ./syncthing
  ];

  users = {
    users.service = {
      isSystemUser = true;
      uid = 670;
      group = "service";
    };
    groups.service = {
      gid = 670;
      members = ["admin"];
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    nvidia = {
      open = true;
      nvidiaSettings = false;
    };
  };

  services.xserver.videoDrivers = ["nvidia"];
}
