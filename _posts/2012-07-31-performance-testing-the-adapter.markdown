---
layout: post
title: "Performance testing the adapter"
date: 2012-07-31 21:00
comments: false
categories: adapter interlok
tags: [adapter, interlok]
published: true
description: "Performance Metrics for the adapter"

---

One of the things that we're always asked is to provide some performance metrics for the adapter. This is always something I'm loathe to do. Raw performance numbers are almost always meaningless in the real world; it depends on too many things, the complexity of your environment, the quality of the network, what type of processing that you're actually doing.

<!-- more -->

Internally we do have some performance metrics about the adapter, gathered using [Perf4j](http://perf4j.codehaus.org) running in AOP mode (using the @Profiled annotation). The information we get out of the adapter helps us tune the adapter in various runtime environments. It's most heavily used by our consultancy team to help them design their workflows. I run them from time to time to make sure that new features/bug-fixes aren't significantly impacting performance.

The development team recently re-ran the tests and we thought we could publish some of the simpler results. For the purposes of the tests we're using 2 JMS Brokers (SonicMQ 8.5) in their out of the box configuration; one is local and the other is remote. The adapter is a single channel adapter (local->remote), with defaults for everything; we used [jmsloadtester](https://github.com/niesfisch/jmsloadtester) to drive the initial message delivery.

I consider all of these metrics relative; the actual numbers will vary from installation to installation. Our test plaform was a Dell LX502 laptop (local Sonic+Adapter) talking to an Intel Core 2 Duo (E6750) connected via a 100Mbps switch; the size of message was about 3k. It was basically done with some old hardware we had lying around in the labs; no shiny hardware for us.

{% highlight text %}
Performance Statistics   10:39:00 - 10:42:00
Tag                                                  Avg(ms)         Min         Max     Std Dev       Count
PtpProducer.produce()                                    3.5           1         310         6.0       10000
PoolingWorkflow(PoolingSonicConfig)                      4.8           2         312         6.2       10000
PoolingWorkflow.sendMessageLifecycleEvent()              0.7           0           7         0.6       10000
{% endhighlight %}

* _PtpProducer.produce()_ metric gives the time taken to physically call _QueueProducer#send(Destination)_ which will involve sending all the bits across the network.
* _PoolingWorkflow.sendMessageLifecycleEvent()_ is the time on average it takes to send the message lifecycle event associated with each message.
* _PoolingWorkflow(PoolingSonicConfig)_ is the average time it takes for the entire workflow to finish, from the point of entry to the point of delivery. It does ignore the time it takes for the JMS Broker to _deliver_ the message to us; by the time we have control so that we can start measuring performance, the bits have already travelled across the network to us.

As we can see, there is an overhead to sending the message lifecycle event; by default it is turned on, but you can easily turn it off by marking each workflow with send-events=false. If we do that, then the numbers change.

{% highlight text %}
Performance Statistics   11:06:00 - 11:09:00
Tag                                                  Avg(ms)         Min         Max     Std Dev       Count
PtpProducer.produce()                                    3.1           1         308         9.1       10000
PoolingWorkflow(PoolingSonicConfigSendNoEvents)          3.3           1         309         9.1       10000
PoolingWorkflow.sendMessageLifecycleEvent()              0.0           0           8         0.1       10000
{% endhighlight %}

Using the adapter in its very simplest form adds an overhead of approximately 0.3 milliseconds to do a glorified JMS copy. We would be able to get some more performance gains by doing JVM tuning and using other configuration options; most of the time though, the adapter *isn't* your bottleneck.

Ultimately though, all you need to know is

1. If you don't care about events then make sure send-events is false.
1. Using PoolingWorkflow will give you a performance benefit if you have complex services like transforms or database lookups, however, it gives you only marginal performance gain if there are no services to be executed.
1. Engage our consultancy team to give you a pro-active health/performance check; they're the people that know how to tune the adapter.

