{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  jellyfin-dir = "/mnt/jellyfin";
in {
  webService.jellyfin = {
    id = 2;
    internalPort = 8096;
  };

  containers.jellyfin = {
    autoStart = true;
    ephemeral = true;

    bindMounts = {
      jellyfin-data = {
        mountPoint = jellyfin-dir;
        hostPath = jellyfin-dir;
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
        imports = [
          ../container
          globalConfig.webService.jellyfin.module
        ];

        users = {
          users.jellyfin.uid = globalConfig.users.users.service.uid;
          groups.jellyfin.gid = globalConfig.users.groups.service.gid;
        };

        services.jellyfin = {
          enable = true;
          openFirewall = true;

          user = "jellyfin";
          group = "jellyfin";

          dataDir = jellyfin-dir + "/data";
          cacheDir = jellyfin-dir + "/cache";
        };

        environment.systemPackages = with pkgs; [
          jellyfin
          jellyfin-web
          jellyfin-ffmpeg
        ];

        system.stateVersion = globalConfig.system.stateVersion;
      };
  };
}
