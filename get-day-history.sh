#!/bin/bash

source $(dirname $0)/token.sh # get TOKEN env var

#get what days we want to do - default to yesterday & today
if [[ -n "$1" ]]; then
  YESTERDAY_DATE=$(date -d "$1" +%Y-%m-%d)
else 
  YESTERDAY_DATE=$(date -d "yesterday" +%Y-%m-%d)
fi

if [[ -n "$2" ]]; then
  TODAY_DATE=$(date -d "$2" +%Y-%m-%d)
else
  # means you only need to specify $1 when redoing old backups
  TODAY_DATE=$(date -d "$YESTERDAY_DATE +1 day" +%Y-%m-%d)
fi

#timestamps for the api calls
YESTERDAY=$(date -d "${YESTERDAY_DATE} 00:00:00 UTC" +%s)
TODAY=$(date -d "${TODAY_DATE} 00:00:00 UTC" +%s)

download_channel() {
  CHID=$1
  CHNAME=$(curl -sS "https://slack.com/api/channels.info?token=${TOKEN}&channel=${CHID}&pretty=1" | grep '"name"' | awk -F'"' '{print $4}')
  FILENAME="channel-archives/${CHNAME}/${YESTERDAY_DATE}.slack.json"

  # set up for writing to the file
  mkdir -p $(dirname "${FILENAME}")
  rm -f "${FILENAME}"

  # get the first page of results; if it's empty, we won't end up printing anything
  LATEST="$TODAY"
  PAGE_COUNTER=1
  PAGE=$(curl -sS "https://slack.com/api/channels.history?token=${TOKEN}&channel=${CHID}&latest=${LATEST}&oldest=${YESTERDAY}&inclusive=1&count=1000&pretty=1")
  sleep 1s

  # while the current page has data, write to the file and get the next page
  while [[ "$(echo "$PAGE" | wc -c)" -gt 145 ]]; do
    echo "writing ${FILENAME} page ${PAGE_COUNTER}"
    echo "$PAGE" >> "${FILENAME}"

    LATEST=$(echo "$PAGE" | grep '"ts":' | tail -n1 | awk -F'"' '{print $4}' | awk -F'.' '{print $1}')
    PAGE_COUNTER=$((PAGE_COUNTER + 1))
    PAGE=$(curl -sS "https://slack.com/api/channels.history?token=${TOKEN}&channel=${CHID}&latest=${LATEST}&oldest=${YESTERDAY}&inclusive=1&count=1000&pretty=1")
    sleep 1s
  done
}

cd /home/devin/slack2html

CHANNEL_IDS=$(curl -sS "https://slack.com/api/channels.list?token=${TOKEN}&pretty=1" 2>/dev/null | grep '"id"' | awk -F'"' '{print $4}')

for CHID in $CHANNEL_IDS; do
  download_channel $CHID
done

#chown -R devin:www-data channel-archives
#find channel-archives -type d -exec chmod 755 '{}' \;
#find channel-archives -type f -exec chmod 644 '{}' \;
