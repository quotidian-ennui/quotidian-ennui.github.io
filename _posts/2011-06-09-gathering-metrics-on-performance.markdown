---
layout: post
title: "Gathering metrics on performance"
date: 2011-06-09 08:58
published: true
comments: false
#categories: [adapter, interlok]
tags: [adapter, interlok]
description: "Setting up the adapter with Perf4J"
keywords: "adapter, java, perf4j, log4j"


---
What's the most important thing when performance tuning the adapter; it's information, having a gut feeling about where the adapter is slow is all well and good, but you'll need to prove it. After all premature optimization is the root of all evil.

In addition to having Perf4J ([http://perf4j.codehaus.org][]) annotations on Workflows, and Producers (which can be enabled using aspectj AOP); 2.7.1 introduced the a new service Perf4jTimingService that can wrap any arbitrary service and gather performance metrics about that service's throughput.

<!-- more -->

It's very simple to configure. You simply need to have wrap the service within the Perf4jTimingService

```xml
<service xsi:type="java:com.adaptris.core.services.Perf4jTimingService">
<log-category>com.adaptris.perf4j.UpdateMessageStatusService</log-category>
<tag>LogMessageService</tag>
<service xsi:type="java:com.adaptris.core.services.LogMessageService"/>
</service>
```


Where the tag is the name that you see in the log file, and log-category is the log4j category that will be used to print the information.

After that, you'll need to configure perf4j using log4j.xml; the instructions on their website are very good, but I will briefly summarise them here.

* Configure an appender for writing out the performance information.
```xml
	<appender name="PERFORMANCE_LOG" class="org.apache.log4j.RollingFileAppender">
	  <param name="File" value="logs/stats.log"/>
	  <param name="Append" value="true"/>
	  <layout class="org.apache.log4j.PatternLayout">
	    <param name="ConversionPattern" value="%m%n"/>
	  </layout>
	</appender>
```

* Configure a Perf4j Appender to use the PERFORMANCE_LOG
```xml
	<appender name="Perf4jLog" class="org.perf4j.log4j.AsyncCoalescingStatisticsAppender">
	  <param name="TimeSlice" value="60000"/>
	  <appender-ref ref="PERFORMANCE_LOG"/>
	</appender>
```

* Now make the appropriate categories log to the perf4j appender
```xml
	<logger name="org.perf4j.TimingLogger" additivity="false">
	  <level value="INFO"/>
	  <appender-ref ref="Perf4jLog"/>
	</logger>
	<logger name="com.adaptris.perf4j" additivity="false">
	  <level value="INFO"/>
	  <appender-ref ref="Perf4jLog"/>
	</logger>
```

Once that's done; you'll get additional information in the log file specified (in our case stats.log)

```text
Performance Statistics   11:05:00 - 11:06:00
Tag          Avg(ms)       Min         Max     Std Dev       Count
MyTag         83.8          14         409        70.0         264
MyOtherTag    79.9          16         968       116.5         132
```

[http://perf4j.codehaus.org]: http://perf4j.codehaus.org
