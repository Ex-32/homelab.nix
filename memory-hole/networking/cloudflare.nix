{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
  sops.secrets."cloudflare_tunnel" = {
    sopsFile = ../secrets.yaml;
  };

  services.cloudflared = let
    routes = {
      "books.catgirl.red" = "bookorbit";
    };

    genRoutes =
      builtins.mapAttrs
      (name: val: "http://127.0.0.1:${toString config.webService."${val}".httpPort}");
  in {
    enable = true;
    tunnels."bf68f8fa-747c-41d0-8a2c-cef1c8e75120" = {
      credentialsFile = config.sops.secrets."cloudflare_tunnel".path;

      ingress = genRoutes routes;

      default = "http_status:404";
    };
  };
}
