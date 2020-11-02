# NixOS (but super-minimal)
## What is this?
This started as a response to the Nixpkgs issue [#21315](https://github.com/NixOS/nixpkgs/issues/21315) - a request for a super-minimal NixOS image with almost nothing in `$PATH` but strictly neccesary software. Everything else could be installed separately.

## What's the progress?
Right now the `PATH` is a little bit smaller - 90 packages vs. 117. You can see the following `nix-repl` snippet to investigate the results of this work.

```nix
nix-repl> self = builtins.getFlake "github:kisik21/nixos-super-minimal"

nix-repl> deprecatedPrograms = ["bash" "info" "man" "oblogout" "way-cooler"]

nix-repl> deprecatedServices = ["beegfs" "beegfsEnable" "buildkite-agent" "cgmanager" "chronos" "d
eepin" "dnscrypt-proxy" "fourStore" "fourStoreEndpoint" "marathon" "mathics" "meguca" "mesos" "openvpn" "osquery" "prey" "rmilter" "seeks" "winstone"]

nix-repl> closure = self.inputs.nixpkgs.lib.nixosSystem ({ modules = [ self.nixosModule ]; })

nix-repl> builtins.length closure.config.environment.systemPackages # profiles/minimal.nix == 117
90

nix-repl> nix-repl> builtins.filter (name: system.config.programs.${name}.enable or false) (builtins.attrNames (builtins.removeAttrs system.config.programs deprecatedPrograms))
[ "command-not-found" ]

nix-repl> builtins.filter (name: system.config.services.${name}.enable or false) (builtins.attrNames (builtins.removeAttrs system.config.services deprecatedServices))
[ "dbus" "nscd" "timesyncd" ]
```

## How to use this?
Use this repository as a flake. `nixosModule` contains the NixOS module, based upon the [minimal.nix](https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/profiles/minimal.nix) in Nixpkgs.

The `checks.x86_64-linux` attribute set contains `toplevelClosure` - the top-level closure for evaluating closure size - and `vm` - a VM that autologins you as `root` and allows you to inspect the system to ensure things don't break.
