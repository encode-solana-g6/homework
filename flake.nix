{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    solana = { url = "https://github.com/nmrshll-templates/solana"; inputs.nixpkgs.follows = "nixpkgs"; };
  };

  outputs = { nixpkgs, ... }:
    let forAllSystems = fnOfPkgs: nixpkgs.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: fnOfPkgs nixpkgs.legacyPackages.${system});
    in {
      devShells = forAllSystems (pkgs: { });
    };
}
