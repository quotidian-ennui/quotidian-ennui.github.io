---
layout: post
title: "Dynamically switching XSLT processing engines"
date: 2012-03-02 16:00
comments: false
categories: adapter interlok
tags: [adapter, interlok]
published: true
description: "Setting up the adapter to use both XSLT 1.0 and 2.0 in the same JVM"
keywords: "adapter, xslt, jruby, jsr223, java, saxon, xalan, interlok"

---

At the moment, for legacy reasons, the adapter ships with Xalan as the XSLT transformation engine. There are still a lot of stylesheets out that that won't work with XSLT 2.0. If your environment is XSLT2.0 only then our recommendation has always been to switch the default transformer factory to something like [Saxon][] using the appropriate JVM system property on the commandline : `-Djavax.xml.transform.TransformerFactory=net.sf.saxon.TransformerFactoryImpl` but this makes all the transforms use saxon as the XSLT processing engine.

What if you wanted to use Saxon and it's XSLT 2.0 engine on a per transform basis?

<!-- more -->

So you have an XSLT 2.0 stylesheet; for the sake of argument it starts with

{% highlight xslt %}
<xsl:stylesheet xmlns:dinos="dinosaur" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xpath-default-namespace="dinosaur"
  exclude-result-prefixes="xs xsl dinos" version="2.0">
</xsl:stylesheet>
{% endhighlight %}

Or perhaps you're using one of the new functions like _format-number_ or _format-date_; anyway, if you had a stylesheet like that it wouldn't work in the adapter by default. It would work if Saxon was the transformation engine, but you have other stylesheets that require Xalan/XSLT1.0. Once again we can use [jruby][] + [EmbeddedScriptingService][] or [ScriptingService][] to execute the transform for us. Not breaking a habit of a lifetime; I'll use EmbeddedScriptingService to illustrate what I mean; ScriptingService would work just as well if you wanted to refer to a ruby script on the filesystem.

{% highlight xml %}
<service xsi:type="java:com.adaptris.core.services.EmbeddedScriptingService">
  <language>jruby</language>
  <script><![CDATA[
include Java
java_import 'net.sf.saxon.TransformerFactoryImpl'

input = $message.getInputStream;
document = javax.xml.transform.stream.StreamSource.new input
stylesheet = javax.xml.transform.stream.StreamSource.new '../transforms/xslt-2.0/new-dinos.xsl'
output = $message.getOutputStream();
result = javax.xml.transform.stream.StreamResult.new output
begin
  transformerFactory = TransformerFactoryImpl.new
  transformer = transformerFactory.newTransformer(stylesheet)
  transformer.transform(document, result)
ensure
  output.close;
  input.close;
end
]]>
  </script>
</service>
{% endhighlight %}

Basically the service, runs the transform _../transforms/xslt-2.0/new-dinos.xsl_ using the saxon transform factory. Of course, performance might not be great as there will be no caching of the stylesheet or anything like that; but it's a good way to start migrating your transforms to Saxon and new XSLT 2.0 features if that's what you need to do.

Obviously you could use *org.apache.xalan.processor.TransformerFactoryImpl* as the TransformerFactory implementation rather than *net.sf.saxon.TransformFactoryImpl* if you wanted to permanently switch to Saxon and only use Xalan for the few legacy stylesheets that you have remaining.

[Saxon]: http://saxon.sourceforge.net/
[jruby]: http://jruby.org
[EmbeddedScriptingService]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/services/EmbeddedScriptingService.html
[ScriptingService]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/services/ScriptingService.html

