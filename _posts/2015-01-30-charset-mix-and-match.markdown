---
layout: post
title: "Character set woes"
date: 2015-01-30 13:00
comments: false
categories: adapter interlok
tags: [adapter, interlok]
published: true
description: "Applications not respecting character sets"
keywords: "integration, character encoding"
header-img: img/banner_crane.jpg
---

Character encoding can be the bane of your life when you're doing integration. It's all fine and dandy when you're dealing with the US-ASCII character set, but it all goes wrong when you start dealing with internationalised data. Even worse, there are situations where the source data is a mix of 2 different character encodings and you get 2 different byte representations for the same character. This is down to the source application not respecting encoding properly; screwing it all up.

<!-- more -->

Of course the adapter is perfectly capable of dealing with this situation if the source data cannot be fixed-at-source; we would just use a [FindAndReplaceService][] on the document and replace the offending characters with the correct ones before continuing.

Given a document that is encoded in ISO-8859-1; the beta character ß is encoded as 0xDF, whereas in UTF-8 it would be encoded as 2 bytes (0xC3, 0x9F). In a document that mixed and matched ISO-8859-1 and UTF-8 characters willy nilly, then you can have the situation where it might be SiecherstraÃŸe or Siecherstraße depending on what the source application feels like doing.

If workflow in question treats messages as ISO-8859-1; then you need to do a find and replace of the UTF-8 characters and replace them with the equivalent ISO-8859-1 character.

{% highlight xml %}
<service xsi:type="java:com.adaptris.core.services.findreplace.FindAndReplaceService">
  <find-replace-pairs>
    <key-value-pair>
      <key>&amp;#xC3;&amp;#x9F;</key>
      <value>&amp;#xDF;</value>
    </key-value-pair>
  </find-replace-pairs>
  <replacement-source xsi:type="java:com.adaptris.core.services.findreplace.ConfiguredReplacementSource"/>
  <replace-first-only>false</replace-first-only>
</service>

{% endhighlight %}

In situations like this though you still have to eyeball the file in question, and then use something like [a UTF-8 table][utf8] to compare the duff values against another character set; a editor that can toggle between hex and text display is very useful as well.

[utf8]: http://www.fileformat.info/info/charset/UTF-8/list.htm
[FindAndReplaceService]: http://development.adaptris.net/javadocs/v2-snapshot/com/adaptris/core/services/findreplace/FindAndReplaceService.html