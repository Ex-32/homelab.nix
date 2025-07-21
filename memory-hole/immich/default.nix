{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  services.immich = {
    enable = true;
    database.enable = true;
    host = "0.0.0.0";
    port = 2283;
    openFirewall = true;
    # accelerationDevices = null;
    mediaLocation = "/mnt/immich";
  };

  users.users.immich.extraGroups = ["video" "render"];

  services.postgresql = {
    dataDir = "/mnt/immich-postgres";
    settings.port = 5432;
  };

  environment.systemPackages = [pkgs.immich-cli];
}
