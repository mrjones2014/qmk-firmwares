{
  description = "Moonlander MK II QMK Firmware";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
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
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
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
