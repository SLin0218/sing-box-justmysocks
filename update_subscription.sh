#!/bin/sh
# shellcheck disable=SC2016
# on termux, apt install jq. path = /data/data/com.termux/files/usr/bin/jq
# on linux, apt install jq. path = /usr/bin/jq

if command -v jq >/dev/null 2>&1; then
  echo "Using jq at $(jq --version)"
else
  if [ -f "/data/data/com.termux/files/usr/bin/jq" ]; then
    export PATH="$PATH:/data/data/com.termux/files/usr/bin/"
  else
    echo "jq is not installed. Please install jq to continue."
    echo "On Termux, you can install it using: apt install jq"
    echo "On Linux, you can install it using: apt install jq"
    echo "On macOS, you can install it using: brew install jq"
    exit 1
  fi
  echo "Using jq at $(jq --version)"
fi

subscription_url="https://jmssub.net/members/getsub.php?service=${service}&id=${id}"
echo $subscription_url

# sing-box config file path
current_dir=$(dirname "$(readlink -f "$0")")
sing_config_template="$current_dir/config-template.json"

subs_resp=$(curl -s "${subscription_url}")
if [ -z "$subs_resp" ];then
  echo Subscription response is empty
fi

config_file=$(jq '.outbounds = [{ "type": "urltest", "tag": "proxy", "outbounds": []}]' "${sing_config_template}")

sing_config="/data/adb/box/sing-box/config.json"

while IFS= read -r line; do
  # Decode the base64 encoded string
  line_decode=$(echo "$line" | grep -oE '//([0-9a-zA-Z]+)#?' | sed 's/[\/|#]//g')
  line_decode=$(printf "%s" "$line_decode" | awk '{len=length($0); if(len%4!=0) {len=len%4; for(i=0;i<4-len;i++) $0=$0"="; } print $0}' | base64 -d)

  if [ "$(printf '%s' "$line" | cut -c1-2)" = "ss" ]; then
    tag_name=$(echo "$line" | grep -oE '@([0-9a-zA-Z]+)\.' | sed 's/[@|\.]//g')
    ss_server=$(echo "$line_decode" |
      sed 's/@/:/g' |
      awk -F: -v tag_name="$tag_name" \
        '{print "{\"tag\": \"" tag_name "\", \"type\": \"shadowsocks\", \"server\": \"" $3 "\", \"server_port\": " $4 ", \"password\": \""$2"\", \"method\": \""$1"\"}"}')
    config_file=$(echo "$config_file" | jq --argjson ss "$ss_server" '.outbounds += [$ss]')
    echo "found shadowsock config $tag_name"
  else
    tag_name=$(echo "$line_decode" | jq -r '.ps' | grep -oE '@([0-9a-zA-Z]+)\.' | sed 's/[@|\.]//g')
    vm_server=$(echo "$line_decode" | jq --arg tag_name "$tag_name" '{
      "tag": $tag_name,
      "type": "vmess",
      "server": .add,
      "server_port": .port|tonumber,
      "uuid": .id,
      "alter_id": .aid,
      "security": "auto"
    }')
    config_file=$(echo "$config_file" | jq --argjson vm "$vm_server" '.outbounds += [$vm]')
    echo "found vmess config $tag_name"
  fi
  config_file=$(echo "$config_file" | jq --arg tag_name "$tag_name" '.outbounds[0].outbounds += [$tag_name]')
done <<EOF
$(echo "$subs_resp" | base64 -d)
EOF

config_file=$(echo "$config_file" | jq --argjson vm '{ "type": "direct", "tag": "direct" }' '.outbounds += [$vm]')

now=$(date +%s)
#cp "${sing_config}" "${sing_config}${now}.bak"
echo "$config_file" >"${sing_config}"

echo "Sing Box Subscription updated successfully"
