#!/bin/sh
# i3status wrapper:
#   - swaps @W@ for the wifi fan matching the signal strength (Android/iOS style)
#   - trims IEC byte units so sizes read "1.2G" instead of "1.2 GiB"
i3status -c "$HOME/.config/i3status/config" | awk '
function wifi(q) {
    if (q >= 75) return W4
    if (q >= 50) return W3
    if (q >= 25) return W2
    return W1
}
BEGIN {
    W1 = "󰤟"; W2 = "󰤢"; W3 = "󰤥"; W4 = "󰤨"; WOFF = "󰖪"
}
{
    gsub(/@W@ +/, "@W@")
    p = index($0, "@W@")
    if (p > 0) {
        rest = substr($0, p + 3)
        q = 0
        if (match(rest, /[0-9]+/)) q = substr(rest, RSTART, RLENGTH) + 0
        $0 = substr($0, 1, p - 1) wifi(q) substr($0, p + 3)
    }
    gsub(/@WOFF@/, WOFF)
    gsub(/ KiB/, "K"); gsub(/ MiB/, "M"); gsub(/ GiB/, "G"); gsub(/ TiB/, "T")
    print
    fflush()
}'
