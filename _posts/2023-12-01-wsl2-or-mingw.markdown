---
layout: post
title: "WSL2 or MINGW+git/bash"
comments: false
tags: [development]
# categories: [development,rant]
published: true
description: "Simple Tool management because sometimes real package managers are overkill"
keywords: ""
excerpt_separator: <!-- more -->
---

Spotify gives you __Wrapped__; I make myself do some introspection and examine my life rather than wondering why my top artist (categorisation error?) was Joseph Haydn during the year. In reviewing my development toolchain; I've realised that I've been using a variation of the same thing (git+bash on Windows with [Scoop][]) for far too long. It's time to shake things up a bit not least because I've started doing a lot more with things like Node & Python rather than Java. My experience under Windows is that it's manageable, but i'm fighting against the tooling rather than getting shit done. WSL2 is obviously the answer to the question that I'm asking, but it means a full migration of all development into the WSL2 filesystem for performance reasons. Generating this blog under WSL2, on the Windows filesystem takes _over a a minute_ but only takes _3 seconds_ if the files are in the native WSL2 VHD.

<!-- more -->

I'm more than happy to use things like `nvm` and `sdkman` to have multiple versions of various compilers and what not; but this actually got me to thinking about package management on Ubuntu. There's [homebrew on linux](https://docs.brew.sh/Homebrew-on-Linux) of course, but what I've found is that (_and I make this statement without really doing proper investigations; don't hate me_) if the package maintainer hasn't got a linux native brew package, then homebrew will happily go and download a bunch of shit and try and compile the tool from scratch; and if that includes downloading a version of GnuPG that then breaks part of your ubuntu desktop then so be it. On my Linux laptop I ended doing a bunch of post-cleanup work that just felt like I was fighting the tooling in exactly the same way that I fight with it on Windows. You can add apt repositories (for helm/kubectl and the like), but sometimes you can't find the tool that you want in the various apt repos, and do you really want to add an additional repository for every tool you might install?

[Scoop][] is my preferred package manager for Windows, mainly because it doesn't require admin rights to install packages and I can build my own bucket to host tools that I can't find elsewhere. So this is about the utility tools, the simple helpers that I use on a day-to-day basis like tflint, terraform-docs etc. I could just use the Scoop variant of those tools since WSL2 will happily run those; but I like to mix and match my platforms there's a full Linux desktop environment as well. I want to use the same tooling on both platforms so that I can concentrate on the problem, not on the tooling. A lot of the tools are just single (golang/rust) binaries that are hosted on github, so I can easily compose my own thing using other tools that are available. I realise that I'll lose a lot of features, but it works precisely how I want it to; and it only took me about an hour to put together.

## Feature set

- Single configuration file
- Userspace only ($HOME/.local/bin)
- Pinned version capability (so I can have the equivalent of `scoop install 7zip@19.0.0`)
- Uses [updatecli][] to manage "tool updates"
- Bash based; thus embeddedable inside a Justfile or similar (which does lead to a bit of a chicken and egg situation if you let it; I just added the prebuilt-mpr apt repo and installed just via that)

## The script

It really is this simple, about 8 lines of bash; finding the tool was the hard part and not having to write it was a blessing.

```
  #!/usr/bin/env bash
  # Pre-Reqs:
  #  sudo apt install jq python3-pip
  #  pip install gh-release-install (https://github.com/jooola/gh-release-install)
  #  pip install yq
  #
  set -euo pipefail

  cat "./config/tools.yml" | yq -c ".[]" | while read line; do
    repo=$(echo "$line" | jq -r ".repo")
    version=$(echo "$line" | jq -r ".version")
    artifact=$(echo "$line" | jq -r ".artifact")
    extract=$(echo "$line" | jq -r ".extract")
    binary=$(echo "$line" | jq -r ".binary")
    gh-release-install "$repo" "$artifact" "$HOME/.local/bin/$binary" --verbose --version "$version" --extract "$extract"
  done
```

## Configuration

- yaml because that's easy to manage via updatecli
- relies on the fact you've gone to the 'releases' page on github for the tool you want to download and inspected the artifact you want (I have had to do this for my own personal scoop bucket, so it's not a new experience).
- you can use 'latest' as the version, but that requires you have a github token to use the GitHub api to find the latest version.

```
kubectx:
  repo: ahmetb/kubectx
  version: v0.9.5
  artifact: kubectx_{tag}_linux_x86_64.tar.gz
  extract: kubectx
  binary: kubectx

shellcheck:
  repo: koalaman/shellcheck
  version: v0.9.0
  artifact: shellcheck-{tag}.linux.x86_64.tar.xz
  extract: shellcheck-{tag}/shellcheck
  binary: shellcheck

k9s:
  repo: derailed/k9s
  version: v0.28.2
  artifact: k9s_Linux_amd64.tar.gz
  extract: k9s
  binary: k9s
```

## UpdateCLI to update the version

I have a 'values file' that I pass in to [updatecli][] so that I can pin the explicit version the tool that I want to use. If it doesn't exist in the values file then it will just use the latest version.

```
name: k9s

sources:
  k9s:
    name: Github release for k9s
    kind: githubrelease
    spec:
      owner: derailed
      repository: k9s
      token: '${{ '{{' }} requiredEnv "GITHUB_TOKEN" }}'
      versionfilter:
        kind: semver
        pattern: '${{ '{{' }} default "*" .versions.k9s }}'

targets:
  k9s:
    kind: yaml
    sourceid: k9s
    name: Update k9s tool version
    spec:
      files:
        - ./config/tools.yml
      key: $.k9s.version
```

```
bsh ❯ updatecli --values ./config/versions.yml diff
#######
# K9S #
#######


SOURCES
=======

k9s
---
Searching for version matching pattern "*"
✔ GitHub release version "v0.28.2" found matching pattern "*" of kind "semver"
...
TARGETS
========

k9s
---

**Dry Run enabled**

✔ - key "$.k9s.version" already set to "v0.28.2", from file "./config/tools.yml"
```

## Summary


Naturally this is an exercise in scratching an itch. Initially I tried the github-cli extension [redraw/gh-install](https://github.com/redraw/gh-install) but that was far too interactive for my liking (though it gave me sufficient pointers to do a better search). There are a lot of tools that could be used in this space like [nix](https://nixos.org/) or [pkgx](https://github.com/pkgxdev/pkgx/) but I often approach those things with a bit of trepidation because they want me to _choose my platform_.

What I've done is largely pointless and isn't going to change the world. Since the tools are all self-contained, I don't think about dependency management or version management. Everytime I run the script, it re-installs all the tools again. It does work how I want it to work though.

I still use [Scoop][] on windows so my mingw+git bash toolchain is still stable. My WSL2 toolchain is simple enough to not get in the way.

[updatecli]: https://updatecli.io
[Scoop]: https://scoop.sh/
