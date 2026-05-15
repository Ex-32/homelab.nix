{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
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
  };

  outputs = inputs @ {nixpkgs, ...}: let
    forSystems = nixpkgs.lib.genAttrs [
      "aarch64-linux"
      "x86_64-linux"
    ];
    nixpkgsFor = forSystems (system: nixpkgs.legacyPackages.${system});

    astrocontrol = import ./astrocontrol;
    kiroshi = import ./kiroshi;
    memory-hole = import ./memory-hole;
  in {
    colmena = {
      meta = {
        specialArgs = {inherit inputs;};
        # this is the build platform
        nixpkgs = nixpkgs.legacyPackages."x86_64-linux";
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
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          colmena
          sops
          ssh-to-age
        ];
      };
    });
  };
}
