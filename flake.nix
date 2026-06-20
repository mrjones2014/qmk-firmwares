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
    qmk_firmware_keychron = {
      url = "https://github.com/Keychron/qmk_firmware";
      ref = "2025q3";
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
        nixcapsKeychron =
          let
            mkQmkFirmware = pkgs.callPackage (import "${inputs.nixcaps}/nix/build.nix" inputs.qmk_firmware_keychron) { };
            mkFlashQmkFirmware = pkgs.callPackage (import "${inputs.nixcaps}/nix/flash.nix" inputs.qmk_firmware_keychron) { };
            mkCompileDb = pkgs.callPackage (import "${inputs.nixcaps}/nix/compiledb.nix" inputs.qmk_firmware_keychron) { };
            flashQmkFirmware =
              args:
              let
                firmware = mkQmkFirmware args;
              in
              {
                type = "app";
                program = "${mkFlashQmkFirmware (removeAttrs args [ "src" ] // { inherit firmware; })}/bin/flash";
              };
          in
          {
            inherit mkQmkFirmware mkCompileDb flashQmkFirmware;
          };
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
        keychronKeyboards = {
          v1_8k = {
            keyboard = "keychron/v1_8k/ansi_encoder";
            src = ./src/v1_8k;
          };
        };
        prefixKeys = prefix: pkgs.lib.mapAttrs' (n: v: pkgs.lib.nameValuePair "${prefix}${n}" v);
        eachKeyboard = op: pkgs.lib.mapAttrs (_: op) keyboards;
        eachKeychronKeyboard = op: pkgs.lib.mapAttrs (_: op) keychronKeyboards;
        firmwares = eachKeyboard nixcaps.mkQmkFirmware;
        keychronFirmwares = eachKeychronKeyboard nixcapsKeychron.mkQmkFirmware;
        compileDbs = eachKeyboard nixcaps.mkCompileDb;
        keychronCompileDbs = eachKeychronKeyboard nixcapsKeychron.mkCompileDb;
      in
      {
        formatter = treefmtEval.config.build.wrapper;
        packages = firmwares // keychronFirmwares;
        apps = (eachKeyboard nixcaps.flashQmkFirmware) // (eachKeychronKeyboard nixcapsKeychron.flashQmkFirmware);
        checks =
          firmwares
          // keychronFirmwares
          // (prefixKeys "compiledb-" (compileDbs // keychronCompileDbs))
          // {
            formatting = treefmtEval.config.build.check self;
          };
        devShells.default = pkgs.mkShell {
          QMK_HOME = "${inputs.nixcaps.inputs.qmk_firmware}";
          packages = [ pkgs.qmk ];
          shellHook = pkgs.lib.concatStringsSep "\n" (
            pkgs.lib.mapAttrsToList (name: db: ''
              ln -sf "${db}/compile_commands.json" src/${name}/compile_commands.json
            '') (compileDbs // keychronCompileDbs)
          );
        };
      }
    );
}
