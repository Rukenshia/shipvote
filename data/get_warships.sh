#!/bin/bash
set -eo pipefail

get_page_meta() {
	curl -s "https://api.worldofwarships.eu/wows/encyclopedia/ships/?application_id=80aa6f7e1d5df049c79d9141dd0826ae&limit=100" | jq  '.meta'
}

get_page() {
	curl -s "https://api.worldofwarships.eu/wows/encyclopedia/ships/?application_id=80aa6f7e1d5df049c79d9141dd0826ae&fields=name,nation,ship_id,type,tier,images.small&limit=100&page_no=${1}" | jq  '.data | to_entries | map(.value)'
}

max_page="$(get_page_meta | jq '.page_total')"

ships="[]"

for p in $(seq 1 ${max_page}); do
	current_page="$(get_page "$p")"

	ships="$(jq -rnc --argjson current "${ships}" --argjson new "${current_page}" '$current + $new')"
done

# rename ship_id to id
ships="$(jq -rnc --argjson ships "${ships}" '$ships | map(. + {id: .ship_id}) | map(del(.ship_id))')"

# flatten images.small to image
ships="$(jq -rnc --argjson ships "${ships}" '$ships | map(. + {image: .images.small}) | map(del(.images))')"

echo "${ships}" > warships.json
