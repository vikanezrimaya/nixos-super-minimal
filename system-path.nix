# This module defines the packages that appear in
# /run/current-system/sw.

{ config, lib, pkgs, ... }:

with lib;

let

  requiredPackages = map (pkg: setPrio ((pkg.meta.priority or 5) + 3) pkg) [
      # Packages that are absolutely neccesary
      pkgs.bashInteractive # bash with ncurses support
      # Packages that are probably neccesary
      pkgs.su # Requires a SUID wrapper - should be installed in system path?
      pkgs.coreutils-full # I've seen environments that don't even need coreutils - they are pulled with Nix instead
      pkgs.ncurses # Includes things such as `reset` - you should have it nearby
      pkgs.stdenv.cc.libc # I sure hope it's here for a reason
      # Packages that might not be so neccesary
      #pkgs.acl # I don't remember the last time I used one of these
      #pkgs.curl # Can be pulled in case network access is required
      #pkgs.attr # see pkgs.acl note
      #pkgs.bzip2
      #pkgs.cpio
      #pkgs.diffutils
      #pkgs.findutils
      #pkgs.gawk
      #pkgs.getent # Clearly this is a useless utility for me
      #pkgs.getconf # What is this?
      #pkgs.gnugrep
      #pkgs.gnupatch
      #pkgs.gnused
      #pkgs.gnutar
      #pkgs.gzip
      #pkgs.xz
      #pkgs.less
      #pkgs.libcap
      #pkgs.nano # Could be downloaded separately
      #pkgs.netcat # Totally unneccesary in a minimal system - NixOS is generous in even providing this in the default closure, some systems don't do that
      #config.programs.ssh.package # Don't install by default, but include in system closure since it can't be separated from the daemon
      #pkgs.mkpasswd # We manage users declaratively
      #pkgs.procps # It can be useful, but not strictly neccesary
      #pkgs.time # we can measure time using the shell builtin
      #pkgs.utillinux
      #pkgs.which
      #pkgs.zstd
    ];

    defaultPackages = map (pkg: setPrio ((pkg.meta.priority or 5) + 3) pkg)
      [ pkgs.perl
        pkgs.rsync
        pkgs.strace
      ];

in

{
  options = {

    environment = {

      systemPackages = mkOption {
        type = types.listOf types.package;
        default = [];
        example = literalExample "[ pkgs.firefox pkgs.thunderbird ]";
        description = ''
          The set of packages that appear in
          /run/current-system/sw.  These packages are
          automatically available to all users, and are
          automatically updated every time you rebuild the system
          configuration.  (The latter is the main difference with
          installing them in the default profile,
          <filename>/nix/var/nix/profiles/default</filename>.
        '';
      };

      defaultPackages = mkOption {
        type = types.listOf types.package;
        default = defaultPackages;
        example = literalExample "[]";
        description = ''
          Set of packages users expect from a minimal linux istall.
          Like systemPackages, they appear in
          /run/current-system/sw.  These packages are
          automatically available to all users, and are
          automatically updated every time you rebuild the system
          configuration.
          If you want a more minimal system, set it to an empty list.
        '';
      };

      pathsToLink = mkOption {
        type = types.listOf types.str;
        # Note: We need `/lib' to be among `pathsToLink' for NSS modules
        # to work.
        default = [];
        example = ["/"];
        description = "List of directories to be symlinked in <filename>/run/current-system/sw</filename>.";
      };

      extraOutputsToInstall = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "doc" "info" "devdoc" ];
        description = "List of additional package outputs to be symlinked into <filename>/run/current-system/sw</filename>.";
      };

      extraSetup = mkOption {
        type = types.lines;
        default = "";
        description = "Shell fragments to be run after the system environment has been created. This should only be used for things that need to modify the internals of the environment, e.g. generating MIME caches. The environment being built can be accessed at $out.";
      };

    };

    system = {

      path = mkOption {
        internal = true;
        description = ''
          The packages you want in the boot environment.
        '';
      };

    };

  };

  config = {

    environment.systemPackages = requiredPackages ++ config.environment.defaultPackages;

    environment.pathsToLink =
      [ "/bin"
        "/etc/xdg"
        "/etc/gtk-2.0"
        "/etc/gtk-3.0"
        "/lib" # FIXME: remove and update debug-info.nix
        "/sbin"
        "/share/emacs"
        "/share/hunspell"
        "/share/nano"
        "/share/org"
        "/share/themes"
        "/share/vim-plugins"
        "/share/vulkan"
        "/share/kservices5"
        "/share/kservicetypes5"
        "/share/kxmlgui5"
        "/share/systemd"
      ];

    system.path = pkgs.buildEnv {
      name = "system-path";
      paths = config.environment.systemPackages;
      inherit (config.environment) pathsToLink extraOutputsToInstall;
      ignoreCollisions = true;
      # !!! Hacky, should modularise.
      # outputs TODO: note that the tools will often not be linked by default
      postBuild =
        ''
          # Remove wrapped binaries, they shouldn't be accessible via PATH.
          find $out/bin -maxdepth 1 -name ".*-wrapped" -type l -delete

          if [ -x $out/bin/glib-compile-schemas -a -w $out/share/glib-2.0/schemas ]; then
              $out/bin/glib-compile-schemas $out/share/glib-2.0/schemas
          fi

          ${config.environment.extraSetup}
        '';
    };

  };
}
