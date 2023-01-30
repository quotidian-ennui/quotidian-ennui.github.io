---
layout: post
title: "TriggeredChannel has it's uses"
date: 2013-10-11 17:00
comments: false
#categories: [adapter, interlok]
tags: [adapter, interlok]
published: true
description: "A TriggeredChannel is one that requires an external trigger"
keywords: "java, adapter, sap, integration, interlok"
excerpt_separator: <!-- more -->
---

I haven't posted for a while, I can see that my last post was in June; the summer holidays must have been quite exciting (or frenetic); can't remember now. Anyway, this post is about something that isn't really used in the adapter; which is [TriggeredChannel][]. It is a channel where the workflows are only started when an external event occurs; hence the name. Once the trigger is received; workflows are started, the channel waits for the workflows to do their thing, and then stops them afterwards and is then ready for the next trigger.

<!-- more -->

There are some subtle differences between a [TriggeredChannel][] and a normal channel; the consumers inside each workflow should really be based around things that actively poll (i.e. [AdaptrisPollingConsumer][] implementations) rather than consumers that wait for activity (like a JmsConsumer or the like, if you need JMS behaviour, there is [JmsPollingConsumer][]). The polling implementation for each consumer should be a [OneTimePoller][] rather than one of the other implementations. This type of channel also handles errors and events slightly differently. By default, the channel will supply its own message error handling implementation, rather than using the Adapter's (in this case a [com.adaptris.core.triggered.RetryMessageErrorHandler][], infinite retries at 30 second intervals); you can change it if you want, but it must still be an instance of [com.adaptris.core.triggered.RetryMessageErrorHandler][]. The trigger itself could be anything you want, it has a consumer/producer/connection element, so you could listen for an HTTP request, or use a [JmxChannelTrigger][] which registers itself as a standard MBean, so you can trigger it remotely via jconsole or the like.

## Example ##

If for instance, an adapter is running on a remote machine, and you don't have the capability to login to the filesystem and retry failed messages then you could use a TriggeredChannel to copy all the files from the _bad_ directory into a _retry_ directory so that the [FailedMessageRetrier][] is triggered. This is quite a marginal use case; if you have the type of failure where messages can be automatically retried without manual intervention then a normal [RetryMessageErrorHandler][] will probably be a better bet. We'll make the trigger a message on a JMS Topic; any message received on the topic _retry-failed-messages_ will start the channel, files will be copied from the bad directory to the retry directory and then the channel will stop.

```xml
<channel xsi:type="java:com.adaptris.core.triggered.TriggeredChannel">
  <unique-id>RETRY_FAILED_MESSAGES</unique-id>
  <trigger>
    <connection xsi:type="java:com.adaptris.core.jms.PasConnection">
       ... config skipped for brevity
    </connection>
    <consumer xsi:type="java:com.adaptris.core.jms.PasConsumer">
      <destination xsi:type="java:com.adaptris.core.ConfiguredConsumeDestination">
        <destination>retry-failed-messages</destination>
        <configured-thread-name>JMS RETRY Trigger</configured-thread-name>
      </destination>
    </consumer>
  </trigger>
  <consume-connection xsi:type="java:com.adaptris.core.NullConnection" />
  <produce-connection xsi:type="java:com.adaptris.core.NullConnection" />
  <workflow-list>
    <workflow xsi:type="java:com.adaptris.core.StandardWorkflow">
      <consumer xsi:type="java:com.adaptris.core.fs.FsConsumer">
        <destination xsi:type="java:com.adaptris.core.ConfiguredConsumeDestination">
          <destination>/path/to/bad/directory</destination>
          <configured-thread-name>BAD_TO_RETRY</configured-thread-name>
        </destination>
        <poller xsi:type="java:com.adaptris.core.triggered.OneTimePoller">
        <create-dirs>true</create-dirs>
      </consumer>
      <service-collection xsi:type="java:com.adaptris.core.ServiceList"/>
      <producer xsi:type="java:com.adaptris.core.fs.FsProducer">
        <destination xsi:type="java:com.adaptris.core.ConfiguredProduceDestination">
          <destination>/path/to/retry/directory</destination>
        </destination>
        <create-dirs>true</create-dirs>
      </producer>
    </workflow>
  </workflow-list>
</channel>
```

[TriggeredChannel]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/triggered/TriggeredChannel.html
[AdaptrisPollingConsumer]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/AdaptrisPollingConsumer.html
[JmsPollingConsumer]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/jms/JmsPollingConsumer.html
[OneTimePoller]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/triggered/OneTimePoller.html
[FailedMessageRetrier]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/FailedMessageRetrier.html
[RetryMessageErrorHandler]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/RetryMessageErrorHandler.html
[com.adaptris.core.triggered.RetryMessageErrorHandler]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/triggered/RetryMessageErrorHandler.html
[JmxChannelTrigger]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/triggered/JmxChannelTrigger.html
