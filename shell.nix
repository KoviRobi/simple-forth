{ pkgs ? import <nixpkgs> { }
}:

with pkgs;
stdenv.mkDerivation {
  name = "fth-dev";
  buildInputs = [ ];
  nativeBuildInputs = [
    (emacsWithPackages (p: [ p.org p.htmlize ]))
    python3 # for python3 -m http.server
  ];
}
