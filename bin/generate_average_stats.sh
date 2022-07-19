#!/bin/bash
set -euf -o pipefail

ARCHIVE_API_URL="https://api.github.com/repos/lincolnloop/python-package-manager-shootout/actions/artifacts"
ARCHIVE_URLS=$(curl -s "$ARCHIVE_API_URL" | jq -r '.artifacts | map(select(.name == "stats"))[].archive_download_url' | head -n4)

# concatenate the stats files into a single file
for url in $ARCHIVE_URLS; do
    curl -sLo -H "Authorization: token $GITHUB_TOKEN" stats.zip "$url"
    unzip -o stats.zip
    cat stats.csv >> tmp.csv
done

# strip extra headers from the stats file
HEADER=$(head -n 1 tmp.csv)
echo "$HEADER" > full.csv
grep -v "$HEADER" tmp.csv >> full.csv

# average stats by tool/stat
sqlite-utils memory full.csv \
  "SELECT tool,stat,AVG(\"elapsed time\") AS \"elapsed time\" FROM full GROUP BY tool,stat" \
  --csv > stats.csv