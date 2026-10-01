{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    colmena = {
      url = "github:nix-community/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    copyparty = {
      url = "github:9001/copyparty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    oh-my-pi = {
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    colmena,
    ...
  }: let
    forSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "x86_64-linux"
    ];
    nixpkgsFor = forSystems (system: nixpkgs.legacyPackages.${system});

    astrocontrol = import ./astrocontrol;
    kiroshi = import ./kiroshi;
    memory-hole = import ./memory-hole;
  in {
    colmenaHive = colmena.lib.makeHive self.outputs.colmena;

    colmena = {
      meta = {
        specialArgs = {inherit inputs;};
        # this is the build platform
        nixpkgs = nixpkgsFor."x86_64-linux";
      };

      inherit astrocontrol kiroshi memory-hole;
    };

    packages = forSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      astrocontrol-image = inputs.nixos-generators.nixosGenerate {
        inherit system;
        format = "sd-aarch64";
        specialArgs = {inherit inputs;};
        modules = [
          astrocontrol
          # this is here to provide a dummy option that disregards deployment
          # config consumed by colmena when building the sd-image
          ({...}: {
            options.deployment = pkgs.lib.mkOption {
              type = pkgs.lib.types.anything;
            };
          })
        ];
      };
    });

    devShells = forSystems (system: let
      pkgs = nixpkgsFor.${system};
      colmenaPkg = inputs.colmena.packages.${system}.default;
    in {
      default = pkgs.mkShell {
        packages = [
          colmenaPkg
          pkgs.sops
          pkgs.ssh-to-age
        ];
      };
    });
  };
}
