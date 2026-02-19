{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true;
    clang-format.enable = true;
    cmake-format.enable = true;
  };
}
