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

  users = {
    users.jellyfin = {
      isSystemUser = true;
      group = "jellyfin";
    };
    groups.jellyfin = {
      members = ["admin"];
    };
  };

  containers.jellyfin = {
    autoStart = true;
    ephemeral = true;

    privateNetwork = true;
    hostAddress = config.webService.jellyfin.hostIP;
    localAddress = config.webService.jellyfin.localIP;

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
        users.users.jellyfin.uid = globalConfig.users.users.jellyfin.uid;
        users.groups.jellyfin.gid = globalConfig.users.groups.jellyfin.gid;

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
