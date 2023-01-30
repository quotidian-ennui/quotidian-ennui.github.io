---
layout: post
title: "Character encoding behaviour in the adapter"
date: 2012-11-15 17:00
comments: false
#categories: [adapter, interlok]
tags: [adapter, interlok]
published: true
description: "Adapter behaviour and character encoding"
keywords: "java, adapter, integration, interlok"
excerpt_separator: <!-- more -->
---

Working with different character encodings is almost fun. I do get asked a lot about this kind of thing; my transform doesn't work, or this EDI document doesn't parse properly (I suppose the customer thinks that diacritics are allowed in the UNOA character set?); I like to say that the adapter only knows as much about encoding as you do; everything is configurable so your choices (or tacit acceptance of the defaults) will have a huge impact on how the adapter behaves.

<!-- more -->

This is particularly true when you have multiple types of data manipulation in a workflow; there are services that work with Strings and some that work directly with the InputStream / Reader. A mixture of these in your service-list will lead to different results depending on whether you've been explicit in your character encoding specification. For instance regular expression services always work on strings; transformation services tend to work on the inputstream. Depending on what you've specified as the character encoding on the message, using these in sequence might lead to unexpected behaviour (something like é will have a different byte representation in ISO-8859-1 as opposed to UTF-8).

Below are a few of the ways in which you can control the character encoding for a given message; You could of course fix the default character encoding for the entire JVM by using the system property _file.encoding_ if you wanted to.

## Fix character encoding at the point of entry

All consumers have a message factory which can be configured; you will have seen it in the example XML. [DefaultMessageFactory](http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/DefaultMessageFactory.html) is the one you're most likely to be using, and this has the ability to assign a default character encoding against the underlying AdaptrisMessage object for all instances that it creates (other message factory implementations also have this behaviour). If you don't specify it, then it will use the JVM default for all String to byte (and vice-versa) operations.

```xml
<consumer xsi:type="java:com.adaptris.core.fs.FsConsumer">
  ... boring configuration skipped.
  <message-factory xsi:type="java:com.adaptris.core.DefaultMessageFactory">
    <default-char-encoding>ISO-8859-2</default-char-encoding>
  </message-factory>
</consumer>
```



## Changing character encoding during data transformation

So, you've written a transform; yours will be good, mine will look something like:

```xml
<?xml version="1.0" encoding="iso-8859-1" ?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:java="http://xml.apache.org/xslt/java" exclude-result-prefixes="java">
  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:template match="*">
    <xsl:call-template name="copy" />
  </xsl:template>

  <xsl:template name="copy">
    <xsl:copy>
      <xsl:for-each select="@*">
        <xsl:copy />
      </xsl:for-each>
      <xsl:apply-templates />
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
```

The details don't really matter, what matters is the fact that you've specified the output encoding in the stylesheet. What happens if this encoding doesn't match what's already specified in the AdaptrisMessage object? If the data contains characters that should be encoded differently between ISO-8859-1 and UTF-8 (such as £), then the resulting file will look a strange when opened up in a dumb editor (dumb editors are actually quite useful so they're only dumb in the same way that dumb terminals are dumb); or when parsed by the target backend  system.

For [Flat-file Transform](http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/transform/FfTransformService.html) and [Xml Transform](http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/transform/XmlTransformService.html) services you can specify the output message encoding which sets the underlying character encoding for the AdaptrisMessage object before any write operations are done. For EDI style services, it continues to use the existing character encoding for the message as it is only performing a limited mark-up/mark-down of the data in question.

```xml
<service xsi:type="java:com.adaptris.core.transform.XmlTransformService">
  <url>http://localhost/super-transform.xsl</url>
  <output-message-encoding>UTF-8</output-message-encoding>
</service>
```

The output message encoding can also be configured when you split a message by Xpath, or retrieve data from a database and insert it into an XML document, so check the javadocs for those services as well.

## Arbitarily changing character encoding

You might want to just change the character encoding to some arbitrary value for subsequent operations. You don't care about the contents of the message you just want to specify the character encoding to be some value other than what it is. If you don't specify an encoding, then it will cause the character encoding of the AdaptrisMessage to revert back to the platform default.

```xml
<service xsi:type="java:com.adaptris.core.services.ChangeCharEncodingService">
  <char-encoding>ISO-8859-5</char-encoding>
</service>
```


## Removing Byte order marks

Finally, on vaguely related note, one of the things that does happen is that you can get redundant UTF-8 byte order marks being generated by some applications (it appears the Microsoft apps like doing this). While not disallowed by the standard this does cause problems with the JVM which was recorded as [this bug](http://bugs.sun.com/bugdatabase/view_bug.do?bug_id=4508058) and is never going to be fixed. Anyway, use [Utf8BomRemover](http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/services/Utf8BomRemover.html) if you encounter mysterious 0xFEFF characters at the start of your data.

