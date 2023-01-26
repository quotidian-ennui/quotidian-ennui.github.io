---
layout: post
title: "FIPS certified algorithms"
date: 2014-05-29 17:00
comments: false
#categories: [adapter, interlok]
tags: [adapter, interlok]
published: true
description: "Using FIPS certified algorithms with Interlok"
keywords: "integration, FIPS"

---

FIPS compliance is all the rage in some sectors. Our formal statement has always been that Interlok can be configured to be as FIPS compliant as the underlying JVM. All encryption/SSL duties are delegated to the JCE and JSSE layers respectively. Failure to support FIPS algorithms isn't normally a product issue, it's a java virtual machine configuration issue.

<!-- more -->

We recently had a support case, which after some chinese whispers involving our support partner, turned out to be that our customer couldn't get Interlok connected to their WebsphereMQ instance using some specific FIPS cipher suites (non-FIPS SSL was working fine). Basically there was always an exception _'MQRC_UNSUPPORTED_CIPHER_SUITE'_; this was expected because the cipher suite that they had selected was a FIPS compliant one, which the JVM, _out of the box_ doesn't support (you have to configure SunJSSE to work in strict FIPS mode). What was odd was that they said it used to work with the WebsphereMQ 6.0 java libraries, but not with the WebsphereMQ 7.0 jars. So the question then becomes; what do we need to do to make a JVM use a FIPS compliant provider?

## The right way ##

The java virtual machine needs to have a FIPS certified provider, here's a list of [certified products][Certified FIPS] so there shouldn't be a problem selecting and purchasing an add-on for the JVM. Once you've made your choice, then all you have to do is configure the JVM to use that provider. This will generally involve modifying `$JAVA_HOME/jre/lib/security/java.security`; adding their providers and putting their jars into the associated `$JAVA_HOME/jre/lib/ext` directory. Each of the providers will have instructions on how to configure their product for the JVM.  You may also have to switch the default SunJSSE provider to use your FIPS JCE provider if they don't provide their own JSSE wrapper as per the [Oracle Docs][]. Alternatively you could compile [Mozilla NSS][] and configure the JVM to use that. As FIPS is an ongoing process, for NSS to satisfy all of the FIPS requirements, you would have to download a pre-built binary on a specific platform that has been certified; the Oracle JVM comes with a wrapper that can use NSS directly.

Sometimes though, you don't want to do things the right way...[^1]

## The quick way ##

If you install Websphere MQ Explorer / Websphere MQ client then you will get a bundled virtual machine which is used to run the eclipse based UI. Switch Interlok to use that JVM instead. The IBM JRE comes pre-built with the FIPS compliant algorithms and providers already, so you don't really need to do anything else. This will mean you don't have much control over the version of the JRE that you use, you're stuck with the one that is shipped with the version of WebsphereMQ that you downloaded[^2]. There may also be problems with this if you have native code that is being loaded by the IBM JRE depending on the architecture.

## The less quick and dirtier way ##

Supposing you want to keep using your existing JVM, but you want to use the _IBMJSSE2/IBMJCEFIPS_ providers, then provided that you have access to an IBM JRE, then you can manually copy some jars from the IBM JRE into your own JVM instance (I tend to use the `$JAVA_HOME/jre/lib/ext` directory)[^3]. The list of jars that I find sufficient for FIPS SSL can be found below, note that this is not a definitive list, this is just a list that has worked for me; your mileage may vary.

```text

24/04/2013  15:45           214,151 ibmcmsprovider.jar
24/04/2013  15:45           372,479 ibmjcefips.jar
24/04/2013  15:45            98,796 ibmjcefw.jar
24/04/2013  15:45         1,342,292 ibmjceprovider.jar
24/04/2013  15:45           501,704 ibmjsseprovider2.jar
24/04/2013  15:45         1,147,135 ibmpkcs.jar
24/04/2013  15:45           361,080 ibmpkcs11impl.jar

```

After that you need to patch `$JAVA_HOME/jre/lib/security/java.security` to add in the IBMJSSE providers before the default SunJSSE provider, or make sure to use an override java.security file every time you start the JVM (using the `java.security.properties` system property).

```properties

security.provider.1=sun.security.provider.Sun
security.provider.2=sun.security.rsa.SunRsaSign
security.provider.3=com.ibm.crypto.fips.provider.IBMJCEFIPS
security.provider.4=com.ibm.crypto.provider.IBMJCE
security.provider.5=com.ibm.jsse2.IBMJSSEProvider2
security.provider.6=com.sun.net.ssl.internal.ssl.Provider
security.provider.7=com.sun.crypto.provider.SunJCE
.. Rest of the providers below.

```


[Oracle Docs]: http://docs.oracle.com/javase/7/docs/technotes/guides/security/jsse/FIPS.html
[Certified FIPS]: http://csrc.nist.gov/groups/STM/cmvp/documents/140-1/140val-all.htm
[Mozilla NSS]: https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS

[^1]: I can't think of any reasons why you'd want to do FIPS compliance the _wrong_ way.
[^2]: Usual disclaimer applies: you may be violating your license agreement with IBM and terms of use if you do this. Run it past legal first. Just because you can doesn't mean you should
[^3]: Definitely run it past legal first before you do this.