Help edit or add a SOPS secret for a host. The argument is the hostname: $ARGUMENTS

Steps:
1. Identify the correct secrets file:
   - Host secrets: `hosts/$ARGUMENTS/secret.sops.yaml`
   - Home secrets: `homes/taylor/secrets/`

2. Show the current (decrypted) contents by running:
   `sops --decrypt hosts/$ARGUMENTS/secret.sops.yaml`

3. Ask the user what secret they want to add or modify.

4. To edit in-place: `sops hosts/$ARGUMENTS/secret.sops.yaml`
   SOPS will open the file in $EDITOR for direct editing.

5. Verify the file re-encrypts cleanly by running:
   `sops --decrypt hosts/$ARGUMENTS/secret.sops.yaml` again after saving.

6. Remind the user to reference the secret in Nix with:
   `sops.secrets.<name> = { sopsFile = ./secret.sops.yaml; };`

NEVER print raw secret values to the terminal output.
NEVER commit an unencrypted `.sops.yaml` file.
Age keys for each host are defined in `.sops.yaml` at the repo root.
