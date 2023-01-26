---
layout: post
title: "Integrating with SAP BAPI function modules"
date: 2013-01-18 17:00
comments: false
#categories: [adapter, interlok]
tags: [adapter, interlok]
published: true
description: "Bridging between SAP and other systems using the adapter framework; Part 1"
keywords: "java, adapter, sap, integration, interlok"

---

SAP R/3 is used in a lot of enterprises and so having to integrate with SAP R/3 is something that we familiar with. The adapter has a broad range of support for SAP R/3; we can send and receive IDocs if you are trading documents electronically, or we can invoke arbitrary RFCs/BAPI functions within SAP R/3 if IDocs aren't your thing.

<!-- more -->

By default, the adapter doesn't ship with the jars and native libraries that are required to connect to SAP; they are free to download from SAP (look for SAP Java Connector and SAP Java IDoc Class Library) for your client platform. You'll need to install the required packages as per their instructions, and copy the jars into the adapter's lib directory; the adapter supports v3 of SAP JCo Standalone (it does support 2.x, but that's been marked as obsolete by SAP). Just as a word of warning, if you happen to be using version 3.0.3, then this will probably not work if you are using JRE 1.6.0_16 for the adapter, you should downgrade to JRE 1.6.0_15, or use a later version of SAP JCo.

## Executing BAPIs ##

For the purposes of this example, we're going to use BAPI_FLIGHT_GET_LIST which is available in any SAP IDES system; if it isn't then you can use the standard program SAPBC_DATA_GENERATOR to generate database for it via transaction SE38 (you will know what all of that means).

Download [this Adapter XML]({{ site.baseurl }}/artifacts/sap-adapter-bapi-base.xml) as a baseline adapter.xml. There are a couple of things that you will need to change, mainly around the connection properties in the destination-provider-info element; as configured, the following properties are used to connect to SAP; your environment definitely won't be the same as our lab, so you'll need to modify these properties (at the very minimum).

```xml
<destination-provider-info>
  <connection-properties>
    <!-- This is the language, you probably want to what you type into the sapgui when you logon

    -->
    <key-value-pair>
      <key>jco.client.lang</key>
      <value>EN</value>
    </key-value-pair>
    <!-- Your username; use what you type into the sapgui when you logon
    -->
    <key-value-pair>
      <key>jco.client.user</key>
      <value>ADAPTRIS</value>
    </key-value-pair>
    <!-- Your password; use what you type into the sapgui when you logon
    -->
    <key-value-pair>
      <key>jco.client.passwd</key>
      <value>ADAPTRIS</value>
    </key-value-pair>
    <!-- The client number; use what you type into the sapgui when you logon
    -->
    <key-value-pair>
      <key>jco.client.client</key>
      <value>810</value>
    </key-value-pair>
    <!-- The system number; this will depend on your environment, generally it's 00
    -->
    <key-value-pair>
      <key>jco.client.sysnr</key>
      <value>00</value>
    </key-value-pair>
    <!-- The application host; this will depend on your environment, generally
         it's the hostname/IP address of the machine where SAP is installed.
    -->
    <key-value-pair>
      <key>jco.client.ashost</key>
      <value>10.1.2.3</value>
    </key-value-pair>
    <!-- Trace mode (set to 0 to disable, or remove it entirely)
         Note that trace mode will create a bunch of files in the local directory which
         will actually be deleted by AutomaticTraceFileDelete after 1 day.
    -->
    <key-value-pair>
      <key>jco.client.trace</key>
      <value>1</value>
    </key-value-pair>
  </connection-properties>
  <!-- This is just the connection-id you want to assign to it, it could be omitted entirely,
       in which case one a unique-one is derived -->
  <connection-id>IDESVR</connection-id>
</destination-provider-info>
```

As you can see, the example adapter simply reads a file from the filesystem, and then executes *BAPI_FLIGHT_GET_LIST* (which is configured statically as the produce destination) passing in some parameters extracted from the input file. The input file is shown below, and has a remarkable similarity to what you might see when you use transaction SE37 to test BAPI_FLIGHT_GETLIST in the sapgui; this is of course intentional; it keeps the example nice and easy to correlate.

```xml
<?xml version="1.0"?>
<BAPI_FLIGHT_GETLIST>
  <INPUT>
    <AIRLINE>LH</AIRLINE>
    <DESTINATION_FROM>
      <AIRPORTID></AIRPORTID>
      <CITY></CITY>
      <COUNTR>DE</COUNTR>
      <COUNTR_ISO></COUNTR_ISO>
    </DESTINATION_FROM>
    <TABLES>
      <DATE_RANGE>
        <item>
          <SIGN>I</SIGN>
          <OPTION>GE</OPTION>
          <LOW>2010-01-01</LOW>
          <HIGH></HIGH>
        </item>
        <item>
          <SIGN>E</SIGN>
          <OPTION>LT</OPTION>
          <LOW>2010-04-01</LOW>
          <HIGH></HIGH>
        </item>
      </DATE_RANGE>
    </TABLES>
  </INPUT>
  <OUTPUT/>
</BAPI_FLIGHT_GETLIST>
```

## Parameters ##

The adapter simply exposes two types of parameter, import parameters and export parameters. Adapter import parameters will correspond to the BAPI function module's _Import_ or _Table_ parameters; similary adapter export parameters will correspond to the BAPI function module's _Export_ or _Table_ parameters.

### Import Parameters ###

There are various types of parameters that can be used, the more interesting ones are [XpathToStructure][] and [XpathToTable][] which allow you to use an xpath to build up complex parameters for the BAPI function. Tables might repeat; structures don't is the simplistic view of the differences. In the example, all the child elements of */BAPI_FLIGHT_GETLIST/INPUT/DESTINATION_FROM* go on to make up each field of the **DESTINATION_FROM** import parameter, and each instance of */BAPI_FLIGHT_GETLIST/INPUT/TABLES/DATE_RANGE/item* is added to the Table parameter **DATE_RANGE**. So in this example, we're looking for flights that occur between 2010-01-01 and 2010-04-01 for the airline LH (Lufthansa).


### Export Parameters ###

In this example we use [TableToXmlPayload][] exclusively to retrieve information from the BAPI function (this is because the module doesn't actually have any export parameters) which we are inserting as elements into the existing document via [InsertNode][]. The Table parameters _RETURN_, and FLIGHT_LIST are parsed and inserted into the document ready for further processing.

This is how easy it is to integrate with SAP BAPI function modules using the adapter.


[XpathToStructure]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/sap/jco3/rfc/params/XpathToStructure.html
[XpathToTable]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/sap/jco3/rfc/params/XpathToTable.html
[TableToXmlPayload]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/sap/jco3/rfc/params/TableToXmlPayload.html
[InsertNode]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/util/text/xml/InsertNode.html

