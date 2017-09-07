---
layout: post
title: "git flow release"
date: 2017-09-07 12:00
comments: false
categories: development
tags: [development]
published: true
description: "Bastardising git flow for release automation"
keywords: "git, development, dvcs"
excerpt_separator: <!-- more -->
---

For a number of reasons (some historical, some legacy, some just daft), the optional Interlok components live in various git providers. This isn't a post that argues that git flow is great; it's well understood so we use it to remove the friction of understanding a bespoke tagging/branching system. When we do a product release there's a Jenkins pipeline that builds all the artefacts based on the release branch from `git flow release`. That means that when we decide that it's time to prepare for a release, we have to do a _git release start_ on every project and publish that branch; all of which is nice and scriptable.

<!-- more -->

Sadly though, when we do a `git flow release finish`, things aren't that simple as _git flow finish_ does like to have a merge message when you merge into both the _master_ and _develop_ branch. The beauty of git is that all these sub-commands are just shell scripts so all we need to do is patch `git-flow-common` and `git-flow-release` so that we don't have to enter a merge message when that part of the pipeline fires.

## git-flow-common

First of all, we add a new function to _git-flow-common_ that generates the merge message (available as a <a href="{{ site.baseurl}}/artifacts/gfc_diff.txt" target="_blank">diff</a>).

{% highlight bash %}
#
# gitflow_render_merge_message
#
# Inputs:
# $1 = source branch
# $2 = destination branch
#
# Renders a pre-defined merge message.
gitflow_render_merge_message() {
  local src_branch=$1
  local dst_branch=$2
  local msg=$(eval "echo $(git config --get gitflow.merge.message)")
  if [ "$msg" != "" ]; then
    echo "$msg"
  fi
}
{% endhighlight %}


## git-flow-release

Then we need to patch the `cmd_finish` function in _git-flow-release_ so that when a merge is attempted on both the `master` and `develop` branches (so it may be 2 places you make some changes). In the end it'll look something like this (available as a <a href="{{ site.baseurl}}/artifacts/gfr_diff.txt" target="_blank">diff</a>) :

{% highlight bash %}

 # try to merge into master
 # in case a previous attempt to finish this release branch has failed,
 # but the merge into master was successful, we skip it now
 if ! git_is_branch_merged_into "$BRANCH" "$MASTER_BRANCH"; then
         git checkout "$MASTER_BRANCH" || \
           die "Could not check out $MASTER_BRANCH."

         local msg=$(gitflow_render_merge_message "$BRANCH" "$MASTER_BRANCH")

         if noflag squash; then
                 if [ "$msg" != "" ]; then
                         git merge --no-ff -m "$msg" "$BRANCH" || \
                                 die "There were merge conflicts."
                 else
                         git merge --no-ff "$BRANCH" || \
                                 die "There were merge conflicts."
                 fi
                 # TODO: What do we do now?
         else
                 git merge --squash "$BRANCH" || \
                         die "There were merge conflicts."
                 git commit
         fi
 fi

{% endhighlight %}


## .gitconfig

Finally you need to modify your local git config so that you define the merge message :

{% highlight bash %}

[gitflow "merge"]
        message = Automated Merge of \\'$src_branch\\' into \\'$dst_branch\\'.

{% endhighlight %}
