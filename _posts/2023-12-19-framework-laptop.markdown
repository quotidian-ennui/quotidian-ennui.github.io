---
layout: post
title: "The masochistic joy of Windows"
comments: false
tags: [tech]
published: true
description: "I bought a framework laptop, pre-built Windows; it needs stickers now."
keywords: ""
excerpt_separator: <!-- more -->
---

I recently purchased a [framework laptop][]; the Framework 13 13th Gen Intel variant. I have no complaints about the hardware, and I'm loving the hardware switch for the webcam & microphone. I have yet to find any niggles with it (though I have only had it for ~1 week). This acts as documentation for my setup to dual boot Windows (on NVMe) and Ubuntu (on 1Tb expansion).

<!-- more -->

It takes a certain type of masochism to use Windows as your primary driver if you're hard-trained as a Unix developer by choice (I had a SCO x86 install back in the day, and probably grew my developer chops on HP-UX). I find Macs get more in the way than Windows (mostly the keyboard), and I have every intention on dual booting this way to see if I can live without MS Outlook (it's a fucking low bar to hurdle, but I don't feel that there's anything out there that's close).

There are choices here to auto-provision laptops if you're an organisational entity; most of those choices don't seem fit into the world where you only might need to use it every 3 years. A lot of this is because I've _chosen not to sync some of these settings online_; that is an explicit choice that I've made, because I know they'll get it wrong and annoy me even more.

## Post Windows install

> I realise that I might be able to do something with [Desired State Configuration][] but _really?, really really?_

![its not worth it](https://imgs.xkcd.com/comics/is_it_worth_the_time.png)

That's the obligatory reference to XKCD done; with the framework laptop I hope to be able to extend out past 3 years by being able to replace the mainboard / battery etc. as needs be for longevity. It's taken ~1 day for the manual windows nonsense, which equates to lets say ~2hours per year.

- Remove all the shitty default programs that don't interest me (_Solitaire Connection_ anyone?) that seem to keep coming back from time to time; I'm pretty sure that I could probably group policy this out of existence but I never wanted to be a Windows admin.
- Install Microsoft Office and try and make it use my O365 account rather than my MS personal account (there's a bunch of reasons why I have 2 accounts).
  - Microsoft is saving my outlook settings "online"; it doesn't seem to do much with toolbar customisations so I have to revisit and remove all the "share with teams/ skype for business" bullshit.
  - What fun there is to be had with _Office TeachingCallouts_.
- Installing WSL2 and doing the WSL shutdown cycle because you have to edit `C:/users/.../.wslconfig` & `/etc/wsl.conf` in WSL2
- (Create your Ubuntu installer); I have a USB-A expansion card, so I just did something with Rufus.

## Get ready to dual boot

- ~~Turn off bitlocker~~ (make sure you _know what your recovery key is_)
- Shrink the Windows partition by 100Mb

Arguably if you're going to disable bitlocker then you can just install Ubuntu alongside the Windows Boot Manager and everything will be fine anyway; I'm doing it like this to keep things nice and separate.

## Installing Ubuntu

- F12 to get the boot menu, and boot using USB key.
- Start installing Ubuntu, but at the point of _Type of Installation_; we're _Something Else_ so we get some manual partitioning fun.
  - Create a 100Mb System EFI partition in the free space on the NVMe drive
  - Use as much or as little of the expansion card for Linux (524288Mb for me) mounted as `/`.
  - Change the boot loader to live on `nvme0n1p5` (or whatever the new partition is called)
- Install/Update/Reboot dance until Ubuntu is happy
  - By now I will have done a `sudo update-alternatives --set editor /usr/bin/vim.basic` and a visudo `NOPASSWD:ALL`
  - `sudo echo "GRUB_GFXMODE=1024x768" >> /etc/default/grub` to force the resolution of the GRUB menu.
  - (`sudo echo "GRUB_PRELOAD_MODULES="part_gpt part_msdos"" >> /etc/default/grub`) since I was investigating stuff, this didn't help, but it doesn't hurt since you can see they're loaded anyway.
  - `sudo update-grub`

- Reboot and enter Windows, at which point you may need to type in your bitlocker key (this does depend on the route you took to enter the Windows bootloader; if it was GRUB then you'll need to type it in, if it was the Windows Boot Manager then you probably won't).

## The generic post install parts.

Most of these steps are OS agnostic other than `scoop`; most of it is scripted with some input required.

- Web browsers with the password managers (including the firefox mozilla sync cycle).
  - Logging into github and making sure that cookie auto-delete knows to whitelist it.
- Logging into github and generating a PAT for the machine...
- `scoop import import.json`
  - There are still manual 'ungoogled-chromium' shenanigans.
- Bootstrap the Ubuntu/WSL2 dev tooling (which is why I now have [ubuntu-dpm][])
- Creating a new GPG key and configuring [gopass][]
- `sdkman | nvm | rvm | pyenv`

## Summary

The end result is a dual boot that is working OK with a single issue. In either OS, the laptop is performing nicely.

- A reboot from Windows results in the GRUB shell; `exit` resulting in another reboot restores GRUB's normal operation.
- A shutdown from Windows and power-on is a normal GRUB event.
- A reboot from Ubuntu is (as you expect) fine.

This is apparently because post Windows reboot the framework expansion card is _missing_. On a power-on boot we have `(hd0,msdos5)` && `(hd1,gpt5)` as valid partitions to boot from. On a Windows 11 reboot we only have `(hd0,gpt5)`[^1]. I'm going to be scratching this itch pretty hard but my interim workaround is to

- Change _new boot priority_ in the BIOS to be `first` rather than `auto`
- Make Windows first
- Change the timeout on to be 5 seconds

This means I have 5 seconds to press F12 and get into the boot menu.


[^1]: This suggests that Windows had disavowed all knowledge of the expansion card...
[framework laptop]: https://frame.work/gb/en
[gopass]: https://github.com/gopasspw/gopass
[ubuntu-dpm]: https://github.com/quotidian-ennui/ubuntu-dpm
[Desired State Configuration]: https://learn.microsoft.com/en-us/powershell/scripting/dsc/overview
