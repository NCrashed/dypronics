with import ./nix/pkgs.nix {
    config = {
      packageOverrides = pkgs: {
        dmd = pkgs.callPackage ./nix/dmd {};
        ldc = pkgs.callPackage ./nix/ldc {};
      };
    };
  };

stdenv.mkDerivation rec {
  name = "dypronics-d-env";
  env = buildEnv { name = name; paths = buildInputs; };

  buildInputs = [
    dmd
    ldc
    dub
    valgrind
    kdeApplications.kcachegrind
    pkg-config
  ];
}
