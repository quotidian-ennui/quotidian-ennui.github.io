---
layout: post
title: "Docker image updates running K8S at home"
comments: false
tags: [tech,kubernetes,terraform]
categories: [tech,kubernetes,terraform]
published: true
description: "Surely there exists an opensource tool that does this niche thing I want."
keywords: ""
excerpt_separator: <!-- more -->
---

I'm running kubernetes at home; it seemed like an amusing thing to do at the time. I have been using helm charts to install the things. As helm charts are updated then the underlying docker images are updated; so as a downstream consumer of the helm charts I just have to worry about whether the helm chart maintainer has lost interest / abandoned the charts. The charts from _k8s-at-home_ have been archived in github which means they are effectively abandoned. Consequently I decided to migrate to terraform to manage my kubernetes infrastructure at least for those charts.

I now have to concern myself with when third-party docker images are updated and published.

<!-- more -->

While I'm using git, it's not pushed to a github/gitlab/gitea whatever; going for something like a dependabot / renovate[^1] would have been an overhead too far. Running my own gitlab instance inside my home kubernetes environment would amuse me but not enough for me to do it. My thinking then went down this path:

- Since each docker registry has an API to search the catalogue we can figure out changes by writing a shell script that checks the various registries where I get my docker images from.
- There is a terraform provider that can give us access to environment variables.
- I'm using `direnv` already to fix my environment on a per-directory basis; it isn't such a stretch to have a single `.env` file that contains the image versions which I can then update in a single location.
- Both terraform and my 'update script' can refer to the same environment.

## Getting Ready

I have a `.env` file that is autoloaded into the environment. This simply contains a fixed key prefix and then some information about the image. We keep track of the registry since quay.io/ghcr.io/docker.io expose either a _docker v1_ or _docker v2_ registry so the way we get tags will differ for each repository.

```dotenv
IMAGE_POWERWALL_NAME="quotidian-ennui/tesla-powerwall-exporter"
IMAGE_POWERWALL_REGISTRY="ghcr.io"
IMAGE_POWERWALL_VERSION="1.4.2"

IMAGE_PIHOLE_NAME="pihole/pihole"
IMAGE_PIHOLE_REGISTRY="docker.io"
IMAGE_PIHOLE_VERSION="2022.12"

IMAGE_DUPLICATI_NAME="linuxserver/duplicati"
IMAGE_DUPLICATI_REGISTRY="docker.io"
# This isn't an immutable image so I ended up with a PullPolicy of 'Always' regardless.
IMAGE_DUPLICATI_VERSION="2.0.6"
```

And my correponding terraform file looks something like this:

```hcl
data "environment_variables" "image" {
  filter = "^IMAGE_"
}

locals {
  powerwall_image_name     = data.environment_variables.image.items.IMAGE_POWERWALL_NAME
  powerwall_version        = data.environment_variables.image.items.IMAGE_POWERWALL_VERSION
  powerwall_image_registry = data.environment_variables.image.items.IMAGE_POWERWALL_REGISTRY
  powerwall_image          = "${local.powerwall_image_registry}/${local.powerwall_image_name}:${local.powerwall_version}"
}
```

## Doing the work

Technically all the script has to do is:
- Get all the environment variables that start with `IMAGE`
- Iterate over the list, and figure out the combination for the registry/image.
- Get the tags for each image and figure out the latest tag
  - since there's no agreed standard for docker image tags we do have to figure out the regular expression that allows us to do a `sort -Vr | head -n 1`. There was a bit of trial and error there.
- If `version in .env != the one from the catalog` then update the `.env` file

I realised that I'd forgotten a lot my bash scripting skills so this has been a good chance to remind myself about indirect variable expansion and associative arrays.

The script is available as a [gist](https://gist.github.com/quotidian-ennui/b19c0a2188e3c41989e0eb1f40dd9db4#file-tf-image-helper-sh) because it might be semi-useful to people who are trying to do the same kind of thing with docker images. You'll need to change it if you're going to look things up from the `ghcr.io` registry because of my hard-coded username, and how it derives my github access token. The `.env` file location is derived from `git rev-parse --show-toplevel` which is fine for me but YMMV.

By default the script only shows you any updates. Running it with the `update` argument means that it will attempt to update the .env file.

```console
$ ./tf-image-helper.sh update
[docker.io/linuxserver/duplicati:2.0.6] -> up-to-date
[docker.io/pihole/pihole:2022.12] -> [2022.12.1]
[docker.io/linuxserver/plex:1.30.1] -> up-to-date
[ghcr.io/quotidian-ennui/tesla-powerwall-exporter:1.4.2] -> up-to-date
[quay.io/titansoft/imagepullsecret-patcher:v0.14] -> up-to-date
[ghcr.io/miguelndecarvalho/speedtest-exporter:v3.5.3] -> up-to-date
[ghcr.io/quotidian-ennui/nginx-wpad:1.0.0] -> up-to-date
$
## .env should how contain IMAGE_PIHOLE_VERSION="2022.12.1"
```

After that I wrap it as part of a `Makefile` simply because with the `set -eo pipefail` in the script means that make will report an error if the script fails, and that's just more _obvious terminal reporting_ for me. If you get the regular expression wrong then the script will terminate; if you're not observant then you might not realise that it _hasn't done all the environment variables you've configured_.

```Makefile
image-update: ## Update Docker images being used
        $(IMAGE_HELPER_SCRIPT) update
```

## Summary

I was a little surprised that there wasn't something more obvious out there that does the job; Perhaps my situation is an edge case because I'm depending on public images that I don't have any input input into; I'm not notified of image updates so that I know to change my corresponding terraform configuration.

I was pointed at [updatecli](https://www.updatecli.io/) after I finished my script by a colleague. This seems suspiciously like a thing that I might have ended up with if I took my script to its logical conclusion and wanted to share my efforts with the world. Point it to a docker registry and then use a file target to update my `locals.tf` file. I might still migrate to it but it does seem like a more expansive tool than I need.

At the moment I'm happy enough with the script that I have, which does precisely the right thing for my environment and particular needs.

[^1]: Dependabot doesn't have support for HCL; I didn't check renovate.
