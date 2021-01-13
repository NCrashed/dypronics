let
nixpkgs = import ./nix/pkgs.nix {
    config = {
      packageOverrides = pkgs: {
        ldc-binary = pkgs.callPackage ./nix/ldc/cross-base.nix { };
        ldc-cross = pkgs.callPackage ./nix/ldc/cross.nix { ldc-rt-armv7l = crossArmv7l.ldc-rt-armv7l; ldc-rt-aarch64 = crossAarch64.ldc-rt-aarch64; };
      };
    };
  };
crossArmv7l = import ./nix/pkgs.nix {
    crossSystem = {
      config = "armv7l-linux-gnueabihf";
    };
    config = {
      packageOverrides = pkgs: {
        ldc-rt-armv7l = pkgs.callPackage ./nix/ldc/cross-rt-armv7l.nix { ldc-binary = nixpkgs.ldc-binary; };
      };
    };
  };
crossAarch64 = import ./nix/pkgs.nix {
    crossSystem = {
      config = "aarch64-linux-gnu";
    };
    config = {
      packageOverrides = pkgs: {
        ldc-rt-aarch64 = pkgs.callPackage ./nix/ldc/cross-rt-aarch64.nix { ldc-binary = nixpkgs.ldc-binary; };
      };
    };
  };
in with crossAarch64; mkShell {
  nativeBuildInputs = [ nixpkgs.ldc-cross ];
  buildInputs = [ zlib openssl ];
}
