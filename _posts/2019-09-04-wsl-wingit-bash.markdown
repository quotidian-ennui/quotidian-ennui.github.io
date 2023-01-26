---
layout: post
title: "Using WSL and Windows Git Bash interchangeably"
comments: false
tags: [development,tech]
#categories: [development,tech]
published: true
description: "Why not both, you shouldn't have to choose; in this instance choice is useful"
keywords: ""
excerpt_separator: <!-- more -->
---

I try to be consistent in my development environments since they are spread across a number of platform: Windows, Linux and latterly Mac because McAfee sucked the performance out of my corporate issued laptop. I'm one of those odd people who happens to use all 3 major platforms actively for development. Scripts have always been _bash_, which means that I need to be able to run bash on my Windows systems; a long time ago it was [Cygwin](https://cygwin.com), but I found I didn't need many of the features that it provided so I ended up using the bash that's provided by [Git for Windows](https://git-scm.com/download/win); I have found that I need rsync to be available to make vagrant provision machines properly. I also like a bit of Windows subsystem for Linux so I have the choice of either installing my tools via [scoop.sh]() or `sudo apt-get`. Sadly _scoop_ hasn't persuaded me that powershell is my goto shell.

<!-- more -->

Once we have WSL installed; which I always do via [https://docs.microsoft.com/en-us/windows/wsl/install-on-server](https://docs.microsoft.com/en-us/windows/wsl/install-on-server); I often don't even bother trying to access the Windows store; you never know when you're going to trigger those corporate _for your own safety this is disabled_ warnings...

### Get rid of various Ubuntu annoyances.

This is just my own preferences; there's nothing that's terribly interesting here
* `sudo apt-get remove command-not-found` - to remove the helpful, but really not helpful, way in which what ostensibly is a `command not found` message turns into one that suggests you install a package. I don't want that thanks very much
* `sudo update-alternatives --config editor` - switch the editor to a sane one that isn't nano thanks very much.
* `sudo visudo` with `%sudo ALL=(ALL:ALL) NOPASSWD:ALL` - I do understand the security ramifications of that, but if you can start WSL on this machine, I'm already fucked.

### Make sure the mountpoints are the same

This was because I wanted my mount points in WSL to be exactly the same as that for WinGit. I didn't know it at the time, but doing this had the happy side-effect of making docker work nicely. In WSL make sure that your `/etc/wsl.conf` contains (this will make all your drives be mounted as _/c_, _/d_ rather than _/mnt/c_)

```
[automount]
root = /
options = "metadata"
```

### Symbolic links

Since WSL has a different home directory; Make a bunch of symbolic links to where the "real directories" are:

* `ln -s /c/users/lchan/.ant .ant`
* `ln -s /c/users/lchan/.ivy2 .ivy2`
* `ln -s /c/users/lchan/.m2 .m2`
* `ln -s /c/users/lchan/.sbt .sbt`
* `mkdir .gradle && cd .gradle && ln -s /c/users/lchan/.gradle/gradle.properties gradle.properties`

You'll see that gradle is treated slightly differently. That's because of the _gradle daemon_; if you symlink the directory the gradle daemon gets all confused, so it's better to double up on the disk usage. Maven/ANT/Ivy don't care so much, which means you can reuse the existing directories for dependency caching.

### Docker Desktop

Docker is my friend; getting docker and docker-compose working on WSL is key for me. Docker desktop requires Hyper-V, and if you haven't yet installed it, it's probably best if you do the port reservation before you install docker otherwise you have to do the reboot dance. After Docker Desktop is installed you'll need to enable the _Expose daemon on tcp://localhost:2375 without TLS_; this is a fair warning, but since according to _netstat -a_, docker is only bound to `127.0.0.1:2375`, it's probably safe enough. I did all of these via an Administrators Powershell; YMMV.

* `netsh interface ipv4 show excludedportrange protocol=tcp` - If this includes port 2375; then the expose daemon on localhost:2375 without TLS will not work, and you might already have Hyper-V enabled
* `dism.exe /Online /Disable-Feature:Microsoft-Hyper-V` - Disable Hyper-V; reboot now before the next bit
* `netsh int ipv4 add excludedportrange protocol=tcp startport=2375 numberofports=1` - Reserve 2375
* `dism.exe /Online /Enable-Feature:Microsoft-Hyper-V /All` - enable Hyper-V; reboot again before the next bit.
* `netsh interface ipv4 show excludedportrange protocol=tcp` - which should give you a little asterisk by 2375; showing you that you have an administered port exclusion.
* Install Docker Desktop; enable the _Expose Deamon on tcp://localhost:2375_ works, run some images as you like in a WinGit shell; how about RabbitMQ just for a change from the `hello-world` image.
```
docker pull "rabbitmq:3-management-alpine"
winpty docker run --name rabbitmq -it --rm -p127.0.0.1:5672:5672 -p127.0.0.1:15672:15672 \
  -e RABBITMQ_DEFAULT_VHOST=vhost -e RABBITMQ_DEFAULT_USER=admin -e RABBITMQ_DEFAULT_PASS=admin \
  -h rabbitmq.local "rabbitmq:3-management-alpine"
```
* Install docker according to their [Ubuntu 18.04 instructions](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
* Install docker-compose either from their binary distribution or using `pip3 install --user docker-compose`; I already had python3 because I needed the AWS CLI.
* `export DOCKER_HOST=tcp://localhost:2375` in the usual way (you know, `~/.bashrc` or whatever is your preference for these things)
* try a `docker images` from WSL which should show you the RabbitMQ image you downloaded previously.

### Conclusion

Apparently WSL has kinda crappy IO performance; I haven't found that it's such a huge difference that I can't use WSL as my main development shell for java. I will use WSL exclusively where I know that the tools in question love Linux/Mac more than they love Windows so things like ruby via [rvm.io](https://rvm.io)[^1]. I also use WSL exclusively if I want to dynamically switch between java 8 and java 11 via an exported function in my bash profile

```
j8() {
  sudo update-java-alternatives -s java-1.8.0-openjdk-amd64 >/dev/null 2>&1
  export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
  java -version
}

j11() {
  sudo update-java-alternatives -s java-1.11.0-openjdk-amd64 >/dev/null 2>&1
  export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
  java -version
}
```

[^1]: Yes, a lot those tools are available on Windows, but it's nice to just be able to do things from the shell w/o having UI installers to contend with, especially if there isn't a scoop package.
[scoop.sh]: https://scoop.sh
