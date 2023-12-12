set positional-arguments := true
OS_NAME:=`uname -o | tr '[:upper:]' '[:lower:]'`

# show recipes
[private]
@help:
  just --list --list-prefix "  "

# jekyll serve --drafts
@serve: check_env
  bundle exec jekyll serve --drafts

# Cleanup
@clean:
  rm -rf .jekyll-cache .sass-cache _site

[private]
[no-cd]
[no-exit-message]
check_env:
  #!/usr/bin/env bash
  set -eo pipefail

  if [[ "{{ OS_NAME }}" == "msys" ]]; then echo "Try again on WSL2+Ubuntu"; exit 1; fi
  which bundle >/dev/null 2>&1 || { echo "jekyll not found; abort"; exit 1; }
  which jekyll >/dev/null 2>&1 || { echo "jekyll not found; abort"; exit 1; }