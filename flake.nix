{
  description = "Heterogeneous docker-swarm cluster";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    press = {
      # pinned specific commit, do not update automatically
      url = "github:RossSmyth/press/c40590326e1f7800c4b751bb7fa18ffca2ab7e03";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      flake-parts,
      git-hooks-nix,
      press,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        git-hooks-nix.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ (import press) ];
            config = { };
          };

          formatter = pkgs.nixfmt-tree;

          pre-commit = {
            check.enable = true;

            settings = {
              addGcRoot = true;

              hooks = {
                # Ansible
                ansible-lint = {
                  enable = true;
                  settings.subdir = "ansible";
                };
                # Misc
                check-added-large-files.enable = true;
                check-yaml.enable = true;
                detect-private-keys.enable = true;
                end-of-file-fixer.enable = true;
                ripsecrets.enable = true;
                trim-trailing-whitespace.enable = true;
                # Nix
                deadnix.enable = true;
                nil.enable = true;
                nixfmt.enable = true;
                # Terraform
                terraform-format.enable = true;
                # Typst
                typstyle = {
                  enable = true;
                  entry = "${pkgs.typstyle}/bin/typstyle --wrap-text -i";
                };
              };
            };
          };

          packages = builtins.listToAttrs (
            map
              (lang: {
                name = "docs-${lang}";
                value = pkgs.buildTypstDocument {
                  name = "report-${lang}";
                  src = ./docs/typst;
                  file = "main.typ";
                  inputs."language" = "${lang}";
                  format = "pdf";
                  typstEnv = p: [ p.note-me ];
                };
              })
              [
                "en"
                "it"
              ]
          );

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              config.pre-commit.settings.enabledPackages
              opentofu
              ansible
              just
              typst
              typstyle
            ];

            shellHook = ''
              ${config.pre-commit.shellHook}
              alias typstwatch="typst watch -f pdf ./docs/typst/main.typ"
              alias typstwatch_en="typstwatch --input language=en"
              alias typstwatch_it="typstwatch --input language=it"
              alias typstformat="typstyle --wrap-text -i ./docs/typst/"
              echo 1>&2 "Welcome to the development shell!"
            '';
          };
        };

      flake = { };
    };
}

# vim: sw=2
