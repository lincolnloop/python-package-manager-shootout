#!/usr/bin/env python
"""
Usage: csv_to_json.py <csv_file>
"""
import csv
import json
import sys
from typing import List


def csv_to_dicts(csv_file: str) -> List[dict]:
    """Convert a CSV file to a JSON file"""
    with open(csv_file, "r") as csv_fh:
        reader = csv.DictReader(csv_fh)
        return list(reader)


graphs = {
    "lock": {"labels": [], "datasets": []},
    "install": {"labels": [], "datasets": []},
    "update": {"labels": [], "datasets": []},
    "add-package": {"labels": [], "datasets": []},
    "tooling": {"labels": [], "datasets": []},
}


def convert_to_chartjs(data: List[dict]):
    """Convert a list of dicts into objects that can be used by ChartJS"""
    vals = []

    for i in data:
        # Get the chart name, allowing that some have both cold and warm runs.
        key = i["stat"]
        split_key = key.rsplit("-", 1)
        label = split_key[-1] if split_key[-1] in {"cold", "warm"} else None
        key = key if label is None else split_key[0]
        if key not in graphs:
            continue

        # Find or create the dataset that this belongs to.
        datasets = graphs[key]["datasets"]
        try:
            dataset = next(d for d in datasets if d.get("label") == label)
        except StopIteration:
            dataset = {"data": []} if label is None else {"data": [], "label": label}
            datasets.append(dataset)

        # Add data to the dataset.
        datum = {
            "id": i["tool"],
            "max": i["elapsed time (max)"],
            "min": i["elapsed time (min)"],
            "avg": i["elapsed time"],
        }
        dataset["data"].append(datum)

        vals.append(float(i["elapsed time (max)"]))

    # cleanup missing data points (might be waiting for a scheduled run)
    for key in list(graphs.keys()):
        if not graphs[key]["datasets"]:
            del graphs[key]

    graphs["max"] = max(*vals)
    return graphs


if __name__ == "__main__":
    data = csv_to_dicts(sys.argv[1])
    print(json.dumps(convert_to_chartjs(data), indent=2))
