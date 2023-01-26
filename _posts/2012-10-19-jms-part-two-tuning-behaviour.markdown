---
layout: post
title: "JMS Part Two; tuning behaviour"
date: 2012-10-19 17:00
comments: false
#categories: [adapter, interlok]
tags: [adapter, interlok]
published: true
description: "Second in series about the Adapter + JMS"
keywords: "java, adapter, jms, integration, interlok"

---

JMS is the bread and butter of the adapter; it's been supported even since it was first released. We use JMS as the backbone of all our community deployments; we aren't picky about the vendor, so long as it supports JMS 1.0 then the adapter will quite happily work with it. I've written previously about [JMS Connections and the adapter][]. Most of time, it _just works_; the problems that you might be having will be configuration based because the default behaviour _just aren't suitable for your environment_.

<!-- more -->

## JMS Message Types and translation

All the standard JMS types are supported, _BytesMessage, TextMessage, MapMessage, ObjectMessage_ are supported in the adapter via their associated [MessageTypeTranslator][] implementations. Of course, vendor specific message types are also supported; such as Progress SonicMQ's XMLMessage type. There's also [AutoConvertMessageTranslator][] which is primarily useful when configuring a consumer. By convention, we like you to know what type of message is being delivered onto the JMS destination that the adapter is receiving messages from; of course, sometimes there might be a mix of message types, or maybe you just don't know. [AutoConvertMessageTranslator][] automagically handles the standard types by delegating to the correct [MessageTypeTranslator][] implementation so if it thinks the [javax.jms.Message][]  is a [TextMessage][] then it will delegate to [TextMessageTranslator][]. The mapping from [MapMessage][] is quite simplistic: all name value pairs are assumed to be strings, and they are converted directly into  metadata; the resulting payload is empty.

## JMSCorrelationID header

The JMS correlation ID is used, well for correlating things; typically a request with a reply message. If you need to handle the correlation id, then you need to configure a [CorrelationIdSource][] implementation. The default is [NullCorrelationIdSource][] which essentially ignores this JMS Header.

## JMSReplyTo header

If the adapter is initiating a request and then waiting for a reply, then the JMSReplyTo header has a temporary destination associated with it. The expectation being that whatever is responding to the request will just use the JMSReplyTo header when replying to the request. Sometimes it doesn't work, perhaps the back-end application doesn't handle temporary destinations very well, or they don't translate well into whatever underlying message system the JMS layer sits on tops of (back-end apps that use IBM MQSeries seem quite prone to this); in situations like this we need to specify a static reply to destination that already exists. Our JMS Producers can be told to _not generate a temporary destination_ and to use a fixed JMSReplyTo destination by using the metadata key *JMSAsyncStaticReplyTo*; this will cause it to set whatever value stored against the metadata key as the JMSReplyTo header. This happens whenever the adapter produces a message to JMS, so it can be applied even if the workflow not trying to do a synchronous request reply (you might be making a request in one workflow, and having a different workflow handling the reply).

So if you wanted to force replies to a given message to come back on *MyReplyToDestination* then the configuration you need is something similar to this :

```xml
<service xsi:type="java:com.adaptris.core.ServiceList">
  <service xsi:type="java:com.adaptris.core.services.metadata.AddMetadataService">
    <metadata-element>
      <key>JMSAsyncStaticReplyTo</key>
      <value>MyReplyToDestination</value>
    </metadata-element>
  </service>
  <service xsi:type="java:com.adaptris.core.StandaloneRequestor">
    <connection xsi:type="java:com.adaptris.core.jms.PtpConnection">
       ... boring config skipped
    </connection>
    <producer xsi:type="java:com.adaptris.core.jms.PtpProducer">
       ... boring config skipped
      <destination xsi:type="java:com.adaptris.core.ConfiguredProduceDestination">
        <destination>SampleQ1</destination>
      </destination>
    </producer>
  </service>
</service>

```

Conversely, if the adapter needs to reply to the JMSReplyTo Header, then within the same workflow, you can use [JmsReplyToDestination][]in the JMS Producer; this will cause it use JmsReplyTo header as the target destination.

## JMSPrority, JMSDeliveryMode and JMSExpiration headers


By convention, the JMSPriority, JMSDeliveryMode, JMSExpiration are configured directly on the producer; time-to-live is configured on the producer, but this is used to derive the JMSExpiration header, as it is the exact time the message expires, but you pass how long the message is valid for at the point of the QueueSender.send() (blame the JMS API if you like). It is possible to control these headers dynamically on a per message basis by having _per-message-properties_ on the producer set to true. If you are going to do that, then the following metadata keys come into effect.

* _JMSPriority_ - this overrides the priority of the message. An integer value is acceptable here; any behaviour when you set the JMSPriority field is determined by the JMS vendor.
* _JMSDeliveryMode_ - this overrides the the delivery mode of the message; it should either be the text "PERSISTENT", "NON_PERSISTENT" or an integer value supported by the JMS vendor (for instance, _6_ would be equivalent to _NON_PERSISTENT_REPLICATED_ for SonicMQ).
* _JMSExpiration_ - this will be used to generate the correct TTL when producing the message. The format of this value should either be a long value (similar to System.currentTimeMillis(), the difference, measured in milliseconds, between the current time and midnight, January 1, 1970 UTC); or a string value in the date format `yyyy-MM-dd'T'HH:mm:ssZ`.


```xml
<service xsi:type="java:com.adaptris.core.ServiceList">
  <service xsi:type="java:com.adaptris.core.services.metadata.AddMetadataService">
    <metadata-element>
      <key>JMSPriority</key>
      <value>9</value>
    </metadata-element>
    <metadata-element>
      <key>JMSDeliveryMode</key>
      <value>NON_PERSISTENT</value>
    </metadata-element>
  </service>
  <service xsi:type="java:com.adaptris.core.services.metadata.AddTimestampMetadataService">
    <metadata-key>JMSExpiration</metadata-key>
    <date-format>yyyy-MM-dd'T'HH:mm:ssZ</date-format>
    <!-- Message expires in one hour -->
    <offset>+PT1H</offset>
  </service>
  <service xsi:type="java:com.adaptris.core.StandaloneProducer">
    <connection xsi:type="java:com.adaptris.core.jms.PtpConnection">
       ... boring config skipped
    </connection>
    <producer xsi:type="java:com.adaptris.core.jms.PtpProducer">
      <destination xsi:type="java:com.adaptris.core.ConfiguredProduceDestination">
        <destination>SampleQ1</destination>
      </destination>
      <per-message-properties>true</per-message-properties>
      <!-- These values will be overriden, so the message when produced
           will have a priority of 9, a delivery mode of NON_PERSISTENT
           and an Expiration of now+1 hour.
      -->
      <priority>4</priority>
      <delivery-mode>PERSISTENT</delivery-mode>
      <time-to-live>0</time-to-live>
    </producer>
  </service>
</service>

```

[JMS Connections and the adapter]: {{site.baseurl}}/blog/2012/06/29/jms-connections-in-the-adapter/
[MessageTypeTranslator]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/MessageTypeTranslator.html
[AutoConvertMessageTranslator]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/AutoConvertMessageTranslator.html
[javax.jms.Message]: http://docs.oracle.com/javaee/5/api/javax/jms/Message.html?is-external=true
[TextMessage]: http://docs.oracle.com/javaee/5/api/javax/jms/TextMessage.html?is-external=true
[TextMessageTranslator]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/TextMessageTranslator.html
[MapMessage]: http://docs.oracle.com/javaee/5/api/javax/jms/MapMessage.html
[CorrelationIdSource]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/CorrelationIdSource.html
[NullCorrelationIdSource]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/NullCorrelationIdSource.html
[JmsReplyToDestination]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/JmsReplyToDestination.html


