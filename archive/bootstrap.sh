#!/usr/bin/env nix-shell
#! nix-shell -i bash --pure
#! nix-shell -p bash git openssh _1password nixos-rebuild
# shellcheck shell=bash

ssh root@192.168.1.230 "bash -s" << EOF
    sopsdir=/var/lib/sops-nix

    # Check for existing sops directory
    if [ -d "$sopsdir"]; then
        echo "Sops dir $sopsdir already exists, doing nothing"
    else
        mkdir -p "$sopsdir"
        echo "Sops directory $sopsdir created"

EOF
ssh root@192.168.1.230 -T "mkdir -p /var/lib/sops-nix"
echo "$(op read op://k8s/nixos/nas_vm_age)" | ssh root@192.168.1.230 'cat > /var/lib/sops-nix/key.txt'
