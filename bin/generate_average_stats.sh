#!/bin/bash
set -euf -o pipefail

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
sqlite-utils memory full.csv \
  "SELECT
    tool,
    stat,
    ROUND(AVG(\"elapsed time\"), 2) AS \"elapsed time\",
    MIN(\"elapsed time\") AS \"elapsed time (min)\",
    MAX(\"elapsed time\") AS \"elapsed time (max)\"
  FROM full
  GROUP BY tool,stat" \
  --csv > stats.csv
echo "Stats saved to stats.csv"