#!/bin/bash

# Get all the tags in the repository
tags=$(git tag)

# Convert the tags into an array
IFS=$'\n' read -r -d '' -a tags_array <<< "$tags"

# Check if the tags list is empty
if [ ${#tags_array[@]} -eq 0 ]; then
  echo "Error: No tags found in the repository."
  exit 1
fi

# Get the last and the previous tag
last_tag=${tags_array[-1]}
if [ ${#tags_array[@]} -gt 1 ]; then
  previous_tag=${tags_array[-2]}
else
  # If no previous tag, use the first commit
  previous_tag="$(git rev-list --max-parents=0 HEAD)"
fi

# Assign the tags to the variables TAG1 and TAG2
TAG1=$previous_tag
TAG2=$last_tag

# Check if the first tag exists
if [ -z "$TAG1" ]; then
  echo "Error: The first tag must be provided as an argument."
  exit 1
fi

# Generate the header of the Markdown content
RELEASE_BODY="# Release Notes for $TAG2\n"
RELEASE_BODY+="## What's Changed\n"

# Check if the second tag exists
if git rev-parse "$TAG2" >/dev/null 2>&1; then
  # If both tags exist, show the commits between them
  RELEASE_BODY+="$(git log $TAG1..$TAG2 --oneline --pretty=format:"- %s")\n"
else
  # If the second tag does not exist, show commits from the beginning of the repo to the first tag
  RELEASE_BODY+="$(git log --oneline $TAG1 --pretty=format:"- %s")\n"
fi

# Add contributors section
RELEASE_BODY+="\n## Contributors:\n"

# Get the list of contributors (commit authors)
contributors=$(git log $TAG1..$TAG2 --pretty=format:"%an" | sort | uniq)
for contributor in $contributors; do
  RELEASE_BODY+="- $contributor\n"
done

# Set the release notes in the GitHub environment variable
{
  echo "RELEASE_BODY<<EOF"
  echo -e "$RELEASE_BODY"
  echo "EOF"
} >> $GITHUB_ENV
