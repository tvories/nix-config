set quiet := true
set shell := ['bash', '-euo', 'pipefail', '-c']

[private]
default:
    @just --list sops

[doc('Re-wrap every *.sops.yaml for the recipients now in .sops.yaml (run after adding or removing a key)')]
updatekeys:
    #!/usr/bin/env bash
    set -euo pipefail
    command -v sops >/dev/null || { echo "sops not found"; exit 1; }
    cd "{{ justfile_directory() }}"
    # .decrypted~* are plaintext leftovers from interrupted `sops` edits.
    find . -type f -name '*.sops.yaml' ! -name '.sops.yaml' ! -name '.decrypted~*' ! -path './archive/*' -print0 \
        | xargs -0 -n1 sops updatekeys -y

[doc('Decrypt and re-encrypt every *.sops.yaml under the current directory')]
[no-cd]
re-encrypt:
    #!/usr/bin/env bash
    set -euo pipefail
    command -v sops >/dev/null || { echo "sops not found"; exit 1; }
    find . -type f -name '*.sops.yaml' ! -name '.sops.yaml' ! -path './archive/*' -print0 \
        | while IFS= read -r -d '' f; do
            echo "Re-encrypting ${f}"
            sops --decrypt --in-place "${f}"
            sops --encrypt --in-place "${f}"
        done
