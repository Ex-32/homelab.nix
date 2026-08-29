{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  samba-dir = "/mnt/samba";
in {
  # these ports need to be open so they can reach the containerized samba
  networking.firewall = {
    allowedTCPPorts = [139 445];
    allowedUDPPorts = [137 138];
  };

  containers.samba = {
    autoStart = true;
    ephemeral = true;

    bindMounts = {
      samba-data = {
        mountPoint = "/var/lib/samba";
        hostPath = samba-dir + "/data";
        isReadOnly = false;
      };
      samba-share = {
        mountPoint = samba-dir;
        hostPath = samba-dir + "/share";
        isReadOnly = false;
      };
    };

    privateNetwork = false;

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
        ];

        users = {
          users = {
            # TODO: there needs to be a unix user matching the samba user;
            # consider auto-generating a user-stub for each normal user in
            # future
            admin = {
              uid = globalConfig.users.users.admin.uid;
              isNormalUser = true;
              group = "users";
            };
            samba = {
              uid = globalConfig.users.users.service.uid;
              isSystemUser = true;
              group = "samba";
            };
          };
          groups.samba.gid = globalConfig.users.groups.service.gid;
        };

        services.samba = {
          enable = true;
          openFirewall = true;
          settings = {
            global = {
              "server string" = "homelab-smb";
              "netbios name" = "homelab-smb";
              "security" = "user";
              #"use sendfile" = "yes";
              #"max protocol" = "smb2";
              # note: localhost is the ipv6 localhost ::1
              "hosts allow" = "192.168.1. 100.100.1. 127.0.0.1 localhost";
              "hosts deny" = "0.0.0.0/0";
              "guest account" = "nobody";
              "map to guest" = "bad user";
            };
            "main" = {
              "path" = samba-dir;
              "browseable" = "yes";
              "read only" = "no";
              "guest ok" = "no";
              "create mask" = "0644";
              "directory mask" = "0755";
              "force user" = "samba";
              "force group" = "samba";
            };
          };
        };

        services.samba-wsdd = {
          enable = true;
          openFirewall = true;
        };

        services.avahi = {
          publish.enable = true;
          publish.userServices = true;
          # ^^ Needed to allow samba to automatically register mDNS records (without the need for an `extraServiceFile`
          nssmdns4 = true;
          # ^^ Not one hundred percent sure if this is needed- if it aint broke, don't fix it
          enable = true;
          openFirewall = true;
        };
      };
  };

  # can't have a host avahi if the container is running one
  services.avahi.enable = lib.mkForce false;
}
