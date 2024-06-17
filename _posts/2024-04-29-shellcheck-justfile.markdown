---
layout: post
title: "Running shellcheck on justfiles"
comments: false
tags: [development]
# categories: [terraform,github]
published: true
description: "More linting, more tooling, more betterer"
keywords: ""
excerpt_separator: <!-- more -->
---

I've found that I like [just](https://just.systems) as a task runner, more so than anything else that I've used. It has some knowledge about task dependencies, and it supports all the major shells (because sometimes you do have to write it in Powershell rather than as a bash script). I use [shellcheck](https://github.com/koalaman/shellcheck) a lot to nip potential issues in the bud so I wanted to be able to shellcheck the tasks that were effectively scripts inside a monolithic Justfile (there does come a point when I will split it up; but ~500 lines is nowhere that yet).

<!-- more -->

The one thing that is true where I have extended scripts inside a justfile is that I always use a shebang to ensure that the script is run in the correct shell. So, realistically all I have to do is

- Extract the script from the justfile
- Run shellcheck on the script.

That boils down to this:

```bash
#!/usr/bin/env bash
set -eo pipefail

JUSTFILE_JSON=$(just --dump-format json --dump --unstable)
recipes=$(echo "$JUSTFILE_JSON" | jq -c --raw-output '.recipes | .[] | .name' | sort)
for recipe in $recipes; do
  output=$(mktemp --tmpdir "justfile-$recipe.XXXXXX")
  just -s "$recipe" | sed -n '/#\!/,$p' > "$output"
  if [[ -s "$output" ]]; then
    shfmt -i 2 -w "$output"
    shellcheck "$output"
  fi
done
cd /tmp && rm -f justfile-*
```

- dump the just file as JSON (otherwise you don't get private recipes).
  - `--unstable` is not required since the json dump format was stablised in 1.15.0, but prebuilt mpr for a long time was still on 1.14.x
- for each recipe in the justfile, write it out to a temporary file, and strip out everything that precedes the shebang
  - `just --show "$recipe"` gives you the recipe name as well as the other `[]` directives.
- format the script with `shfmt`
- run shellcheck on the output

It will fail on the first shellcheck failure, and the name of the file emitted by shellcheck gives you the recipe name that didn't pass linting. I find that I need to disable _SC2194_ and _SC2050_ quite a lot because I often use just variables (so {% raw %}`case "{{ var }}" in...` {% endraw %}) which shellcheck will treat as constants, and complain at you.

I've now wrapped that snippet into a [user-justfile](https://just.systems/man/en/chapter_73.html)[^1] along with some other tasks that I find generically useful in almost all my development projects (like wrapping git-semver to figure out what the next version should be).

[^1]: [tomodachi94](https://github.com/tomodachi94) helpfully raised a PR on this blog since the just manual URLs aren't stable, they change when new sections are added; this means if you go somewhere quite random, scroll through the manual until you find _Global and User Justfiles_.
