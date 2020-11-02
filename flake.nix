{
  description = "Super-minimal NixOS module";
  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
    };
  };
  outputs = inputs: let
    inherit (inputs) self nixpkgs;
  in {
    nixosModule = { config, pkgs, lib, ... }: {
      imports = [
        (inputs.nixpkgs + "/nixos/modules/profiles/minimal.nix")
        ./system-path.nix
      ];
      disabledModules = ["config/system-path.nix"];
      services.udisks2.enable = false;
      services.nscd.enable = false;
      # Turn off if you want to disable command-not-found
      programs.command-not-found.enable = lib.mkDefault true;
    };

    # The closure to check
    checks.x86_64-linux.toplevel-closure = let
      additionalConfig = { config, pkgs, lib, ... }: {
        nixpkgs.localSystem.system = "x86_64-linux";
        boot = {
          loader = {
            grub = {
              enable = true;
              efiSupport = true;
              device = "nodev";
            };
          };
        };
        fileSystems = {
          "/" = {
            device = "/dev/sda2";
            fsType = "ext4";
          };
          "/boot" = {
            device = "/dev/sda1";
            fsType = "vfat";
          };
        };
      };
    in (nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModule
        additionalConfig
      ];
    }).config.system.build.toplevel;
    checks.x86_64-linux.vm = (nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModule
        ({...}: { nixpkgs.localSystem.system = "x86_64-linux"; services.mingetty.autologinUser = "root"; })
      ];
    }).config.system.build.vm;
  };
}
