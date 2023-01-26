---
layout: post
title: "Javadocs with UML diagrams"
comments: false
tags: [development,java]
#categories: [development,java]
published: true
description: "Pictures make people think you care about documentation!"
keywords: ""
excerpt_separator: <!-- more -->
---

What I've often noticed is that javadocs are kind of treated as a second class citizen when it comes a lot of opensource projects; not all projects, there are some with excellent javadocs; but, sadly, more often than not javadocs are an afterthought. Now, I'm as guilty as the next person for not having great javadocs; but you can spruce up your javadocs with some pretty UML diagrams courtesy of plantuml, graphviz and umldoclet...

<!-- more -->

Since gradle is now my build tool of choice all of this is gradle specific; I've done something similar with ant, and I'm sure you could do it using maven, but maven creates a different set of problems. These steps will build you javadocs with UML diagrams on any system that has graphviz installed. On windows you can easily install that using [scoop.sh][]; on linux it's going to be available via your preferred package manager; personally I haven't had much luck with homebrew on the mac vis-a-vis graphviz, the dot executable fails to execute properly; I haven't had the inclination to investigate since I *don't need it*.

## First of all figure out if you have graphviz

Look through the path, and see if dot(.exe) is available; don't forget to add the import at the top of your build script.

```
import org.apache.tools.ant.taskdefs.condition.Os

ext.hasGraphViz = { ->
  def app = "dot"
  if (Os.isFamily(Os.FAMILY_WINDOWS)) {
    app = app + ".exe"
  }
  return System.getenv("PATH").split(File.pathSeparator).any{
    java.nio.file.Paths.get("${it}").resolve(app).toFile().exists()
  }
}

```

## Next include a custom configuration for umldoclet

Add in a custom `umlDoclet` configuration so that you can add the umldoclet jars to that configuration and use them in your javadoc task. For Java 9+ you can use umldoclet version 2+, 1.1.4 is appropriate for Java 8.

```
configurations {
  umlDoclet {}
}

dependencies {

  umlDoclet("nl.talsmasoftware:umldoclet:1.1.4")
}
```

## Create UML javadocs if graphviz is available

We want the javadoc task to create some javadocs regardless of whether the developer actually has graphviz installed or not[^1]; so we patch the bundled javadoc task so it doesn't execute if graphviz is available, _umlJavadoc_ executes instead when we run `./gradlew javadoc`.


```
javadoc {
  onlyIf {
    !hasGraphViz()
  }
  configure(options) {
    options.tags('apiNote:a:API Note:', 'implSpec:a:Implementation Requirements:','implNote:a:Implementation Note:')
    title= componentName
  }
}

task umlJavadoc(type: Javadoc) {
  group 'Documentation'
  description 'Build javadocs using plantuml + graphviz + umldoclet, if dot is available'

  onlyIf {
    hasGraphViz()
  }
  source = sourceSets.main.extensions.delombokTask
  classpath = project.sourceSets.main.compileClasspath
  configure(options) {
    options.tags('apiNote:a:API Note:', 'implSpec:a:Implementation Requirements:','implNote:a:Implementation Note:')
    options.docletpath = configurations.umlDoclet.files.asType(List)
    options.doclet = "nl.talsmasoftware.umldoclet.UMLDoclet"
    options.addStringOption "umlBasePath", destinationDir.getCanonicalPath()
    options.addStringOption "umlImageFormat", "SVG"
    options.addStringOption "umlExcludedReferences", "java.lang.Exception,java.lang.Object,java.lang.Enum"
    options.addStringOption "umlIncludePrivateClasses","false"
    options.addStringOption "umlIncludePackagePrivateClasses","false"
    options.addStringOption "umlIncludeProtectedClasses","false"
    options.addStringOption "umlIncludeAbstractSuperclassMethods","false"
    options.addStringOption "umlIncludeConstructors","false"
    options.addStringOption "umlIncludePublicFields","false"
    options.addStringOption "umlIncludePackagePrivateFields","false"
    options.addStringOption "umlIncludeProtectedFields", "false"
    options.addStringOption "umlIncludeDeprecatedClasses", "false"
    options.addStringOption "umlIncludePrivateInnerClasses", "false"
    options.addStringOption "umlIncludePackagePrivateInnerClasses", "false"
    options.addStringOption "umlIncludeProtectedInnerClasses","false"
    title= componentName
  }
}
javadoc.dependsOn umlJavadoc
```

## Modify your package-info.java

Depending on the version of umldoclet; you may have to modify your package-info.java to refer to your lovely pic. In later versions, it actually generates `object` refs that do that for you in the package summary, so you don't need to. If you do need to, then it's as simple as

```
/**
 * My awesome package.
 *
 * <img alt="UML" src="package.svg"/>
 */
package io.quotidianennui.awesomeness;

```

#### Lombok

If you're using [lombok][], then you might notice that your UML javadocs don't actually contain all the methods you might expect; that's because in the example above we're generating javadocs on the _lombokified_ source code; what we need to do is to delombok first. If you're using the freefair lombok gradle plugin then you need to change the source so that it is the source from the _delombokTask_...

```
source = sourceSets.main.extensions.delombokTask
```

#### CircleCI

If you're using [circleCI][][^2] then you can make sure that graphviz is available during your publish, so that your javadocs are published with the UML built in.

```
  publish:
    docker:
      - image: circleci/openjdk:8-jdk

    working_directory: ~/project

    environment:
      JAVA_TOOL_OPTIONS: -Xmx2G -Djava.security.egd=file:/dev/./urandom
      TERM: dumb

    steps:
      - checkout

      - run:
          name: Configure
          command: |
            sudo apt-get -y update
            sudo apt-get -y install graphviz
            mkdir -p ~/.gradle
            echo "org.gradle.warning.mode=none" > ~/.gradle/gradle.properties

      - restore_cache:
          keys:
            - dependencies

      - run:
          name: Publish
          command: |
            chmod +x ./gradlew
            ./gradlew test publish

      - save_cache:
          paths:
            - ~/.gradle/caches
            - ~/.gradle/wrapper
          key: dependencies
```


[scoop.sh]: https://scoop.sh
[lombok]: https://projectlombok.org
[circleCI]: https://circleci.com

[^1]: I always try to make things work without forcing specific directory structures / installed software on other people.
[^2]: Other CI tools are available; I just happen to use circleci because it's easy to build with both java8 & java11
