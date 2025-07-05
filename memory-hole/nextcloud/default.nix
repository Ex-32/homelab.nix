{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  admin-password = "services/nextcloud/admin_password";
in {
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud31;
    home = "/mnt/nextcloud";
    hostName = "100.100.1.164";
    configureRedis = true;
    config = {
      adminpassFile = config.sops.secrets."${admin-password}".path;
      dbtype = "sqlite";
    };
  };

  sops.secrets."${admin-password}" = {
    sopsFile = ../secrets.yaml;
  };
}
