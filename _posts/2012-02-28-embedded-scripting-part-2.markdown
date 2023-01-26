---
layout: post
title: "Embedded Scripting part 2"
date: 2012-02-28 14:00
comments: false
#categories: [adapter, interlok]
tags: [adapter, interlok]
published: true
description: "Using a jruby script to re-format EDI messages"
keywords: "adapter, jruby, jsr223, edi, interlok"

---

This week I had the first real use case for embedding a script inside an adapter workflow. In one particular instance we were actually receiving EDI files that were terminated by an odd character; _od_ and _hexdump_ thought it was `\0205` (0x85) but when we read the file in using a java test stub it turned out to be `0xffffff85` which was annoying to say the least.

We can turn it into 0x85 by doing a classic & 0xFF, but you can't do that terribly easily within the adapter, so this is a perfect chance for us to use [[jruby]](http://jruby.org)!

<!-- more -->

I had intended to use _gsub_ to do a regular expression find and replace within ruby but this wouldn't work because there are some subtle differences between jruby/ruby strings and java string. The representation of the 0x85 char in a ruby string became automagically converted to 0x3F (a question mark) when I accessed it in ruby. There's probably a very clear documented reason for that but I really wasn't going to RTFM. The simple answer is to iterate through the sequence of characters and to replace the offending character directly with something else rather than trying to use a regular expression.

### The guts of the service

I've used java code everywhere rather than trying to use the ruby functionality provided by jruby; probably tons of better ways to do this, but my main goal is to avoid any encoding issues when inline type conversion takes place between ruby and java; those duck languages aren't all they're cracked up to be sometimes. Of course as it's interpreted you don't get any feedback of syntax errors until you try and send a message through the service (random ; littered all over the place is just the legacy of my C/C++ and java habits, I know I don't need them).

```xml
<service xsi:type="java:com.adaptris.core.services.EmbeddedScriptingService">
  <language>jruby</language>
  <script><![CDATA[
include Java

payloadBytes=$message.payload;
sb = java.lang.StringBuilder.new;
$length = payloadBytes.length;
$i=0;
while $i < $length do
  # If we don't do it like this, the byte conversion between ruby + java sometimes
  # screws things up; so we just use "hex" values all the way.
  hex = java.lang.Integer::toHexString((payloadBytes.at($i) & 0xFF));
  charValue = java.lang.Integer.parseInt(hex, 16);
  # Let's convert 0x85 (octal 205) to caret + linefeed (on windows that becomes crlf)
  if charValue == 0x85
    sb.append("^\n");
  else
    sb.append(java.lang.Character::toChars(java.lang.Integer::parseInt(hex, 16)));
  end
  $i +=1;
end
$message.setStringPayload(sb.toString);
]]></script>
</service>
```

There you have it, we have successfully dealt with a problem file without resorting to any custom services. The end result is a nicely formatted EDI file where previously I might have had to _tr '\205' '\135'_ the file in another process entirely.

