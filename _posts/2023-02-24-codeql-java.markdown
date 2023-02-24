---
layout: post
title: "CodeQL scanning fun and games"
comments: false
tags: [development,java]
# categories: [development,java]
published: true
description: "Getting CodeQL to feature parity with LGTM"
keywords: ""
excerpt_separator: <!-- more -->
---

CodeQL is the successor to LGTM; I was hoping for a seamless transition to CodeQL, but sadly that wasn't to be. A lot of the things that I had been previously been doing like `@SuppressWarnings("lgtm[ignore-this-weak-crypto]")` were being ignored, and I've been ignoring the security code scanning alerts as well. It's taken a while, but now I've actually embarked on a journey where I am in the process of using it for some additional projects and I wanted to make sure that I have the feature set that I'm used to :- _being able to suppress alerts in the code, not in an external tool_. This is important because the code will always exist for the lifetime of the product but tools come and go.

<!-- more -->

Right now it seems that discoverability around CodeQL features is a mess; it's hard to find the right arcane invocation that allows you to do the thing that you want to do. Over the last few days I've intermittently had to do a lot of programming by coincidence as I copy pasta'd a bunch of things that seemed to make sense, but there's no unified explanation as to why you're doing what you're doing. Perhaps this is the feeling everyone has when they start using a new language/framework/tool.

First of all, the auto-generated _codeql-analysis.yml_ file provided by github is _generically useful_, but not _useful specifically_. Since none of the projects that I'm working mix and match languages, I don't really need to have a matrix style execution of the pipeline and I can just concentrate on a single language pipeline. In order to support the suppression annotations and comments we need to configure some extra things. These weren't especially clear at the time I was doing it, but now that I've done it, it does in fact make sense and I'll never be able to unknow what I now know. My explanation here is almost certainly filled with errors and misunderstanding, so you're going to have to _focus on the heavenly glory rather than the finger pointing at the moon_.

## CodeQL with additional packs

There are CodeQL packs, but where can I find them? There's no obvious registry whatever that you can publish to (if you've used something like the terraform registry/docker hub/github action marketplace; this seems a bit crazy) so I had to figure it out based on looking at the source code. We need to add the specific _AlertSuppression_ queries since they don't appear to be fired by default. `AlertSuppression.ql` handles comments, and `AlertSuppressionAnnotations.ql` handles the SuppressWarnings annotations. If our language target was something like C# then `AlertSuppressionAnnotations.ql` would not be available. Have a look at the various languages in the [standard CodeQL library](https://github.com/github/codeql) and search for _alert-suppression_

```yaml
    # curly braces causes a problem with jekyll template rendering
    # so I used [[ ]] instead where I would use curly braces
    - name: Initialize CodeQL
      uses: github/codeql-action/init@v2
      with:
        languages: "java"
        # languages: "$[[ matrix.language ]]"
        queries: security-and-quality
        packs: "codeql/java-queries:AlertSuppression.ql,codeql/java-queries:AlertSuppressionAnnotations.ql"
      env:
        GITHUB_TOKEN: $[[ secrets.GITHUB_TOKEN ]]
```

## CodeQL analysis + suppression

Do the compile step via gradle/maven/whatever; gradle (`gradle testClasses`) in my case using the standard gradle build action. Now that the alert suppression packs have been enabled, what that means is that during the analysis phase it will generate the alerts as normal (but these alerts will have attached information about the suppressions). After the analysis, what we want to do is to effectively rewrite the sarif files so that those alerts are dismissed. The `dismiss-alert` action allows us to do this quite easily.

```yaml
    # curly braces causes a problem with jekyll template rendering
    # so I used [[ ]] instead where I would use curly braces
    - name: Perform CodeQL Analysis
      # define an 'id' for the analysis step so we can use its outputs.
      id: analyze
      uses: github/codeql-action/analyze@v2
      with:
        category: "/language:java"
        output: sarif-results
    - name: Dismiss alerts
      if: github.ref == format('refs/heads/{0}', github.event.repository.default_branch)
      uses: advanced-security/dismiss-alerts@v1
      with:
        sarif-id: $[[ steps.analyze.outputs.sarif-id ]]
        sarif-file: sarif-results/java.sarif
      env:
        GITHUB_TOKEN: $[[ secrets.GITHUB_TOKEN ]]
```


## The actual code.

Let's imagine that we have this. Example code is largely meaningless, but hopefully you get the gist; beer is bad, gin is better, but beer is still allowed.

```java
public class Drink {
  @Deprecated(since = "19:00; drink gin() instead")
  public void beer() {  }
  public void gin() { }
}

public class AtTheBar {
  @SuppressWarnings("deprecation")
  public void drinkBeer() {
    new Drink().beer();
  }

  @SuppressWarnings("deprecation")
  public void anotherBeer() {
    new Drink().beer();
  }

  @SuppressWarnings("deprecation")
  public void moreBeer() {
    new Drink().beer();
  }
}
```

CodeQL will raise 3 code scanning alerts (all of them _DeprecatedMethod or constructor invocation_) when the workflow runs. If you view the alert then we can see that the associated rule is `java/deprecated-call`. CodeQL isn't suppressing the alert even though we have the appropriate java deprecation suppression. This seems counter-intuitive to me, but since the _SuppressWarnings_ annotation is quite specific to java, perhaps there's a different AlertSuppression that I've missed.

We can suppress the alerts in 2 ways.
- Add an extra entry to the SuppressWarnings annotation with the rule you want to suppress (very java specific, but has the same scoping capabilities as the SuppressWarnings annotation itself).
- Add a comment at/near the offending line (since go/ruby/javascript/cpp/python/swift/c# have the same comment syntax, this is what we would generally end up doing).

```java
public class AtTheBar {
  @SuppressWarnings({"deprecation", "codeql[java/deprecated-call]"})
  public void drinkBeer() {
    new Drink().beer();
  }

  @SuppressWarnings({"deprecation"})
  public void anotherBeer() {
    new Drink().beer(); // lgtm[java/deprecated-call]
  }

  @SuppressWarnings("deprecation")
  public void moreBeer() {
    // codeql[java/deprecated-call]
    new Drink().beer();
  }
}
```

I found that the comment construct `// codeql[java/deprecated-call]` didn't work as an end of line comment. [The codeql suppression comment code](https://github.com/github/codeql/blob/main/shared/util/codeql/util/suppression/AlertSuppression.qll#L97-L123) is subtly different to the corresponding lgtm suppression comment code in the same file. However, we have 3 (or 2 if we're not java) ways in which we can affect security alerts from CodeQL and that's good enough for my stated intention at the start of this post.

## Final thoughts

I know that my choice of `queries: xxx` is a driving factor here. I can see from the [suites defined](https://github.com/github/codeql/tree/main/java/ql/src/codeql-suites) that I could use `lgtm-full` which will apply the [lgtm-selectors.yml](https://github.com/github/codeql/blob/main/misc/suite-helpers/lgtm-selectors.yml) filter and that gives me the alert-suppression capability without explicitly referencing _AlertSuppression.ql_; this appears to be the only standard suite that enables it. Either way, I think that we would still have to use the _dismiss-alerts_ action to modify the resulting sarif analysis files.

Lombok is still going to cause me trouble with CodeQL but that's an adventure for a different day. I believe that the technique I was using (doing a delombok inline and compiling that) will work, but the linking in terms of source code will be broken because there's no map of the now delombok'd line numbers against where they were generated from in the original file. Hopefully the snippet extract will be enough of a hint that developers can find it in the original source file. Sadly, lombok is more useful than CodeQL in terms of productivity usefulness for developers.
