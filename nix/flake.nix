{
  # Reference:
  # https://davi.sh/blog/2024/01/nix-darwin/
  #
  # I installed nix from https://zero-to-nix.com/start/install with:
  # curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
  description = "system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
        url = "github:LnL7/nix-darwin";
        inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = {pkgs, ... }: {

        services.nix-daemon.enable = true;
        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility. please read the changelog
        # before changing: `darwin-rebuild changelog`.
        system.stateVersion = 4;

        # The platform the configuration will be used on.
        # If you're on an Intel system, replace with "x86_64-darwin"
        # nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.hostPlatform = "x86_64-darwin";

        # Declare the user that will be running `nix-darwin`.
        users.users.tclem= {
            name = "tclem";
            home = "/Users/tclem";
        };

        # Create /etc/zshrc that loads the nix-darwin environment.
        # NOTE: This makes loading a new shell, very, very slow.
        # programs.zsh.enable = true;

        environment.systemPackages = [
            pkgs.neovim
        ];
    };
  in
  {
    darwinConfigurations."hueco" = nix-darwin.lib.darwinSystem {
      modules = [
         configuration
      ];
    };
  };
}
