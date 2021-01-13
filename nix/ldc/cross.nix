{ stdenv, fetchurl, curl, tzdata, autoPatchelfHook, fixDarwinDylibNames, libxml2, zlib, ldc-rt-armv7l, ldc-rt-aarch64 }:
with stdenv;
let
  version = "1.25.0-beta1";
in mkDerivation {
  pname = "ldc-cross";
  inherit version;

  src = fetchurl rec {
    name = "ldc2-${version}-linux-x86_64.tar.xz";
    url = "https://github.com/ldc-developers/ldc/releases/download/v${version}/${name}";
    sha256 = "0i3wqj87l1a5k0ljpn0brw4jbji5mmi24lap6j37n2rsz8xzvzlf";
  };
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [ zlib libxml2 ];

  propagatedBuildInputs = [ curl tzdata ];

  installPhase = ''
    mkdir -p $out

    cat <<EOT >> ./etc/ldc2.conf
    "^armv7l.*-linux-gnueabihf$":
    {
        switches = [
            "-defaultlib=phobos2-ldc,druntime-ldc",
            "-gcc=arm-linux-gnueabihf-gcc",
        ];
        lib-dirs = [
            "%%ldcbinarypath%%/../arm-lib",
        ];
        rpath = "%%ldcbinarypath%%/../arm-lib";
    };
    "^aarch64-.*-linux-gnu":
    {
        switches = [
            "-defaultlib=phobos2-ldc,druntime-ldc",
            "-gcc=aarch64-linux-gnu-gcc",
        ];
        lib-dirs = [
            "%%ldcbinarypath%%/../aarch64-lib",
        ];
        rpath = "%%ldcbinarypath%%/../aarch64-lib";
    };

    EOT
    mkdir -p $out
    mv bin etc import lib LICENSE README $out/
    cp -r ${ldc-rt-armv7l}/lib $out/arm-lib
    cp -r ${ldc-rt-aarch64}/lib $out/aarch64-lib
  '';

  meta = with lib; {
    inherit version;
    description = "The LLVM-based D Compiler";
    homepage = "https://github.com/ldc-developers/ldc";
    # from https://github.com/ldc-developers/ldc/blob/master/LICENSE
    license = with licenses; [ bsd3 boost mit ncsa gpl2Plus ];
    maintainers = with maintainers; [ ThomasMader lionello ];
    platforms = [ "x86_64-linux" ];
  };
}
