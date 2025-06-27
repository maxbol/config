{
  stdenv,
  lib,
  fetchurl,
  perl,
  zlib,
  ...
}:
stdenv.mkDerivation rec {
  pname = "openssl";
  version = "1.0.1";

  src = fetchurl {
    url = "https://www.openssl.org/source/old/${version}/openssl-${version}.tar.gz";
    sha256 = "sha256-TZ8KWUqaibKOGgSpUEwEEE9lCO4nrR4O/dF6em277u4="; # Replace with actual hash
  };

  nativeBuildInputs = [perl];
  buildInputs = [zlib];

  configurePhase = ''
    ./config shared --prefix=$out --openssldir=$out/ssl zlib
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    make install_sw
  '';

  meta = with lib; {
    description = "OpenSSL 1.0.0 (shared libraries)";
    homepage = "https://www.openssl.org";
    license = licenses.openssl;
    platforms = platforms.linux;
  };
}
