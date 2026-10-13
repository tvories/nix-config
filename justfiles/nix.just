set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

repo_dir := justfile_directory()
ssh_user := "taylor"
domain := "mcbadass.local"

[private]
default:
    @just --list nix

[private]
require +cmds:
    for c in {{ cmds }}; do command -v "$c" >/dev/null || { echo "$c not found"; exit 1; }; done

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

[doc('Build on this machine, then switch the remote host (nh cannot force a local build for tback)')]
apply-nixos-local host: (require "nix" "nixos-rebuild")
    nixos-rebuild switch --flake "{{ repo_dir }}#{{ host }}" --sudo --build-host "" --target-host "{{ ssh_user }}@{{ host }}.{{ domain }}"
