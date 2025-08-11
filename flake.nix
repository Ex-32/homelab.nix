{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    impermanence.url = "github:nix-community/impermanence";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = inputs @ {nixpkgs, ...}: {
    colmena = {
      meta = {
        specialArgs = {inherit inputs;};
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [];
        };
      };

      astrocontrol = import ./astrocontrol;
      kiroshi = import ./kiroshi;
      memory-hole = import ./memory-hole;
    };

    devShells = let
      forSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
      ];

      nixpkgsFor = forSystems (system: import nixpkgs {inherit system;});
    in
      forSystems (system: let
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
