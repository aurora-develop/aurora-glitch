FILES_PATH=${FILES_PATH:-./}
CURRENT_VERSION=''
RELEASE_LATEST=''

get_current_version() {
    CURRENT_VERSION=$(cat VERSION)
}

get_latest_version() {
    # Get latest release version number
    RELEASE_LATEST=$(curl -s https://api.github.com/repos/aurora-develop/aurora/releases/latest | jq -r '.tag_name')
    if [[ -z "$RELEASE_LATEST" ]]; then
        echo "error: Failed to get the latest release version, please check your network."
        exit 1
    fi
}

download_web() {
    DOWNLOAD_LINK="https://github.com/aurora-develop/aurora/releases/latest/download/aurora-linux-amd64.tar.gz"
    if ! wget -qO "$ZIP_FILE" "$DOWNLOAD_LINK"; then
        echo 'error: Download failed! Please check your network or try again.'
        return 1
    fi
    curl -s https://api.github.com/repos/aurora-develop/aurora/releases/latest | jq -r '.tag_name' > VERSION
    return 0
}

decompression() {
    tar -zxf "$1" -C "$TMP_DIRECTORY"
    EXIT_CODE=$?
    if [ ${EXIT_CODE} -ne 0 ]; then
        "rm" -r "$TMP_DIRECTORY"
        echo "removed: $TMP_DIRECTORY"
        exit 1
    fi
}

install_web() {
    install -m 755 ${TMP_DIRECTORY}/aurora ${FILES_PATH}/app.js
}

run_web() { 
    killall app.js 2>/dev/null &
    if [ "${PROXY_URL}" != "" ]; then
        export PROXY_URL=${PROXY_URL}
    fi
    if [ "${Authorization}" != "" ]; then
        export Authorization=${Authorization}
    fi
    export SERVER_PORT=8080
    exec ./app.js 2>&1 &
}

generate_argo(){
    cat > argo.sh << EOF
check_file() {
    [ ! -e cloudflared ] && wget -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x cloudflared
}

run_argo() {
  chmod +x cloudflared && nohup ./cloudflared tunnel --edge-ip-version auto --protocol http2 run --token ${ARGO_AUTH} 2>/dev/null 2>&1 &
}

if [ "${ARGO_AUTH}" != "" ]; then
  check_file
  run_argo
fi
EOF
}

generate_autodel() {
  cat > auto_del.sh << EOF
while true; do
  rm -rf /app/.git
  sleep 5
done
EOF
}

generate_autodel
generate_argo
[ -e auto_del.sh ] && bash auto_del.sh &
if [ "${ARGO_AUTH}" != "" ]; then
bash argo.sh &
fi

TMP_DIRECTORY="$(mktemp -d)"
ZIP_FILE="${TMP_DIRECTORY}/aurora-linux-amd64.tar.gz"

get_current_version
get_latest_version
if [ "${RELEASE_LATEST}" = "${CURRENT_VERSION}" ]; then
    "rm" -rf "$TMP_DIRECTORY"
    run_web
    exit
fi

download_web
EXIT_CODE=$?
if [ ${EXIT_CODE} -eq 0 ]; then
    :
else
    "rm" -r "$TMP_DIRECTORY"
    run_web
    exit
fi
decompression "$ZIP_FILE"
install_web
"rm" -rf "$TMP_DIRECTORY"
run_web