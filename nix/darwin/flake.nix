{
  description = "DeeJay nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-sketchy = {
      url = "github:FelixKratz/homebrew-formulae";
      flake = false;
    };
    homebrew-aerospace = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, homebrew-core, homebrew-cask, homebrew-sketchy, homebrew-aerospace, nixpkgs }:
  let
    configuration = { pkgs, config, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ pkgs.neovim
	  pkgs.mkalias
	  pkgs.go
	  pkgs.awscli2
	  pkgs.aws-sam-cli
	  pkgs.stow
	  pkgs.ripgrep
	  pkgs.python310
	  pkgs.qmk
        ];

      homebrew = {
	enable = true;
	brews = [
	  "mas"
	  "powerlevel10k"
	  "nvm"
	  "sketchybar"
	];
	casks = [
	  "wezterm"
	  "aerospace"
	  "mos"
	];
	onActivation.cleanup = "zap";
      };

      fonts.packages = [
	 pkgs.nerd-fonts.jetbrains-mono
	 pkgs.nerd-fonts.hack
      ];

      system.activationScripts.applications.text = let
	    env = pkgs.buildEnv {
	    name = "system-applications";
	    paths = config.environment.systemPackages;
	    pathsToLink = "/Applications";
	  };
	in
	  pkgs.lib.mkForce ''
	  # Set up applications.
	  echo "setting up /Applications..." >&2
	  rm -rf /Applications/Nix\ Apps
	  mkdir -p /Applications/Nix\ Apps
	  find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
	  while read -r src; do
	    app_name=$(basename "$src")
	    echo "copying $src" >&2
	    ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
	  done
	      '';

      system.defaults = {
	dock = {
	  autohide = true;
	  expose-group-apps = true;
	  persistent-apps = [
	      "/Applications/WezTerm.app"
	      "/Applications/Zen.app"
	      "/System/Applications/Mail.app"
	      "/System/Applications/Calendar.app"
	    ];
	};
	spaces.spans-displays = false;
	finder.FXPreferredViewStyle = "clmv";
	NSGlobalDomain = {
	  _HIHideMenuBar = true;
	};
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."simple" = nix-darwin.lib.darwinSystem {
      modules = [
	configuration
	nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "deejay-air";

            # Optional: Declarative tap management
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
  	      "homebrew/homebrew-cask" = homebrew-cask;
	      "FelixKratz/homebrew-formulae" = homebrew-sketchy;
	      "nikitabobko/homebrew-tap" = homebrew-aerospace;
            };

            # Optional: Enable fully-declarative tap management
            #
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = false;
          };
        }
      ];
    };
    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwingConfigurations."simple".pkgs;
  };
}
