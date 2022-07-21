#!/bin/bash
set -euf -o pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

RUN_COUNT=4
RUN_LIST=$(gh run list --workflow benchmark --json databaseId,event --limit 50 --jq 'map(select(.event=="schedule")) | .[].databaseId')
RECENT_RUNS=$(echo "$RUN_LIST" | head -n "$RUN_COUNT")
# concatenate the stats files into a single file
for id in $RECENT_RUNS; do
    echo "Downloading stats from run $id"
    gh run download "$id" --name stats
    cat stats.csv >> tmp.csv
    rm -f stats.csv stats.db
done

# strip extra headers from the stats file
echo "Joining stats files"
HEADER=$(head -n 1 tmp.csv)
echo "$HEADER" > full.csv
grep -v "$HEADER" tmp.csv >> full.csv

echo "Calculating average stats across runs"
# average stats by tool/stat
# load-extension is built for linux/amd64, remove if you want to run on Mac
# built from https://kedeligdata.blogspot.com/2010/09/sqlite-with-stdev-standard-deviation.html
sqlite-utils memory full.csv \
  --load-extension "$SCRIPT_DIR/libsqlitefunctions" \
  "SELECT
    tool,
    stat,
    ROUND(AVG(\"elapsed time\"), 2) AS \"elapsed time\",
    MIN(\"elapsed time\") AS \"elapsed time (min)\",
    MAX(\"elapsed time\") AS \"elapsed time (max)\",
    ROUND(stdev(\"elapsed time\"), 2) AS \"elapsed time (stdev)\"
  FROM full
  GROUP BY tool,stat" \
  --csv > stats.csv
echo "Stats saved to stats.csv"