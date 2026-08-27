{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  ip-prefix = "10.69.1";

  forward = {
    srcPort = 2283;
    destPort = 2283;
    destAddr = "${ip-prefix}.1";
  };
in {
  webForward = [forward];

  containers.immich = let
    dbDir = "/mnt/postgres";
    mediaDir = "/mnt/immich";
  in {
    autoStart = true;
    ephemeral = true;

    privateNetwork = true;
    hostAddress = "${ip-prefix}.1";
    localAddress = "${ip-prefix}.2";

    bindMounts =
      {
        immich-data = {
          mountPoint = mediaDir;
          hostPath = "/mnt/immich/data";
          isReadOnly = false;
        };
        immich-db = {
          mountPoint = dbDir;
          hostPath = "/mnt/immich/db";
          isReadOnly = false;
        };
        immich-library = {
          mountPoint = "/mnt/library";
          hostPath = "/mnt/immich/library";
          isReadOnly = false;
        };
      }
      // (let
        syncthing-dirs = [
          "pixel7-dcim"
          "pixel7-downloads"
          "pixel7-pictures"
        ];
        genBindMount = dir: {
          name = "syncthing-${dir}";
          value = rec {
            mountPoint = "/mnt/syncthing/${dir}";
            hostPath = mountPoint;
            isReadOnly = true;
          };
        };
      in
        builtins.listToAttrs (builtins.map genBindMount syncthing-dirs));
    config = let
      globalConfig = config;
    in
      {
        config,
        pkgs,
        lib,
        ...
      }: {
        services.immich = {
          enable = true;
          database.enable = true;
          host = "0.0.0.0";
          port = forward.destPort;
          openFirewall = true;
          # accelerationDevices = null;
          mediaLocation = mediaDir;
        };

        users = {
          users.immich.extraGroups = ["video" "render" "syncthing"];
          groups.syncthing.gid = globalConfig.users.groups.syncthing.gid;
        };

        services.postgresql = {
          dataDir = dbDir;
          settings.port = 5432;
        };

        system.stateVersion = globalConfig.system.stateVersion;
      };
  };

  environment.systemPackages = [pkgs.immich-cli];
}
