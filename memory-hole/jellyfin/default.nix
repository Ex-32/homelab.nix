{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  jellyfin-dir = "/mnt/jellyfin";
in {
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    dataDir = jellyfin-dir + "/data";
    cacheDir = jellyfin-dir + "/cache";
  };
  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];
}
