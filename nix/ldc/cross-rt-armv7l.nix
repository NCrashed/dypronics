{ stdenv, fetchurl, libxml2, zlib, cmake, unzip, ldc-binary }:
with stdenv;
let
  version = "1.25.0-beta1";
in mkDerivation {
  pname = "ldc-rt-armv7l";
  inherit version;

  src = fetchurl rec {
    name = "ldc-${version}-src.zip";
    url = "https://github.com/ldc-developers/ldc/releases/download/v${version}/${name}";
    sha256 = "1l15gm4r94kjmw61iliwgr6sqp1cgcvj8n68796ppp5fadz887hb";
  };
  dontConfigure = true;

  nativeBuildInputs = [ cmake unzip ldc-binary ];

  buildInputs = [ ];

  propagatedBuildInputs = [ ];

  buildPhase = ''
   ldc-build-runtime -j8 \
      --ldcSrcDir="." \
      --dFlags="-mtriple=armv7l-linux-gnueabihf" \
      --buildDir=arm-rt --targetSystem="Linux;UNIX"
  '';
  installPhase = ''
    mkdir -p $out
    mv arm-rt/lib $out/lib
  '';

  meta = with lib; {
    inherit version;
    description = "The LLVM-based D Compiler runtime library for ARM";
    homepage = "https://github.com/ldc-developers/ldc";
    # from https://github.com/ldc-developers/ldc/blob/master/LICENSE
    license = with licenses; [ bsd3 boost mit ncsa gpl2Plus ];
    maintainers = with maintainers; [ ThomasMader lionello ];
    platforms = [ "armv7l-linux" ];
  };
}
