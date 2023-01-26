---
layout: post
title: "So your backend system isn't cloud ready"
date: 2013-03-28 09:00
comments: false
#categories: [adapter, integration, interlok]
tags: [adapter, interlok, integration]
published: true
description: "Your backend system isn't cloud-ready, that's not a big deal if you have an adapter."
keywords: "java, adapter, http, integration, interlok"

---

In our brave new cloud-based world a lot of integration happens over the web via HTTP; for a lot of scenarios, a full WS stack that uses SOAP+UDDI+WSDL is complete overkill and a timesink. Sometimes you just want to send some data around and get a response; this is where the adapter can fit into your integration landscape and help you get things done[^1].

<!-- more -->

## Handling incoming HTTP Requests

The Adapter comes with Jetty built in and configurable as a connection type and consumer. It's very easy to build a very simple HTTP workflow that receives some data, and just does some stuff, and send a reply back to the client request. So, one of the very simplest workflows you could have is one that takes in some data, applies a transformation to it, and gives the response back to the client.

```xml

<channel>
  <unique-id>receive-via-http</unique-id>
  <consume-connection xsi:type="java:com.adaptris.core.http.jetty.HttpConnection">
    <port>12345</port>
  </consume-connection>
  <workflow-list>
    <workflow xsi:type="java:com.adaptris.core.StandardWorkflow">
      <consumer xsi:type="java:com.adaptris.core.http.jetty.MessageConsumer">
        <destination xsi:type="java:com.adaptris.core.ConfiguredConsumeDestination">
          <destination>/some/url</destination>
          <configured-thread-name>/some/url</configured-thread-name>
        </destination>
      </consumer>
      <service-list xsi:type="java:com.adaptris.core.ServiceList">
        <service xsi:type="java:com.adaptris.core.transform.XmlTransformService">
          <url>./config/mappings/some-mapping.xsl</url>
        </service>
      </service-list>
      <producer xsi:type="java:com.adaptris.core.http.jetty.ResponseProducer">
        <http-response-code>200</http-response-code>
        <send-payload>true</send-payload>
        <additional-headers>
          <key-value-pair>
            <key>Content-Type</key>
            <value>text/xml</value>
          </key-value-pair>
        </additional-headers>
      </producer>
    </workflow>
  </workflow-list>
</channel>
```

You can compose complicated behaviour based on this example, the services you want to apply could be anything, a database lookup, a SAP BAPI invocation; all you need to do is to remember to have a [ResponseProducer](http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/http/jetty/ResponseProducer.html) as the registered producer; that will write the reply back to the client. You could have workflows that map to different resources that do a multitude of different things.

[^1]: Sometimes things have to get done and your dirty proof of concept gets deployed into production...