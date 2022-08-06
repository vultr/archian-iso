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
    if [[ ! -x /root/archian.json ]]; then
        if [[ -n "${json}" ]]; then
            if [[ "${json}" =~ ^((http|https|ftp)://) ]]; then
                curl "${json}" --retry-connrefused -s -o /root/archian.json >/dev/null
                rt=$?
            else
                cp "${json}" /root/archian.json
                rt=$?
            fi
        else
           # Try overridable domain path!
           curl --retry-connrefused -s http://installer.archian.com -o /root/archian.json >/dev/null
           rt=$?
        fi
    fi
}

if [[ $(tty) == "/dev/tty1" ]]; then
    archian_json
    cd /root/archian
    /root/archian/install.sh
fi

# Disable ssh to support packer on automated install
if [ -f /root/archian.json ]; then
    systemctl stop sshd
fi