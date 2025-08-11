{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  networking = {
    hostName = "kiroshi";
    hostId = "f9ed61d6";
    useDHCP = lib.mkDefault true;
    firewall = {
      enable = lib.mkForce true;
    };
    networkmanager.enable = true;
  };

  services = {
    mullvad-vpn = {
      enable = true;
      enableExcludeWrapper = false;
      package = pkgs.mullvad-vpn;
    };
    resolved.enable = true;
  };
}
