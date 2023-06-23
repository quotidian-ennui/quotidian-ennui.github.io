---
layout: post
title: "Repository workflow permissions via terraform"
comments: false
tags: [terraform,github]
# categories: [terraform,github]
published: true
description: "When you think to yourself, I must be able to do this via terraform..."
keywords: ""
excerpt_separator: <!-- more -->
---

The [github terraform provider](https://github.com/integrations/terraform-provider-github) is ace; I've been using it to manage my personal github repos and also my organisation ones (well, the ones I have sufficient rights to manage at least), however, one thing did strike me as I was down the rabbit hole - I can't easily change the permissions model for workflow actions on an individual  basis; I can cascade them from an organisational perspective, but not on an individual repository basis (_this is true as of the github terraform provider 5.28.1_). That's something I wanted to do and since terraform is infinitely flexible I was sure that I could do something tricksy with one of the other providers without having to write my own.

<!-- more -->

I settled on using the the `scottwinkler/shell` provider (of course it's dangerous, but entirely suitable for the hackery that I like amuse myself with); a colleague suggested `devops-rob/terracurl` but having looked at the documentation it didn't quite fit although a curl style interaction is precisely what we're doing here eventually.

## What I wanted

- Capture existing state of the permissions which is essentially `gh api repos/$owner/$repo/actions/permissions/workflow` (or its curl equivalent) and store it in terraform state.
- Capture my desired state based on terraform variables or what not, and if it differs, then apply it.

Pretty simple, so here's a cut down version of the configuration I wanted to see in my locals.tf (sometimes I like to go from the top down, sometimes from the bottom up), where `workflow_perms` and `workflow_pr_approve` match up to the equivalent fields from the API call (`default_workflow_permissions` & `can_approve_pull_request_reviews` respectively) and I am overwriting the defaults for the _fantastic-octo-parakeet_ project.

```terraform
  public_repos = [
    {
      name    = "gh-my"
      desc    = "Show open issues/PR in your repos"
      topics  = ["gh-extension"]
      license = "wtfpl"
    },
    {
      name                = "fantastic-octo-parakeet"
      desc                = "It's a great auto-generated name"
      license             = "unlicense"
      issues              = false
      workflow_perms      = "read"
      workflow_pr_approve = false
    }
  ]
```

## What I did

The key is to force a "state change" when my desired state deviates from the actual github repository state; this is where the shell provider comes in quite handy since you're able to do any kind of arbitrary scripting you want to (in my case `bash` for my version of platform portability), executing any kind of arbitrary commands you want to.

```terraform
provider "shell" {
  # Force bash to be on the path for wingit+bash / wsl equivalence.
  interpreter = ["bash", "-c"]
}

# Assign workflow default permissions via gh-api because it's not
# exposed via terraform.
resource "shell_script" "public_repo_workflow_perms" {
  for_each = {
    for _, spec in local.public_repos : spec.name => spec
  }
  environment = {
    owner          = local.github_owner
    repo           = github_repository.public_repo[each.value.name].name
    action_approve = try(each.value.workflow_pr_approve, true)
    perms          = try(each.value.workflow_perms, "write")
  }
  lifecycle_commands {
    read   = <<-EOF
      gh api "repos/$owner/$repo/actions/permissions/workflow" | jq ". + { _desired_action_approval: $action_approve , _desired_workflow_perms: \"$perms\"}"
    EOF
    create = <<-EOF
      gh api --method=PUT "repos/$owner/$repo/actions/permissions/workflow" -F can_approve_pull_request_reviews=$action_approve -F default_workflow_permissions="$perms"
    EOF
    delete = <<-EOF
      echo "{}"
    EOF
  }
}
```

- `read` is called to get the current state, which means we query github for the permissions, and then _add via jq_ our desired states.
  - The shell provider requires you to emit JSON, the github cli already does since it doesn't modify api call output.
- `create` is called if the output of _read_ differs from what terraform has in its state (there is some nuance here, but a _tainted forceNew_ because I don't have an update method is fine here)
    - since there is no output from create it keeps the state from _read_ otherwise the output here would overwrite things.
- `delete` does nothing; it doesn't need to.

Once we plan & apply we can query the state and check it:

```terraform
bsh ❯ terraform state show 'shell_script.public_repo_workflow_perms["fantastic-octo-parakeet"]'
# shell_script.public_repo_workflow_perms["fantastic-octo-parakeet"]:
resource "shell_script" "public_repo_workflow_perms" {
    dirty             = false
    environment       = {
        "action_approve" = "false"
        "owner"          = "quotidian-ennui"
        "perms"          = "read"
        "repo"           = "fantastic-octo-parakeet"
    }
    id                = "cia4j9nh6q92h23ujpm0"
    output            = {
        "_desired_action_approval"         = "false"
        "_desired_workflow_perms"          = "read"
        "can_approve_pull_request_reviews" = "false"
        "default_workflow_permissions"     = "read"
    }
    working_directory = "."
```

If I change locals.tf and switch `workflow_pr_approve` to true for fantastic-octo-parakeet then the state from _read_ would change so _create_ will be executed.

## Caveats

- You now need a configured [gh cli](https://github.com/cli/cli) and also [jq](https://github.com/jqlang/jq) installed where you're running terraform; that's naturally available if your pipeline is using a standard github runner, and will already be available on your local machine if you've been doing any 'dev' work in the last 3 years.
- The shell provider is relatively unloved, it's not changed for ~2 years; it's possible that future versions of terraform will break it (because of SDK upgrades and the like). By then it's equally likely that the github provider will provide this feature and I don't need to do it like this any longer.



