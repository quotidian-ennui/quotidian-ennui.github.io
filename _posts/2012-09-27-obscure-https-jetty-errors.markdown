---
layout: post
title: "HTTPS Jetty error"
date: 2012-09-28 13:00
comments: false
#categories: [adapter, interlok]
tags: [adapter, interlok]
published: true
description: "Figuring out an obscure jetty error in the adapter"
keywords: "java, adapter, jetty, integration, interlok"
excerpt_separator: <!-- more -->
---

Recently our integrations team have been deploying some HTTPS enabled adapters to service some customers who wanted to POST requests into our hub infrastructure. Interestingly they encountered a problem which they came to me with. Basically, during testing with one particular customer they found that there was excessive continuous logging which ended up raising a red flag via some our file system monitoring processes (I did have a little chuckle at their work-around initially).

<!-- more -->

The error message was a continual stack trace along these lines being logged to the adapter log file, the adapter was still working and happily processing requests from other partners:
```text
2012-09-25 13:22:03,576 DEBUG [qtp4349625-31] [log] EXCEPTION
javax.net.ssl.SSLException: Connection has been shutdown: javax.net.ssl.SSLException: java.net.SocketException: Connection reset
        at com.sun.net.ssl.internal.ssl.SSLSocketImpl.checkEOF(SSLSocketImpl.java:1255)
        at com.sun.net.ssl.internal.ssl.AppInputStream.read(AppInputStream.java:65)
        at org.eclipse.jetty.io.ByteArrayBuffer.readFrom(ByteArrayBuffer.java:388)
        at org.eclipse.jetty.io.bio.StreamEndPoint.fill(StreamEndPoint.java:132)
        at org.eclipse.jetty.server.bio.SocketConnector$ConnectorEndPoint.fill(SocketConnector.java:209)
        at org.eclipse.jetty.server.ssl.SslSocketConnector$SslConnectorEndPoint.fill(SslSocketConnector.java:612)
        at org.eclipse.jetty.http.HttpParser.parseNext(HttpParser.java:289)
        at org.eclipse.jetty.http.HttpParser.parseAvailable(HttpParser.java:214)
        at org.eclipse.jetty.server.HttpConnection.handle(HttpConnection.java:411)
        at org.eclipse.jetty.server.bio.SocketConnector$ConnectorEndPoint.run(SocketConnector.java:241)
        at org.eclipse.jetty.server.ssl.SslSocketConnector$SslConnectorEndPoint.run(SslSocketConnector.java:664)
        at org.eclipse.jetty.util.thread.QueuedThreadPool$3.run(QueuedThreadPool.java:529)
        at java.lang.Thread.run(Thread.java:619)
Caused by: javax.net.ssl.SSLException: java.net.SocketException: Connection reset
        at com.sun.net.ssl.internal.ssl.Alerts.getSSLException(Alerts.java:190)
        at com.sun.net.ssl.internal.ssl.SSLSocketImpl.fatal(SSLSocketImpl.java:1611)
        at com.sun.net.ssl.internal.ssl.SSLSocketImpl.fatal(SSLSocketImpl.java:1574)
        at com.sun.net.ssl.internal.ssl.SSLSocketImpl.handleException(SSLSocketImpl.java:1538)
        at com.sun.net.ssl.internal.ssl.SSLSocketImpl.handleException(SSLSocketImpl.java:1483)
        at com.sun.net.ssl.internal.ssl.AppInputStream.read(AppInputStream.java:86)
        ... 11 more
Caused by: java.net.SocketException: Connection reset
        at java.net.SocketInputStream.read(SocketInputStream.java:168)
        at com.sun.net.ssl.internal.ssl.InputRecord.readFully(InputRecord.java:293)
        at com.sun.net.ssl.internal.ssl.InputRecord.read(InputRecord.java:331)
        at com.sun.net.ssl.internal.ssl.SSLSocketImpl.readRecord(SSLSocketImpl.java:789)
        at com.sun.net.ssl.internal.ssl.SSLSocketImpl.readDataRecord(SSLSocketImpl.java:746)
        at com.sun.net.ssl.internal.ssl.AppInputStream.read(AppInputStream.java:75)
        ... 11 more
2012-09-25 13:22:03,576 DEBUG [qtp4349625-31] [log] EXCEPTION
javax.net.ssl.SSLException: Connection has been shutdown: javax.net.ssl.SSLException: java.net.SocketException: Connection reset
        at com.sun.net.ssl.internal.ssl.SSLSocketImpl.checkEOF(SSLSocketImpl.java:1255)
        at com.sun.net.ssl.internal.ssl.AppInputStream.read(AppInputStream.java:65)
        at org.eclipse.jetty.io.ByteArrayBuffer.readFrom(ByteArrayBuffer.java:388)
        at org.eclipse.jetty.io.bio.StreamEndPoint.fill(StreamEndPoint.java:132)
        at org.eclipse.jetty.server.bio.SocketConnector$ConnectorEndPoint.fill(SocketConnector.java:209)
        at org.eclipse.jetty.server.ssl.SslSocketConnector$SslConnectorEndPoint.fill(SslSocketConnector.java:612)
        at org.eclipse.jetty.http.HttpParser.parseNext(HttpParser.java:289)
        at org.eclipse.jetty.http.HttpParser.parseAvailable(HttpParser.java:214)
        at org.eclipse.jetty.server.HttpConnection.handle(HttpConnection.java:411)
        at org.eclipse.jetty.server.bio.SocketConnector$ConnectorEndPoint.run(SocketConnector.java:241)
```

They verified the problem running on a local adapter, and it didn't take me too long to figure out what the problem was. Basically they were using a self-signed certificate and what our customer had done was to try and connect to the adapter using his browser; and once he'd done that it started generating all the spurious logging. The root cause is the termination of the SSL negotiation while the browser comes up with the _This connection is untrusted because we can't verify the sites identity; do you want to continue?_ page. Easy to fix once you know what the problem is.

There are two solutions to the problem, and we used both in the end.

- First and best, use a properly signed certificate from Thawte / Verisign / whoever, so long as it's not DigiNotar.
    - Once we imported the self-signed certificate into Firefox, the stack trace logging went away
- Second and most expedient, change log4j.xml to simply not output the logging because it's not terribly relevant and can be safely ignored (it's logging @ DEBUG level, and it's information that you don't care about).

```xml
<logger name="org">
  <level value="FATAL"/>
</logger>
```

## Actually using a real certificate

Anyway, this led them down another twisty rabbit warren of confusion. It turns out that our standard certificate was created using openssl for our apache instances (i.e. using _openssl genrsa_, and all that business) which meant that the private key and certificate were stored in separate files rather than in a single PKCS12 file. This did present some trouble when trying to use something like keytool or [portecle](http://portecle.sourceforge.net) to try and generate a keystore for use by jetty. This isn't rocket science; and [google](http://lmgtfy.com/?q=import+certificate+private+key+keystore) can give you the answers; the top 2 links basically are the links you need (stackoverflow, and agentbob.info)

We ended up going with the instructions from [http://www.agentbob.info/agentbob/79-AB.html](http://www.agentbob.info/agentbob/79-AB.html) which can be basically condensed down to the following steps:

* Create DER encoded files of all PEM files.
* Concatenate all the certificates into a single file, creating a certificate chain (this will depend on whether or not your CA provider gives you intermediate certificates which you need to configure using _SSLCertificateChainFile_)
* Modify [ImportKey.java](http://www.agentbob.info/agentbob/80/version/default/part/AttachmentData/data/ImportKey.java) slightly to resolve a minor issue[^1]
    * Change line 147 from <code>certs = (Certificate[])c.toArray();</code> to <code>certs = (Certificate[])c.toArray(new Certificate[0]);</code>
* Compile and execute ImportKey.java

```console
[lchan@acheron ~]$ # Here our files are mycert.pem (the signed cert from the CA), mykey.pem (our private key file),
[lchan@acheron ~]$ # intermediate.pem (the intermediate certificates for the chain).

[lchan@acheron ~]$ # Generate mykey.der:
[lchan@acheron ~]$ openssl pkcs8 -topk8 -nocrypt -in mykey.pem -inform PEM -out mykey.der -outform DER

[lchan@acheron ~]$ # Generate mycert.der:
[lchan@acheron ~]$ openssl x509 -in mycert.pem -inform PEM -out mycert.der -outform DER

[lchan@acheron ~]$ # Generate intermediate.der:
[lchan@acheron ~]$ openssl x509 -in intermediate.pem -inform PEM -out intermediate.der -outform DER

[lchan@acheron ~]$ # Merge the certificate and the intermediate DERs:
[lchan@acheron ~]$ cat mycert.der intermediate.der >> all.der

[lchan@acheron ~]$ javac ImportKey.java
[lchan@acheron ~]$ java ImportKey mykey.der all.der
Using keystore-file : ~/keystore.ImportKey
Certificate chain length: 2
Key and certificate stored.
Alias:importkey  Password:importkey

```

Afterwards you can use keytool/portecle to modify the keystore alias/passwords and whatnot as desired and start using them in jetty.

[^1]: This is so you don't have to go through the comments...
