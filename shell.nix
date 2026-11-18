let
  flakeLock = builtins.fromJSON (builtins.readFile ./flake.lock);
  nixpkgsLock = flakeLock.nodes.nixpkgs.locked;
  xpgLock = flakeLock.nodes.xpg.locked;
in
{
  pkgs ? import (builtins.fetchTarball {
    name = nixpkgsLock.rev;
    url = "https://github.com/${nixpkgsLock.owner}/${nixpkgsLock.repo}/archive/${nixpkgsLock.rev}.tar.gz";
    sha256 = nixpkgsLock.narHash;
  }) { },
  xpgPkgs ? import (
    pkgs.fetchFromGitHub {
      inherit (xpgLock) owner repo rev;
      sha256 = xpgLock.narHash;
    }
  ),
}:
pkgs.mkShell {
  buildInputs = [
    xpgPkgs.xpg
  ];
  shellHook = ''
    export HISTFILE=.history
  '';
}
