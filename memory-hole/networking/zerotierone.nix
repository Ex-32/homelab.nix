{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  allowedUnfree = [
    "zerotierone"
  ];

  services.zerotierone = {
    enable = true;
    joinNetworks = [
      "8286ac0e474c397c"
    ];
  };
}
