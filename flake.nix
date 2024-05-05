{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/23.11";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = { self, nixpkgs, treefmt-nix, flake-utils, systems }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      {
        packages.default = let
          stdenv = pkgs.stdenv;
          ruby = pkgs.ruby;
          gems = pkgs.bundlerEnv {
            name = "frt";
            ruby = pkgs.ruby;
            gemdir = ./.;
          };
        in stdenv.mkDerivation rec {
          name = "frt";
          src = ./.;
          buildInputs = [ gems ruby ];

          installPhase = ''
            mkdir -p $out/{bin,share/beef}
            cp -r * $out/share/beef
            bin=$out/bin/beef

            cat > $bin <<EOF
            #!/bin/sh -e
            exec ${gems}/bin/bundle exec ${ruby}/bin/ruby $out/share/beef/beef "\$@"
            EOF

            chmod +x $bin
          '';
        };

        formatter = treefmtEval.config.build.wrapper;
        checks.formatting = treefmtEval.config.build.check self;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            ruby
            bundix
          ];

          shellHook = ''
            export PS1="\n[nix-shell:\w]$ "
          '';
        };
      });
}

