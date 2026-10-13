argparse h/help l/labels -- $argv
or return

if set -q _flag_help; or test (count $argv) -lt 1
    echo "Usage: gsi [-l|--labels] <instance-name-prefix>"
    echo "Search GCE instances across the org by name prefix."
    echo "  -l, --labels   include a LABELS column"
    return 1
end

set -l org 319215453412
set -l show_labels false
set -q _flag_labels; and set show_labels true
set -l tmp (mktemp)

# One call: map every folder ID in the org to its display name
gcloud asset search-all-resources --scope=organizations/$org \
    --asset-types=cloudresourcemanager.googleapis.com/Folder --format=json >$tmp

gcloud asset search-all-resources --scope=organizations/$org \
    --asset-types=compute.googleapis.com/Instance \
    --query="name:\"$argv[1]*\"" --format=json |
    @jq@ -r --slurpfile f $tmp --argjson labels $show_labels '
      def dash: if . == "" then "-" else . end;
      ($f[0] | map({key: (.name | split("/") | last), value: .displayName}) | from_entries) as $m
      | (["NAME","PROJECT_ID","PROJECT_NUMBER","FOLDER_PATH","INTERNAL_IP","EXTERNAL_IP"]
          + (if $labels then ["LABELS"] else [] end) | @tsv),
        (.[] | [
          .displayName,
          (.name | split("/projects/")[1] | split("/")[0]),
          (.project | split("/") | last),
          ((.folders // []) | map(split("/") | last | ($m[.] // .)) | reverse | join(" > ") | dash),
          ((.additionalAttributes.internalIPs // []) | join(",") | dash),
          ((.additionalAttributes.externalIPs // []) | join(",") | dash)
        ] + (if $labels then [((.labels // {}) | to_entries | map("\(.key)=\(.value)") | join(",") | dash)] else [] end)
        | @tsv)' | column -t -s \t

rm -f $tmp
