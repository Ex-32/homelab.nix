{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  services.syncthing = rec {
    enable = true;
    dataDir = "/mnt/syncthing";
    configDir = dataDir + "/config";
  };
}
