{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  stash-dir = "/mnt/stash";

  secrets = ["admin_password" "jwt_key" "session_key"];
in {
  webService.stash = {
    id = 69;
    internalPort = 9999;
  };

  containers.stash = {
    autoStart = true;
    ephemeral = true;

    bindMounts = {
      stash-data = {
        mountPoint = "/mnt/data";
        hostPath = stash-dir + "/data";
        isReadOnly = false;
      };
      stash-library = {
        mountPoint = "/mnt/library";
        hostPath = stash-dir + "/library";
        isReadOnly = false;
      };

      secrets = {
        mountPoint = "/run/secrets";
        hostPath = "/run/secrets/services/stash";
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
          globalConfig.webService.stash.module
        ];

        users = {
          users.stash.uid = globalConfig.users.users.service.uid;
          groups.stash.gid = globalConfig.users.groups.service.gid;
        };

        services.stash = {
          enable = true;
          openFirewall = true;

          user = "stash";
          group = "stash";

          jwtSecretKeyFile = "/run/secrets/jwt_key";
          sessionStoreKeyFile = "/run/secrets/session_key";

          dataDir = "/mnt/data";

          mutableSettings = true;

          username = "admin";
          passwordFile = "/run/secrets/admin_password";
        };

        system.stateVersion = globalConfig.system.stateVersion;
      };
  };

  sops.secrets = builtins.listToAttrs (map (secret: {
      name = "services/stash/${secret}";
      value = {
        sopsFile = ../secrets.yaml;
        owner = "service";
        group = "service";
      };
    })
    secrets);
}
