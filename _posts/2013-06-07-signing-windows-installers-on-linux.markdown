---
layout: post
title: "Signing Windows Installers on Linux"
date: 2013-06-07 17:00
comments: false
#categories: [development]
tags: [development]
published: true
description: "Quick Dirty how to sign a windows installer on linux"
keywords: "windows linux authenticode"

---

One of the things that's happened with Windows 8/2012 is that you need to sign your installers or a big fat warning will present itself to the user when they click on it. I'm not exactly sure how having a signed installer protects the user as certifying authorities will sign any old certificate. Anyhow, with the release of 2.9.0 the installer supported Windows 8/2012 without having to run it in compatibility mode; but the warning still presents itself to the user on startup. With the release of 2.9.1 (now in beta) we're going to sign our installers. Hopefully no more warnings when you start the installer (other than UAC prompts).

<!-- more -->

The adapter jars are already signed so we have a valid certificate, so really it's just a case of using that certificate to sign the install.exe after it gets generated. We do all our builds on Linux rather than Windows; using ant no less. The standard way of signing using [signcode][] is clearly windows only (apparently you can run it under WINE, but really, that's far too much effort) so I opted to use [osslsigncode][] instead; osslsigncode is available via either the epel or rpmforge repositories if you're using CentOS or you can just compile it from scratch.

To do the signing, you basically have to export your key from your keystore (I always use [portecle][] for keystore operations) as a PKCS12/PFX file so that you can convert it using openssl; odd that you can't do this directly in portecle, but it only allows private key export as a PKCS12 file; so openssl it is.

```console
openssl pkcs12 -in authenticode.pfx -nocerts -nodes -out key.pem
openssl pkcs12 -in authenticode.pfx -nokeys -nodes -out cert.pem
openssl rsa -in key.pem -outform DER -out authenticode.key
openssl crl2pkcs7 -nocrl -certfile cert.pem -outform DER -out authenticode.spc
osslsigncode -spc authenticode.spc -key authenticode.key -t http://timestamp.verisign.com/scripts/timstamp.dll -in install.exe -out install-signed.exe
```

It looks convoluted, but the only files you need are the .spc and .key file after all of that. How you protect your key afterwards is up to you... Thereafter it's a simple case of writing an ant macro that abstracts the signing of the created executables as a post build step.

```xml
<macrodef name="sign-windows-installers" uri="uri:release">
  <attribute name="builddir" default="${installer.build.dir}" />
  <attribute name="installer-name" default="${installer.name}" />
  <attribute name="code-signer-executable" default="osslsigncode"/>
  <attribute name="spc-file"/>
  <attribute name="key-file"/>
  <sequential>
    <move todir="@{builddir}/Installers/Windows">
      <fileset dir="@{builddir}/Installers/Windows">
        <include name="**/@{installer-name}.exe"/>
      </fileset>
      <mapper type="glob" from="*" to="*.unsigned"/>
    </move>
    <for param="unsigned-installer">
      <fileset dir="@{builddir}/Installers/Windows">
        <include name="**/@{installer-name}.exe.unsigned"/>
      </fileset>
      <sequential>
        <var name="ia.windows.installer.output.dir" unset="true"/>
        <dirname file="@{unsigned-installer}" property="ia.windows.installer.output.dir"/>
        <exec executable="@{code-signer-executable}" dir="@{builddir}/Installers/Windows">
          <arg value="-spc"/>
          <arg value="@{spc-file}"/>
          <arg value="-key"/>
          <arg value="@{key-file}"/>
          <arg value="-t"/>
          <arg value="http://timestamp.verisign.com/scripts/timstamp.dll"/>
          <arg value="-in"/>
          <arg value="@{unsigned-installer}"/>
          <arg value="-out"/>
          <arg value="${ia.windows.installer.output.dir}/@{installer-name}.exe"/>
        </exec>
      </sequential>
    </for>
  </sequential>
</macrodef>
```

```xml
<target name="test-signing" depends="init,macrodef.init">
  <release:sign-windows-installers
     builddir="${build.dir}"
     installer-name="${installer.name}"
     spc-file="${install.module}/authenticode.spc"
     key-file="${install.module}/authenticode.key"
  />
</target>
```


I'm using the antcontrib project to do some funky stuff with the 'var' and 'for' tasks. The [build doctor][] will not approve as [ant-contrib is evil][] for being non-declarative; I myself find it useful to turn ant into a programming language from time to time. Understanding the nature of the rule and why it's a best practise hopefully means that you know when a deviation from it isn't always a bad thing.



[signcode]: http://msdn.microsoft.com/en-us/library/9sh96ycy%28v=vs.80%29.aspx
[osslsigncode]: http://osslsigncode.sourceforge.net/
[portecle]: http://portecle.sourceforge.net/
[build doctor]: http://www.build-doctor.com/
[ant-contrib is evil]: http://www.build-doctor.com/2009/09/21/ant-contrib-the-power-and-the-pain/