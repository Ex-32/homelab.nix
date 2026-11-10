{
  config,
  pkgs,
  lib,
  nixpkgs,
  inputs,
  ...
}: let
  pi-dir = "/mnt/pi";
  stats-port = {
    internal = "31414";
    external = "31416";
  };
in {
  # FIXME: don't hardcode this
  services.caddy.virtualHosts = {
    "https://memory-hole.tail3782b9.ts.net:${stats-port.external}" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:${stats-port.internal}
      '';
    };
  };

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
      omp = inputs.oh-my-pi.packages.${pkgs.stdenv.hostPlatform.system}.omp;
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
        in [
          # basics
          pkgs.man-pages

          # cli tools
          pkgs.bat
          pkgs.dust
          pkgs.fd
          pkgs.file
          pkgs.fzf
          pkgs.git
          pkgs.jq
          pkgs.nodejs
          pkgs.ripgrep
          pkgs.tree
          python

          # tui tools
          pkgs.htop
          pkgs.lazygit
          pkgs.neovim
    
          # term multplexers 
          pkgs.herdr
          pkgs.zellij
          
          # agentic tooling
          omp
          pkgs.beads
          pkgs.pi-coding-agent

          # build toolchains (rust-analyzer/clangd shell out to these)
          pkgs.cargo
          pkgs.clang # provides cc/c++ (rustc's default linker)
          pkgs.cmake
          pkgs.gnumake
          pkgs.rustc

          # language servers and formatters
          ## nix
          pkgs.alejandra
          pkgs.nixd
          ## rust
          pkgs.rust-analyzer
          pkgs.rustfmt
          ## python
          pkgs.pyright
          pkgs.ruff
          ## c/c++
          pkgs.clang-tools # clangd, clang-format, clang-tidy
          ## cmake
          pkgs.cmake-language-server
          ## shell
          pkgs.bash-language-server
          pkgs.shellcheck
          pkgs.shfmt
          ## config
          pkgs.marksman
          pkgs.taplo
          pkgs.vscode-langservers-extracted
          pkgs.yaml-language-server
        ];

        systemd.services.omp-stats = {
          description = "omp usage statistics dashboard";
          wantedBy = ["multi-user.target"];

          serviceConfig = {
            Type = "simple";
            User = "pi";
            Group = "pi";
            # omp resolves ~/.omp (sessions, stats.db) from HOME
            Environment = ["HOME=/home/pi"];
            WorkingDirectory = "/home/pi";
            ExecStart = "${omp}/bin/omp stats --host 127.0.0.1 --port 31414";
            Restart = "on-failure";
            RestartSec = "5s";
            # omp only handles SIGINT for a clean closeDb(); a systemd-default
            # SIGTERM would kill it mid-write (WAL is crash-safe, but unclean)
            KillSignal = "SIGINT";
            TimeoutStopSec = "15s";
          };
        };

        nix.settings = {
          experimental-features = ["nix-command" "flakes"];
          use-xdg-base-directories = true;
        };

        system.stateVersion = globalConfig.system.stateVersion;
      };
  };
}
