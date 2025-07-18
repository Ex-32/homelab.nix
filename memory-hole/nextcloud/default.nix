{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  admin-secret = "services/nextcloud/admin_password";
  admin-secret-path = config.sops.secrets."${admin-secret}".path;
  nextcloud-home = "/var/lib/nextcloud";
in {
  containers.nextcloud = {
    autoStart = true;
    ephemeral = true;
    bindMounts = {
      nextcloud-home = {
        mountPoint = nextcloud-home;
        hostPath = "/mnt/nextcloud/home";
        isReadOnly = false;
      };
      admin-secret = {
        mountPoint = admin-secret-path;
        hostPath = admin-secret-path;
        isReadOnly = true;
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
        services.nextcloud = {
          enable = true;
          package = pkgs.nextcloud31;
          home = nextcloud-home;
          hostName = globalConfig.networking.fqdn;
          configureRedis = true;
          config = {
            adminpassFile = admin-secret-path;
            dbtype = "sqlite";
          };
        };

        system.stateVersion = globalConfig.system.stateVersion;
      };
  };

  sops.secrets."${admin-secret}".sopsFile = ../secrets.yaml;
}
