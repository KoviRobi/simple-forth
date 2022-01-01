{ pkgs ? import <nixpkgs> { }
}:

with pkgs;
stdenv.mkDerivation {
  name = "fth-dev";
  buildInputs = [ ];
  nativeBuildInputs = [
    (emacsWithPackages (p: [ p.org ]))
  ];
}
