{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  base-dir = "/mnt/bookorbit";
  db-dir = base-dir + "/db";
  data-dir = base-dir + "/library";

  secrets = ["envfile"];
in {
  webService.bookorbit = {
    id = 42;
  };

  containers.bookorbit = {
    autoStart = true;
    ephemeral = true;

    bindMounts = {
      db = {
        mountPoint = db-dir;
        hostPath = db-dir;
        isReadOnly = false;
      };

      data = {
        mountPoint = data-dir;
        hostPath = data-dir;
        isReadOnly = false;
      };

      secrets = {
        mountPoint = "/run/secrets";
        hostPath = "/run/secrets/services/bookorbit";
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
        imports = [
          ../container
          globalConfig.webService.bookorbit.module
        ];

        users = {
          users.bookorbit = {
            uid = globalConfig.users.users.service.uid;
            group = "bookorbit";
          };
          groups.bookorbit.gid = globalConfig.users.groups.service.gid;
        };

        services.bookorbit = {
          enable = true;
          createDatabaseLocally = true;
          openFirewall = true;

          user = "bookorbit";
          group = "bookorbit";

          environment = {
            PORT = globalConfig.webService.bookorbit.internalPort;
            APP_DATA_PATH = data-dir;
          };

          environmentFile = "/run/secrets/envfile";
        };

        services.postgresql.dataDir = db-dir;
        systemd.tmpfiles.rules = [
          "d ${db-dir} 0700 postgres postgres -"
        ];

        system.stateVersion = globalConfig.system.stateVersion;
      };
  };

  sops.secrets = builtins.listToAttrs (map (secret: {
      name = "services/bookorbit/${secret}";
      value = {
        sopsFile = ../secrets.yaml;
        owner = "service";
        group = "service";
      };
    })
    secrets);
}
