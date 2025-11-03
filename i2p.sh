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


echo $sudo | sudo -S apt-add-repository ppa:i2p-maintainers/i2p
echo "Adding i2p to mirrors and downloading... this may take a while..."
echo $sudo | sudo -S apt-get update > /dev/null
echo $sudo | sudo -S apt-get install i2p
echo "Successfully downloaded i2p"

# modify config
if [! -f /etc/default/i2p]; then
	echo "i2p config not found; check download link"	
fi

i2prouter start

if [! $? -eq 0]; then
	echo 'failed to start iprouter'
fi

socat TCP-LISTEN:8765,reuseaddr,fork,bind=0.0.0.0 TCP:127.0.0.1:7657 &
echo "Successfully started i2pserver; check 127.0.0.1:8765"


# "Garlic routing" was coined by Michael J. Freedman in Roger Dingledine's Free Haven Master's Section 8.1.1 (June 2000),  
# as derived from Onion Routing.[6] However, the garlic routing implementation in I2P differs from the design proposed by 
# Freedman. The key distinction is that garlic routing used unidirectional tunnels, while mainstream alternatives like Tor 
# and Mixmaster use bidirectional tunnels.

# libtorrent fuels all of the mainstream torrenting clients
