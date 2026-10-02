{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  miniflux-dir = "/mnt/miniflux";
  dbDir = miniflux-dir + "/db";

  # miniflux reads the admin password from its file, but MEDIA_PROXY_PRIVATE_KEY
  # has no _FILE variant in 2.2.x — so the key has to be handed over as a literal
  # in the same EnvironmentFile, rendered from sops at activation
  credentialsFile = "/run/miniflux-credentials";

  secrets = [
    "admin_password"
    "media_proxy_key"
  ];
in {
  webService.miniflux = {
    id = 4;
    internalPort = 8080;
  };

  containers.miniflux = {
    autoStart = true;
    ephemeral = true;

    bindMounts = {
      miniflux-db = {
        mountPoint = dbDir;
        hostPath = dbDir;
        isReadOnly = false;
      };

      secrets = {
        mountPoint = "/run/secrets";
        hostPath = "/run/secrets/services/miniflux";
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
          globalConfig.webService.miniflux.module
        ];

        # the unit runs as `miniflux`; a static user (rather than the module's
        # DynamicUser) is what lets it read the sops secret and pass `peer`
        # authentication to postgres over the unix socket
        users = {
          users.miniflux = {
            uid = globalConfig.users.users.service.uid;
            group = "miniflux";
          };
          groups.miniflux.gid = globalConfig.users.groups.service.gid;
        };

        systemd.tmpfiles.rules = [
          "d ${dbDir} 0700 postgres postgres -"
        ];

        services.postgresql.dataDir = dbDir;

        systemd.services.miniflux-credentials = {
          description = "Miniflux credentials, rendered from sops";
          wantedBy = ["multi-user.target"];
          before = ["miniflux.service"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "miniflux-credentials" ''
              umask 077
              {
                printf 'ADMIN_USERNAME=admin\n'
                printf 'ADMIN_PASSWORD_FILE=/run/secrets/admin_password\n'
                printf 'MEDIA_PROXY_PRIVATE_KEY=%s\n' "$(cat /run/secrets/media_proxy_key)"
              } > ${credentialsFile}
              chown miniflux:miniflux ${credentialsFile}
            '';
          };
        };

        services.miniflux = {
          enable = true;

          # the password never reaches the store or an env var: miniflux reads
          # it from the mounted secret, and CREATE_ADMIN (default 1) creates
          # the user on first boot, skipping it on every later start
          adminCredentialsFile = credentialsFile;

          config = {
            # caddy reaches us over the veth pair, so bind every interface
            LISTEN_ADDR = "0.0.0.0:${toString globalConfig.webService.miniflux.internalPort}";

            # must match the caddy vhost in ../networking/containers.nix
            BASE_URL = "https://memory-hole.tail3782b9.ts.net:${toString globalConfig.webService.miniflux.httpsPort}";
            # secure cookies: fine behind the tailscale TLS vhost, but it means
            # the auto-generated plain-HTTP vhost (:8004) can't log in
            HTTPS = "1";
            TRUSTED_REVERSE_PROXY_NETWORKS = "${globalConfig.webService.miniflux.hostIP}/32";

            POLLING_SCHEDULER = "entry_frequency";
            POLLING_FREQUENCY = "30";
            POLLING_LIMIT_PER_HOST = "2";

            MEDIA_PROXY_MODE = "all";

            LOG_FORMAT = "json";
          };
        };

        system.stateVersion = globalConfig.system.stateVersion;
      };
  };

  sops.secrets = builtins.listToAttrs (map (secret: {
      name = "services/miniflux/${secret}";
      value = {
        sopsFile = ../secrets.yaml;
        owner = "service";
        group = "service";
      };
    })
    secrets);
}
