user=$(whoami)
#!/bin/bash
set -euo pipefail

if pgrep -x i2p >/dev/null 2>&1; then
	echo "i2p is not running, please start it before running this script"
else
	echo "i2p is running"
fi


sudo apt install qbittorrent-nox

# write minimal prefs (adjust path if your user is different)
if ! sudo mkdir -p /home/"$user"/.config/qBittorrent; then
	echo "Failed to make qbittorrent config; did you pass in usr?"
fi
cfg="/home/$user/.config/qBittorrent/qBittorrent.conf"

sudo tee "$cfg" > /dev/null <<'EOF'
[Preferences]
Connection\ProxyType=1
Connection\Proxy\Host=127.0.0.1
Connection\Proxy\Port=4445
Connection\ProxyPeerConnections=true
Connection\ProxyOnlyForTorrents=true
[Bittorrent]
DHT=false
PEX=false
LocalPeerDiscovery=false
EOF

# hand ownership back to the user (if needed)
sudo chown "$user:$user" "$cfg"

echo "Wrote qbittorrent config (port 4445)"

# proxy thru i2p (4444)
count="$( ( ss -ltn '( sport = :4445 )' || lsof -iTCP:4445 -sTCP:LISTEN ) 2>/dev/null | wc -l )"
if [ "$count" -eq 0 ]; then
	echo "i2p webproxy is NOT found; failing"
else
	echo "i2p running..."
fi

# HTTP via I2P HTTP proxy; HTTPS usually needs an outproxy (I2P may block it)
export http_proxy="http://127.0.0.1:4444"
export https_proxy="http://127.0.0.1:4444"
export no_proxy="localhost,127.0.0.1,.local"
# Or prefer SOCKS for generic TCP:
export all_proxy="socks5://127.0.0.1:4445"


cat > env.txt  << 'EOF'
export http_proxy="http://127.0.0.1:4444"
export https_proxy="http://127.0.0.1:4444"
export no_proxy="localhost,127.0.0.1,.local"
# Or prefer SOCKS for generic TCP:
export all_proxy="socks5://127.0.0.1:4445"
EOF
echo "Success -- env variables written to env. Run . ./env to activate"

