set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

repo_dir := justfile_directory()
ssh_user := "taylor"
domain := "mcbadass.local"
# The WSL distro's hostname (deskmonster) differs from its flake attribute.
local_host := if env("WSL_DISTRO_NAME", "") != "" { "wsl" } else { `hostname -s` }

[private]
default:
    @just --list nix

[private]
require +cmds:
    for c in {{ cmds }}; do command -v "$c" >/dev/null || { echo "$c not found"; exit 1; }; done

[doc('Build and switch this NixOS machine (defaults to wsl inside WSL)')]
switch host=local_host: (require "nix" "nh")
    nh os switch "{{ repo_dir }}" --hostname "{{ host }}"

[doc('Build a nix-darwin configuration and diff it against the running system')]
build-darwin host: (require "nix" "darwin-rebuild" "nvd")
    cd "{{ repo_dir }}" && darwin-rebuild build --flake "{{ repo_dir }}#{{ host }}"
    cd "{{ repo_dir }}" && nvd diff /run/current-system result

[doc('Build and diff a nix-darwin configuration, confirm, then switch to it')]
apply-darwin host: (build-darwin host)
    #!/usr/bin/env bash
    set -euo pipefail
    read -rp "Do you want to continue applying this configuration? [y/N] " ans
    [[ "${ans}" =~ ^[Yy] ]] || { echo "Aborted."; exit 1; }
    sudo darwin-rebuild switch --flake "{{ repo_dir }}#{{ host }}"

[doc('Build a NixOS configuration on the remote host itself')]
build-nixos host: (require "nix")
    nix-shell -p nixos-rebuild --run 'nixos-rebuild build --flake "{{ repo_dir }}#{{ host }}" --fast --use-remote-sudo --build-host "{{ ssh_user }}@{{ host }}.{{ domain }}" --target-host "{{ ssh_user }}@{{ host }}.{{ domain }}"'

[doc('Build a NixOS configuration on this machine (faster for slow targets like the RPi)')]
build-nixos-local host: (require "nix")
    nix-shell -p nixos-rebuild --run 'nixos-rebuild build --flake "{{ repo_dir }}#{{ host }}" --fast --use-remote-sudo --build-host "" --target-host "{{ ssh_user }}@{{ host }}.{{ domain }}"'

[doc('Build locally and switch a remote NixOS host with nh')]
apply-nixos host: (require "nix" "nh")
    nh os switch "{{ repo_dir }}" --hostname "{{ host }}" --target-host "{{ ssh_user }}@{{ host }}.{{ domain }}" --elevation-strategy passwordless

[doc('Build nixos.wsl for the wsl host into out_dir, with this repo (WIP included) copied to ~/gits/nix-config')]
build-wsl-image out_dir="/mnt/c/Users/taylor/Downloads" age_key="": (require "nix")
    #!/usr/bin/env bash
    set -euo pipefail
    stage=$(mktemp -d)
    trap 'sudo rm -rf "$stage"' EXIT
    home="$stage/home/taylor"
    mkdir -p "$home/gits"
    chmod 700 "$home"
    cp -a "{{ repo_dir }}" "$home/gits/nix-config"
    # Claude Code keys project memory by repo path, which changes to ~/gits.
    mem="$HOME/.claude/projects/$(echo "{{ repo_dir }}" | tr / -)"
    if [ -d "$mem" ]; then
        mkdir -p "$home/.claude/projects"
        cp -a "$mem" "$home/.claude/projects/-home-taylor-gits-nix-config"
    fi
    if [ -n "{{ age_key }}" ]; then
        install -D -m 600 "{{ age_key }}" "$home/.config/age/keys.txt"
    fi
    # Build as this user (root would trip git's repo-ownership check), run as root.
    builder=$(nix build --no-link --print-out-paths "{{ repo_dir }}#nixosConfigurations.wsl.config.system.build.tarballBuilder")
    cd "{{ out_dir }}"
    sudo "$builder/bin/nixos-wsl-tarball-builder" --extra-files "$stage" --chown /home/taylor 1000:100
    ls -lh "{{ out_dir }}/nixos.wsl"

[doc('Build on this machine, then switch the remote host (nh cannot force a local build for tback)')]
apply-nixos-local host: (require "nix" "nixos-rebuild")
    nixos-rebuild switch --flake "{{ repo_dir }}#{{ host }}" --sudo --build-host "" --target-host "{{ ssh_user }}@{{ host }}.{{ domain }}"
