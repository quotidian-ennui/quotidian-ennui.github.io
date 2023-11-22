---
layout: post
title: "Detecting Terraform Drift with Github actions"
comments: false
tags: [development,terraform]
# categories: [development,terraform]
published: true
description: "Like dichotomous branching, or a 'Back to the Future'-esque timeline; drift is gonna happen"
keywords: ""
excerpt_separator: <!-- more -->
---

I've been using terraform for a while and what I've discovered is that there doesn't seem to be a whole wealth of information about what to do when cold hard reality smacks your utopian infrastructure as code in the face. A classic example might be a support engineer adding `LOG_LEVEL=super-verbose` as an environment variable via the AWS console to some particular runtime because they're getting reports that _something blahblahblah doesn't work_.

If the first thought in your head is _**"That'll never happen because IaC means they just have to modify some file; raise a PR; and then it'll get auto deployed after going through the appropriate approval gates"**_; this blog post is not for you.

<!-- more -->

I've been using a pipeline that's based on [this blog post](https://warman.io/blog/2023/03/fixing-automating-terraform-with-github-actions/). That's not a pre-requisite; you just have to be be able to generate repository dispatch events after doing the terraform plan. Post terraform plan we generate a repository dispatch event so that we can trigger other activity[^1]. We can have a downstream consumer that raises github issues in the event that a scheduled terraform plan shows changes.

## The repository dispatch event

There's no right answer here; capture the information that you think is most useful. We extract a oneliner from the terraform plan via this JQ snippet and turn it into something very similar to what you see on the commandline. It doesn't have to be a one-liner; [tf-summarize](https://github.com/dineshba/tf-summarize) can generate nice output for inclusion as a PR comment.

```bash
# shellcheck disable=SC2016,SC2034
JQ_JSON_PLAN_ONELINER='
    (
      [
        .resource_changes[]?.change |
        [
          .actions?,
          if has("importing") then
            "importing"
          else
            empty
          end
        ]
      ] | flatten
    ) | {
      "plan_outcome_import":(map(select(.=="importing")) | length),
      "plan_outcome_add":(map(select(.=="create")) | length),
      "plan_outcome_change":(map(select(.=="update")) | length),
      "plan_outcome_destroy":(map(select(.=="delete")) | length)
    } | to_entries | map("\(.key)=\(.value)") | @sh
'
plan_oneliner() {
  exitcode="${PLAN_EXITCODE}"
  plan_outcome_add="0"
  plan_outcome_change="0"
  plan_outcome_destroy="0"
  plan_outcome_import="0"

  if [ "$exitcode" == "0" ]; then
    echo "has-changes=no" >>"$GITHUB_OUTPUT"
    echo "Terraform plan has no changes"
  elif [ "$exitcode" == "2" ]; then
    # shellcheck disable=SC2016
    eval "export $(terraform show -json "$PLAN_JSON_FILE" | jq -r "${JQ_JSON_PLAN_ONELINER}")"
    {
      printf "has-changes=yes\n"
      printf "add=%s\n" "${plan_outcome_add}"
      printf "change=%s\n" "${plan_outcome_change}"
      printf "destroy=%s\n" "${plan_outcome_destroy}"
    } >>"$GITHUB_OUTPUT"
    oneliner="Terraform plan has changes: ${plan_outcome_import} to import, ${plan_outcome_add} to add, ${plan_outcome_change} to change, ${plan_outcome_destroy} to destroy."
    echo "summary-oneliner=$oneliner" >>"$GITHUB_OUTPUT"
    echo "$oneliner"
  fi
}
```

You have full control over the `client_payload` part of the [repository dispatch event](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#repository_dispatch). Bear in mind that the JSON forming the client_payload may only have 10 top level properties so we're nesting into custom_data to avoid the limit. The other values in the `client_payload` are standardised values that we've found useful for other downstream consumers but won't contain the right information in this context. We'll be using `event_name` as an additional filter and our client payload looks something like this:

```json
{
  ...
  "event": {
    // other bits skipped for brevity.
    "client_payload": {
      "repository" : "quotidian-ennui/infrastructure",
      "workflow" : "terraform.yml",
      "event_name" : "schedule|pull_request|...", // event will be ignored if it's not schedule
      "actor" : "...", // likely to be the last committer on the main branch, so not very useful
      "ref" : "refs/heads/main", // it's a schedule so default branch
      "sha": "commit sha", // it's a schedule so latest on default branch
      "custom_data": {
        "plan_has_changes": "yes || no || unknown", // from terraform-plan
        "plan_result": "success || failure || skipped || cancelled", // Whether terraform plan actually finished
        "plan_oneliner": "Terraform plan has changes: [n] to import, [n] to add, [n] to change, [n] to destroy. || 'n/a'",
        "workflow_run_url": "https://github.com/... pointing to the workflow run that triggered this"
      }
    }
  }
}
```

The format of your client_payload starts becoming important because you're going to be using it in other workflows that live on the default branch of the repository. You need to orchestrate the modification the client_payload (generating new payloads while living on `feature/new-client-payload`) and the downstream workflows to match (all executing from `refs/head/main`). It's overkill right now, and the words 'schema validation' aren't my favourite words in the world, but it's something to think about.

## Detecting Terraform drift

Once you are consistently producing the repository dispatch event then you can add a new workflow that listens for the event and actually does the work. This sequence diagram (sequence diagram purists, please excuse my wilful abuse) describes what we're trying to do

![sequence]({{ blog_baseurl }}/images/posts/terraform-drift.svg)

The workflow itself is relatively simple because you don't need much else other than `gh` which is available on every github runner (other actions are available to interact with github issues). Everything here is inlined for clarity.

```yaml
name: tf-drift
run-name: terraform drift detection
on:
  repository_dispatch:
    types:
      - post-tf-plan

permissions:
  contents: read
  issues: write

jobs:
  terraform_drift:
    name: Detect Terraform Drift
    runs-on: ubuntu-latest
    if: |
      github.event.client_payload.event_name == 'schedule' &&
      github.event.client_payload.custom_data.plan_result == 'success'
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          ref: ${{ '{{' }} github.event.repository.default_branch }}
      - name: Query issues
        id: query_issues
        uses: quotidian-ennui/find-matching-issues@main
        with:
          query: is:issue is:open tfsha:${{ '{{' }} hashFiles('terraform/*.tf') }}
          token: ${{ '{{' }} secrets.GITHUB_TOKEN }}
          format: simple
      - name: Issue Details
        id: issue_details
        env:
          TF_SHA: ${{ '{{' }} hashFiles('terraform/*.tf') }}
          GITHUB_TOKEN: ${{ '{{' }} secrets.GITHUB_TOKEN }}
        run: |
          ISSUE_BODY=$(mktemp --tmpdir="${RUNNER_TEMP}" tf-drift.XXXXXXXXXX)
          if [[ -s "${{ '{{' }} steps.query_issues.outputs.path }}" ]]; then
            url=$(head -n1 ${{ '{{' }} steps.query_issues.outputs.path }})
            state=$(gh issue view --json state --jq '.state' "$url")
            # shellcheck disable=SC2129
            echo "existing_issue=$url" >> "$GITHUB_OUTPUT"
            echo "issue_state=$state" >> "$GITHUB_OUTPUT"
          fi
          {
            echo "Terraform drift detected - $(/bin/date -u '+%Y-%m-%d')"
            echo ""
            echo "<!-- tfsha:$TF_SHA -->"
            echo "${{ '{{' }} github.event.client_payload.custom_data.plan_oneliner }}"
            echo ""
            echo "[Workflow Run](${{ '{{' }} github.event.client_payload.custom_data.workflow_run_url }})"
          } >>"$ISSUE_BODY"
          # shellcheck disable=SC2129
          echo "issue_title=Terraform drift detected: $(/bin/date -u '+%Y-%m-%d')" >> "$GITHUB_OUTPUT"
          echo "issue_body=${ISSUE_BODY}" >> "$GITHUB_OUTPUT"

      - name: Create issue
        id: create_issue
        if: |
          steps.issue_details.outputs.existing_issue == '' &&
          github.event.client_payload.custom_data.plan_has_changes == 'yes'
        env:
          GITHUB_TOKEN: ${{ '{{' }} secrets.GITHUB_TOKEN }}
        run: |
          echo "scheduled run, planned changes, no existing issue : there is drift"
          gh issue create -l terraform -F "${{ '{{' }} steps.issue_details.outputs.issue_body }}" -t "${{ '{{' }} steps.issue_details.outputs.issue_title }}" -R "${{ '{{' }}  github.repository }}"

      - name: Update issue
        id: update_issue
        if: |
          steps.issue_details.outputs.existing_issue != '' &&
          steps.issue_details.outputs.issue_state == 'OPEN' &&
          github.event.client_payload.custom_data.plan_has_changes == 'yes'
        env:
          GITHUB_TOKEN: ${{ '{{' }} secrets.GITHUB_TOKEN }}
        run: |
          echo "scheduled run, planned changes, existing issue : there is still drift"
          gh issue comment "${{ '{{' }} steps.issue_details.outputs.existing_issue }}" -F "${{ '{{' }} steps.issue_details.outputs.issue_body }}"

      - name: Close issue
        id: close_issue
        if: |
          steps.issue_details.outputs.existing_issue != '' &&
          steps.issue_details.outputs.issue_state == 'OPEN' &&
          github.event.client_payload.custom_data.plan_has_changes == 'no'
        env:
          GITHUB_TOKEN: ${{ '{{' }} secrets.GITHUB_TOKEN }}
        run: |
          echo "scheduled run, no planned changes, existing issue : there is no longer drift"
          gh issue close "${{ '{{' }} steps.issue_details.outputs.existing_issue }}" -c "[Workflow Run](${{ '{{' }} github.event.client_payload.custom_data.workflow_run_url }}) shows no drift"

      - name: Reopen Issue
        id: reopen_issue
        if: |
          steps.issue_details.outputs.existing_issue != '' &&
          steps.issue_details.outputs.issue_state == 'CLOSED' &&
          github.event.client_payload.custom_data.plan_has_changes == 'yes'
        env:
          GITHUB_TOKEN: ${{ '{{' }} secrets.GITHUB_TOKEN }}
        run: |
          echo "scheduled run, planned changes, existing issue (already closed): reopening issue"
          gh issue reopen "${{ '{{' }} steps.issue_details.outputs.existing_issue }}"
          gh issue comment "${{ '{{' }} steps.issue_details.outputs.existing_issue }}" -F "${{ '{{' }} steps.issue_details.outputs.issue_body }}"
```

## Notes

- After discussion within the team and some prototyping usage we found that we didn't want to have a single ticket being constantly re-opened because of drift (once things are mature, your terraform files aren't likely to change but runtime variables might e.g. `tfvars | environment` which won't be reflected because `hashFiles("*.tf")`).
  - Once a ticket is closed, then it's off the table and we open a new ticket (in our original use-case, the support engineer has figured out the problem, and removed the environment variable; re-opening the issue just causes contextual toil). Although this example includes it, the _reopen issue_ branch will never be fired because the query will never trigger it.
- We're always adding a new comment showing a link to the workflow that found the drift. If our schedule is to run every day then this will cause a lot of additional comments in the issue. It might be better to have it update a single comment.
- [quotidian-ennui/find-matching-issues][] is a custom composite action that is a variation on [https://github.com/lee-dohm/select-matching-issues][] (which is nodejs based). The original action still works (as of 2023-11-20) but once Github mandates a runtime upgrade to Node20 it is likely to stop working without upgrading the underlying dependencies.
  - Usage of either action makes the assumption that the search using the hash of the terraform files is likely to only return a single issue. Multiple results may lead you to update the wrong ticket.

[^1]: we appear to have started using github actions as an orchestration framework
[quotidian-ennui/find-matching-issues]: https://github.com/quotidian-ennui/find-matching-issues
[https://github.com/lee-dohm/select-matching-issues]: https://github.com/lee-dohm/select-matching-issues