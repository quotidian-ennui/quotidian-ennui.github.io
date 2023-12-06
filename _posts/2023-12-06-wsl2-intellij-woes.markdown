---
layout: post
title: "IntelliJ isn't playing nicely with WSL2"
comments: false
tags: [development,java]
# categories: [development,rant]
published: true
description: "There's always a fight against the tooling; I avoided it mostly."
keywords: ""
excerpt_separator: <!-- more -->
---

In the midst of my move of all "code related" things into WSL2, I started using Visual Studio Code with the Java extension pack and this works well enough. However, I'm a long time IntelliJ user for Java (I was using their Rust preview but stopped because it's not _that much better than the equivalent vscode extensions_). If you search for 'IntelliJ WSL2' through your preferred search engine, you'll find the official documentation that says its supported and you can just point it at a project in `\\wsl$\Ubuntu\home\user\project` and it'll be quite happy. I gave it a go, and that's not my experience.

<!-- more -->

## Before we continue

I'll admit a few things here, I don't think any of this is in any way 'special' but it's worth noting:

1. I install IntelliJ via the Scoop extras bucket. Currently it's _IntelliJ IDEA 2023.2.5 (Community Edition)_; so we can consider it a Windows install.
2. My Windows Java instances are managed by sdkman running on wingit bash (I don't run java via powershell/cmd)
3. My primary desktop has multiple disks
    - I'm using reparse points as symbolic links (so C:/Users/lewin/.gradle is a symbolic link to D:/storage/.gradle as my NVME drive is smaller than my SSD)
4. My automount location is / (i.e. /mnt/c is not a thing)[^1]
5. WSL/Ubuntu is mounted as a network drive `W:/`.

## Problem Statement

1. Open a project mounted in WSL
2. Fix the Gradle JVM problem (i.e. point it at one installed in WSL `/home/user/.sdkman/...``; it auto detects a few).
3. Change the JDK in 'project structure' to point at the WSL JDK we just selected.

There's an error in the build log
```
Running Gradle on WSL...
Error: Could not find or load main class org.jetbrains.plugins.gradle.tooling.proxy.Main
Caused by: java.lang.ClassNotFoundException: org.jetbrains.plugins.gradle.tooling.proxy.Main
Error: Could not find or load main class org.jetbrains.plugins.gradle.tooling.proxy.Main
Caused by: java.lang.ClassNotFoundException: org.jetbrains.plugins.gradle.tooling.proxy.Main
```

Well, as my daughter would say to me while I'm filling the air with noise about something she's clearly not interested in: _"Cool" while looking pointedly at her phone and ignoring me_.

A cursory search on the internet tells me nothing that I didn't know already; it's now 2 years after the IDEA 2021.1 EAP release. I know that it's nothing to do with my gradle installation since `./gradlew compileJava` works quite happily on WSL2, and the name of the class suggests that IntelliJ wants to do something special with Gradle. _Cool_.

So why isn't `$SCOOP/apps/idea/current/IDE/plugins/gradle/lib/gradle.jar` in the classpath in this situation when it is when it opens a project on `D:\whereever`. This is a jar that lives in the IDEA installation directory and solely under the purview of IntelliJ.

```
bsh ❯ jar -tvf ./plugins/gradle/lib/gradle.jar | grep proxy
...
 26348 Fri Nov 30 00:00:00 GMT 1979 org/jetbrains/plugins/gradle/tooling/proxy/Main.class
```

I don't know for sure (I have my suspicions[^1]), and I don't care; I can continue using Visual Studio Code since it works well enough and keep having everything inside WSL2; Or... we just treat IntelliJ as _special_; ignore its WSL support and make sure we synchronize things between NTFS & ext4.

Clearly we're in yet another fight with the tooling. I like things how I like them, and you're making assumptions that you shouldn't be making. Making the assumptions is one thing, but not documenting them is always a real pain in the ass.

## Enter Mutagen

I've been using [mutagen][] for a little while to sync things between my desktop & linux machines elsewhere (it's what its designed for) so we can use it here to sync things between WSL2 & Windows.

- Choose a location where you want to sync the code you're going to open in IntelliJ to; I'm using `D:\storage\idea-workdir`
- Create a `.mutagen.yml` in the root of your project if you have special requirements like ignores and the like.
    - I usually have one for gradle projects where I exclude `build` and `.gradle` to avoid too much traffic.
    - I have one for Rust projects that excludes `target` for the same reason if I want to build on Windows.

This then is a simple script that manages the startup of the synchronisation sessions of the project directory between WSL2 & Windows. I run it on WSL2 only because I'm making a clean break of things and wingit+bash is hidden in Windows Terminal.

```bash
#!/usr/bin/env bash

set -eo pipefail

TARGET_BASE=/d/storage/idea-workdir

cfg_args() {
  if [[ -f "$(pwd)/.mutagen.yml" ]]; then
    echo "-c $(pwd)/.mutagen.yml"
  else
    echo ""
  fi
}

sync_fresh() {
  local name
  local target_dir
  sync_stop
  name=$(basename "$(pwd)")
  target_dir="$TARGET_BASE/$name"
  rm -rf "$target_dir"
  sync_start
}

sync_start() {
  local target_dir
  local current_dir
  local name
  current_dir="$(pwd)"
  name=$(basename "$current_dir")
  target_dir="$TARGET_BASE/$name"
  if mutagen sync list | grep "$name" > /dev/null; then
    echo "Already a sync called $name"
  else
    mkdir -p "$target_dir"
    # shellcheck disable=SC2046
    mutagen sync create "$current_dir" "$target_dir" --name "$name" $(cfg_args)
  fi
}

sync_stop() {
  local name
  name=$(basename "$(pwd)")
  if mutagen sync list | grep "$name" > /dev/null; then
    mutagen sync terminate "$name"
  fi
}

sync_list() {
  mutagen sync list
}


check_env() {
  if [[ "$(uname -o | tr '[:upper:]' '[:lower:]')" == "msys" ]]; then echo "Try again on WSL2+Ubuntu"; exit 1; fi
  if ! builtin type -P mutagen > /dev/null; then
    echo "mutagen is not installed"
    exit 1
  fi
}

ACTION=${1:-list}
check_env
sync_"$ACTION"
```

- `syncfs fresh` will stop any existing sync, remove the target directory and create a new one.
    - There is the implicit assumption that the project directory basename is 'unique' enough for the target.

## Summary

- If you have changed the mount point for your Windows filesystem, then you need to make a symbolic link between that and `/mnt` for IntelliJ to be happy.
- It's not the fault of IntelliJ that accessing files over `//wsl$` is so slow; javac is somewhat IO bound so it's just not useful.
- I made IntelliJ dance to my spin on WSL2; well done me, I guess.

> [mutagen][] has been acquired by Docker; I have no idea what's in the future for it. They have a paid for subscription which I'm not using; other tools are available.

[mutagen]: https://mutagen.io/
[^1]: If you didn't realise as soon as I mentioned it; it's this. I prefer `/c` over `/mnt/c`. JetBrains have made a dirty assumption and not for the first time. I symlink shimmed it, but it's too bloody slow to be usable anyway.