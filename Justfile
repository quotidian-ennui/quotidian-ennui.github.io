set positional-arguments
set unstable
set script-interpreter := ['/usr/bin/env', 'bash', "-eo", "pipefail"]

OS_NAME := `uname -o | tr '[:upper:]' '[:lower:]'`

# show recipes
[private]
@help:
    just --list --list-prefix "  "

[doc("Install deps")]
@install:
    bundle install

[doc("jekyll serve --drafts")]
@serve: check_env
    bundle exec jekyll serve --drafts

[doc("cleanup")]
@clean:
    rm -rf .jekyll-cache .sass-cache _site

[doc("make a new draft")]
[script]
draft title:
    #
    today="$(date "+%Y-%m-%d")"
    cp _drafts/template.markdown "_drafts/$today-{{ title }}.markdown"
    echo "$today-{{ title }}.markdown created"

[no-cd]
[no-exit-message]
[private]
[script]
check_env:
    #
    if [[ "{{ OS_NAME }}" == "msys" ]]; then echo "Try again on WSL2+Ubuntu"; exit 1; fi
    which bundle >/dev/null 2>&1 || { echo "jekyll not found; abort"; exit 1; }
    which jekyll >/dev/null 2>&1 || { echo "jekyll not found; abort"; exit 1; }
