# Custom QMK Firmwares

Custom QMK firmwares, with out-of-tree compilation made possible by [Nixcaps](https://github.com/agustinmista/nixcaps).

- ZSA Moonlander MK I
  - Cross-OS shortcuts (ctrl vs. cmd shortcuts on Linux vs. macOS)
- TogKey Pad Plus

## Features

- **Cross-OS Shortcuts**: Same physical keys adapt to macOS (CMD) vs Linux (CTRL) automatically using QMK's OS detection.
- **LSP setup**: Autocomplete and type checking for QMK firmware development.
  - The `devShell` sets up `compile_commands.json` files for each keyboard (`.gitignore`d)
- **Nix-managed**: Reproducible builds, all dependencies handled auatomatically
  - Out-of-tree compilation and flashing made possible by [Nixcaps](https://github.com/agustinmista/nixcaps)

## Quick Start

You can use `direnv` to manage the Nix `devShell`. I highly recommend using [nix-direnv](https://github.com/nix-community/nix-direnv).

```bash
direnv allow
# from now on, the devShell will activate whenever you `cd` into the project
# the repo root should have an auto-generated `compile_commands.json` file
# that clangd will use for LSP configuration
nvim src/moonlander/keymap.c
```

## Build

Building the firmware is a Nix derivation:

```bash
nix build .#moonlander
nix build .#togkey
# outputs to ./result/bin/*
```

You can also flash the firmware by running:

```bash
nix run .#moonlander
nix run .#togkey
```

This will automatically rebuild the firmware if needed, using the power of Nix to detect when rebuild is needed.
