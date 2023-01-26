---
layout: post
title: "Embbeded scripts in a workflow"
date: 2011-04-21 08:58
published: true
#categories: [ adapter, interlok]
tags: [adapter, interlok]
description: "Using JSR223 languages in the adapter"
keywords: "adapter, interlok, java, jruby, jsr223"

---

Let's take a look at some of the features that are available in the Adapter; today we're going focus on scripting language support.

For a while now (since 2.7.0) you've been able to embed a script (using any JSR223 scripting language) as part of a service. You can either use EmbeddedScriptingService (where the script is inline in the XML) or ScriptingService (where you refer to the filename containing the script).

<!-- more -->

Using a script as part of your workflow is a very powerful tool during integration; sometimes it is very hard to declaratively configure everything the business requires in XML. Let's never fall into the trap of thinking XML is a programming language.

Anyway, using a scripting language like ruby (as implemented by via JRuby) you can do as much (or as little as you like) to the message as it passes through the workflow. Accessing metadata, and subsequently deleting the file the metadata value refers to; randomly generating some data, you're just limited by your familiarity with the scripting language.

Let's look at an example; first of all you'll need to download the jruby binary from [http://www.jruby.org]. Put the jar in to the adapter-lib directory and then, we'll just insert this service into our workflow.

```xml
<service xsi:type="java:com.adaptris.core.services.EmbeddedScriptingService">
 <script><![CDATA[
$message.addMetadata('documentReference', "D" + rand(9999999999).to_s().rjust(10, '0'));

# Select a message-type from the valid list
msgtype_index = rand(4);
msg_types = Array[ "MessageType_1", "MessageType_2", "MessageType_3", "MessageType_4" ]
$message.addMetadata('messageType', msg_types.at(msgtype_index));

]]></script>
 <language>jruby</language>
</service>
```

Here we're just adding 2 items of metadata, messageType and documentReference, randomly generated. This is a pretty powerful way of generating test data within the adapter and checking behaviour.

If you do end up going down the road of using jruby, then just make sure to start the adapter with `-Dorg.jruby.embed.localcontext.scope=threadsafe` if you're using jruby in more than 1 workflow

