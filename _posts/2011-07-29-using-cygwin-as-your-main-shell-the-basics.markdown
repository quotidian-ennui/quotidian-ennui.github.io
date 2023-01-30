---
layout: post
title: "Using Cygwin as your main shell; the basics"
date: 2011-07-29 11:46
comments: false
published: true
#categories: [tech]
tags: [tech]
description: "Setting up Cygwin so that the permissions play nice with other windows programs"
keywords: "cygwin, java"
excerpt_separator: <!-- more -->
---

I use Cygwin all the time, if it wasn't for Microsoft Outlook I would have probably given up the Windows platform a long time ago. That there isn't a PIM out there that is as good as Outlook is a really damning statement in some ways, Outlook isn't that good if you don't have an Exchange environment. No, Google mail + calendar is NOT THAT GOOD.

<!-- more -->
Again, I'm digressing, it's not going to turn into a rant about usability of Thunderbird / Evolution / Apple Mail  (which I thought was truly abysmal on OSX 10.5) vs Outlook.

Cygwin means that all my scripting can be done in bash, and thus portable between environments; because our production environments are almost always RHEL. So, I live in the bash shell all the time, but there are times when I still like to use cmd.exe to do things. I have found that the Cygwin security model doesn't seem to play that nicely with the NTFS user permissions. I can access things fine in cygwin/bash but I can't delete them or they're not visible when I come to try and work on them in the command prompt (oddly, mostly other windows programs seem fine) .

This then, is the one of the few times where I recommend loosening the security straitjacket.
Previously I would use set the environment variable CYGWIN=NONTSEC  and it would be good, but since the cygwin 1.7 we can't do that, so /etc/fstab it is, with a noacl flag on everything and override on the / mount.

```text
# none /cygdrive cygdrive binary,posix=0,user 0 0
C:/cygwin/bin   /usr/bin        ntfs    binary,auto,noacl
C:/cygwin/lib   /usr/lib        ntfs    binary,auto,noacl
C:/cygwin       /               ntfs    override,binary,auto,noacl
none            /cygdrive       cygdrive        binary,posix=0,user,noacl
```


Also, let's talk about the tool that helps you translate between unix style paths and windows ones, we're all pretty familiar with this; it's ever present in any kind of start script that I write for a java program.

```bash
JAR_LIST=`ls -1 lib/*.jar`
for jar in $JAR_LIST
do
  CLASSPATH=$CLASSPATH:$jar
done
```

This won't work.

The java executable doesn't play nice with : separated paths (or even understand /cygdrive/c/ as a path). You'll need to use cygpath to fix up the classpath into Windows format prior to invoking java.exe; this is easy enough to do, you just have to detect whether or not you're running under cygwin or not

```bash
cygwin=false
case "`uname`" in
  CYGWIN*) cygwin=true ;;
esac
CLASSPATH="./config"
JAR_LIST=`ls -1 lib/*.jar`
for jar in $JAR_LIST
do
  CLASSPATH=$CLASSPATH:$jar
done
if $cygwin; then
  LOCALCLASSPATH=`cygpath --path --mixed "$CLASSPATH"`
  export JAVA_HOME="/cygdrive/c/java/jdk"
else
  LOCALCLASSPATH=$CLASSPATH
  export JAVA_HOME="/opt/java/jdk1.6"
fi
$JAVA_HOME/bin/java -cp "$LOCALCLASSPATH" org.apache.camel.spring.Main
```

