---
layout: post
title: "MSMQ and Java interoperability"
date: 2012-11-21 08:00
comments: false
categories: adapter interlok
tags: [adapter, interlok]
published: true
description: "Bridging between MSMQ and java using the adapter framework"
keywords: "java, adapter, msmq, integration, interlok"

---

Microsoft Message Queueing is a pretty good way of allowing applications running on different servers to communicate in a failsafe manner; it's baked directly into all recent versions of Windows and has extensive API support via Visual Studio. However, all your applications are going to be running on the Windows platform and this can cause issues if your technology stack spans multiple platforms. Bridging between MSMQ and other platforms like a java based ESB might be causing you a bit of a headache.

<!-- more -->

The adapter supports MSMQ natively and is an excellent way of hooking up your ESB infrastructure to a MSMQ infrastructure. It supports MSMQ3.0 and above which restricts it to Windows platforms later than XP / 2003; this doesn't mean that previous versions of MSMQ aren't supported; just that you need to run the adapter on XP or later. The JVM running the adapter needs to be 32bit as the native interface we use to access the underlying ActiveX libraries was compiled for x86.

Now all of the pre-requisites out of the way we can get on with actually configuring the adapter to work with MSMQ.

## Connecting to MSMQ ##


Download [this Adapter XML]({{ site.baseurl }}/artifacts/msmq-adapter-base.xml) for a very simple configuration of an MSMQ adapter. All it does is generate a message every 5 seconds send it to an MSMQ queue, read from that queue, and print out the contents of the message (I've left off lots of interesting things that can be configured in the adapter). Of course, real life requirements aren't going to be as simple as this but we can use this as a template for building up different behaviour.

### MSMQ destinations ###

As you can see from the example, we're using a local private queue 'zzlc' as specified by `DIRECT=OS:.\private$\zzlc`; the syntax for the queue name is described more fully in the [MSMQQueueInfo.FormatName documentation](http://msdn.microsoft.com/en-us/library/ms705703%28VS.85%29.aspx).

## Message formats ##

### Incoming Message Format ###

MSMQ message bodies can contain arbitrary data, it could be a String, an array of unsigned integers, numeric types, currency, date, a COM object. The adapter will always try and treat the incoming message as Text (equivalent of VT_BSTR) when receiving a message from MSMQ.

You might not have direct control over the back-end application; so it is possible for messages to be delivered to the adapter that aren't VT_BSTR. We can automagically do some conversions for you if that's appropriate.  You will want this behaviour regardless if the back-end component writes a redundant UTF-8 BOM (after all, UTF-8 doesn't suffer from byte ordering issues, so having a BOM is pretty redundant c.f. [this bug](http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=4508058)).

It's magic, so the conversion is not always accurate, results can be undefined if the object doesn't translate well into text; if not explicitly specified in the message-factory, then the platform default character encoding is used as the base character set for the converted String (probably Cp1252 if you're in Western Europe).

{% highlight xml %}
<consumer xsi:type="java:com.adaptris.core.msmq.MsmqPollingConsumer">
  ... Existing configuration skipped
  <attempt-silent-conversion-to-string>true</attempt-silent-conversion-to-string>
</consumer>
{% endhighlight %}

Doing this will help deal with MSMQ messages that are the variant `VT_UI1 | VT_ARRAY` type (I always just refer to this as a byte array). For more information about character encoding in the adapter; I've [written about it previously.]({{ site.baseurl }}/blog/2012/11/15/adapter-and-character-encoding/)

### Outgoing message format ###

Outgoing messages can be of two types; `VT_BSTR` or `VT_UI1 | VT_ARRAY`. You control the output via the [MessageFormatter][1]. [StringMessageFormat][] or [ByteArrayMessageFormat][] are the available message formats; the default being StringMessageFormat.

{% highlight xml %}
<producer xsi:type="java:com.adaptris.core.msmq.StandardMsmqProducer">
   ...Existing Configuration skipped
   <message-formatter xsi:type="java:com.adaptris.core.msmq.ByteArrayMessageFormat"/>
</producer>
{% endhighlight %}

## Mapping to and from MSMQ headers

All messages on delivered via MSMQ have a set of properties associated with them; some or all of them can be mapped by using a list of [property mappers][PropertyMapper] If, for instance, you wanted add the _ArrivedTime_ as an item of metadata when you receive the message then you could configure that as part of the consumer.

{% highlight xml %}
<consumer xsi:type="java:com.adaptris.core.msmq.MsmqPollingConsumer">
  ...Existing Configuration skipped
  <property-mapper xsi:type="java:com.adaptris.core.msmq.MetadataMapper">
    <property-name>ArrivedTime</property-name>
    <metadata-key>msmqArrivedTimeMetadataKey</metadata-key>
  </property-mapper>
</consumer>
{% endhighlight %}

Similarly if you wanted to set the value of the _Label_ property to the AdaptrisMessage's unique-id when you send the data to MSMQ then you can do that as well.

{% highlight xml %}
<producer xsi:type="java:com.adaptris.core.msmq.StandardMsmqProducer">
  ...Existing Configuration skipped
  <property-mapper xsi:type="java:com.adaptris.core.msmq.MessageIdMapper">
    <property-name>Label</property-name>
  </property-mapper>
</producer>
{% endhighlight %}

Some properties aren't byte arrays (like _CorrelationId_) so you may need to use the optional [ByteTranslator][2] element to translate those fields into strings.

For instance, if you wanted to make the _Id_ property of the MSMQ Message the AdaptrisMessage unique-id then you would need to use a combination of [MessageIdMapper][] and a [ByteTranslator][] implementation to make that happen. In this example; we're turning the 20byte id into its hex representation, and we're also storing the _Id_ property as metadata under the key _msmqOriginalId_ (but base64 encoded).

{% highlight xml %}
<consumer xsi:type="java:com.adaptris.core.msmq.MsmqPollingConsumer">
  ...Existing Configuration skipped
  <property-mapper xsi:type="java:com.adaptris.core.msmq.MessageIdMapper">
    <property-name>Id</property-name>
    <byte-translator xsi:type="java:com.adaptris.util.text.HexStringByteTranslator"/>
  </property-mapper>
  <property-mapper xsi:type="java:com.adaptris.core.msmq.MetadataMapper">
    <property-name>Id</property-name>
    <byte-translator xsi:type="java:com.adaptris.util.text.Base64ByteTranslator"/>
    <metadata-key>msmqOriginalId</metadata-key>
  </property-mapper>
</consumer>
{% endhighlight %}

The _Id_ property is "read-only" on the MSMQ Message so you won't be able to use the AdaptrisMessage's unique id as the Id property (it won't fit into the 20byte requirement for _CorrelationId_ either). Correlating messages between multiple technology stacks can cause its own particular set of issues and is a subject for another day.

A full list of supported properties can found in the [MSMQMessage property documentation](http://msdn.microsoft.com/en-us/library/ms705286%28VS.85%29.aspx).

This is how easy it is to integrate MSMQ with Java.

[1]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/msmq/StandardMsmqProducer.html#setMessageFormatter(com.adaptris.core.msmq.MsmqMessageFormat)
[StringMessageFormat]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/msmq/StringMessageFormat.html
[ByteArrayMessageFormat]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/msmq/ByteArrayMessageFormat.html
[PropertyMapper]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/msmq/PropertyMapper.html
[2]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/msmq/PropertyMapper.html#setByteTranslator(com.adaptris.util.text.ByteTranslator)
[MessageIdMapper]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/msmq/MessageIdMapper.html
[ByteTranslator]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/util/text/ByteTranslator.html