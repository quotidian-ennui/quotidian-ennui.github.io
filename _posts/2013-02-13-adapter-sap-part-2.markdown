---
layout: post
title: "Stateful RFC using the adapter framework"
date: 2013-02-15 17:00
comments: false
#categories: [adapter, interlok]
tags: [adapter, interlok]
published: true
description: "Bridging between SAP and other systems using the adapter framework; Part 2"
keywords: "java, adapter, sap, integration, interlok"

---

Last time I wrote about how easy it was to execute an [arbitrary BAPI using the adapter framework]({{ site.baseurl }}/blog/2013/01/18/adapter-sap-part-1) and get meaningful results back as XML. At the simplest level, that's pretty much all you really need to integrate with SAP. Unless...

<!-- more -->

There's always something that doesn't easily fit into a simple workflow, so there are additional supporting components that can help with SAP integration. Today I'll just talk about how to ensure that multiple BAPI calls can share the same RFC connection. Generally speaking, when inserting data using a BAPI, there are no guarantees that data inserted by that BAPI will be available for the next BAPI call unless the same underlying connection is re-used which leads us to what SAP calls a stateful function call with JCo.

## Stateful RFC Calls ##

So to manage a stateful sequence of RFC calls, then you need to use [RfcServiceList][] [StatefulSessionStart][] and [StatefulSessionEnd][]. These classes ensure that the underlying RFC connection is kept open during message processing and the same connection is re-used by all JCo services in the list.

[RfcServiceList][] is simply a wrapper around a standard [ServiceList][] but allows you to specify an [RfcConnection][] to be used by all services that require a connection; this is propagated to child services and re-used. [StatefulSessionStart][] and [StatefulSessionEnd][] do exactly what they imply, they start and end a stateful session, and should be the first and last services in a [RfcServiceList][] respectively.

It is best illustrated with an example

```xml
<service-collection xsi:type="java:com.adaptris.core.ServiceList">
 <service xsi:type="java:com.adaptris.core.sap.jco3.rfc.services.RfcServiceList">
  <rfc-connection xsi:type="java:com.adaptris.core.sap.jco3.rfc.RfcConnection">
    ... Connection information skipped for brevity.
  </rfc-connection>
  <service xsi:type="java:com.adaptris.core.ServiceList">
    <!-- Here we specify continue of fail so that we always end up calling StatefulSessionEnd -->
    <continue-on-fail>true</continue-on-fail>
    <service xsi:type="java:com.adaptris.core.sap.jco3.rfc.services.StatefulSessionStart" />
    <service xsi:type="java:com.adaptris.core.StandaloneRequestor">
      <producer xsi:type="java:com.adaptris.core.sap.jco3.rfc.bapi.BapiProducer">
        <destination xsi:type="java:com.adaptris.core.ConfiguredProduceDestination">
          <destination>BAPI_COMPANYCODE_GETLIST</destination>
        </destination>
        <export-parameter xsi:type="java:com.adaptris.core.sap.jco3.rfc.params.TableToXmlPayload">
          <parameter-name>COMPANYCODE_LIST</parameter-name>
          <xml-handler xsi:type="java:com.adaptris.util.text.xml.InsertNode">
            <xpath-to-parent-node>/BAPI_COMPANYCODE_GETLIST</xpath-to-parent-node>
          </xml-handler>
        </export-parameter>
        <return-parser xsi:type="java:com.adaptris.core.sap.jco3.rfc.bapi.AddBasicMetadata" />
      </producer>
    </service>
    <!--
     WE've just called BAPI_COMPANYCODE_GETLIST, so this is a document that contains "COMPANY_ID"s
     so we split it to get each individual company code.
    -->
    <service xsi:type="java:com.adaptris.core.services.splitter.AdvancedMessageSplitterService">
      <!-- This splits on /COMPANYCODE_LIST/item -->
      <splitter xsi:type="java:com.adaptris.core.services.splitter.XpathMessageSplitter">
        <xpath>/BAPI_COMPANYCODE_GETLIST/COMPANYCODE_LIST/item</xpath>
          <encoding>UTF-8</encoding>
          <copy-object-metadata>true</copy-object-metadata>
      </splitter>
      <service-collection xsi:type="java:com.adaptris.core.ServiceList">
        <!-- This grabs the company name as metadata -->
        <service xsi:type="java:com.adaptris.core.services.metadata.XpathMetadataService">
          <xpath-metadata-query>
            <query-expression>/item/COMP_NAME</query-expression>
            <metadata-key>CompanyName</metadata-key>
          </xpath-metadata-query>
        </service>
        <!-- Ok, so now we can call BAPI_COMPANYCODE_GETDETAIL for each "iteration"
             of /COMPANYCODE_LIST/item
        -->
        <service xsi:type="java:com.adaptris.core.StandaloneRequestor">
          <producer xsi:type="java:com.adaptris.core.sap.jco3.rfc.bapi.BapiProducer">
            <destination xsi:type="java:com.adaptris.core.ConfiguredProduceDestination">
              <destination>BAPI_COMPANYCODE_GETDETAIL</destination>
            </destination>
            <export-parameter xsi:type="java:com.adaptris.core.sap.jco3.rfc.params.StructureToXmlPayload">
              <parameter-name>COMPANYCODE_DETAIL</parameter-name>
              <xml-handler xsi:type="java:com.adaptris.util.text.xml.ReplaceOriginal" />
            </export-parameter>
            <!-- WE get the company code ID from the XML -->
            <import-parameter xsi:type="java:com.adaptris.core.sap.jco3.rfc.params.XpathString">
              <parameter-name>COMPANYCODEID</parameter-name>
              <xpath>/item/COMP_CODE</xpath>
              <null-converter xsi:type="java:com.adaptris.util.text.NullToEmptyStringConverter" />
            </import-parameter>
            <return-parser xsi:type="java:com.adaptris.core.sap.jco3.rfc.bapi.AddBasicMetadata" />
          </producer>
          </service>
          <!-- as the final step in our sequence we write out all the company details to SampleQ1 -->
          <service xsi:type="java:com.adaptris.core.StandaloneProducer">
            <connection xsi:type="java:com.adaptris.core.jms.PtpConnection">
              ... Info skipped for brevity.
            </connection>
            <producer xsi:type="java:com.adaptris.core.jms.PtpProducer">
              <destination xsi:type="java:com.adaptris.core.ConfiguredProduceDestination">
                <destination>SampleQ1</destination>
              </destination>
              <message-translator xsi:type="java:com.adaptris.core.jms.TextMessageTranslator">
            </producer>
          </service>
        </service-collection>
      </service>
    </service>
    <service xsi:type="java:com.adaptris.core.sap.jco3.rfc.services.StatefulSessionEnd" />
  </service>
</service-collection>
```

Here, we are calling the function `BAPI_COMPANYCODE_GETLIST` and then for each company id that is returned we will execute `BAPI_COMPANYCODE_GETDETAIL`. Each of those records will end up with the company details written out to `SampleQ1`.

Building up complexity in the adapter framework is simply a matter of deciding which pieces you want, and adding them into the workflow. It can be as simple or as complicated as you like.



[RfcServiceList]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/sap/jco3/rfc/services/RfcServiceList.html
[StatefulSessionStart]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/sap/jco3/rfc/services/StatefulSessionStart.html
[StatefulSessionEnd]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/sap/jco3/rfc/services/StatefulSessionEnd.html
[ServiceList]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/ServiceList.html
[RfcConnection]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/sap/jco3/rfc/RfcConnection.html

