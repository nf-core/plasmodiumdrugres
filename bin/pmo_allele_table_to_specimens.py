#!/usr/bin/env python3

"""
Convert a library-level allele table extracted from a PMO into a specimen-level allele table.

The input table must contain the columns 'library_sample_name', 'specimen_name',
'target_name', 'seq' and 'reads' (as written by
`pmotools-python extract_allele_table --default_base_col_names library_sample_name,target_name,seq
--specimen_info_meta_fields specimen_name --microhap_fields reads`).

Specimens with more than one library sample are handled with --method:
  combine    keep all library samples and sum reads of identical microhaplotypes
  max_reads  keep only the library sample with the highest total read count

Usage:
  pmo_allele_table_to_specimens.py \
      --input pmo_allele_table.tsv \
      --method combine \
      --output allele_table.tsv
"""

import argparse
import sys

import pandas as pd

KEY_COLS = ["specimen_name", "target_name", "seq"]


def parse_args() -> argparse.Namespace:
  parser = argparse.ArgumentParser(
    description="Convert a library-level PMO allele table to a specimen-level allele table."
  )
  parser.add_argument("--input", required=True, help="Library-level allele table (TSV).")
  parser.add_argument(
    "--method",
    choices=["combine", "max_reads"],
    default="combine",
    help="How to handle specimens with more than one library sample (default: combine).",
  )
  parser.add_argument(
    "--output", default="allele_table.tsv", help="Specimen-level allele table (TSV)."
  )
  return parser.parse_args()


def join_unique(values: pd.Series) -> str:
  return ",".join(sorted(set(values.astype(str))))


def main() -> None:
  args = parse_args()
  table = pd.read_csv(args.input, sep="\t", dtype={"specimen_name": str, "library_sample_name": str})

  missing = [c for c in ["library_sample_name", *KEY_COLS, "reads"] if c not in table.columns]
  if missing:
    sys.exit(f"Error: input allele table is missing columns: {', '.join(missing)}")

  libraries_per_specimen = table.groupby("specimen_name")["library_sample_name"].nunique()
  n_replicated = int((libraries_per_specimen > 1).sum())

  if args.method == "max_reads" and n_replicated > 0:
    library_reads = (
      table.groupby(["specimen_name", "library_sample_name"], as_index=False)["reads"]
      .sum()
      .sort_values(["specimen_name", "reads", "library_sample_name"], ascending=[True, False, True])
    )
    keep = library_reads.drop_duplicates("specimen_name")["library_sample_name"]
    table = table[table["library_sample_name"].isin(keep)]

  extra_cols = [c for c in table.columns if c not in ["library_sample_name", *KEY_COLS, "reads"]]
  aggregations = {c: join_unique for c in extra_cols}
  aggregations["reads"] = "sum"
  out = table.groupby(KEY_COLS, as_index=False, sort=False).agg(aggregations)
  out[[*KEY_COLS, *extra_cols, "reads"]].to_csv(args.output, sep="\t", index=False)

  if n_replicated > 0:
    action = (
      "reads of identical microhaplotypes were summed"
      if args.method == "combine"
      else "only the library sample with the most reads was kept"
    )
    print(
      f"{n_replicated} specimen(s) had more than one library sample; {action}.",
      file=sys.stderr,
    )


if __name__ == "__main__":
  main()
