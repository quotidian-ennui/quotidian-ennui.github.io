---
layout: post
date: 2017-03-29 09:00
comments: false
tags: [adapter, interlok]
categories: [adapter, interlok]
published: true
title: "e.printStackTrace() as JSON"
description: "Sometimes you don't want to hide the stacktrace"
keywords: "interlok"
---

Let's suppose that you have an Interlok instance service HTTP requests and the data being transferred around is JSON messages. In the event that an exception happens what would normally happen is an exception is printed in the log file and a HTTP 500 error returned back to the client. What if we want to send more information such as the stack trace back to the caller as a JSON message.

When an exception is thrown during processing; then 3 things happen

1. The exception is stored as part of object metadata (against the key `java.lang.Exception`)
1. The location of the exception is stored as part of object metadata (against the key `java.lang.Exception_Cause`)
1. The workflow where the exception happened is recorded as normal metadata against the key `workflowId`

We can use [EmbeddedScriptingService][] to build up an exception report that can be rendered as JSON by the Jackson JSON streaming API classes. If you are already depending on the [adp-json][] optional package then you'll already have these classes available to you.

{% highlight xml %}

  <message-error-handler class="standard-processing-exception-handler">
    <processing-exception-service class="service-list">
      <services>
        <embedded-scripting-service>
          <language>javascript</language>
          <script>
            <![CDATA[
                var objectHeaders = message.getObjectHeaders();

                var exceptionReport = new java.util.HashMap();
                exceptionReport.put("workflow", message.getMetadataValue("workflowId"));
                var exception = objectHeaders["java.lang.Exception"];
                if(exception != null) {
                  exceptionReport.put("exception", exception);
                  exceptionReport.put("exceptionMessage", exception.getMessage());
                }
                var exceptionLocation = objectHeaders["java.lang.Exception_Cause"];
                if(exceptionLocation != null) {
                  exceptionReport.put("exceptionLocation", exceptionLocation);
                }
                message.setContent(new com.fasterxml.jackson.databind.ObjectMapper().writer(new com.fasterxml.jackson.core.util.DefaultPrettyPrinter()).writeValueAsString(exceptionReport), "UTF-8");

              ]]>
          </script>
        </embedded-scripting-service>
        <standalone-producer>
          <producer class="jetty-standard-response-producer">
            <status-provider class="http-configured-status">
              <status>INTERNAL_ERROR_500</status>
            </status-provider>
            <send-payload>true</send-payload>
          </producer>
        </standalone-producer>
      </services>
    </processing-exception-service>
  </message-error-handler>

{% endhighlight %}

So our exception handling chain becomes :

1. Grab the object metadata.
1. Create a map to store our report and store the workflowId in it.
1. If an exception exists in object metadata, then store the exception itself, and the exception message into the report
1. If the cause exists in object metadata, then store the cause in the report
1. Render the map as text using the jackson ObjectMapper.
1. Send the payload back to the caller.

With an example JSON response of :

{% highlight json %}

{
  "workflow" : "rectangle@schema-validator",
  "exceptionLocation" : "JsonSchemaService(foolish_einstein)",
  "exceptionMessage" : "#/rectangle/b: -1.0 is not higher or equal to 0",
  "exception" : "...skipped for brevity"
}

{% endhighlight %}


[EmbeddedScriptingService]: https://development.adaptris.net/javadocs/v3-snapshot/Interlok-API/com/adaptris/core/EmbeddedScriptingService.html
[adp-json]: https://development.adaptris.net/nexus/content/groups/public/com/adaptris/adp-json/
