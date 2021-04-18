#!/usr/bin/env bash

archian_json_cmdline ()
{
    local param
    for param in $(< /proc/cmdline); do
        case "${param}" in
            archian_json=*) echo "${param#*=}" ; return 0 ;;
        esac
    done
}

archian_json ()
{
    local json rt
    json="$(archian_json_cmdline)"
    if [[ -n "${json}" && ! -x /root/archian.json ]]; then
        if [[ "${json}" =~ ^((http|https|ftp)://) ]]; then
            curl "${json}" --retry-connrefused -s -o /root/archian.json >/dev/null
            rt=$?
        else
            cp "${json}" /root/archian.json
            rt=$?
        fi
    fi
}

if [[ $(tty) == "/dev/tty1" ]]; then
    archian_json
    cd /root/
    /root/install.sh
fi
