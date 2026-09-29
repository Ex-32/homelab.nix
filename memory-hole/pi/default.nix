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
      pi-ssh = {
        mountPoint = "/etc/ssh";
        hostPath = pi-dir + "/ssh";
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
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOom0DL7dOkxkF2Xf2s5LX8Z6w8u/ugde2CiA28kUCIm"
            ];
          };
          groups.pi = {
            gid = globalConfig.users.groups.service.gid;
          };
        };

        services.openssh = {
          enable = true;
          ports = lib.mkForce [31415];
          settings = {
            PermitRootLogin = "no";
            PasswordAuthentication = false;
          };
        };

        environment.systemPackages = let
          python = pkgs.python3.withPackages (ps:
            with ps; [
              ipympl
              jupyter
              matplotlib
              numpy
              opencv4
              pandas
              plotille
              pwntools
              scipy
              sympy
            ]);
          helix = pkgs.symlinkJoin {
            name = "helix-with-deps";
            paths = [pkgs.helix];
            nativeBuildInputs = [pkgs.makeBinaryWrapper];
            postBuild = ''
              wrapProgram $out/bin/hx --suffix PATH : ${lib.makeBinPath (with pkgs; [
                # nix
                nixd
                alejandra

                # rust
                rust-analyzer
                rustfmt

                # python
                ruff
                pyright

                # shell
                bash-language-server
                shellcheck
                shfmt

                # config
                taplo
                yaml-language-server
                vscode-langservers-extracted
                marksman
              ])}
            '';
          };
        in [
          helix
          pkgs.bat
          pkgs.dust
          pkgs.fd
          pkgs.file
          pkgs.fzf
          pkgs.git
          pkgs.htop
          pkgs.jq
          pkgs.katex
          pkgs.lazygit
          pkgs.man-pages
          pkgs.neovim
          pkgs.nodejs
          pkgs.pi-coding-agent
          pkgs.ripgrep
          pkgs.zellij
          python
        ];

        nix.settings = {
          experimental-features = ["nix-command" "flakes"];
          use-xdg-base-directories = true;
        };

        system.stateVersion = globalConfig.system.stateVersion;
      };
  };
}
