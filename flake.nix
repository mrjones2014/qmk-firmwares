{
  description = "Custom QMK firmwares built with nixcaps";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    qmk_firmware = {
      url = "https://github.com/qmk/qmk_firmware";
      ref = "0.31.11";
      flake = false;
      type = "git";
      submodules = true;
    };
    nixcaps = {
      url = "github:agustinmista/nixcaps";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        qmk_firmware.follows = "qmk_firmware";
      };
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        nixcaps = inputs.nixcaps.lib.${system};
        keyboards = {
          moonlander = {
            keyboard = "zsa/moonlander";
            src = ./src/moonlander;
          };
          togkey = {
            keyboard = "togkey/pad_plus";
            src = ./src/togkey;
          };
        };
      in
      {
        formatter = treefmtEval.config.build.wrapper;
        checks.formatting = treefmtEval.config.build.check self;
        packages = pkgs.lib.mapAttrs (_: config: nixcaps.mkQmkFirmware config) keyboards;
        apps = pkgs.lib.mapAttrs (_: config: nixcaps.flashQmkFirmware config) keyboards;
        devShells.default = pkgs.mkShell {
          QMK_HOME = "${inputs.nixcaps.inputs.qmk_firmware}";
          packages = [
            pkgs.qmk
          ];
          shellHook = pkgs.lib.concatStringsSep "\n" (
            pkgs.lib.mapAttrsToList (name: config: ''
              ln -sf "${nixcaps.mkCompileDb config}/compile_commands.json" src/${name}/compile_commands.json
            '') keyboards
          );
        };
      }
    );
}
