{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  users.users.user = {
    isNormalUser = true;
    password = "verysecurepass";
  };
}
