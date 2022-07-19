#!/bin/bash
set -euf -o pipefail

RUN_COUNT=6
RECENT_RUNS=$(gh run list --workflow benchmark --json databaseId,event --limit 100 --jq 'map(select(.event=="schedule")) | .[].databaseId' | head -n "$RUN_COUNT")
# concatenate the stats files into a single file
for id in $RECENT_RUNS; do
    gh run download "$id" --name stats
    cat stats.csv >> tmp.csv
    rm -f stats.csv stats.db
done

# strip extra headers from the stats file
HEADER=$(head -n 1 tmp.csv)
echo "$HEADER" > full.csv
grep -v "$HEADER" tmp.csv >> full.csv

# average stats by tool/stat
sqlite-utils memory full.csv \
  "SELECT
    tool,
    stat,
    AVG(\"elapsed time\") AS \"elapsed time\",
    MIN(\"elapsed time\") AS \"elapsed time (min)\",
    MAX(\"elapsed time\") AS \"elapsed time (max)\"
  FROM full
  GROUP BY tool,stat" \
  --csv > stats.csv