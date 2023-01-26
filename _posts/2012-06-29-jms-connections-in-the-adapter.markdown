---
layout: post
title: "JMS Connections in the adapter"
date: 2012-06-29 17:00
comments: false
#categories: [adapter, interlok]
tags: [adapter, interlok]
published: true
description: "JMS Connections, error handling and their variations"
keywords: "java, adapter, jms, integration, interlok"

---

JMS is the messaging platform that the adapter is _almost always_ deployed against. Getting the adapter to work in a consistent way with a number of JMS Providers; some of which aren't as _compliant_ as others; has been key goal of ours for a long time. We're at the stage where I'm happy that the features provided by the adapter allow us to work in a consistent manner with almost any JMS Provider.

<!-- more -->

The base type for any JMS connection is either [PtpConnection][] or [PasConnection][] depending on whether you want to handle JMS Queues or Topics. There are two other types of connection that are interesting; the first can be used as either a produce or consume connection in a channel;  [UseExistingJmsConnection][] means that the adapter re-uses the existing connection endpoint as the other side of the channel. Of course it's going to be pretty meaningless where both the consume and produce connection are [UseExistingJmsConnection][]; it also wouldn't work.

```xml
<channel>
    <consume-connection xsi:type="java:com.adaptris.core.jms.PtpConnection">
    </consume-connection>
    <!-- This simply means that you reuse the PtpConnection above as your
         produce-connection.
    -->
    <produce-connection xsi:type="java:com.adaptris.core.jms.UseExistingJmsConnection"/>
</channel>
```

The other type of connection is [FailoverJmsConnection][] which is actually a proxy for one or more [PtpConnection][] or [PasConnection][] instances. The rationale behind [FailoverJmsConnection] was to transparently support failover for those JMS providers whose APIs don't support seamless failover to backup brokers (WebsphereMQ, I'm looking at you). In most cases now, it's of marginal benefit; but when you are faced with a particularly recalcitrant JMS provider that won't give you the failover that you need it is definitely one to look at.

Connections to the JMS Providers are handled by the provider specific [VendorImplementation] instances. If one isn't available for your preferred messaging platform, then it's possible to use a JNDI vendor implementation which simply retrieves the appropriate connection factory from JNDI. If you end up using [JndiVendorImplementation][] or its variants then then broker-url field has no meaning as the _ConnectionFactory_ that is stored in JNDI should already be pre-configured for access to the correct JMS broker instance.

That's your basics covered; after that, things get a little more tricky when it comes to handling situations that result from the JMS Broker deciding to pack its bags and go on holiday. It always surprises me how often that happens. I like to think that this is the 3rd hardest thing in programming after cache-invalidation and naming things; failing gracefully, and making things behave consistently during the error-recovery phase. Any monkey can make code work, but making it fail gracefully seems to be dying art.

The basic error handling mechanism in JMS is the _ExceptionListener_ interface; if you specify the ExceptionListener for a connection, this will be notified when the connection goes away at any point. So, in all cases, you'd want to have a [JmsConnectionErrorHandler][] (which implements the ExceptionListener interface) configured on the appropriate connection which will end up restarting the channel if and when the connection is terminated. Alternatively use an [ActiveJmsConnectionErrorHandler][] which actively tries to send a message every 'n' milliseconds (5000 by default) onto a temporary destination. The message is marked as NON_PERSISTENT and has a TTL of 5 seconds so _shouldn't_ affect performance. If the send fails, then the broker is deemed to have died, and the component is restarted. In some cases you might have to use an ActiveJmsConnectionHandler, some JMS providers don't always seem to honour the _ExceptionListener_ contract[^1].

_But... and there always is_

There is one situation where you can't have a [JmsConnectionErrorHandler][] configured on each and every connection; that is when you are physically connecting to the same broker for both ends of a channel (if you are bridging queues and topics; it might not be possible for you to use [UseExistingJmsConnection][]). Some very interesting things used to happen if you did; in the end we couldn't reliably guarantee restarts of the affected channel so we put a check so that it caused an error upon initialisation. The way the check works is actually very simplistic; it simply checks the broker-url element for equality, and if they are, then it reports the exception _"com.adaptris.core.CoreException: This channel has been configured with 2 ErrorHandlers that are incompatible with each other"_.

It may just be that you're getting the error erroneously; if one of the connections is a JNDI connection, then the broker-url may not be configured; if you're a copy-and-paster then you might have a broker-url copied over from your paste buffer; just make sure to put in a unique value into the broker-url field for JNDI connections.

```xml
<channel>
    <consume-connection xsi:type="java:com.adaptris.core.jms.PtpConnection">
      <broker-url>SomeDummyValue</broker-url>
      <vendor-implementation xsi:type="java:com.adaptris.core.jms.jndi.StandardJndiImplementation">
        <jndi-params>
          <key-value-pair>
            <key>java.naming.factory.initial</key>
            <value>com.sonicsw.jndi.mfcontext.MFContextFactory</value>
          </key-value-pair>
          <key-value-pair>
            <key>com.sonicsw.jndi.mfcontext.domain</key>
            <value>Domain1</value>
          </key-value-pair>
          <key-value-pair>
            <key>java.naming.provider.url</key>
            <value>tcp://localhost:2506</value>
          </key-value-pair>
          <key-value-pair>
            <key>java.naming.security.principal</key>
            <value>Administrator</value>
          </key-value-pair>
          <key-value-pair>
            <key>java.naming.security.credentials</key>
            <value>Administrator</value>
          </key-value-pair>
        </jndi-params>
        <jndi-name>MyConnectionFactory</jndi-name>
      </vendor-implementation>
    </consume-connection>
    <produce-connection xsi:type="java:com.adaptris.core.jms.PtpConnection">
      <vendor-implementation xsi:type="java:com.adaptris.core.jms.activemq.BasicActiveMqImplementation"/>
      <broker-url>tcp://localhost:61616</broker-url>
    </produce-connection>
</channel>
```

If you have a perfect network, with little or no latency, and you know that you will only have 6.05 seconds downtime a week; then error handling might be moot. Congratulations on your five nines reliability.

So in summary:

1. [PtpConnection][] [PasConnection][] allow JMS Queue/JMS Topic connections
1. [UseExistingJmsConnection][] allows you to re-use the channel's connection as either the produce or consume connection.
1. Use [FailoverJmsConnection][] to handle JMS Brokers without their own transparent failover.
1. Always have a [JmsConnectionErrorHandler][] configured, apart from the single exceptional circumstance.
1. Use [ActiveJmsConnectionErrorHandler][] if during testing you discover that the ExceptionListener is not being triggered.
1. Make sure all JNDI connections have a unique broker-url element (unless of course the special case from rule 4 applies).

[^1]: ActiveJmsConnectionErrorHandler made an appearance largely as a result having to tell our WebsphereMQ customers to install *APAR IY81774* and setting a system property (activateExceptionListener=true) before WebsphereMQ would actually invoke the ExceptionListener in all cases.
[PtpConnection]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/PtpConnection.html
[PasConnection]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/PasConnection.html
[UseExistingJmsConnection]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/UseExistingJmsConnection.html
[FailoverJmsConnection]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/FailoverJmsConnection.html
[VendorImplementation]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/VendorImplementation.html
[JndiVendorImplementation]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/JndiVendorImplementation.html
[JmsConnectionErrorHandler]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/JmsConnectionErrorHandler.html
[ActiveJmsConnectionErrorHandler]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/ActiveJmsConnectionErrorHandler.html





