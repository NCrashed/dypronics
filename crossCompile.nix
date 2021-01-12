let
nixpkgs = import ./nix/pkgs.nix {
    config = {
      packageOverrides = pkgs: {
        ldc-binary = pkgs.callPackage ./nix/ldc/cross-base.nix { };
        ldc-cross = pkgs.callPackage ./nix/ldc/cross.nix { ldc-cross-rt = crossPkgs.ldc-cross-rt; };
      };
    };
  };
crossPkgs = import ./nix/pkgs.nix {
    crossSystem = {
      config = "armv7l-linux-gnueabihf";
    };
    config = {
      packageOverrides = pkgs: {
        ldc-cross-rt = pkgs.callPackage ./nix/ldc/cross-rt.nix { ldc-binary = nixpkgs.ldc-binary; };
      };
    };
  };
in with nixpkgs; crossPkgs.mkShell {
  nativeBuildInputs = [ nixpkgs.ldc-cross ]; # your dependencies here
  buildInputs = [ crossPkgs.zlib crossPkgs.openssl ];
}
