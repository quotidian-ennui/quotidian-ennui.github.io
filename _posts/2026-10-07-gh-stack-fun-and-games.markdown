---
layout: post
title: "Fun and games with GitHub stacked PRs"
comments: false
tags: [development,github]
published: true
description: "How much can I abuse gh stack so it dances to my tune?"
keywords: ""
excerpt_separator: <!-- more -->
---

[Stacked Pull Requests](https://github.blog/changelog/2026-10-06-stacked-pull-requests-generally-available) became generally available at the start of the month (according to that post only a couple of days ago, so maybe I was too quick on the draw). You can read all the blurb about what a stack is and when to use it from their official documentation. You might not care to ever stack your PRs, in which case this blog entry isn't for you. I do use github almost exclusively so I've started abusing it in ways that probably make no sense to designers of the feature.

<!-- more -->

I have opinions about pull requests (shared by some, not by others) and I have been  curious as to what the impact of the new [extension](https://github.com/github/gh-stack) in the ghcli tool will have in terms of workflow.

First of all, the good. I think stacks are a great way of organising your pull requests if they are ones that build on top of each other (which is precisely the use-case I'm sure github had in mind). They're also great for organising a PR such that you have a less onerous testing regime. For instance, stacking a bunch of dependabot dependency upgrades into a single PR means that you can just run _all the tests_ at the end and be fairly sure that the entire stack just works.

Next comes the weird gotchas that I've been wrestling with over the last few days.

- If you have a ruleset that enforces linear history, then `gh stack merge` is unlikely to work since the merge may well break that linearity (yes, I should read the fine documentation).
- If you use stacks, then you must use an async merge if you want to merge an individual PR; which means that a stack will implicitly break [gh-squash-merge](https://github.com/quotidian-ennui/gh-squash-merge) which I use _all the time_ to merge PRs
- `gh stack merge` doesn't, by default, allow you to specify the message used to commit that PR which means you probably end up with the default message. This isn't a great look for me because I've gotten used to my beautiful hand-crafted messages via `gh-squash-merge` and how I can make that sing and dance with `git cliff`.
- If you have expensive runners then trying to merge a stack can rebase the entire stack causing a flood of expensive build operations for each PR in the stack as they get rebased.
  - This will cause problems if you have a fixed pool of 'large-runners' and your PR stack actually exceeds the max in the pool. Pool of 10, with a stack of 9 PRs... good work, but not all of the PRs will build I suspect.
  - (note to self, don't have expensive actions / runners)

Of course, because there is a full REST API availability to support the feature we can write our own spin using the REST API rather than relying on the `gh stack merge` command.

[This PR](https://github.com/quotidian-ennui/gh-squash-merge/pull/129), now merged, allows me to use `gh squash merge` to merge an individual PR in the stack and provide my own commit message. There is of course a side-effect of the async-merge API, they're quite explicit about it: _It will merge all PRs in the stack up to and including the one specified_. This means you can fall foul of the linearity ruleset, but it means that I can still get my lovingly hand-crafted PR descriptions into the commit message provided I only merge the bottom PR of a stack.

I also use [gh-merge-train](https://github.com/quotidian-ennui/gh-merge-train) to chain merges together because I have long running actions and I simply am not going to come back to a terminal window 15 minutes later to then rebase and merge another PR; gh-merge-train just takes that pain away from me, and I can just get on with doing something more interesting instead while merging a bunch of PRs in the background.

[This gh-merge-train PR](https://github.com/quotidian-ennui/gh-merge-train/pull/29) prototypes a feature that I've been using for a couple of days to help me manage a stacked PR in a merge-train context. The associated PR description documents what's happening under the covers; which is essentially to assume that the all or nothing guarantee of `gh stack` isn't something that you care about _that much_ and merging each of the PRs in order from the bottom up is good enough.

It hasn't happened to me reliably, but is conceptually possible so your mileage is going to vary here: If you have the ruleset _Dismiss stale PR approvals_ and/or _Require approval of the most recent_ then because the merge base changes as the bottom of the stack is merged; this can in fact dismiss a previous approval. So if you're merging your own stack; and the entire stack has someone else's approval (and of course approvals are required); then it is possible to end up where an individual merge fails because of the merge-base change. This has happened in some of my stacks but I can't seem to reliably make it always happen but I end up having to get approvals for the still open PRs in the stack again.

## When I've ended up using stacks

- Merging dependabot PRs that could be linked but aren't (because reasons): I create PRs from dependabot PRs using this script [gh-stack-create](https://github.com/quotidian-ennui/ghcli-utils/blob/main/gh-stack-create); rebase; and then test the PR at the top of the stack. Afterwards I submit and merge. This is a great use for `gh stack` to make sure all those pesky dependencies all play nicely with each other when you know they're related.
- When I have a chain of pull requests where the code builds on top of each other. This is the classic use-case. I try to make it so that the bottom of the stack can always be merged safely e.g. it's an addition to a JSON model that has a sensible default; this can be merged, and have no runtime effect on downstream components if suddenly we want that change so another parallel stream can start.
- A series of changes where each PR in a stack is an logical unit of work that is separate but related; a good example here is where I changed a monorepo so that all docker images ended up being built with a distroless image. Each of the PRs targetted a different service, but I still end up with a better release notes because it's more obvious from the commit message headline.
