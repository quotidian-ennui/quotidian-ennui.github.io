---
layout: post
title: "UpdateCLI + HCL"
comments: false
tags: [development,terraform]
# categories: [development,terraform]
published: true
description: "Using the UpdateCLI shell plugin to modify HCL config files"
keywords: ""
excerpt_separator: <!-- more -->
---

I rely a lot on dependabot to keep my projects up to date; however, there are some things that dependabot doesn't yet know about. In any project there is a bunch of additional tooling that makes our lives easier, those tools all deserve to be updated to latest and greatest too! We've been using [updatecli](https://updatecli.io) for that and it's been very useful in managing updates to things that don't get revisited that often (like pre-commit hook versions via the yaml plugin)

<!-- more -->

One of the things you will have in any terraform project is a `.tflint.hcl` file that contains your configuration for tflint. The rulesets defined by tflint are useful in giving you a degree of confidence about your terraform resources; I don't find `terraform validate` that useful, the various plugins you can get for your favourite editor can replace it. The configuration is essentially HCL which is no surprise.

Out of the box updatecli doesn't support HCL (true as of 0.54; though it probably should) and I was wondering how I would update tflint's configuration with newer rulesets. My colleague was using the file plugin with regular expressions to handle updates and that has been working well enough, provided the `version` directive was underneath the `source` directive (because `("github.com\/terraform-linters\/tflint-ruleset-aws"\s+version\s+=\s+)"(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)"` just doesn't fill me with joy). It works and once things are provably working you have more important fish to fry most of the time.

I got a little too fixated on doing some kind of HCL->JSON(or yaml)->HCL round trip so i could use a transformation tool like jq or jslt. This proved to be a bit of a blind alley (I can get tunnel vision about how it's always a data-format-problem). Taking a step back, after a slack huddle (and colleagues using different search terms), two tools were mentioned: [hclq](https://hclq.sh) & [hcledit](https://github.com/minamijoyo/hcledit). Both will absolutely work for what I wanted, and my initial PR used hclq, but subsequently changed to hcledit since hclq is a project that is dead (the author is no longer actively maintaining it).

What we're going to is to update `.tflint.hcl` using updatecli with the shell plugin and `hcledit`. hcledit was installed via my [personal scoop bucket](https://github.com/quotidian-ennui/personal-scoop-bucket) (other package managers are available). Yes I am making it much more difficult for myself by being on Windows, my corporate overlords haven't seen fit to give me a Linux laptop.

## tflint.hcl

Our tflint configuration uses a relatively old version of the aws ruleset (almost 3 months old!) which clearly needs to be upgraded to the latest version.

```
plugin "terraform" {
  enabled = true
  preset  = "all"
}

rule "terraform_standard_module_structure" {
  enabled = false
}

plugin "aws" {
  enabled = true
  version = "0.23.1"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
```

## Updatecli configuration

Our updatecli configuration is simple for the source, we just need to look at the github release for tflint-ruleset-aws

<!-- using {{ '{{' }} because of LIQUID TEMPLATING -->
```yaml
sources:
  aws-ruleset:
    kind: githubrelease
    spec:
      owner: terraform-linters
      repository: tflint-ruleset-aws
      token: '{{ '{{' }} requiredEnv "GITHUB_TOKEN" }}'
      versionfilter:
        kind: semver
    transformers:
      - trimPrefix: "v"
```

Our target needs to use the shell plugin with a couple of caveats that we'll go into

```yaml
  update-terraform-tflint.hcl:
    kind: shell
    sourceid: aws-ruleset
    spec:
      shell: bash
      command: ./scripts/tflint-update.sh terraform
      environments:
        - name: HCLEDIT_DIR
          value: '{{ '{{' }} requiredEnv "HCLEDIT_DIR" }}'
```

- updatecli _knows_ that we're on windows, so the default shell is powershell. We need to change the shell because `bash` is the lowest common factor on all machines[^1].
- Because of how updatecli executes the command; bash _loses_ its environment (and by that token its path), which means on windows/git+bash it is the default `/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:.`
    - Since we've lost the path, the script can't know where `hcledit` is; we force an environment variable to be defined so that we can derive it.
    - I could have installed hcledit into `/usr/local/bin` but I'm on Windows and I don't tend to install things directly into the git+bash environment

## The shell script

This process flow is actually very simple; updatecli will append the detected version as the last parameter to the command so your effective command is `bash ./scripts/tflint-update.sh terraform 0.24.3`

- Figure out the current version in `.tflint.hcl`
- If the `currentVersion != $2` & we aren't in DRY_RUN mode, then update .tflint.hcl

This is close to the simplest script possible; everything that's hard-coded could be derived from environment variables or from parameters to the script.

```bash
#shellcheck disable=SC2148
# The usual usr/bin/env bash doesn't work because when running with updatecli windows
# because you lose your environment so usr/bin/env won't find bash
set -eo pipefail

basedir=$(dirname "$0")/..
TFLINT="${basedir}/${1}/.tflint.hcl"
HCLEDIT="$HCLEDIT_DIR/hcledit"
currentVersion=$("$HCLEDIT" attribute get plugin.aws.version -f "${TFLINT}" | sed -e "s/\"//g")
detectedVersion=$(echo "$2" | sed -e "s/^[[:blank:]]*//" -e "s/[[:blank:]]*$//")

# if the current version != detectedVersion then do the thing.
if [[ "$currentVersion" != "$detectedVersion" ]]; then
  echo "Update to $detectedVersion"
  if [[ "$DRY_RUN" != "true" ]]; then
    echo "Updating ${TFLINT}"
    updateString="\"$detectedVersion\""
    "$HCLEDIT" attribute set 'plugin.aws.version' "$updateString" -f "${TFLINT}" -u
  fi
```

Since `hclq` only works on stdin and stdout you need to do a bit more redirecting but it's fundamentally the same: `hclq get plugin.aws.version` will do the right thing, as will `hqlq set "plugin.aws.version" "$detectedVersion"` (updateString wraps the variable in quotes which is required by hcledit but not by hclq).

## updatecli execution

If you run `updatecli diff` then you're in dry run mode which means that `$DRY_RUN == "true"` so you won't do any updating; but an `updatecli apply` gives you.

```
update-terraform-tflint.hcl
---------------------------
The shell 🐚 command "bash C:\\TEMP\\updatecli\\bin\\7af49c68dec0a773adb1891eda37c961c96a7ec8f12331e4bbd01f31035ae1ad.ps1" ran successfully with the following output:
----
Update to 0.24.3
Updating ./scripts/../terraform/.tflint.hcl
----
⚠ - ran shell command "./scripts/tflint-update.sh terraform 0.24.3"

⚠ tflint-aws-rulset:
        Source:
                ✔ [aws-ruleset]
        Target:
                ⚠ [update-terraform-tflint.hcl]
```


[^1]: or lowest common denominator if you don't like technical correctness