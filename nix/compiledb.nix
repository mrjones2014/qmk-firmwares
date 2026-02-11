{
  lib,
  qmk,
  stdenv,
  python313,
  jq,
  ...
}:
{
  qmk-firmware,
  src,
  keyboard,
  variant ? null,
  target ? null,
}:
let
  build_args = (import ./build-args.nix { inherit lib; }) { inherit keyboard variant target; };
in
stdenv.mkDerivation {
  name = "${build_args.keymapName}-compiledb";
  src = qmk-firmware;
  buildInputs = [
    qmk
    jq
  ];

  postPatch = ''
    mkdir -p ${build_args.keymapDir}
    cp -r ${src}/* ${build_args.keymapDir}/
    substituteInPlace ./util/uf2conv.py \
      --replace "#!/usr/bin/env python3" "#!${python313}/bin/python3"
  '';

  buildPhase = ''
    qmk compile \
        -j 4 \
        --compiledb \
        --env SKIP_GIT=true \
        --env QMK_HOME=$PWD \
        --env QMK_FIRMWARE=$PWD \
        --env BUILD_DIR=${build_args.buildDir} \
        --env TARGET=${build_args.targetName} \
        --keyboard ${build_args.keyboardVariant} \
        --keymap ${build_args.keymapName}
  '';

  installPhase = ''
    mkdir -p $out

    # Post-process compile_commands.json:
    # 1. Rewrite sandbox paths for keymap files to relative src/ paths
    # 2. Strip ARM cross-compilation flags that clangd can't handle
    jq '
      map(
        # Rewrite keymap source file paths to relative
        .file = (.file | gsub(".*/keyboards/${build_args.keyboard}/keymaps/${build_args.keymapName}/"; ""))
        |
        # Rewrite directory to current dir for keymap files
        .directory = "."
        |
        # Strip problematic ARM flags from command/arguments
        if .command then
          .command = (.command | gsub("-mno-thumb-interwork|-mthumb|-mcpu=[^ ]*|-march=[^ ]*|-mfloat-abi=[^ ]*|-mfpu=[^ ]*|--target=arm-none-eabi|-mno-unaligned-access|-fsingle-precision-constant|-specs=[^ ]*|--specs=[^ ]*|-mmcu=[^ ]*"; ""))
        else . end
        |
        if .arguments then
          .arguments = [.arguments[] | select(
            test("^-mno-thumb-interwork$|^-mthumb$|^-mcpu=|^-march=|^-mfloat-abi=|^-mfpu=|^--target=arm-none-eabi$|^-mno-unaligned-access$|^-fsingle-precision-constant$|^-specs=|^--specs=|^-mmcu=") | not
          )]
        else . end
      )
    ' compile_commands.json > $out/compile_commands.json
  '';

  dontFixup = true;
}
