---
layout: post
title: "Github SSH Signing Keys via terraform"
comments: false
tags: [terraform,github]
# categories: [terraform,github]
published: true
description: "I must be able to do this via terraform but it's in the backlog"
keywords: ""
excerpt_separator: <!-- more -->
---

I was reading some [git hints & tips](https://blog.gitbutler.com/git-tips-and-tricks/) and I realised that I _really should be signing my commits_ since github supports signing using SSH keys. I previously haven't been because GnuPG was just too hard (even though I use it with `gopass`); reusing my ssh keys seems like a good idea with github.

<!-- more -->

## .gitconfig

The contents of my `.gitconfig` is as follows:

```
[user]
	name = Lewin Chan
	email = 8480608+quotidian-ennui@users.noreply.github.com
	signingKey = ~/.ssh/id_rsa.pub

[gpg]
	format = ssh

[commit]
	gpgsign = true

[tag]
	gpgsign = true

[gpg "ssh"]
	allowedSignersFile = /home/lchan/.dotfiles/gitconfig/allowed_signers
```

The allowedSignersFile configuration is simply to allow `git log --show-signature` to show the right thing; it isn't really that necessary. The `allowed_signers` file simply contains `email-address  $(cat ~/.ssh/id_rsa.pub)`. Afterwards I had to add my ssh authentication key as a signing key to github to get the lovely [verified badge on my commits](https://github.com/quotidian-ennui/ubuntu-dpm/commit/417c7a2ccc3997bd47dc519109be31fb971320ac). Until then you would see _unverified_ next to the commit[^1].

The natural consequence of this is that we need to effectively duplicate all our ssh keys in github; once for ssh authentication and once for ssh signing which means I want to manage it via terraform.

## Terraform

Sadly, the github terraform provider has support for git ssh signing keys [in the backlog](https://github.com/integrations/terraform-provider-github/issues/1917). Once again we need to resort to the `scottwinkler/shell` provider to do the heavy lifting for us. I've found myself, yet again, with a pragmatic but brittle solution because one project doesn't feature-align with another.

- You need to have the `admin:ssh_signing_key` scope assigned to your token (because you might be deleting keys)
- By the same token you probably want `write:public_key` and `read:public_key` as well to manage your ssh keys.
- You need a configured [gh cli](https://github.com/cli/cli) and also [jq](https://github.com/jqlang/jq) installed where you're running terraform; that's naturally available if your pipeline is using a standard github runner, and will already be available on your local machine if you've been doing any 'dev' work in the last 3 years.
- This example wouldn't pass `shellcheck` I suspect (there are better ways of grabbing stdin for the 'delete' lifecycle command).
- I used the `gh api` variant because `gh ssh-key` is geared towards commandline interactive use in this instance (no -json flag for ssh-key)

```terraform
locals {
  ssh_keys = {
    desktop = {
      ssh_key = "ssh-rsa AAAAB..."
    }
    working_copy_iphone = {
      ssh_key = "ssh-rsa AAAAB3N..."
    }
    framework_ubuntu = {
      ssh_key = "ssh-ed25519 AAAAC3NzaC1l..."
    }
    framework_windows = {
      ssh_key = "ssh-ed25519 AAAAC3NzaC1l..."
    }
  }
}

# Add our ssh authentication keys
resource "github_user_ssh_key" "ssh_auth_keys" {
  for_each = local.ssh_keys
  title    = each.key
  key      = each.value.ssh_key
}

# Assign ssh signing keys because its not currently exposed by the
# terraform provider.
resource "shell_script" "ssh_signing_keys" {
  for_each = local.ssh_keys
  environment = {
    title       = each.key
    signing_key = each.value.ssh_key
  }
  lifecycle_commands {
    read   = <<-EOF
      gh api "/user/ssh_signing_keys" | jq ".[] | select(.title==\"$title\")"
    EOF
    create = <<-EOF
      gh api --method=POST "/user/ssh_signing_keys" -f "key=$signing_key" -f "title=$title"
    EOF
    delete = <<-EOF
      IN=$(cat)
      id=$(echo $IN | jq -r .id)
      gh api --method=DELETE "/user/ssh_signing_keys/$id"
    EOF
  }
}
```

After a plan+apply we can check the state:

```terraform
bsh ❯ tofu state show 'shell_script.ssh_signing_keys["framework_windows"]'
# shell_script.ssh_signing_keys["framework_windows"]:
resource "shell_script" "ssh_signing_keys" {
    dirty             = false
    environment       = {
        "signing_key" = "ssh-ed25519 AAAAC3NzaC1l..."
        "title"       = "framework_windows"
    }
    id                = "cn6bblahblahblahblah"
    output            = {
        "created_at" = "2024-02-14T13:25:56.162+00:00"
        "id"         = "123456"
        "key"        = "ssh-ed25519 AAAAC3NzaC1l...""
        "title"      = "framework_windows"
    }
    working_directory = "."

    lifecycle_commands {
        create = <<-EOT
            gh api --method=POST "/user/ssh_signing_keys" -f "key=$signing_key" -f "title=$title"
        EOT
        delete = <<-EOT
            IN=$(cat)
            id=$(echo $IN | jq -r .id)
            gh api --method=DELETE "/user/ssh_signing_keys/$id"
        EOT
        read   = <<-EOT
            gh api "/user/ssh_signing_keys" | jq ".[] | select(.title==\"$title\")"
        EOT
    }
}
```

## Summary

- Yay, I now have an extra 'badge' on my commits (because we gotta catch 'em all).
- What should happen if I decommission a machine, and the ssh key no longer exists (or I rotate it because I'm moving my RSA key to ed25519).
  - removing the key as as signing key means all my historical commits from that machine are no longer verified.
  - Is it better or worse to be unverified as opposed to nothing at all from the point of view of fearmongering by well-meaning security wonks[^1].
  - A potential answer might be to have a single ssh signing key and multiple ssh authentiation keys (but you're just kicking the key rotation problem down the road).
- `lazygit` now shows a full screen logging window during the commit for signing (because passwords...)

[^1]: Not signing commits means that we never see the _verified/unverified/partially verified_ badges.
