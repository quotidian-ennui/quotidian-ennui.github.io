---
layout: post
title: "Keeping track of my 'public' IP history"
comments: false
tags: [random]
# categories: [development,rant]
published: true
description: "Never bothered upgrading to a fixed IP Address, how sad."
keywords: ""
excerpt_separator: <!-- more -->
---

I've been with BT Broadband since pretty much its inception; it hasn't been awful, and I've never been a fan of the race to the bottom. I remember the old Alcatel frog modem and all the joys that entailed; one of the things that I've never bothered with is having a fixed IP Address; didn't really see the point what with VPNs and all that. However, recently, for work purposes they wanted to have a whitelist of IP Addresses that could access non-functional testing services.

<!-- more -->

The problem is actually two-fold (other than me not having a fixed IP Address):

1. The company doesn't use IAC for managing these kinds of things; previously I would have raised a PR on the terraform module that manages the whitelist.
2. The page where you can configure the whitelist doesn't allow you to have comments associated with the entry; so it's just a bunch of raw `1.1.1.1/32` entries.

All of this means that if my IP address changes, I need to figure out which entry I need to delete after adding my new IP address; this a straightforward problem and it's now just a script that runs on a login shell on my corporate laptop (as I enter WSL2).

```bash
#!/usr/bin/env bash
# Just detects if our external IP address has changed and
# Stores it in a database with history

#shellcheck disable=SC2317
set -euo pipefail
LOCAL_STATE_DIR="$HOME/.local/state/ip-changes"
IP_HISTORY_DB="$LOCAL_STATE_DIR/ip_history.db"
COLUMN_DEF="LAST_SEEN,ADDRESS"
ACTION_LIST="help|check|last|current|dump|prune"

check_database() {
  if [[ ! -f "$IP_HISTORY_DB" ]]; then
    >&2 echo -e "\n>>> Database file not found. Creating a new one."
    mkdir -p "$LOCAL_STATE_DIR"
    sqlite3 "$IP_HISTORY_DB" <<EOF
create table ip_history(
  last_seen datetime,
  address text
);
EOF
  fi
}

prune_database() {
  local last_month
  last_month="$(date --date 'now - 1 month' "+%Y-%m-%d")"
  sqlite3 "$IP_HISTORY_DB" <<EOF
delete from ip_history where last_seen < "$last_month";
EOF
}

dump_addresses() {
  sqlite3 "$IP_HISTORY_DB" <<EOF
select last_seen,address from ip_history order by last_seen DESC;
EOF
}

last_address() {
  sqlite3 "$IP_HISTORY_DB" <<EOF
select address from ip_history order by last_seen DESC limit 1;
EOF
}

last_row() {
  sqlite3 "$IP_HISTORY_DB" <<EOF
select last_seen,address from ip_history order by last_seen DESC limit 1;
EOF
}

insert_address() {
  local ip="$1"
  sqlite3 "$IP_HISTORY_DB" <<EOF
insert into ip_history values(datetime(), "$ip");
EOF
}

external_address() {
  curl -fsL --connect-timeout 10 https://ifconfig.me
}

action_help() {
  cat <<EOF

Tool that helps tracks your external IP Address in a sqlite database.

Why?
Because BT Broadband doesn't give me a fixed IP Address and there
are resources I need access to that are IP filtered.

Usage: $(basename "$0") [check|last|current|dump|prune|help]
  help         : show this help
  check        : check the current external IP address and record it if
                 it differs from the 'last' and do prune housekeeping

                 **check is the default action if no params**
  last         : show the last recorded ip address
  current      : show the current IP address per https://ifconfig.me
  dump         : dump the contents of the database
  prune        : prune the database of entries > 1 month old

EOF
  exit 2
}

action_last() {
  last_row | column -s "|" -t -N "$COLUMN_DEF"
}

action_current() {
  external_address
}

action_dump() {
  dump_addresses | column -s "|" -t -N "$COLUMN_DEF"
}

action_prune() {
  prune_database
}

action_check() {
  local detectedIP
  local current_addr
  detectedIP=$(external_address)
  current_addr=$(last_address)
  if [[ "$current_addr" != "$detectedIP" ]]; then
    echo -e "\n>>> IP Address Change detected from [$current_addr] to [$detectedIP]"
    insert_address "$detectedIP"
    prune_database
  fi
}

main() {
  local action=${1:-check}
  if [[ ! "${action}" =~ ^$ACTION_LIST$ ]]; then
    echo "Invalid action: $action"
    action_help
  fi
  check_database
  action_"$action"
}

{
  main "$@"
  exit $?
}
```

In reality the only bash function that's interesting is `action_check` (and its execution chain); I know that the IP address history will be marginally broken if I'm in the office (but I'm generally a remote worker), and if they start tunnelling all traffic via the VPN (if they started doing that, then I wouldn't have to whitelist my IP address).
