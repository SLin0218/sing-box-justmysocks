# sing-box-justmysocks

sing-box-justmysocks is a subscription data conversion script for [justmysocks](justmysocks.net).

## Installation

### Dependency

- [jq](https://github.com/jqlang/jq)
- [box_for_magrisk](https://github.com/taamarin/box_for_magisk) Android Transparent Proxy Configuration Tool, requires root.

```
git clone https://github.com/SLin0218/sing-box-justmysocks.git
```

## Sing-box config template

```jsonc
{
  "log": {
    "level": "info",
    "output": "box.log",
    "timestamp": true,
  },
  "dns": {
    "servers": [
      {
        "type": "udp",
        "tag": "local",
        "server": "223.5.5.5",
      },
      {
        "type": "fakeip",
        "tag": "fakeip",
        "inet4_range": "198.18.0.0/15",
        "inet6_range": "fc00::/18",
      },
    ],
    "rules": [
      {
        "clash_mode": "Direct",
        "server": "local",
      },
      {
        "clash_mode": "Global",
        "server": "fakeip",
      },
      {
        "rule_set": ["geosite-geolocation-cn", "geoip-cn"],
        "server": "local",
      },
      {
        "query_type": ["A", "AAAA"],
        "server": "fakeip",
      },
    ],
  },
  "inbounds": [
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "127.0.0.1",
      "listen_port": 8809,
      "sniff": true,
    },
    {
      "type": "tproxy",
      "tag": "tproxy-in",
      "listen": "127.0.0.1",
      "listen_port": 9898,
      "sniff": true,
    },
  ],
  "outbounds": [],
  "route": {
    "rules": [
      {
        "clash_mode": "Direct",
        "outbound": "direct",
      },
      {
        "clash_mode": "Global",
        "outbound": "proxy",
      },
      {
        "type": "logical",
        "mode": "or",
        "rules": [
          {
            "protocol": "dns",
          },
          {
            "port": 53,
          },
        ],
        "action": "hijack-dns",
      },
      {
        "type": "logical",
        "mode": "or",
        "rules": [
          {
            "port": 853,
          },
          {
            "network": "udp",
            "port": 443,
          },
          {
            "protocol": "stun",
          },
        ],
        "action": "reject",
      },
      {
        "rule_set": "geosite-category-ads-all",
        "action": "reject",
      },
      {
        "package_name": [
          // wechat package name
          "com.tencent.mm",
          //..
        ],
        "outbound": "direct",
      },
      {
        "rule_set": ["geosite-geolocation-cn", "geoip-cn"],
        "outbound": "direct",
      },
      {
        "ip_is_private": true,
        "outbound": "direct",
      },
    ],
    "rule_set": [
      {
        "type": "remote",
        "tag": "geosite-geolocation-cn",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-cn.srs",
      },
      {
        "type": "remote",
        "tag": "geoip-cn",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs",
      },
      {
        "type": "remote",
        "tag": "geosite-category-ads-all",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/refs/heads/rule-set/geosite-category-ads-all.srs",
      },
    ],
    "final": "proxy",
    "auto_detect_interface": false,
    "default_domain_resolver": "local",
  },
  "experimental": {
    "cache_file": {
      "enabled": true,
      "store_fakeip": true,
      "store_rdrc": true,
    },
    "clash_api": {
      "external_controller": "127.0.0.1:9090",
      "external_ui": "dashboard",
    },
  },
}
```

## Usage

```sh
./update_subscription.sh
```

## License

[MIT](https://choosealicense.com/licenses/mit/)
