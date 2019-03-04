#!/usr/bin/env bash

[[ -n "$1" ]] && DO_TOKEN="$1"
[[ -n "$2" ]] && DO_PROJECT="$2"
[[ -n "$3" ]] && DNS_SUFFIX="$3"

if [[ -z ${DO_TOKEN} ]] || [[ -z ${DO_PROJECT} ]] || [[ -z ${DNS_SUFFIX} ]]; then
    exit 1
fi

droplets_url="$(curl -s -X GET \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${DO_TOKEN}" \
    "https://api.digitalocean.com/v2/projects/${DO_PROJECT}/resources" |
    jq -r '.resources[].links.self' |
    grep '/droplets/')"

IFS=$'\n'
for d in ${droplets_url}; do
    # get droplet informations
    info_droplet="$(curl -s -X GET \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${DO_TOKEN}" \
        "${d}" |
        jq '.droplet.name, .droplet.region.slug, .droplet.networks.v4[0].ip_address' |
        tr -d '\"')"

    dname="$(echo "${info_droplet}" | sed -n '1p' | grep -Eo '[a-zA-Z0-9]+$')"
    dregion="$(echo "${info_droplet}" | sed -n '2p' | grep -Eo '[a-zA-Z0-9]+')"
    dip="$(echo "${info_droplet}" | sed -n '3p' | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')"

    echo "Creating DNS record:"
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${DO_TOKEN}" \
        -d "{\"name\":\"${dregion}-${dname}.${DNS_SUFFIX}\",\"ip_address\":\"${dip}\"}" \
        "https://api.digitalocean.com/v2/domains"
done
IFS=$' '

