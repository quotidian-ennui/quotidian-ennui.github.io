---
layout: post
title: "Advanced Adapter Error Handling"
date: 2012-02-24 17:00
published: true
comments: false
categories: adapter interlok
tags: [adapter, interlok]
published: true
description: "Setting up the adapter for multiple ways of handling errors"
keywords: "adapter, java, interlok"

---

As we all know error handling within the adapter can be configured at the workflow, channel or adapter level. Most of the time we just write the original file out to something that can't fail (well, unlikely to fail in the context of things) like the file system.

What if you want to do more with it?

<!-- more -->

With the advent of the [ProcessingExceptionHandler][] interface it's been possible to insert arbitrary services into exception processing. Additionally with [ExceptionReportService][] you can get additional information about the exception that occurred.

Of course; behaviour like this is not without associated cost. If the services that you applying as part of the ProcessingExceptionHandler fail, then there is no fall back, you don't pass go and collect 200 dollars. You need to make sure that the first thing you do is to *archive* the file so that can be reprocessed.

### Example configuration ###

Let's see an example configuration that does stuff.

{% highlight xml %}
<message-error-handler xsi:type="java:com.adaptris.core.StandardProcessingExceptionHandler">
  <processing-exception-service xsi:type="java:com.adaptris.core.ServiceList">
    <!-- First of all; let's write the message out to an errors directory.
    -->
    <service xsi:type="java:com.adaptris.core.StandaloneProducer">
      <producer xsi:type="java:com.adaptris.core.fs.FsProducer">
        <destination xsi:type="java:com.adaptris.core.ConfiguredProduceDestination">
          <destination>messages/errors</destination>
        </destination>
        <create-dirs>true</create-dirs>
        <encoder xsi:type="java:com.adaptris.core.MimeEncoder" />
      </producer>
    </service>
    <!-- Next we create a "report" based on the document that failed.
         Use a CloneMessageServiceList so the document isn't modified as we'll
         only be working on the clone.
    -->
    <service xsi:type="java:com.adaptris.core.CloneMessageServiceList">
      <service xsi:type="java:com.adaptris.core.ServiceList">
        <!-- Just run a transform to wrap the XML document with a "ROOT" Element.
            -->
        <service xsi:type="java:com.adaptris.core.transform.XmlTransformService">
          <url>./config/mappings/exception-wrapper.xsl</url>
        </service>
        <service xsi:type="java:com.adaptris.core.services.exception.ExceptionReportService">
          <!-- do an e.printStackTrace() but wrap it inside an element called <ErrorElement>
          -->
          <exception-generator xsi:type="java:com.adaptris.core.services.exception.SimpleExceptionReport">
            <element>ErrorElement</element>
          </exception-generator>
          <!-- Insert ErrorElement in as a new node in the document.
          -->
          <document-merge xsi:type="java:com.adaptris.util.text.xml.InsertNode">
            <xpath-to-parent-node>/Root</xpath-to-parent-node>
          </document-merge>
        </service>
        <service xsi:type="java:com.adaptris.core.StandaloneProducer">
          <!-- For our purposes here, we are just writing out to the Filesystem again,
               But this could be anyway, a JMS Queue, a JMSReplyTo Destination
               so you're always responding with some relevant information.
          -->
          <producer xsi:type="java:com.adaptris.core.fs.FsProducer">
            <destination xsi:type="java:com.adaptris.core.ConfiguredProduceDestination">
              <destination>./messages/error-reports</destination>
            </destination>
            <create-dirs>true</create-dirs>
          </producer>
        </service>
      </service>
    </service>
  </processing-exception-service>
</message-error-handler>
{% endhighlight %}

So what does message-error-handler do?

- An error is encountered in the workflow, so the message-error-handler is triggered.
- First of all we write the original message is written out to *messages/errors* in a MIME-encoded format (so it can be retried)
- Next we have some steps to actually create a report from the document that errored.
    - Run the document through a transform
    - Generate a simple exception report (basically an `e.printStackTrace()` equivalent) which is nested inside an element called *ErrorElement*
    - Insert this element as a child element of *Root*
- Write the document out to ./messages/error-reports

If we configure a workflow like this, we can see what happens quite easily.

{% highlight xml %}
<workflow xsi:type="java:com.adaptris.core.StandardWorkflow">
  <unique-id>AlwaysFails</unique-id>
  <consumer xsi:type="java:com.adaptris.core.fs.FsConsumer">
    <destination xsi:type="java:com.adaptris.core.ConfiguredConsumeDestination">
      <destination>messages/adapter-in</destination>
    </destination>
    <create-dirs>true</create-dirs>
  </consumer>
  <service-collection xsi:type="java:com.adaptris.core.ServiceList">
    <service xsi:type="java:com.adaptris.core.services.exception.ThrowExceptionService">
      <exception-generator xsi:type="java:com.adaptris.core.services.exception.ConfiguredException">
        <message>Oh Boy, ThrowExceptionService threw an Exception, who'd have thought.</message>
      </exception-generator>
    </service>
  </service-collection>
</workflow>
{% endhighlight %}

### Testing our config

Right then, we can start it up and copy a test message in to *messages-adapter-in*. For our purposes the document is a very simple XML document that looks like

{% highlight xml %}
<?xml version="1.0" encoding="utf-8"?>
<Envelope>
  <Palindrome>Pack My Box With A Dozen Liqour Jugs</Palindrome>
  <debug>
    <a1>A1</a1>
    <a2>A2</a2>
  </debug>
</Envelope>
{% endhighlight %}

After 20 seconds or so, we can see that eventually a couple of new directories are created *messages/errors* and *messages/error-reports*; which is exactly what we expected. message/errors just contains the original file, along with the stacktrace in a MIME encoded file, but messages/error-reports contains a nicely formatted XML document that contains both the original message and the stacktrace in the XML.

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<Root>
  <Envelope>
  <Palindrome>Pack My Box With A Dozen Liqour Jugs</Palindrome>
  <debug>
    <a1>A1</a1>
    <a2>A2</a2>
  </debug>
</Envelope>
  <Exception>
<![CDATA[
com.adaptris.core.ServiceException: Oh Boy, ThrowExceptionService threw an Exception, who'd have thought.
  at com.adaptris.core.services.exception.ConfiguredException.create(ConfiguredException.java:43)
  at com.adaptris.core.services.exception.ThrowExceptionService.doService(ThrowExceptionService.java:38)
  at com.adaptris.core.ServiceList.applyServices(ServiceList.java:39)
  at com.adaptris.core.ServiceCollectionImp.doService(ServiceCollectionImp.java:189)
  at com.adaptris.core.WorkflowImp.handleMessage(WorkflowImp.java:740)
  at com.adaptris.core.StandardWorkflow.onAdaptrisMessage(StandardWorkflow.java:97)
  at com.adaptris.core.fs.FsConsumer.processFile(FsConsumer.java:80)
  at com.adaptris.core.fs.FsConsumerImpl.processMessages(FsConsumerImpl.java:103)
  at com.adaptris.core.PollerImp.processMessages(PollerImp.java:82)
  at com.adaptris.core.FixedIntervalPoller$PollerTimerTask.run(FixedIntervalPoller.java:83)
  at java.util.TimerThread.mainLoop(Timer.java:512)
  at java.util.TimerThread.run(Timer.java:462)
]]>
</Exception>
</Root>
{% endhighlight %}

Of course this usage scenario is fairly redundant as both files as written have stacktraces in them; but if we were having to return information to a calling process via a JMSReplyTo destination, then having the stacktrace available in XML would be pretty useful; perhaps you want to email someone that there's been an error. If you wanted specific behaviour from your exception report, then all you need to do is make your own concrete implementation of [ExceptionReportGenerator][] and configure it.


[ProcessingExceptionHandler]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/ProcessingExceptionHandler.html
[ExceptionReportService]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/services/exception/ExceptionReportService.html
[ExceptionReportGenerator]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/services/exception/ExceptionReportGenerator.html

