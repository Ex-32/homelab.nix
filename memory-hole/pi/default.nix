{
  config,
  pkgs,
  lib,
  nixpkgs,
  ...
}: let
  pi-dir = "/mnt/pi";
in {
  containers.pi = {
    autoStart = true;
    ephemeral = true;

    bindMounts = {
      pi-home = {
        mountPoint = "/home/pi";
        hostPath = pi-dir + "/home";
        isReadOnly = false;
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
        ];

        # since this is an interactive environment we're not importing the
        # minimal container module, but we will add some options for containers
        boot.isNspawnContainer = true;
        systemd.oomd.enable = false;

        # need to manually specify that we want interactive characteristics for
        # this user because it has a uid <1000
        users = {
          users.pi = {
            isSystemUser = true;
            uid = globalConfig.users.users.service.uid;
            group = "pi";
            home = "/home/pi";
            homeMode = "700";
            shell = pkgs.bash;
            createHome = true;
          };
          groups.pi = {
            gid = globalConfig.users.groups.service.gid;
          };
        };

        environment.systemPackages = [
          pkgs.duf
          pkgs.dust
          pkgs.fd
          pkgs.file
          pkgs.fselect
          pkgs.fzf
          pkgs.htop
          pkgs.lsof
          pkgs.man-pages
          pkgs.pciutils
          pkgs.pi-coding-agent
          pkgs.ripgrep
          pkgs.usbutils
        ];

        nix.settings = {
          experimental-features = ["nix-command" "flakes"];
          use-xdg-base-directories = true;
        };

        system.stateVersion = globalConfig.system.stateVersion;
      };
  };
}
