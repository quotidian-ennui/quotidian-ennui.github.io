---
layout: post
date: 2016-12-09 11:00
comments: false
tags: [adapter, interlok]
#categories: [adapter, interlok]
published: true
title: "Using Exceptions for Flow Control"
description: "GOTOs are back, or perhaps they never went away."
keywords: "interlok"
---


If you search for the phrase "exceptions as flow control" then most of the top hits are about how bad it is and how you shouldn't. I don't disagree with that point, exceptions should be unexpected, so you shouldn't really be treating them as an expectation. Put it another way, exceptions are, in essence, GOTO statements; everyone knows that GOTOs are bad.

![goto](https://imgs.xkcd.com/comics/goto.png)

We recently had to integrate with an API that would provide us with all the new orders created by the application so that we can forward them to the supplier. In the event that there were more than a certain  amount; a `next_page_url` tag would be present in the returned JSON. There were a couple of issues with the behaviour that we batted around internally, but ultimately things and well... reasons[^1]. The way things work is all perfectly fine, but it isn't really designed for machine driven interaction (it seems to be a thing for API designers to think that ultimately there's someone looking at a screen and clicking on things).

One of our consultants decided to use [BranchingServiceCollection][] as a loop. This has always been possible, though not explicitly documented; if any service in a [BranchingServiceCollection][] returns `true` for _isBranching()_ then it is allowed to dictate the id of the next _Service_ that will be executed by the collection. Most of the time, only the `first-service-id` does that which means that it effectively becomes a if/else construct.

```xml

<service-list>
  <services>
    <add-metadata-service>
      <metadata-element>
        <key>url</key>
        <value>https://the/api/url</value>
      </metadata-element>>
    </add-metadata-service>
    <branching-service-collection>
      <first-service-id>get-data</first-service-id>
      <services>
        <branching-service-enabler>
          <unique-id>get-data</unique-id>
          <success-id>check-for-next-page</success-id>
          <failure-id>rethrow-exception</failure-id>
          <service class="service-list">
            <services>
              <!-- Do the API Call here using a MetadataDestination and process each of the
                   orders
              -->
            </services>
          </service>
        </branching-service-enabler>
        <branching-service-enabler>
          <unique-id>check-for-next-page</unique-id>
          <success-id>get-data</success-id>
          <failure-id>complete</failure-id>
          <service class="service-list">
            <services>
              <metadata-filter-service>
                <filter class="regex-metadata-filter">
                  <exclude-pattern>next_page_url</exclude-pattern>
                  <exclude-pattern>url</exclude-pattern>
                </filter>
              </metadata-filter-service>
              <service-list>
                <continue-on-fail>true</continue-on-fail>
                <services>
                  <json-path-service>
                    <source class="string-payload-data-input-parameter"/>
                    <json-path-execution>
                      <source class="constant-data-input-parameter">
                        <value>$.next_page_url</value>
                      </source>
                      <target class="metadata-data-output-parameter">
                        <metadata-key>next_page_url</metadata-key>
                      </target>
                    </json-path-execution>
                  </json-path-service>
                </services>
              </service-list>
              <!-- throws exception and stops loop if next_page_url returns null -->
              <validate-metadata-service>
                <required-key>next_page_url</required-key>
              </validate-metadata-service>
              <copy-metadata-service>
                <metadata-keys>
                  <key-value-pair>
                    <key>next_page_url</key>
                    <value>url</value>
                  </key-value-pair>
                </metadata-keys>
              </copy-metadata-service>
            </services>
          </service>
        </branching-service-enabler>
        <throw-exception-service>
          <unique-id>rethrow-exception</unique-id>
          <exception-generator class="last-known-exception"/>
        </throw-exception-service>
        <service-list>
          <unique-id>complete</unique-id>
        </service-list>
      </services>
    </branching-service-collection>
  </services>
</service-list>

```

Since 3.4.1 we've had [BranchingServiceEnabler][] which wraps any other service which returns `true` for _isBranching()_ and allows you to control the behaviour of [BranchingServiceCollection][] without additional work. Put simply, if the wrapped service throws an exception, then the `fail-id` is used as the next service, otherwise `success-id` is used. With this in mind what he's done is quite elegant. Essentially we flip-flop between two services until we no longer have a `next_page_url`. Actual errors processing calls to the API are rethrown and result in a failure. When we have read all the documents and `next_page_url` no longer exists in the JSON (we fail to json-path it out); we throw an exception that is handled as a loop termination marker and we finally fall out of the self-imposed loop.

Sadly though, this means that he used exceptions as a flow control mechansim and the velociraptors got him. However, it was interesting enough that it deserves recognition for posterity.

---
Comic courtsey of the generous [xkcd license](http://xkcd.com/license.html)

[^1]: Reasons, you know like when you say 'because' to a recalcitrant 5 year old.

[BranchingServiceCollection]: https://development.adaptris.net/javadocs/v3-snapshot/Interlok-API/com/adaptris/core/BranchingServiceCollection.html
[BranchingServiceEnabler]: https://development.adaptris.net/javadocs/v3-snapshot/Interlok-API/com/adaptris/core/services/BranchingServiceEnabler.html
