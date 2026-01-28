let 
  sources = import ./npins;
  pkgs = import sources.nixpkgs {
    config.allowUnfree = true;
  };
  pkgsUnstable = import sources.nixpkgs-unstable {
    config.allowUnfree = true;
  };
  nixos = import (sources.nixpkgs + "/nixos");
  fw13-hardware = import (sources.nixos-hardware + "/framework/13-inch/amd-ai-300-series");
  homeManager = import (sources.home-manager + "/nixos" );
  diskoModule = sources.disko + "/module.nix";
in nixos {
	  configuration = { pkgs, ...} : {
	    imports =
	      [ # Include the results of the hardware scan.
		fw13-hardware
		./hardware-configuration.nix
		homeManager
	        diskoModule
	      ];

	   services.udev.packages = [ pkgs.game-devices-udev-rules ];
	   services.udev.extraRules = ''
  	     KERNEL=="event*", SUBSYSTEM=="input", MODE="0660", GROUP="input"
  	   '';

	   home-manager.useGlobalPkgs = true; 
	   home-manager.useUserPackages = true; 
	   # You should fix the modules to be as shallow as possible and to install packages in global packages (the reason some stuff is installed but not available is this one)
	   home-manager.users.toniogela = { pkgs, config, ... }: {
	     imports = [ ./firefox ./zsh ./neovim ];
	     _module.args = { inherit pkgsUnstable; };
	     home.packages = [ ];
	     home.enableNixpkgsReleaseCheck = true;
	     home.file = {
		".config/niri/config.kdl".source = ./dotfiles/niri.kdl;
		".config/wallpaper.svg".source = ./dotfiles/wallpaper.svg;
		".config/kitty/kitty.conf".source = ./dotfiles/kitty.conf;
		"notes.md".source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/notes.md;
	     };
	     programs.home-manager.enable = true;
	     home.stateVersion = "25.11";
	   };
	  
	    nix = {
	      channel.enable = false;
	      settings.experimental-features = [ "nix-command" ];
	      nixPath = [ "nixpkgs=/etc/nixos/nixpkgs" "nixos-config=/etc/nixos/configuration.nix" ];
	    };
	  
	    environment = {
	      etc."nixos/nixpkgs".source = builtins.storePath pkgs.path;
	      variables."NH_FILE" = "/etc/nixos/configuration.nix";
	      shellAliases = {
		ls = "${pkgs.eza}/bin/eza -la --icons --git --group-directories-first --color=auto --git-ignore";
	      };
	    };
	  
	    boot.loader.systemd-boot = {
	      enable = true;
	      consoleMode = "5";
	      configurationLimit = 10;
	    };
	  
	    boot.loader.efi.canTouchEfiVariables = true;
	    boot.kernelParams = [ "console=tty2" ];
	    boot.consoleLogLevel = 0;
	  
	    networking.hostName = "toniogela-nixos-fw13"; # Define your hostname.
	  
	    networking.networkmanager.enable = true;
	  
	    time.timeZone = "Europe/Rome";
	  
	    fonts.packages = [ pkgs.nerd-fonts.sauce-code-pro ];
	  
	    i18n = {
	     defaultLocale = "en_GB.UTF-8";
	     extraLocales = [
	      "it_IT.UTF-8/UTF-8"
	     ];
	    };
	  
	    # console = {
	    #   font = "Lat2-Terminus16";
	    #   keyMap = "us";
	    #   useXkbConfig = true; # use xkb.options in tty.
	    # };
	  
	    services.fwupd.enable = true;
	    services.fprintd.enable = true;
	  
	    services.logind.settings.Login = {
	      HandleLidSwitch = "suspend";
	      HandleLidSwitchExternalPower = "suspend";
	      HandleLidSwitchDocked = "ignore";
	      HoldoffTimeoutSec=10;
	    };
	  
	    services.power-profiles-daemon.enable = false;
	    services.tlp = {
	      enable = true;
	      settings = {
		CPU_SCALING_GOVERNOR_ON_AC = "performance";
		CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
	      };
	    };
	  
	    services.greetd = {
	      enable = true;
	      useTextGreeter = true;
	      settings = {
		switch = false;
		default_session = {
		  command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'niri-session' --asterisks --theme 'border=red;time=green;title=green;prompt=green;button=black;action=black'";
		  user = "toniogela";
		};
	      };
	    };
	  
	    services.avahi = {
	      enable = true;
	      nssmdns4 = true;
	      openFirewall = true;
	    };

	    # programs.gpu-screen-recorder.enable = true;

	    services.printing = {
	      enable = true;
	      drivers = with pkgs; [
		cups-filters
		cups-browsed
		brlaser
	      ];
	    };

	    hardware.bluetooth.enable = true;
	  
	    services.pulseaudio.enable = false;
	    security.rtkit.enable = true;
	    services.pipewire = {
	      enable = true;
	      alsa.enable = true;
	      alsa.support32Bit = true;
	      pulse.enable = true;
	    };
	  
	    # https://github.com/NixOS/nixos-hardware/issues/1603
	    services.pipewire.wireplumber.extraConfig.no-ucm = {
	      "monitor.alsa.properties" = {
		"alsa.use-ucm" = false;
	      };
	    };

	    users.defaultUserShell = pkgs.zsh;
	    programs.zsh.enable = true;
	    programs.zoxide.enable = true;
	  
	    users.users.toniogela = {
	      isNormalUser = true;
	      extraGroups = [ "wheel" "gamemode" "lpadmin" "input" ];
	    };
	  
	    programs.niri.enable = true;
	    programs.waybar.enable = false;
	    programs.firefox.enable = false;

	    nixpkgs.config.allowUnfree = true;
	    programs.steam.enable = true;
	    programs.gamescope.enable = true;
	    programs.gamemode = {
	      enable = true;
	      enableRenice = true;

	      settings = {
		general = {
		  renice = 10;
		};
	      };
	    };

	    hardware.graphics.enable = true;
	    hardware.graphics.enable32Bit = true;
	  
	    hardware.enableAllFirmware = true;

	    environment.systemPackages = with pkgs; [
	      git
	      eza
	      nh
	      swaylock-effects
	      swaybg
	      npins
	      neovim
	      comma
	      bluetui
	      brightnessctl
	      playerctl
	      framework-tool-tui
	      kitty
	      pavucontrol
	      fuzzel
	      yazi
	      gh
	      xwayland-satellite
	      (retroarch.withCores (cores: with cores; [
		mgba
		play
	      ]))
	    ];
	  
	    # programs.mtr.enable = true;
	    # programs.gnupg.agent = {
	    #   enable = true;
	    #   enableSSHSupport = true;
	    # };
	  
	    # Open ports in the firewall.
	    # networking.firewall.allowedTCPPorts = [ ... ];
	    # networking.firewall.allowedUDPPorts = [ ... ];
	    # Or disable the firewall altogether.
	    # networking.firewall.enable = false;
	  
	    system.copySystemConfiguration = true;
	  
	    system.stateVersion = "25.11";
	  };
	}
