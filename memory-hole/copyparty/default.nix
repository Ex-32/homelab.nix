{
  config,
  pkgs,
  lib,
  nixpkgs,
  inputs,
  ...
}: let
  copyparty-dir = "/mnt/copyparty";

  secrets = ["admin_password"];
in {
  webService.copyparty = {
    id = 3;
  };

  containers.copyparty = {
    autoStart = true;
    ephemeral = true;

    bindMounts = {
      copyparty-data = {
        mountPoint = "/var/lib/copyparty/";
        hostPath = copyparty-dir + "/data";
        isReadOnly = false;
      };

      copyparty-vol = {
        mountPoint = copyparty-dir;
        hostPath = copyparty-dir + "/vol";
        isReadOnly = false;
      };
      samba = {
        mountPoint = "/mnt/samba";
        hostPath = "/mnt/samba";
        isReadOnly = false;
      };
      jellyfin = {
        mountPoint = "/mnt/jellyfin";
        hostPath = "/mnt/jellyfin";
        isReadOnly = false;
      };
      stash = {
        mountPoint = "/mnt/stash";
        hostPath = "/mnt/stash/library";
        isReadOnly = false;
      };

      secrets = {
        mountPoint = "/run/secrets";
        hostPath = "/run/secrets/services/copyparty";
        isReadOnly = true;
      };
    };

    config = let
      globalConfig = config;
      globalInputs = inputs;
    in
      {
        config,
        pkgs,
        lib,
        ...
      }: {
        imports = [
          ../container
          globalInputs.copyparty.nixosModules.default
          globalConfig.webService.copyparty.module
        ];

        nixpkgs.overlays = [globalInputs.copyparty.overlays.default];

        users = {
          users.copyparty.uid = globalConfig.users.users.service.uid;
          groups.copyparty.gid = globalConfig.users.groups.service.gid;
        };

        services.copyparty = {
          enable = true;

          user = "copyparty";
          group = "copyparty";

          settings = {
            i = "0.0.0.0";
            p = [globalConfig.webService.copyparty.internalPort];

            fk = 8;
            re-maxage = 3600;
            e2dsa = true;
            e2ts = true;
          };

          accounts = {
            "admin".passwordFile = "/run/secrets/admin_password";
          };

          volumes = let
            admin-only = {
              r = [];
              rw = ["admin"];
            };
          in {
            "/" = {
              path = copyparty-dir;
              access = admin-only;

              flags = {
                dedup = true;
              };
            };
            "/samba" = {
              path = "/mnt/samba";
              access = admin-only;
            };
            "/jellyfin" = {
              path = "/mnt/jellyfin";
              access = admin-only;
            };
            "/stash" = {
              path = "/mnt/stash";
              access = admin-only;
            };
          };

          openFilesLimit = 8192;
        };

        system.stateVersion = globalConfig.system.stateVersion;
      };
  };

  sops.secrets = builtins.listToAttrs (map (secret: {
      name = "services/copyparty/${secret}";
      value = {
        sopsFile = ../secrets.yaml;
        owner = "service";
        group = "service";
      };
    })
    secrets);
}
