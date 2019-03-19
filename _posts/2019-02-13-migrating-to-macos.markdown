---
layout: post
title: "Migrating to MacOS for work"
comments: false
tags: [tech]
categories: [tech]
published: true
description: "Some annoyances; a different kind of friction; ultimately a bit meh"
keywords: "macos, windows"
excerpt_separator: <!-- more -->
---

I'm a long time Microsoft DOS/WFW/95/NT/2000/XP/Vista/7/10 user on the desktop; I can make it sing and dance exactly to my tune. Where other people complain about Windows, or get frustrated by it; I never have a problem. Now, Windows isn't perfect, far from it, but it's a basically a tool that causes me minimal friction, letting me get on and solve interesting problems; I don't use it in production, just for my desktop. Last summer, I got so annoyed with the corporate build of Windows 10 that I submitted a requisition for a Macbook Pro; I'm not actually sure which model it is, but it has a touch bar and 16Gb of RAM. Now that I've been using it for about 5 months I thought I'd jot down my thoughts about the transition. My last long-term experience of the Mac was back in 2007/2008; does it create more or less friction a decade later?

<!-- more -->

## Applications ##

There are going to be things that you must have to help you transition; mine are [Spectacle][] - since `windows left/right arrow key` is something I use a lot, and completely missing from the Mac; [Karabiner Elements][] as it's hard to stop using `ctrl-shift-c/v` when that's your muscle memory reflex; [Sensible Side Buttons][] because extra buttons are an actual thing on mice, and I want to use them.

[MacBrew][] has made my life a lot easier but I had to do some dodgy hacks to get it to install on the Mac; this is all to do with how the powers that be have set up the Mac (not how I would...) rather than anything else. The BSD shell tools like `tar` and `readlink` are subtly different to the GNU equivalents so I've had to end up doing stuff to make things portable-ish...

```
function findReadlink()
{
 which greadlink >/dev/null 2>&1
 if [ $? == 0 ]; then
   echo "greadlink"
 else
   echo "readlink"
 fi
}
```

## The Good ##

Things haven't really changed all that much, I still have the toolchain that I need to get stuff done, albeit with some caveats. This is the key thing here, it doesn't actually bother me all that much that I'm using a Mac or Windows; it generally takes me ~10 minutes to switch between the two in the mornings (I make a conscious decision which one to use at the start of the day).

The touchpad is excellent compared to the equivalent Lenovo/Dell/Asus offerings.

Getting the love from all the other developers is nice; now I don't have to _google-fu_ and figure out how to do the stuff on Windows. This was already on the wane because of docker but it always made me a trifle sad that if you didn't't have any skin in the Microsoft development enviroment game (after all my primary development platform is the JVM), but you had to use Windows, you weren't a trendy developer, and as such, not worthy of developer love.

Docker desktop works with the Cisco VPN, whereas on Windows 10, it never did. This is actually a big plus since I have to be on the VPN all the time now because reasons...

It has forced me to be more platform neutral; I'm now using docker to host tiddywiki (which I use to write notes); I will probably end up using docker to host javadocs so that I can work offline.

## The Bad ##

The keyboard is still my biggest gripe; I'm just not happy with it; the layout is wrong and chiclet keys are shit and will always be shit. I grew up with the BBC Model B; learnt to touch type on a british layout typewriter; so this counts as friction. I can map the keyboard to British PC when I have an external keyboard plugged in. I can even have it mapped to British PC keyboard with just the laptop keyboard but of course Apple in its infinite wisdom thinks that the laptop keyboard is special and the _backtick_ key should stay as labelled (bottom left of a Mac UK keyboard screen) when it should really be where the _paragraph mark_ key is (top left). The paragraph mark key is the `\` key when on the laptop; when I have an external keyboard plugged in everything is in the right place. At least I suppose the `@` key is mapped correctly so I don't make loads of mistakes typing email addresses.

The touch bar is pointless; I have it setup to only show the expanded control strip (which gives me basically the media keys) with overrides for certain apps where I do use the function keys a lot; a non-tactile `esc` key doesn't help with VI. I only see the touch bar when I'm using the laptop without additional monitors.

Outlook; required by policy since Mail.app can't be started; isn't as good as the Windows version. I'm making do, but I'm really missing quick actions and being able to edit the toolbar. Being able to edit the toolbar would allow me to fit things into my workflow, such as creating appointments from emails (rather than meetings) since I use appointments to remind me to __reply to emails__. Interestingly because Mail can't be started, it actually causes a bunch of other problems because of the nature of the default application (which I can't change, again, not the Mac, but more a corporate-policy-issue),

I've actually gone back to using [midnight commander][] and [vifm][] on the commandline because Finder is so rubbish. I don't think Windows Explorer is actually __good__ but compared to Finder it's like being in charge of a machine-gun nest against a cavalry charge.

_Grab_ is just not as good as _Snipping Tool_; the Windows version with its built in annotation/highlight makes it easy to do mark-up screenshots and the like, it's just not as easy with Grab.

USB-C doesn't float my boat at all; having to buy extra peripherals and cables to get dual monitor support makes me sad; I accept that this is because I'm stuck in USB-A land but equally how many webcams have you seen that come native with a USB-C cable?

The dock seems like a bit of an afterthought, espcially with the menu bar at the top it squashes the vertical real estate (more so since the laptop screen isn't 1080p anyway). I've got it on the right hand side of the screen but I'm not convinced by it. It's a niggle; if you have dual monitors then you get the added bonus of having to look for the menu bar on the wrong screen sometimes, but that's probably just me.

## The Ugly ##

The ugly is all down to how the Macs are managed within our corporate environment; corporate IT seems to be quite Windows centric, so perhaps this is unsurprising; I'm sure there are fixes and workarounds, but life is too short to spend my time trying to fix _problems which shouldn't really be problems if people actually did their fucking job_.

I can't use Skype for Business / Teams / Outlook without being on the VPN; everything gets horribly confused and breaks. I could never use Outlook on Windows without the VPN, but I could certainly use Teams and Skype.

Even though I have administrative access, my administrative access _doesn't work well_ unless I'm on the VPN.

Single sign on is completely broken; I have to sign on multiple times with Safari (or Chrome) whereas on Windows 10 this wouldn't be the case since Edge knows about my domain credentials. Firefox doesn't play well with domain credentials on either platform.

## Summary ##

Having a Mac is useful, since my team is fully on Windows 10, so I get a different point of view. It has a different kind of friction; it's different as opposed to bad; on the whole it doesn't make me want to scream. Given the choice I wouldn't a swap a properly configured Microsoft Surface Pro or the Dell XPS13 Linux edition for a Macbook.

For my personal stuff, I will still continue to use Windows 10. With _WSL_ I get a full linux shell and toolchain; with _WinGit_ I get a good-enough linux-style toolchain; it doesn't cause me any friction and gets out of my way.


[Spectacle]: https://www.spectacleapp.com/
[Karabiner Elements]: https://github.com/tekezo/Karabiner-Elements
[Sensible Side Buttons]: https://sensible-side-buttons.archagon.net
[MacBrew]: https://brew.sh/
[midnight commander]: http://www.midnight-commander.org
[vifm]: https://vifm.info/