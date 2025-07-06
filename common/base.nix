{
  inputs,
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # Pending https://github.com/NixOS/nixpkgs/issues/55674
  options.allowedUnfree = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
  };

  config = {
    deployment = {
      targetPort = lib.mkDefault 22;
      targetUser = lib.mkDefault "admin";
    };

    nix.settings = {
      experimental-features = ["nix-command" "flakes"];
      use-xdg-base-directories = true;
      allowed-users = lib.mkForce ["@wheel"];
      trusted-users = lib.mkForce ["@wheel"];
    };

    # Pending https://github.com/NixOS/nixpkgs/issues/55674
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) config.allowedUnfree;

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    sops = {
      defaultSopsFile = ./secrets.yaml;
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      secrets = {
        "login/admin".neededForUsers = true;
      };
    };

    users = {
      mutableUsers = false;
      users.admin = {
        isNormalUser = true;
        extraGroups =
          ["wheel"]
          ++ (let
            jf = config.services.jellyfin;
          in (lib.lists.optional jf.enable jf.group));
        hashedPasswordFile = config.sops.secrets."login/admin".path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOur5HKJFSG3TktQCoy1V+t/wIQLo7d0auhSt6IrVkJ6"
        ];
      };
    };

    security = {
      sudo.enable = false;
      doas = {
        enable = true;
        wheelNeedsPassword = false;
      };
    };
    deployment.privilegeEscalationCommand = ["doas" "-n" "--"];

    system.stateVersion = "24.11";
  };
}
