set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

mod nix 'justfiles/nix.just'
mod sops 'justfiles/sops.just'

[private]
default:
    @just --list
