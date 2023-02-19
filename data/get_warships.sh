#!/bin/bash
set -eo pipefail

get_page_meta() {
	curl -s "https://api.worldofwarships.eu/wows/encyclopedia/ships/?application_id=80aa6f7e1d5df049c79d9141dd0826ae&limit=100" | jq  '.meta'
}

get_page() {
	curl -s "https://api.worldofwarships.eu/wows/encyclopedia/ships/?application_id=80aa6f7e1d5df049c79d9141dd0826ae&fields=name,nation,ship_id,type,tier,images.small&limit=5&page_no=${1}" | jq  '.data | to_entries | map(.value)'
}

max_page="$(get_page_meta | jq '.page_total')"

ships_tmpfile="$(mktemp)"
echo "[]" > "${ships_tmpfile}"
ships_tmpfile2="$(mktemp)"

for p in $(seq 1 "${max_page}"); do
	current_page="$(get_page "$p")"

	jq -rnc --slurpfile current "${ships_tmpfile}" --argjson new "${current_page}" '$current[] + $new' > "${ships_tmpfile2}"
  cp "${ships_tmpfile2}" "${ships_tmpfile}"
done

set -x
# rename ship_id to id
jq -rnc --slurpfile ships "${ships_tmpfile}" '$ships[] | map(. + {id: .ship_id}) | map(del(.ship_id))' > "${ships_tmpfile2}"
cp "${ships_tmpfile2}" "${ships_tmpfile}"

# flatten images.small to image
jq -rnc --slurpfile ships "${ships_tmpfile}" '$ships[] | map(. + {image: .images.small}) | map(del(.images))' > "${ships_tmpfile2}"
cp "${ships_tmpfile2}" "${ships_tmpfile}"

# wrap ship data in object with data property
jq -rnc --slurpfile ships "${ships_tmpfile}" '{"data": $ships[]}' > "${ships_tmpfile2}"
cp "${ships_tmpfile2}" "${ships_tmpfile}"

mv "${ships_tmpfile}" warships.json
