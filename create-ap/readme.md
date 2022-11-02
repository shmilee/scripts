1. https://github.com/lakinduakash/linux-wifi-hotspot

```
sudo create_ap wlan0 wlan0 yourAP YourPass -g 192.168.6.1
```

2. transocks https://github.com/cybozu-go/transocks

Bin https://github.com/cybozu-go/transocks/issues/29

```
./transocks -f ./transocks.toml
```

3. https://gist.github.com/andersondanilo/a28e7165fa8a9700d8ead20a224ecf44

```
./configure_iptables_transocks_and_create_ap.sh
```

4. ap-client -> ap -> transocks -> 8087
