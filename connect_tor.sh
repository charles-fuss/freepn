parse_yaml() {
  local file="$1" parent="$2" prefix="${3:-}"
  awk -v parent="$parent" -v pfx="$prefix" '
    $0 ~ "^[[:space:]]*" parent ":[[:space:]]*$" { inmap=1; next }
    inmap && match($0, /^[[:space:]]+([A-Za-z0-9_.-]+):[[:space:]]*([^#[:space:]]+)/, m) {
      printf "%s%s_%s=\"%s\"\n", pfx, parent, m[1], m[2]
    }
    inmap && /^[[:space:]]*[A-Za-z0-9_.-]+:[[:space:]]*$/ && $0 !~ "^[[:space:]]*" parent ":" { exit }
  ' "$file"
}
config=$(parse_yaml config.yml ports)
sudo=$(parse_yaml config.yml sudo)
# awk has built in operators (NR,NF,OFS, etc)
tor_port=$(echo "$config" | awk -F'[^0-9]+' '/^ports_tor=/{print $2}')
exit_port=$(echo "$config" | awk -F'[^0-9]+' '/^ports_torrent_exit=/{print $2}')

#turn on tor // i2p better apparently, this is slow and clogs up network bandwidth
# this is insecure (parse shell logs, processes), but w/e
echo $sudo | sudo -S apt update && echo $sudo | sudo -S apt install tor
echo $sudo | sudo -S tor --SocksPort $exit_port 