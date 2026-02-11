{
  description = "Moonlander MK II QMK Firmware";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    qmk-firmware = {
      flake = false;
      url = "https://github.com/qmk/qmk_firmware.git";
      ref = "0.30.6";
      type = "git";
      submodules = true;
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      qmk-firmware,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        build = pkgs.callPackage ./nix/build.nix { };
        flash = pkgs.callPackage ./nix/flash.nix { };
        compiledb = pkgs.callPackage ./nix/compiledb.nix { };
        keyboards = {
          moonlander = {
            inherit qmk-firmware;
            keyboard = "zsa/moonlander";
            src = ./src/moonlander;
          };
          togkey_pad_plus = {
            inherit qmk-firmware;
            keyboard = "togkey/pad_plus";
            src = ./src/togkey_pad_plus;
          };
        };
        moonlander-compiledb = compiledb keyboards.moonlander;
        togkey-compiledb = compiledb keyboards.togkey_pad_plus;
      in
      {
        packages = {
          moonlander = {
            build = build keyboards.moonlander;
            flash = flash keyboards.moonlander;
            compiledb = moonlander-compiledb;
          };
          togkey = {
            build = build keyboards.togkey_pad_plus;
            flash = flash keyboards.togkey_pad_plus;
            compiledb = togkey-compiledb;
          };
        };
        devShells.default = pkgs.mkShell {
          QMK_HOME = "${qmk-firmware}";
          packages = [
            pkgs.qmk
          ];
          shellHook = ''
            ln -sf "${moonlander-compiledb}/compile_commands.json" src/moonlander/compile_commands.json
            ln -sf "${togkey-compiledb}/compile_commands.json" src/togkey_pad_plus/compile_commands.json
          '';
        };
      }
    );
}
