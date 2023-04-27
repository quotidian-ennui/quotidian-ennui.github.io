---
layout: post
title: "Makefile last resort"
comments: false
tags: [development]
# categories: [development]
published: true
description: "gmake/make is still here, still being mysterious, still giving you fun times"
keywords: ""
excerpt_separator: <!-- more -->
---

GNU Make has been around for an awfully long time, and I've recently starting reverting back to it because I've been doing a lot of terraform. It's still incredibly useful even though I'm not actually _building anything locally_. I hadn't really thought about make for a long time (since not writing any C in anger), and I've forgotten everything that I ever knew about make. It's a bit like riding a bike though, you're not better than the next person, but what you are is just quicker at constructing the right search term and understanding the results because you have the memory trigger from a different era.

<!-- more -->

I was recently asked by a colleague some questions about a Makefile that someone else had refactored; I realised that the refactor might potentially have some side effects since they were using last resort rules. The Makefile _worked_ but any changes down the line might compound the issue. As is always the way, they were trying to be clever, not being clever enough, and should have just stuck with the keeping it simple; DRY wouldn't have been an issue, because they wouldn't have repeated themselves anyway (oh and documenting the reasons for their changes might have been useful as well).

This actually got me to thinking about last resort rules and when I'd actually use it. I found one because I'm using terraform to manage my home infrastruture, and terraform projects end up being amusingly similar. My project structure goes like this; incidentally all the subdirectories are actually git submodules because why not.

```
terraform
   |- (Makefile -> this is now new)
   |- github
       |- Makefile
       |- *.tf
   |- k8s
       |- Makefile
       |- *.tf
   |- aws
       |- Makefile
       |- *.tf
```

Previously I didn't have a Makefile at the top level because I would just change to the appropriate sub-module and work out of that; I still want the individual sub-modules to be independent but I can easily have a top-level Makefile that can be used to call either all or some of the indivdual submodules. This is what I have in all its glory:

```makefile
MAKEFLAGS+= --silent --always-make
.DEFAULT_GOAL:= help
SHELL:=bash

UPDATE_CLI:=updatecli
REQUIRED_BINARIES:=updatecli
CLEAN_TARGETS:=$(addsuffix clean,$(sort $(dir $(wildcard */Makefile))))
.PHONY: clean help check_binaries updatecli updatecli-apply

help:
  grep -E '^[\%a-zA-Z_\%-]+.*:.*?## .*$$' $(word 1,$(MAKEFILE_LIST)) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

check_binaries:
  $(foreach bin,$(REQUIRED_BINARIES),$(if $(shell command -v $(bin) 2> /dev/null),,$(error Please install `$(bin)`)))

clean: $(CLEAN_TARGETS) ## Cleanup

updatecli:  ## Check dependencies via updatecli
  $(UPDATE_CLI) diff

updatecli-apply:  ## Updates dependencies via updatecli
  $(UPDATE_CLI) apply

%: ## subdir/target -> run 'make target' in subdir
  if [[ "." != "$(*D)" ]]; then \
    $(MAKE) --directory $(CURDIR)/$(*D) $(*F); \
  else \
    echo "$* isn't a valid target"; \
    exit 1; \
  fi
```

- 'help' is not important here, it's just something that I carry around with me in case I don't have autocomplete actions for make enabled.

What's important here are 3 things

- `CLEAN_TARGETS` essentially builds a string _"github/clean k8s/clean aws/clean"_ which are used as pre-requisites for _clean_ because those directories have a Makefile in them.
- The `.PHONY` target because otherwise make will do something you don't want with the _clean_ target (If you remove the `.PHONY`, _make clean_ will actually attempt 4 invocations, one in each subdirectory, and once again in __'.'__; the last invocation here is bad for all the reasons you imagine it's bad).
- We can use the automatic variable parts of the stem to build our actual make command. _make github/plan_ will essentially run the _plan_ target in the github directory.
  - We add in some protection here to check that that directory part isn't __'.'__ because that will just end up being quite bad. This protects against the _make unknown-target_ scenario but already makes the Makefile harder to maintain because there's now a dependency on bash etc.

So, now I have a simple Makefile[^1] that uses a last resort rule, it's useful, but if I were to add a new target in this Makefile you can start to see where all the things could start going wrong. I could easily break things and I have done trying to do different things. _There's an overhead in mental load when you're using last resort matches_. In some cases it might make some sense but a lot of the time you're just storing up trouble for yourself in the future when you've forgotten to document why you had the last resort rule in the first place.

[^1]: Depends if your definition of simple depends on line count.
