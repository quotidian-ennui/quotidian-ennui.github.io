---
layout: post
title: "Dismissing Dependabot Alerts"
comments: false
tags: [development,github]
# categories: [development,rant]
published: true
description: "Like my docs, I like my 'reasons' to be next to my source code..."
keywords: ""
excerpt_separator: <!-- more -->
---

Recently the organisation that I'm with has migrated to GitHub. This means that I don't need to wrestle with how BitBucket is an utter shambles when it comes to interacting with my preferred terminal based workflow (I could forgive it a lot more when it still supported Mercurial). I can retire [bitbucket-pr](https://github.com/quotidian-ennui/bitbucket-pr) as some kind of low-rent GitHub CLI replacement (I was teetering on the rabbit-hole edge where I was gonna go full rust/golang on the whole scripto nonsense).

Anyway, the move to GitHub hasn't been without its wrinkles; not least of which is that we have a license for snyk and dependabot is habitually 'hassling us' with its alerts (is there a day where a nodejs alert isn't raised?). Some of those vulnerabilities we had traditionally been suppressing with a `.snyk` file.

Oh, GitHub has a CLI tool, which we can make do whatever we want!

<!-- more -->

We already do suppressions via a `.snyk` file (of course, other 3rd party vulnerability scanning tools are available); I am not a big fan of having to clickity click through someone else's vision of what makes a good developer UI. If we think about the format of the file, it's just YAML and we can spin it into something similar that we can then use to dismiss dependabot security alerts via their [REST API](https://docs.github.com/en/rest/dependabot/alerts?apiVersion=2022-11-28). I would use GraphQL if I wanted to manage vulnerability alerts over many different repositories that I'm a member of, but this is targetted just at a single repo.

I ended up with this as a format for a configuration file which is eminently constructable from a `.snyk` file using a yq / jq or jslt / yq chain (or in fact, just yq since it's probably overpowered).

```yaml
"CVE-OR-GHSA-ID":
  packages:
    - some list of packages
    - that are affected
    - "com.fasterxml.jackson.core:jackson-core"
  reason: not_used
  comment: >-
    The affected package is only used in the maven test scope and thus we don't really care
```

It's pretty easy to figure out the chain of what we have to do.

- Get a list of all the open vulnerabilities in the repository
- Iterate over the configuration file
  - For each open vulnerability
    - Check if the package & GHSA or CVE ID matches the config item
    - Dismiss with the reason + comment if it matches.

Which means the script looks something like this (making full use of existing tools like `yq|jq|gh`):

> - We don't even bother figuring out the owner & repo and just pass in `:owner` and `:repo`; the GitHub CLI does a lot of heavy lifting for us.

```bash
GH_REST_API_VERSION="X-GitHub-Api-Version: 2022-11-28"
GH_ACCEPT="Accept: application/vnd.github+json"
REASON_LIST="fix_started|inaccurate|no_bandwidth|not_used|tolerable_risk"
VULNS_JSON_REST_JQ='
  .[] |
  {
    "CVE": .security_advisory.cve_id,
    "GHSA": .security_advisory.ghsa_id,
    "alert_id": .number,
    "package" : .dependency.package.name,
    "severity": .security_advisory.severity
  }
'
VULNS_DISMISS_JQ='"\(.number): \(.state)"'

gh_api() {
  gh api -H "$GH_REST_API_VERSION" -H "$GH_ACCEPT" "$@"
}

open_vulns_via_rest() {
  gh_api "repos/:owner/:repo/dependabot/alerts?state=open" | jq -c "$VULNS_JSON_REST_JQ"
}

reason_is_valid() {
  local reason="$1"
  if [[ ! "${reason}" =~ ^($REASON_LIST)$ ]]; then
    return 1
  fi
  return 0
}

dismiss_alert() {
  local dismiss_entry="$1"
  local open_vulns="$2"
  local packages=()
  local vuln_id=""
  local comment=""
  local reason=""
  local gh_params=()
  local cve_id=""
  local ghsa_id=""
  local affected_package=""
  local alert_id=""

  vuln_id=$(echo "$dismiss_entry" | jq -r ".key")
  mapfile -t packages < <(echo "$dismiss_entry" | jq -r '.value.packages | .[]')
  comment="$(echo "$dismiss_entry" | jq -r ".value.comment")"
  reason="$(echo "$dismiss_entry" | jq -r ".value.reason")"
  if ! reason_is_valid "$reason"; then
    echo "$vuln_id does not contain a valid reason [$reason]"
    exit 1
  fi
  echo "ℹ️ Dismissing $vuln_id"
  while read -r vuln; do
    cve_id="$(echo "$vuln" | jq -r ".CVE")"
    ghsa_id="$(echo "$vuln" | jq -r ".GHSA")"
    affected_package="$(echo "$vuln" | jq -r ".package")"
    alert_id="$(echo "$vuln" | jq -r ".alert_id")"
    # If the key matches either the CVE number or the GHSA ID then we check
    # the packages to see if we should ignore.
    if [[ "$vuln_id" == "$cve_id" || "$vuln_id" == "$ghsa_id" ]]; then
      # it's an intentional substring search.
      #shellcheck disable=SC2076
      if [[ " ${packages[*]} " =~ " ${affected_package} " ]]; then
        echo "🔍 Dismissing alert#$alert_id as $reason"
        gh_params=()
        gh_params+=("-f" "state=dismissed")
        gh_params+=("-f" "dismissed_reason=$reason")
        gh_params+=("-f" "dismissed_comment=$comment")
        gh_api --method PATCH "/repos/:owner/:repo/dependabot/alerts/$alert_id" "${gh_params[@]}" | jq -r "$VULNS_DISMISS_JQ"
      fi
    fi
  done <<<"$open_vulns"
}

dismiss_each_alert() {
  local alert_file="$1"
  local open_vulns="$2"

  cat "$alert_file" | yq -p yaml -o json | jq -c "to_entries | .[]" | while read -r entry; do
    dismiss_alert "$entry" "$open_vulns"
  done
}

GIT_ROOT="$(git rev-parse --show-toplevel)"
IGNORE_FILE="$GIT_ROOT/.github/dismiss-alerts.yml"

if [[ -f "$IGNORE_FILE" ]]; then
  OPEN_VULNS="$(open_vulns_via_rest)"
  if [[ -n "$OPEN_VULNS" ]]; then
    dismiss_each_alert "$IGNORE_FILE" "$OPEN_VULNS"
  else
    echo "👌 No Open Alerts"
  fi
fi
```

Since I can script it; I can make it into a [GitHub Action](https://github.com/quotidian-ennui/actions-olio/tree/main/dismiss-dependabot-alerts). So I did. Doing it as an action means you need a GitHub App that has the correct permissions, since we can never get the right permissions via a standard workflow token.

Now, all I have to do is to have a meta-yaml file that I can _compile_ into the `.snyk` & `.github/dismiss-alerts.yml` files as part of the build.

## Bonus Chatter

Of course, the `.snyk` file has an expiry date in it. It's perfectly reasonsable to do much the same thing since a _dismissed_ alert can be re-opened. Simply have a new key in the dismiss-alerts file that marks the expiry date and then we can re-open any dismissed tickets if today is after the expiry.