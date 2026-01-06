#!/usr/bin/env bash

# archive_old_files.sh
#
# Purpose:
#   Find files older than N days under SOURCE_DIR, create a dated .tar.gz archive,
#   print the files being archived, and (optionally) delete them after success.
#
# Usage:
#   ./archive_old_files.sh
#   DRY_RUN=1 ./archive_old_files.sh
#   DELETE_AFTER=1 ./archive_old_files.sh archive_old_files.sh
#
# Purpose:
#   Find files older than N days under SOURCE_DIR, create a dated .tar.gz archive,
#   print the files being archived, and (optionally) delete them after success.
#
# Usage:
#   ./archive_old_files.sh
#   DRY_RUN=1 ./archive_old_files.sh
#   DELETE_AFTER=1 ./archive_old_files.sh

set -euo pipefail

read -rp "Source Directory: " source_dir
read -rp "Archive Directory: " archive_dir
DAYS_OLD=30


DRY_RUN="${DRY_RUN:-0}"
DELETE_AFTER="${DELETE_AFTER:-0}"

STAMP="$(date +%Y-%m-%d_%H%M%S)"
ARCHIVE_NAME="old_files_${DAYS_OLD}d_${STAMP}.tar.gz"
ARCHIVE_PATH="${archive_dir}/${ARCHIVE_NAME}"

mkdir -p "$archive_dir"

echo "Source directory : ${source_dir}"
echo "Archive directory: ${archive_dir}"
echo "Age threshold    : > ${DAYS_OLD} days (mtime) "
echo "Archive output   : ${ARCHIVE_PATH}"
echo "Dry run          : ${DRY_RUN}"
echo "Delete after     : ${DELETE_AFTER}"


if [[ ! -d "${source_dir}" ]]; then
	echo "ERROR: ${source_dir} does not exit or is not a directory" >&2 
	exit 1
fi

file_list_nul="$(mktemp)"
trap 'rm -f "${file_list_nul}"' EXIT

find "${source_dir}" -type f -mtime "+${DAYS_OLD}" -print0 > "${file_list_nul}"

if [[ "${DRY_RUN}" == "1" ]]; then
	echo "DRY_RUN=1 set. Skipping archive creation and deletion."
	exit 0
fi


echo "Creating archive... "
tar --null --files-from="$file_list_nul" -cvzf "$ARCHIVE_PATH"

echo "Archive created: $ARCHIVE_PATH"

if [[ "$DELETE_AFTER" == "1" ]]; then
	echo "Deleting archived files (because DELETE_AFTER=1)..."
	xargs -0 rm -f < "${file_list_nul}"
	echo "Deletion complete."
else
	echo "DELETE_AFTER is not set to 1. Original files were NOT deleted."
fi

