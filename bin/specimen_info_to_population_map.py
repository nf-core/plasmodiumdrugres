#!/usr/bin/env python3

"""
Create a two-column population map from a specimen_info table.

Given:
  - a tab-delimited input table ("specimen_info") with a required column
    'specimen_name' and additional metadata columns, and
  - a list of field names,
this script:
  1. Selects the 'specimen_name' column and the specified fields.
  2. Concatenates the specified fields for each row with '_' into a new
     'population' column.
  3. Writes a two-column, tab-delimited output table:
       specimen_name<TAB>population

Usage:
  specimen_info_to_population_map.py \
      --specimen-info specimen_info.tsv \
      --fields country site year \
      --output population_map.tsv
"""

import argparse
import csv
import sys
from typing import List


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser(
    description="Create population map from specimen_info table."
  )
  parser.add_argument(
    "--specimen-info",
    required=True,
    help="Path to input specimen_info TSV file.",
  )
  parser.add_argument(
    "--fields",
    required=True,
    nargs="+",
    help=(
      "One or more column names from specimen_info to combine into "
      "the population label."
    ),
  )
  parser.add_argument(
    "--separator",
    default="_",
    help=(
      "String used to join the selected fields into the population label "
      "(default: '_')."
    ),
  )
  parser.add_argument(
    "--output",
    default="population_map.tsv",
    help=(
      "Path to output TSV file (specimen_name and population). "
      "Defaults to 'population_map.tsv' in the current directory."
    ),
  )
  return parser.parse_args()


def validate_columns(header: List[str], fields: List[str]) -> None:
  if "specimen_name" not in header:
    sys.exit("Error: Input table must contain a 'specimen_name' column.")

  missing = [f for f in fields if f not in header]
  if missing:
    sys.exit(
      "Error: The following requested fields are not present in the input "
      f"header: {', '.join(missing)}"
    )


def main() -> None:
  args = parse_args()

  try:
    with open(args.specimen_info, newline="") as infile:
      reader = csv.DictReader(infile, delimiter="\t")
      if reader.fieldnames is None:
        sys.exit("Error: Input file appears to be empty or lacks a header.")

      header = reader.fieldnames
      validate_columns(header, args.fields)

      with open(args.output, "w", newline="") as outfile:
        writer = csv.writer(outfile, delimiter="\t")
        writer.writerow(["specimen_name", "population"])

        for row in reader:
          specimen_name = row.get("specimen_name", "").strip()
          # Combine requested fields with the chosen separator to form the population label.
          # Strip each value to avoid hidden trailing whitespace (e.g. CR/LF) ending up
          # inside filenames later in the pipeline.
          population_parts = [str(row.get(field, "")).strip() for field in args.fields]
          population = args.separator.join(population_parts)
          writer.writerow([specimen_name, population])

  except FileNotFoundError as e:
    sys.exit(f"Error: {e}")


if __name__ == "__main__":
  main()
