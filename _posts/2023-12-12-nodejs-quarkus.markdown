---
layout: post
title: "Straight line port of a nodejs project to java/quarkus"
comments: false
tags: [java,nodejs]
published: true
description: "It's because of supportability reasons (honestly, not because I was bored)"
keywords: ""
excerpt_separator: <!-- more -->
---

I forked a [nodejs project](https://github.com/dmyerscough/tesla-powerwall-exporter) a last year since I had a need to do some pretty charts with data from my Tesla Powerwall. It's been working well enough, and I hacked around with it to get some additional info out and to make sure it could run in my homelab. Since it's a fairly easy project to understand from a feature perspective it's one that I'm using to experiment with other languages. I have a Go implementation and a Rust implementation in the works which might eventually get pushed.

<!-- more -->

Java is the language that I'm most familiar with so I used Quarkus+Java as a stalking horse to get the concepts right in my head for the other languages. I kept the logic largely the same between the two versions and I have no trouble understanding either. Of course no-one 'loves' java because there's _too much boilerplate/too verbose/insert your pet peeve here_.

This is my collected ruminations on my one-day porting effort of the application to Quarkus; I actually got a bit side tracked by Quarkus/Graal native images.

## The raw

Here's some raw information so that you can jump to some conclusions.

> Note that I'm not counting the additional build files (like build.gradle/package*.json etc) from the projects or tests.

| Measure | Node | Quarkus |
|-----|------|----------|
| Lines of Code (wc -l) | ~480 | ~180 [^1] |
| Runtime dependencies | 104[^2] | 119[^3] |
| Docker Image Size | ~146MB | ~465MB  |
| Memory Consumption K8S | ~50Mb | ~100Mb |
| Startup Time in K8S | 2s | 3s |

It's going to be a bit _ne supra crepidam_ if you read too much into it as these kind of stats mean nothing. A lot of code is about feelings and intuition.

[My fork (tag: 1.4.12)](https://github.com/quotidian-ennui/tesla-powerwall-exporter/tree/npm) is ~230 commits ahead of the original largely because of dependabot who has raised 319 PRs; this is since Nov 2022. I actually got quite irked over time, and once dependabot started allowing the grouping of dependencies; I did that to to reduce the PR count.

I kept the java application very vanilla Quarkus but the extensions have included lots more features than I really need (and are disabled explicitly in configuration); you'll see there is significant difference in the image size when it comes to the Java variant but the base image size for `registry.access.redhat.com/ubi8/openjdk-21` is 448Mb and this accounts pretty much for the difference between the two images.

## The feelings

From a coding perspective I used visual studio code for both (because of IntelliJ+WSL woes) and the developer experience is largely the same (IntelliJ is somewhat better for changing my mind with respect to naming simply because of muscle memory) and the live reload feature of `gradle quarkusDev` is very useful when you're building up application behaviour.

I ended up using `com.github.jmongard.git-semver-plugin` as an alternative to `npm version` with everything still wrapped in a Justfile.

Due to the nature of the environment here I can lose connectivity to the powerwall for some time. All of it is transient, but what I've found is that kubernetes will restart my pod (npm) several times a day. It doesn't do that with the java image since those exceptions aren't terminating the process (they're logged by the quarkus scheduler and the job is triggered again). This means the gauges stay at the last collected value rather than completely disappearing from the dashboard. Kubernetes is _meant to restart pods that have failed_; I just don't like the notifications.

One of the things that has frustrated me most was there weren't any tests (mocked or otherwise); this meant in order to test things I had to be at home; check that the application started; see if I could connect to `/metrics` and see some data. I'm not familiar with the npm ecosystem that I can make an effective choice about a unit testing framework whereas in Java I might naturally gravitate towards junit, mockito, testcontainers or similar. Fundamentally this means I don't have confidence that some arbitrary npm upgrade suggested by dependabot isn't going to break me. I have the option here to write tests because I'm familiar with the testing frameworks.

I am 'better' at java than I am javascript. That's simply to do with knowing what to search for and already knowing the ecosystem. This is always the problem though; learning the syntax of a language isn't the hard part; it's learning the ecosystem and the idioms that go along with it. I just find that I don't get on with npm in the same way that I don't really get on with pip.

## Conclusion

All of this is just re-inventing the wheel; I didn't need to port to java and it hasn't really gained me very much in terms of features. It has given me a better understanding of the Quarkus ecosystem (which I hadn't really played with much before). From a supportability perspective java is boring that's a good thing but doesn't mean much for a toy like this.

I still haven't written any tests.

[^1]: You can add another 50 lines of yaml (because I amused myself by enabling `quarkus-config-yaml`)
[^2]: `ls -1 ./node_modules | wc -l`
[^3]: `ls -1 /deployments/boot /deployments/main | wc -l` +1 (for quarkus-run.jar).

