{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  immich-dir = "/mnt/immich";
in {
  services.immich = {
    enable = true;
    database.enable = true;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;
    # accelerationDevices = null;
    mediaLocation = immich-dir;
  };

  users.users.immich.extraGroups = ["video" "render"];

  services.postgresql.dataDir = immich-dir + "/postgresql";

  environment.systemPackages = [pkgs.immich-cli];
}
