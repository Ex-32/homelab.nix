{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  containers.immich = let
    dbDir = "/mnt/postgres";
  in {
    autoStart = true;
    ephemeral = true;
    bindMounts = {
      immich-db = {
        mountPoint = dbDir;
        hostPath = "/mnt/immich-db";
        isReadOnly = false;
      };
      syncthing = rec {
        mountPoint = "/mnt/syncthing";
        hostPath = mountPoint;
        isReadOnly = false;
      };
    };
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
        };

        users = {
          users.immich.extraGroups = ["video" "render" "syncthing"];
          # FIXME: remove implicit dependency on syncthing
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
