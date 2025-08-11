{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  audio-fix = pkgs.callPackage ./audio-fix.nix {
    kernel = config.boot.kernelPackages.kernel;
  };
in {
  boot = {
    initrd = {
      systemd.enable = true;
      availableKernelModules = ["xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod"];
      kernelModules = [];
      supportedFilesystems = ["zfs"];
    };

    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 1;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    kernelModules = ["kvm-intel"];
    extraModulePackages = [audio-fix];
    supportedFilesystems = ["zfs"];
  };
}
