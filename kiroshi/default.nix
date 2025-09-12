{
  name,
  nodes,
  pkgs,
  lib,
  inputs,
  ...
}: {
  deployment.targetHost = "kiroshi";

  allowedUnfree = [
    "b43-firmware"
  ];

  imports = [
    inputs.nixos-hardware.nixosModules.apple-imac-18-2
    ../common/base.nix
    ./boot
    ./desktop
    ./filesystem
    ./networking
    ./user
  ];

  # NOTE: suspend is kinda broken on like *all* even semi-modern mac hardware,
  # so we'll have to do without
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  time.timeZone = "US/Central";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
  };
}
