#!/bin/bash

OWNER="aurora-develop"
REPO="aurora"

LATEST_RELEASE=$(curl -s https://api.github.com/repos/$OWNER/$REPO/releases/latest | grep "tag_name" | cut -d : -f2,3 | tr -d \",)

ASSET_URL=$(curl -s https://api.github.com/repos/$OWNER/$REPO/releases/latest | grep "browser_download_url.*linux-amd64.tar.gz" | cut -d : -f2,3 | tr -d \")

wget -O aurora.tar.gz $ASSET_URL

tar -xzvf aurora.tar.gz

chmod +x aurora

./aurora
