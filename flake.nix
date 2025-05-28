{
  description = "Git server setup/config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { flake-parts, git-hooks-nix, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        git-hooks-nix.flakeModule
      ];

      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { config, pkgs, ... }: {
        formatter = pkgs.nixpkgs-fmt;

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
              nixpkgs-fmt.enable = true;
              # Terraform
              terraform-format.enable = true;
            };
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            opentofu
            ansible
            just
          ];
          shellHook = ''
            ${config.pre-commit.installationScript}
            echo 1>&2 "Welcome to the development shell!"
          '';
        };
      };

      flake = { };
    };
}

# vim: sw=2
