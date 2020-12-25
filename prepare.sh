#!/usr/bin/env bash

helpmessage() {
    echo -e "usage: ${BASH_SOURCE[0]}\n"
    echo -e "    -h, --help     show (this) help message"
}

ARGS=()

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)      helpmessage; exit 0 ;;
        -u|--uninstall) uninstall=1; shift ;;
        -*)             echo -e "invalid option: $1\n"; exit 1 ;;
        *)              ARGS+=("$1"); shift ;;
    esac
done

set -- "${ARGS[@]}"

[ $# -ne 0 ] && { echo -e "check arguments\n"; exit 1; }

if [ -z $uninstall ]; then
    deps=(lilypond jq dylibbundler)
    brew install "${deps[@]}"
else
    mapfile -t deps < requirements.txt
    brew uninstall "${deps[@]}"
fi
