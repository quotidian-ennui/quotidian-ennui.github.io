---
layout: post
title: "Change is just change"
comments: false
tags: [general]
#categories: [general]
published: true
description: "Plus ça change, plus c'est la même chose"
keywords: ""
excerpt_separator: <!-- more -->
---

In the midst of the COVID-19 pandemic, we should all be getting a lot of time for introspection and examination. This was going to be a post about the changes I needed to make to git-flow so that we can support the changes that github decided on around default branch naming in git. It veered off on a tangent pretty quickly because I didn't need to do anything with git-flow. The original script writer decided that _master, production, and main_ were all valid trunk branch names for the default behaviour, so now we have git-flow enabled with `main+develop` and older repositories with  `master+develop`. I suspect this isn't by coincidence.

<!-- more -->

The whole naming thing got me to thinking about the the reasons for the change and whether we should consider it something that people will just label _political correctness gone mad_. It should be apparent now that the bulk of civilization is built on top of the indenture of _the other_ and the exploitation of _the other_ for the beneft of those who are _inside_. Change only comes when people have a reason to change, this seldom comes from those that want things to stay the same. The people who are most determined to make those changes aren't going to be the insiders. For me the status quo works so this means I have no fundamental desire to change it, but this just means I should be supportive of change when it comes.

To have some historical context to my own personal situation; I'm a first generation immigrant from Hong Kong (SAR) to the UK a long time ago. I got casual abuse and racism when I was young, I was the only Chinese lad in my school for probably about 10 years (all of primary, 1/2 of secondary). Weakness or otherness in general is going to picked up by children and torn apart and I've had plenty of experience of being _the other_. However, I've never been stopped and searched because of the colour of my skin, or been locked up because I got a bit shouty and angry down the pub. That's left me with a relatively unscathed journey through life, so I'm pretty ambivalent about it all.

My own culture and upbringing feeds in as well when examining my ambivalence. There's plenty of things that my parents say that are racist; my dad complained about people on the bus chattering away on the bus in a foreign language, I tried to arch an eyebrow at him, failed, but mentioned that he never speaks English to my mum on the bus. They have a phrase they use at dinner time to hurry us along: _The Japanese are coming_[^1]; they say it to their grandchildren when they're being particularly tardy at the dinner table. This harks back to a time before theirs (they were born in the 1940s) but is a phrase that has seeped into their consciousness, into mine, and into their grandchildren. Is it a racist turn of phrase? almost certainly. They didn't experience it, but they are certainly parroting a truth that was relevant to them in living memory. It isn't relevant to me, but I'm still parroting it as though it were a truism that shouldn't be questioned.

There are those that are going to go all ragey and quote Niemoller and say it's the thin end of the wedge, or the start of a slippery slope. Language evolves and changes; its meaning derives from consensus and no amount of railing against the dying of the light is going to change that. Language purists have already lost the fight about literally,  fewer/less, use of the semi-colon and the greengrocer's apostrophe. They're going to lose the fight about _master_, especially outside of its meaning of expertise. This isn't the hill that I'd choose to die on; if I needed to patch git-flow to make things work seamlessly with our internal notion of repository correctness, then I would have. We certainly wouldn't have insisted on retaining the `master+develop` naming convention.

[^1]: No, not in the influx of technology way.