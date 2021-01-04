#!/bin/bash
set -e
echo "Ignoring WireGuard support..."
rm -rf net/wireguard
exit 

echo "Updating Wireguard"
echo "Setting user agent..."
USER_AGENT="WireGuard-AndroidROMBuild/0.2 ($(uname -a))"

echo "Setting .wireguard-fetch-lock..."
exec 9>.wireguard-fetch-lock

echo "flock-ing the lock..."
flock -n 9 || exit 0

echo "Stat-ing the .check file..."
[[ $(( $(date +%s) - $(stat -c %Y "net/wireguard/.check" 2>/dev/null || echo 0) )) -gt 86400 ]] || exit 0

echo "curl'ing the d/l..."
while read -r distro package version _; do
	if [[ $distro == upstream && $package == kmodtools ]]; then
		VERSION="$version"
		break
	fi
done < <(curl -A "$USER_AGENT" -LSs --connect-timeout 30 https://build.wireguard.com/distros.txt)

[[ -n $VERSION ]]

echo "touch-ing the .check..."
if [[ -f net/wireguard/version.h && $(< net/wireguard/version.h) == *$VERSION* ]]; then
	touch net/wireguard/.check
	exit 0
fi

echo "rm-ing the old wirguard dir..."
rm -rf net/wireguard
mkdir -p net/wireguard

echo "curl-ing the new wirguard dir..."
echo "$VERSION"
curl -A "$USER_AGENT" -LsS --connect-timeout 30 "https://git.zx2c4.com/WireGuard/snapshot/WireGuard-$VERSION.tar.xz" | tar -C "net/wireguard" -xJf - --strip-components=2 "WireGuard-$VERSION/src"

echo "sed-ing the config"
sed -i 's/tristate/bool/;s/default m/default y/;' net/wireguard/Kconfig
touch net/wireguard/.check
