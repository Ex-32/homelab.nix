{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  boot = {
    initrd = {
      systemd.enable = true;
      availableKernelModules = ["xhci_pci" "ehci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "sr_mod"];
      kernelModules = [];
      supportedFilesystems = ["zfs"];
    };

    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
    supportedFilesystems = ["zfs"];
  };
}
