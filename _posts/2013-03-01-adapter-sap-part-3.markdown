---
layout: post
title: "Handling BAPI errors using the Adapter Framework"
date: 2013-03-01 17:00
comments: false
#categories: [adapter, interlok]
tags: [adapter, interlok]
published: true
description: "Bridging between SAP and other systems using the adapter framework; part 3"
keywords: "java, adapter, sap, integration, interlok"

---

So, this is yet another blog post about executing BAPI functions in SAP using the Adapter Framework; one day I will get bored with writing about SAP, but right now, it's on the top of the heap. Today's post is around error handling and reporting; any monkey can make something work, but handling error conditions gracefully is often a stumbling block that can trip you up during integration.

<!-- more -->

## Handling Errors ##

Often the technical execution of the BAPI function will succeed but there may have been some business error during the execution (e.g. the data couldn't be found); this is reported in the standard RETURN parameter from the BAPI which either exists as an `EXPORT` parameter or as part of the `TABLE` parameter list. [BapiProducer][] allows you to configure an instance of [BapiReturnParser][] which is able to interrogate this parameter and produce behaviour based on the values stored in the the structure.

The simplest implementation is [FailOnError][] which does exactly what it suggests; in the event of an error (the TYPE field is _'A'_ or _'E'_) it throws an exception triggering standard error handling. There are other implementations, if you just wanted to mark that the BAPI function had failed, then you could use [AddFailureMetadata][] which simply makes an item of metadata _true_ in the event of failure.

If the BAPI function execution is part of a request/reply workflow (e.g. you're looking up someone's address from SAP); then you can always map the `RETURN` parameter explicitly into your XML document, and parse it when processing the reply.

## Reporting on Exceptions ##

Errors could happen during the processing of the message; it's all well and good capturing the `RETURN` parameter in your XML document, but what if a ServiceException is raised prior to the execution, or the execution failed technically in some fashion (perhaps you got a parameter wrong). This is where [BapiExceptionReport][] comes in, which allows you to map exceptions into a standard `RETURN` element; you would use this as part of a [ProcessingExceptionHandler]({{ site.baseurl }}/blog/2012/02/24/advanced-adapter-error-handling) chain.

As always, examples are worth a thousand words.

```xml
<message-error-handler xsi:type="java:com.adaptris.core.StandardProcessingExceptionHandler">
  <processing-exception-service xsi:type="java:com.adaptris.core.ServiceList">
    <service xsi:type="java:com.adaptris.core.services.exception.ExceptionReportService">
      <exception-generator xsi:type="java:com.adaptris.core.sap.jco3.rfc.bapi.exception.BapiExceptionReport">
        <default-exception-mapping>
          <id>ADAPTER_EXCEPTION</id>
          <number>000</number>
          <type>A</type>
        </default-exception-mapping>
        <exception-mapping>
          <exception-class>com.adaptris.core.sap.jco3.rfc.params.ParameterException</exception-class>
          <id>PARAM_EXCEPTION</id>
          <number>000</number>
          <type>A</type>
        </exception-mapping>
        <exception-mapping>
          <exception-class>com.sap.conn.jco.JCoRuntimeException</exception-class>
          <id>JCO_EXCEPTION</id>
          <number>000</number>
          <type>A</type>
        </exception-mapping>
      </exception-generator>
      <document-merge xsi:type="java:com.adaptris.util.text.xml.InsertNode">
        <xpath-to-parent-node>//OUTPUT</xpath-to-parent-node>
      </document-merge>
    </service>
    <service xsi:type="java:com.adaptris.core.StandaloneProducer">
      <producer xsi:type="java:com.adaptris.core.jms.PtpProducer">
        <destination xsi:type="java:com.adaptris.core.jms.JmsReplyToDestination"/>
      </producer>
      ... Connection config skipped.
    </service>
  </processing-exception-service>
</message-error-handler>
```

So if the exception that is raised is a JCoRuntimeException then the following block of XML will be inserted under the `//OUTPUT` node. The default-exception-mapping is what is used when an explicit match for an exception can't be found, so in the case of a `ServiceException` it would generate a `RETURN` element with an `ID` of `ADAPTER_EXCEPTION`.

```xml
<RETURN>
  <TYPE>A</TYPE>
  <ID>JCO_EXCEPTION</ID>
  <NUMBER>000</NUMBER>
  <MESSAGE>'The value of e.getMessage()'</MESSAGE>
  <LOG_NO/>
  <LOG_MSG_NO/>
  <MESSAGE_V1/>
  <MESSAGE_V2/>
  <MESSAGE_V3/>
  <MESSAGE_V4/>
  <PARAMETER/>
  <ROW>0</ROW>
  <SYSTEM/>
</RETURN>
```

Remember that the error handling chain can be configured at a number of levels, adapter wide, channel wide, or on an individual workflow basis; you can compose complicated behaviour in a very simple way.

[BapiProducer]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/sap/jco3/rfc/bapi/BapiProducer.html
[BapiReturnParser]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/sap/jco3/rfc/bapi/BapiReturnParser.html
[FailOnError]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/sap/jco3/rfc/bapi/FailOnError.html
[AddFailureMetadata]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/sap/jco3/rfc/bapi/AddFailureMetadata.html
[BapiExceptionReport]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/sap/jco3/rfc/bapi/exception/BapiExceptionReport.html
