 
#!/bin/bash

# Usage: ./generate-release-markdown.sh [local]

tags=$(git tag --sort=version:refname)
IFS=$'\n' read -r -d '' -a tags_array <<< "$tags"

if [ ${#tags_array[@]} -eq 0 ]; then
  echo "Error: No tags found in the repository."
  exit 1
fi

if [ -n "$GITHUB_REF_NAME" ]; then
  TAG2="$GITHUB_REF_NAME"
else
  last_idx=$(( ${#tags_array[@]} - 1 ))
  TAG2=${tags_array[$last_idx]}
fi

previous_tag=""
for i in "${!tags_array[@]}"; do
  if [ "${tags_array[$i]}" = "$TAG2" ] && [ "$i" -gt 0 ]; then
    previous_tag=${tags_array[$((i - 1))]}
    break
  fi
done

if [ -z "$previous_tag" ]; then
  previous_tag="$(git rev-list --max-parents=0 HEAD)"
fi

TAG1=$previous_tag

RELEASE_BODY="# Release Notes for $TAG2\n"
RELEASE_BODY+="## What's Changed\n"

if git rev-parse "$TAG2" >/dev/null 2>&1; then
  RELEASE_BODY+="$(git log "$TAG1".."$TAG2" --pretty=format:"- %s")\n"
else
  RELEASE_BODY+="$(git log "$TAG1" --pretty=format:"- %s")\n"
fi

if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_REPOSITORY" ]; then
  logins=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/compare/${TAG1}...${TAG2}" \
    | jq -r '.commits[].author.login // empty' | sort -u)
  mentions=""
  while IFS= read -r login; do
    [ -n "$login" ] && mentions+="@$login "
  done <<< "$logins"
  [ -n "$mentions" ] && RELEASE_BODY+="\n## New Contributors\n$mentions\n"
else
  contributors=$(git log "$TAG1".."$TAG2" --pretty=format:"%an" | sort | uniq)
  mentions=""
  while IFS= read -r contributor; do
    if [[ "$contributor" == *" "* ]]; then
      mentions+="$contributor "
    else
      mentions+="@$contributor "
    fi
  done <<< "$contributors"
  [ -n "$mentions" ] && RELEASE_BODY+="\n## New Contributors\n$mentions\n"
fi



if [ "$1" == "local" ]; then
  printf '%b\n' "$RELEASE_BODY" > release_notes.md
  echo "Release notes saved to release_notes.md"
else
  printf '%b\n' "$RELEASE_BODY" > release_notes.md
  if [ -n "$GITHUB_ENV" ]; then
    {
      echo "RELEASE_BODY<<EOF"
      printf '%b\n' "$RELEASE_BODY"
      echo "EOF"
    } >> "$GITHUB_ENV"
  fi
fi
