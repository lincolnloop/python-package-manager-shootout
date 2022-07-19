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
    "add-package": {"labels": [], "datasets": []},
}


def convert_to_chartjs(data: List[dict]):
    """Convert a list of dicts into objects that can be used by ChartJS"""
    vals = []
    for i in data:

        if i["stat"] in graphs:
            key = i["stat"]
        else:
            continue
        vals.append(float(i["elapsed time"]))
        if graphs[key]["datasets"] and graphs[key]["datasets"][-1]:
            graphs[key]["datasets"][-1]["data"].append(float(i["elapsed time"]))
        else:
            graphs[key]["datasets"].append({"data": [float(i["elapsed time"])]})
        if i["tool"] not in graphs[key]["labels"]:
            graphs[key]["labels"].append(i["tool"])

    # install needs both cold & warm datapoints
    graphs["install"] = {"labels": []}
    warm = {"data": [], "label": "warm"}
    cold = {"data": [], "label": "cold"}
    for i in data:
        if i["stat"] == "install-cold":
            cold["data"].append(float(i["elapsed time"]))
        elif i["stat"] == "install-warm":
            warm["data"].append(float(i["elapsed time"]))
        else:
            continue
        vals.append(float(i["elapsed time"]))
        if i["tool"] not in graphs["install"]["labels"]:
            graphs["install"]["labels"].append(i["tool"])
    graphs["install"]["datasets"] = [cold, warm]

    # cleanup missing data points (might be waiting for a scheduled run)
    for graph in list(graphs.keys()):
        if not graphs[graph]["datasets"]:
            del graphs[graph]

    graphs["max"] = max(*vals)
    return graphs


if __name__ == "__main__":
    data = csv_to_dicts(sys.argv[1])
    print(json.dumps(convert_to_chartjs(data), indent=2))
