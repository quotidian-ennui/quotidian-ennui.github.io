---
layout: post
title: "Windows Scripting Host as an Administrator"
date: 2011-09-30 08:58
comments: false
published: true
#categories: [tech]
tags: [tech]
description: "Starting WSH scripts with elevated credentials"
keywords: "windows7, vmware, wsh, uac"
excerpt_separator: <!-- more -->
---

If you're like me then perhaps you often don't want your network interfaces to be enabled all the time. You might not have a hardware switch to turn off your wireless and going to Network and Sharing -> Change Adapter Settings right click enable / disable seems like such a chore especially when my default group policy means that you're prompted for your password each time.

Well, the windows scripting host is your friend; here's how to toggle your network interfaces

<!-- more -->

First of all name your network interfaces something clear; I'm going to use "VMWare-1" and "VMWare-2" because I like to disable the VMWare stuff until I'm actually using it, it used to cause a whole host of suspend/resume issues for me.

Then, you'll need a script to toggle the interfaces on and off which is what this does, if it's enabled, it'll disable it,  and vice versa. I'm going to call it vmnet-toggler.vbs (the .vbs will associate it with the wscript exe by default)

```vbnet
strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapter Where NetConnectionID='VMWare-1' OR NetConnectionID='VMWare-2'")

For Each objItem in colItems
  Select Case objItem.NetEnabled
    Case 0
      objItem.Enable
    Case -1
      objItem.Disable
  End Select
Next
```

If you just run this, it won't work of course, unless of course you're an Administrator and UAC is disabled. Only those with weak minds disable UAC, so it won't have worked.

What you need is a script to call this script with admin rights; that's all you need to do, we're looking for the admin script in the same directory as this script.

```vbnet
Set objShell = CreateObject("Shell.Application")
Set FSO = CreateObject("Scripting.FileSystemObject")
strPath = FSO.GetParentFolderName (WScript.ScriptFullName)
scriptName = strPath & "\vmnet-toggler.vbs"

If FSO.FileExists(scriptName) Then
     objShell.ShellExecute "wscript.exe", _
        Chr(34) & scriptName & Chr(34), "", "runas", 1
```

You can put a shortcut to the second script in the start menu or whatever, you will be asked to type in your password on the secure desktop prompt, but that's only the once for all the network interfaces you want to disable.

If you're super lazy then perhaps you can edit your group policy so that Administrators are "auto-elevated without prompting", but I wouldn't recommend that.
