argparse h/help g/gcp 'p/prefix=' -- $argv
or return

if set -q _flag_help; or test (count $argv) -lt 1
    echo "Usage: adgroup [-g|--gcp] [-p|--prefix PREFIX] <user>"
    echo "List Active Directory groups for a user (by sAMAccountName, first.last, email, or full name)."
    echo "  -g, --gcp             only show gcp-*, gl-*, and user-sync-* groups"
    echo "  -p, --prefix PREFIX   only show groups starting with PREFIX (case-insensitive)"
    echo "  Uses \$AD_PASSWORD if set; otherwise prompts without echoing."
    return 1
end

set -l server (set -q AD_SERVER; and echo $AD_SERVER; or echo "ldaps://davita-ldap.gcp.davita.com")
set -l base (set -q AD_BASE; and echo $AD_BASE; or echo "dc=davita,dc=corp")
set -l bind_user (set -q AD_BIND_USER; and echo $AD_BIND_USER; or echo "$USER@davita.corp")

set -l query (string trim -- (string join " " -- $argv))
set -l esc (string replace -a '\\' '\5c' -- $query \
    | string replace -a '*' '\2a' \
    | string replace -a '(' '\28' \
    | string replace -a ')' '\29')
set -l dot_esc (string replace -a ' ' '.' -- $esc)

set -l clauses "(sAMAccountName=$esc)(mail=$esc)(userPrincipalName=$esc)(displayName=$esc)(cn=$esc)"
if not string match -q '*@*' -- $query
    set clauses "$clauses(mail=$dot_esc@davita.com)(userPrincipalName=$dot_esc@davita.com)(userPrincipalName=$esc@davita.corp)"
    set -l parts (string split -m 1 '.' -- $dot_esc)
    if test (count $parts) -eq 2
        set clauses "$clauses(&(givenName=$parts[1])(sn=$parts[2]))(displayName=$parts[2], $parts[1])"
    end
end
set -l filter "(&(objectClass=user)(objectCategory=person)(|$clauses))"

set -l pw $AD_PASSWORD
if test -z "$pw"
    read -s -P "Password for $bind_user: " pw
    if test -z "$pw"
        echo "Password is required." >&2
        return 1
    end
end

set -l passfile (mktemp)
chmod 600 $passfile
printf '%s' "$pw" >$passfile

set -l out (ldapsearch -x -LLL -o ldif-wrap=no -o nettimeout=10 \
    -H "$server" -b "$base" -D "$bind_user" -y "$passfile" \
    "$filter" sAMAccountName displayName mail memberOf 2>&1)
set -l rc $status
rm -f $passfile

if test $rc -ne 0
    printf '%s\n' $out >&2
    return $rc
end

if test -z "$out"
    echo "No AD user found matching: $query" >&2
    return 1
end

set -l gcp_only 0
set -q _flag_gcp; and set gcp_only 1

printf '%s\n' $out | awk -v gcp_only="$gcp_only" -v prefix="$_flag_prefix" '
  function flush() {
    if (dn == "") return
    printf "# %s (sAMAccountName=%s, mail=%s)\n", (name != "" ? name : "-"), (sam != "" ? sam : "-"), (mail != "" ? mail : "-") > "/dev/stderr"
    for (i = 1; i <= n; i++) print groups[i]
    dn = sam = name = mail = ""
    delete groups
    n = 0
  }
  /^dn: /             { flush(); dn = substr($0, 5) }
  /^sAMAccountName: / { sam = substr($0, 17) }
  /^displayName: /    { name = substr($0, 14) }
  /^mail: /           { mail = substr($0, 7) }
  /^memberOf: /       {
    cn = substr($0, 11)
    gsub(/\\\\,/, "\034", cn)
    sub(/^[Cc][Nn]=/, "", cn)
    sub(/,.*$/, "", cn)
    gsub(/\034/, ",", cn)
    lcn = tolower(cn)
    if (gcp_only == "1" && lcn !~ /^(gcp-|gl-|user-sync-)/) next
    if (prefix != "" && index(lcn, tolower(prefix)) != 1) next
    groups[++n] = cn
  }
  END { flush() }
' | sort -f
