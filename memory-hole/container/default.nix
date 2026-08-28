{
  config,
  pkgs,
  lib,
  nixpkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/minimal.nix")
  ];

  boot.isNspawnContainer = true;

  systemd.oomd.enable = false;

  documentation.enable = false;
  documentation.nixos.enable = false;

  environment.defaultPackages = lib.mkForce [];
}
