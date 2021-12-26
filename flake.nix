{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs";
    npmlock2nix = {
      url = "github:andir/npmlock2nix?ref=parse-yarn-lock";
      flake = false;
    };
    funkwhale = {
      type = "git";
      url = "https://dev.funkwhale.audio/funkwhale/funkwhale.git";
      ref = "stable";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, npmlock2nix, funkwhale }: {
    overlay = final: prev: {
      npmlock2nix = final.callPackage npmlock2nix { };
      funkwhale-node_modules = final.npmlock2nix.internal.yarn.node_modules {
        src = funkwhale + "/front";
        nativeBuildInputs = [ final.python3 ];
        preBuild = ''
          sed -i 's/env -S bash -eux/env bash\nset -eux/' scripts/*.sh
          patchShebangs scripts
        '';
        postBuild = ''
          echo 'module.exports = {};' > node_modules/fomantic-ui-css/tweaked/postcss.config.js
        '';
      };
      funkwhale = final.npmlock2nix.build {
        node_modules = final.funkwhale-node_modules;
        src = funkwhale + "/front";
        preBuild = ''
          sed -i 's/env -S bash -eux/env bash\nset -eux/' scripts/*.sh
          patchShebangs scripts
        '';
        installPhase = ''
          cp -rv dist $out
        '';
      };
    };

    packages.x86_64-linux.funkwhale =
      let
        pkgs = import nixpkgs {
          overlays = [ self.overlay ];
          system = "x86_64-linux";
        };
      in
      pkgs.funkwhale;

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.funkwhale;

  };
}
