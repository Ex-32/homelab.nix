{
  config,
  pkgs,
  lib,
  nixpkgs,
  inputs,
  ...
}: let
  optional = lib.lists.optional;
  optionals = lib.lists.optionals;
in {
  imports = [
    inputs.impermanence.nixosModule
  ];

  environment.persistence."/persist" = {
    directories =
      [
        "/home/admin"

        "/etc/ssh"
        {
          directory = "/etc/secrets";
          mode = "0500";
        }

        "/var/lib/nixos"
        "/var/log"
        # below we use the `config` variable to introspect the state of this
        # config as defined by other parts of the flake, this allows conditional
        # enabling of persistent storage at certain locations when specific
        # features are enabled such as NetworkManagers connection data store and
        # libvirtd's VM image store
      ]
      ++ (optional config.services.mullvad-vpn.enable "/etc/mullvad-vpn")
      ++ (optional config.services.samba.enable "/var/lib/samba")
      ++ (optional config.services.tailscale.enable "/var/lib/tailscale")
      ++ (optional config.services.zerotierone.enable "/var/lib/zerotier-one");

    files = [
      "/etc/machine-id"
    ];
  };

  # don't fuck with /etc/machine-id since we're handling that
  systemd.services."systemd-machine-id-commit".enable = false;
}
