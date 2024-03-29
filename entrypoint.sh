#!/bin/bash

# get latest tag
lastTag=$(git describe --tags `git rev-list --tags --max-count=1`)
t="${lastTag:1}"
# print latest
echo "Tag: $lastTag Version: $t"

# if we have a blank tag, get all commits
if [ -z "$t" ]
then
    log=$(git log --pretty=oneline)
    t=0.0.0
# otherwise, get commits since last tag
else
    log=$(git log $t..HEAD --pretty=oneline)
fi

# supports #major, #minor, #patch (anything else will be 'minor')
case "$log" in
    *#major* ) new=$(semver bump major $t);;
    *#patch* ) new=$(semver bump patch $t);;
    * ) new=$(semver bump minor $t);;
esac

# get repo name from git
commit=$(git rev-parse HEAD)
remote=$(git config --get remote.origin.url)
repo=$(basename $remote .git)

echo "Posting Tag: v$new on commit $commit to https://api.github.com/repos/$REPO_OWNER/$repo/git/refs"

# POST a new ref to repo via Github API
curl -s -X POST https://api.github.com/repos/$REPO_OWNER/$repo/git/refs \
-H "Authorization: token $GITHUB_TOKEN" \
-d @- << EOF
{
  "ref": "refs/tags/v$new",
  "sha": "$commit"
}
EOF