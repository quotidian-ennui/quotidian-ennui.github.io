---
layout: post
title: "Pinning GitHub Actions to hashes"
comments: false
tags: [development,github]
# categories: [development,github]
published: true
description: "Might be more secure, but by the same token may not be"
keywords: ""
excerpt_separator: <!-- more -->
---

So, supply chain attacks are all the rage; and by all the rage I mean it's a thing that's happening, security people are concerned, and there's been some thought leadership happening around it. People that know me know that I have a tangential interest in security; I couldn't hold my own in a conversation about security with a professional but I am a dangerous amateur. If I'm lucky maybe the semi-finals of the local county schools' championships (choose your elitist activity here, I would choose trash-talking). I'm not going to talk about why you should pin, but some of the practical consequences on pinning.

<!-- more -->

Pinning is relatively straightforward, I just make sure that I'm already on a strict semantic version of the action (i.e. `@v4.1.1` not `@v4`) and then I just use `npx pin-github-action -i "build.yml" -c " {ref}"` which will do the right thing and modify the action reference to the hash. Afterwards I use `prettier -w "build.yml"` just to have things consistent.  If you aren't already on a semantic version then you can just use `gh release list --repo "actions/checkout" --exclude-drafts --exclude-pre-releases --json "tagName" -q ".[].tagName" | sort -rV | head -n 1`[^1] to get the latest release. You're running in github so you have access to dependabot so use that to keep your actions up to date.

## Consequences of pinning

- There are more dependabot pull requests, so you have to figure out how to reduce that toil.
- You still have to trust the action and all the dependencies of that action.

If we look at a real world project (_kubernetes-sigs/metrics-server_) then we can see the following (I'm using this as an example because a recent PR came up in my github feed, the same story happens in all my repositories...):

- `lint-test-chart.yaml` pins to a specific `mikefarah/yq` hash.
  - If you look at the action.yml in the yq project then you can see that it refers to the docker image `mikefarah/yq:4-githubaction` which of course is eminently mutable and could conceivably pull the rug from under your feet at any time[^2].
  - Transitive dependencies aren't tracked in the 'insights' tab of the repo; you can't search for `yq` and see the docker image come up; just the action itself.

So, deciding to pin doesn't release you from the obligation of doing the work to understand your supply chain. If you're going to pin your github actions because your security wonks said it was best practise then you haven't done anything other than tick a checkbox and make sure they get off your back (good for you!).

The other extreme might be that your org ends up having a policy where they restrict what actions can run in your project even going so far as to pin them to specific hashes. This is dangerous in a different way if they do that without having an useful way of updating that list[^3]. Even worse, they decide to fork all the actions as private projects inside the org and force you to use them because that won't lead to a maintenance nightmare at all.


[^1]: Of course you already have a dependency tree of your actions right? if not then `grep ih "uses:" * | sort | uniq` might be your friend.
[^2]: Hmm, what if I was targeting a lot of companies running kubernetes?
[^3]: Have you had pain with the recent major version upgrades because everyone has started standardising on Node20 to run actions? Imagine you had to raise a support ticket for every action...
