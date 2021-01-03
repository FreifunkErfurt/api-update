#!/bin/sh
#
# api update - Generate api file based on template
#
# This script will update node counter based on meshviewer json
# data in a template used for freifunk api.
#
# Copyright Freifunk Erfurt, 2021
# Marcel Pennewiss <opensource@pennewiss.de>
#
# Version: 1.0
# Last-Modified: 2021-01-02
#
# REQUIREMENTS:
#   * jq

# CONFIGURATION ################################################

TEMPLATE="template.json"
OUTPUT="/var/www/public_html/freifunk-api.json"
MESHVIEWER_JSON_URL="https://map.erfurt.freifunk.net/meshviewer/data/meshviewer.json"

# SCRIPT #######################################################

SCRIPT_PATH=$(realpath "$0" | sed 's|\(.*\)/.*|\1|')

# Download meshviewer json file
get_meshviewer_json() {

  # Create temp file
  TEMP_FILE=$(mktemp)

  # Get Meshviewer file
  $(which wget) --quiet $MESHVIEWER_JSON_URL -O "$TEMP_FILE" > /dev/null 2>&1

  return $?
}

# Update api file
update_api_file() {

  # Get nodes
  __NODECOUNT=$(jq '.nodes[] | select(.is_online == true and .is_gateway == false) | .node_id' "$TEMP_FILE" | wc -l)

  # Get current date/time
  __LASTCHANGE=$(date -u +%FT%TZ)

  # Update json template to new file
  jq --ascii-output \
     --arg NODECOUNT "$__NODECOUNT" \
     --arg LASTCHANGE "$__LASTCHANGE" \
     '.state.nodes = ($NODECOUNT|tonumber) | .state.lastchange = $LASTCHANGE' \
     "$SCRIPT_PATH/$TEMPLATE" > "$OUTPUT.new"

  # Move new file to destination file
  mv "$OUTPUT.new" "$OUTPUT"
}

# Cleanup temp file
cleanup() {
  # Remove existing tempfile
  [ -f "$TEMP_FILE" ] && rm "$TEMP_FILE"
}


get_meshviewer_json
if get_meshviewer_json; then
  update_api_file
fi
cleanup
