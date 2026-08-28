{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  hostName = "memory-hole";
  domain = "tail3782b9.ts.net";
in {
  options = let
    inherit (lib) types;
    ipPrefix = "10.67";
  in {
    webService = lib.mkOption {
      type = types.attrsOf (types.submodule ({
        config,
        name,
        ...
      }: {
        options = {
          id = lib.mkOption {
            type = types.int;
            description = "Web service ID, must be between 0-99 and unique.";
          };
          internalPort = lib.mkOption {
            type = types.int;
            default = 8080;
            description = "The port on the container to which traffic will be forwarded";
          };

          hostIP = lib.mkOption {
            type = types.str;
            readOnly = true;
            default = "${ipPrefix}.${toString config.id}.1";
          };
          localIP = lib.mkOption {
            type = types.str;
            readOnly = true;
            default = "${ipPrefix}.${toString config.id}.2";
          };

          httpPort = lib.mkOption {
            type = types.int;
            readOnly = true;
            default = 8000 + config.id;
          };
          httpsPort = lib.mkOption {
            type = types.int;
            readOnly = true;
            default = 4400 + config.id;
          };

          module = lib.mkOption {
            type = types.deferredModule;
            readOnly = true;
            default = {...}: {
              networking.resolvconf.enable = false;
              environment.etc."resolv.conf".text = ''
                nameserver ${config.hostIP}
              '';
            };
          };

          config = {
            assertions = [
              {
                assertion = config.id >= 0 && config.id <= 99;
                message = "ID must be between 0 and 99.";
              }
            ];
          };
        };
      }));
      default = {};
    };

    tcpForward = lib.mkOption {
      type = types.listOf (types.submodule {
        options = {
          srcPort = lib.mkOption {
            type = types.int;
            description = "The source port on the host that will be forwarded.";
          };
          destPort = lib.mkOption {
            type = types.int;
            description = "The destination port that will be forwarded to";
          };
          destAddr = lib.mkOption {
            type = types.str;
            description = "The destination address that will be forwarded to";
          };
        };
      });
      default = [];
    };
  };

  config = let
    webServices = builtins.attrValues config.webService;
  in {
    assertions = [
      {
        assertion = lib.allUnique (map (x: x.id) webServices);
        message = "All web service IDs must be unique";
      }
      {
        assertion =
          builtins.all
          (x: builtins.hasAttr x config.containers)
          (builtins.attrNames config.webService);
        message = "Each webService must have an associated container of the same name";
      }
    ];

    networking = {
      firewall = {
        allowedTCPPorts =
          (map (x: x.srcPort) config.tcpForward)
          ++ (map (x: x.httpPort) webServices)
          ++ (map (x: x.httpsPort) webServices);

        interfaces."ve-+" = {
          allowedTCPPorts = [53];
          allowedUDPPorts = [53];
        };
      };

      nat = let
        tcpForwards2forwardPorts = {
          srcPort,
          destPort,
          destAddr,
        }: {
          sourcePort = srcPort;
          proto = "tcp";
          destination = "${destAddr}:${toString destPort}";
        };
      in {
        enable = true;
        internalInterfaces = ["ve-+"];
        forwardPorts = map tcpForwards2forwardPorts config.tcpForward;
      };
    };

    services = {
      resolved = {
        enable = true;
        settings.Resolve.DNSStubListenerExtra = map (serv: serv.hostIP) webServices;
      };

      tailscale = {
        enable = true;
        openFirewall = true;
        permitCertUid = "caddy";
      };

      caddy = let
        webForwards2virtualHosts = serv: [
          {
            name = "${hostName}.${domain}:${toString serv.httpsPort}";
            value = {
              extraConfig = ''
                reverse_proxy ${serv.localIP}:${toString serv.internalPort}
              '';
            };
          }
          {
            name = "http://:${toString serv.httpPort}";
            value = {
              extraConfig = ''
                reverse_proxy ${serv.localIP}:${toString serv.internalPort}
              '';
            };
          }
        ];
      in {
        enable = true;
        virtualHosts =
          builtins.listToAttrs
          (builtins.concatMap webForwards2virtualHosts webServices);
      };
    };

    containers = let
      mkNetworkConfig = name: serv: {
        privateNetwork = true;
        hostAddress = serv.hostIP;
        localAddress = serv.localIP;

        extraFlags = ["--resolv-conf=off"];
      };
    in
      builtins.mapAttrs mkNetworkConfig config.webService;
  };
}
