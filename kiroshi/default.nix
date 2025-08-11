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

  environment.systemPackages = [
    pkgs.htop
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
  };
}
