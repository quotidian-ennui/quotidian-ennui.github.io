---
layout: post
title: "Dynamic Environment Variables"
comments: false
tags: [tech]
categories: [tech]
published: true
description: "I use direnv; I can't make up my mind about my preferred shell/platform combination"
keywords: ""
excerpt_separator: <!-- more -->
---

I've been using [direnv](https://direnv.net) to control my environment variables on a per-directory basis for a while. It all really started because I needed to use my personal AWS credentials for some projects and my corporate AWS credentials for others. While it was certainly possible, the hoops I had to jump through to try and provision KMS against my corporate credentials just made me lose the will to live. Sometimes it's just more expedient to use my personal AWS credentials depending on what technology I want to play around with.

I'm back on Windows after a couple of years with a Mac. I might eventually go back to a Mac but at the moment the lack of _arm64_ docker images for the things that I commonly use makes me a little wary. Windows means I that use [scoop.sh](https://scoop.sh) to install software, but I will use a combination of Windows git-bash, WSL v1 and WSL v2 depending on my mood. WSL v2 is faster to startup, but has crap performance when attaching to your windows filesystem. WSL v1 has better performance against the windows filesystem but takes more time to startup because of corporate AV scanning. This just means more hoops for me to make my direnv configuration consistent across all 3 bash instances.

<!-- more -->

## Ubuntu vs direnv


Ubuntu bundles with an older version of direnv; at the time of writing it's 2.21, whereas scoop has installed 2.30.3. That means I need to make sure that I update the direnv standard library on WSL every once in a while: `wget -O ~/.config/direnv/direnvrc https://raw.githubusercontent.com/direnv/direnv/master/stdlib.sh`


## IP address on git-bash/WSL/WSL2

I work with AWS a fair amount and running localstack in docker is something I do quite often; I just expose the required ports via docker-compose.

Due to how the AWS SDK works, if you use a custom endpoint and address it via a DNS name, it may use DNS based access which ultimately means trying to connect to `zzlc-s3-work.localhost` when accessing S3 buckets. Changing your custom endpoint to be an IP address means things work fine. If I'm running the process on my local machine then that's fine; it's just `http://127.0.0.1:4566`. If I've decided to run my services via another docker-compose file, then it's a slightly different proposition. I know I could do something funky with `docker network` but there is still the problem that I don't necessarily _know the IP address of the localstack, wherever it's running_.

Of course I don't need to know the IP address of the localstack process running inside docker, I just need to know my own physical machines IP address depending on the shell that I'm running in. After opening up all the shells this is what I've come up with. I find it useful as a local `.envrc.local` file that can be sourced by direnv as required. WSL v2 works but isn't strictly correct; provided a WSL v2 console is running then containers running via docker have access to your local machine via that IP Address.

```bash
#!/bin/bash

function windows_hostip() {
  # hostname -I doesn't work on git-bash because it's from coreutils
  local hostip=$(ping -n 1 -4 host.docker.internal | grep -i "Reply from" | cut -d' ' -f3 | cut -d":" -f1)
  echo $hostip
}

function wsl_hostip() {
  # WSL1 has multiple addresses and the "real ip appears to be the last one"
  # WS2 only has one...
  local ipAddrs=$(expr "$(hostname -I)" : '[[:space:]]*\(.*\)[[:space:]]*$')
  local ipAddrArray=($ipAddrs)
  echo ${ipAddrArray[-1]}
}

function wslVersion() {
  # The detection here is uncertain but on my version of WSL1 it's a wslfs
  # if [ $( mount -t lxfs | grep '^rootfs' -c ) -gt 0 ]; then
  if [ $( mount -t wslfs | grep '^rootfs' -c ) -gt 0 ]; then
    echo "1"
  else
    echo "2"
  fi
}

function derivePlatform() {
  local uname=$(uname)
  if [ -n "${WSL_DISTRO_NAME}" ]; then
    echo "WSL$(wslVersion)"
  else
    echo $uname
  fi
}

case "$(derivePlatform)" in
  CYGWIN*|MINGW*|MSYS* )
    export LOCALSTACK_ENDPOINT="http://$(windows_hostip):4566"
    ;;
  WSL*)
    export LOCALSTACK_ENDPOINT="http://$(wsl_hostip):4566"
    ;;
  *)
    # hostname -I will probably work on other Linux platforms?
    export LOCALSTACK_ENDPOINT="http://$(wsl_hostip):4566"
    ;;
esac
```

## Putting it all together

After that it's just a case of composing everything so you get the right behaviour.

- Use env_file inside docker-compose to refer to a file.
```
  interlok:
    build:
      context: .
      dockerfile: ./src/main/interlok/docker/Dockerfile
    env_file:
      - .env
```
- Inside .env set the real environment variable as required : `AWS_CUSTOM_ENDPOINT=${LOCALSTACK_ENDPOINT}`
- Make .envrc resolve `LOCALSTACK_ENDPOINT`
```
$ cat .envrc
source_env_if_exists .envrc.local
dotenv_if_exists .env
```
