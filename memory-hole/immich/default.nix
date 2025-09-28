{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  containers.immich = let
    dbDir = "/mnt/postgres";
    mediaDir = "/mnt/immich";
  in {
    autoStart = true;
    ephemeral = true;
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
          port = 2283;
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
