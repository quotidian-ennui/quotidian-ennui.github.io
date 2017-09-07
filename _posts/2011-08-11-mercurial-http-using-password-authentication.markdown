---
layout: post
title: "Mercurial / HTTP using Password Authentication"
date: 2011-08-11 08:58
published: true
comments: false
categories: tech development scm
tags: [tech, development, scm]
description: "Setting up apache with mercurial with password authentication"
keywords: "mercurial, http, dvcs, apache, linux, centos"

---

Generally speaking,  we host our mercurial repositories using SSH; sometimes of course, we need to do it via HTTP because we don't want to give external contractors SSH access because who knows what damage they can do with a terminal (anyone who's seen someone do rm -rf * in /etc knows what I'm talking about). It's bad enough they damage the contents of the repository with their inability to read a good primer site like [http://hginit.com][] (you know who you are).

<!-- more -->

The following image shows a mercurial graphlog and is a nice example of what can happen if you really haven't taken the time to understand mercurial; no names no pack drill as they say, but I know who you are (yes, this was done by the same person, and yes, that was pretty frustrating).

![mercurial branch madness]({{ blog_baseurl }}/images/posts/mercurial-branch-madness.png)

This then, is a quick start guide that is distilled from the user guide that is available on the mercurial website, step by step instructions that assume you're running CentOS 5.6 with mercurial and apache pre-installed; I don't need to tell you how to enable the RPMForge yum repository do I? You're also savvy enough to understand the key concepts behind apache configuration; cutting and pasting this won't work, well it might, or it might not.

Having done all of this though, you might want to secure the apache server with a certificate/HTTPS, because you care about security inasmuch as you know that it's something that needs to be done to make you compliant to some idiotic regime (compliance is important, but when it's done badly you may as well just host all your stuff on an public anonymous FTP server). This will also allow you to remove the push_ssl = false setting in the hgrc file; but this is all a subject for another day.

* Create a directory /var/www/mercurial
* Copy /usr/share/doc/mercurial/hgweb.cgi in there.
* touch /var/www/mercurial/hgweb.config
* Modify hgweb.cgi to refer to hgweb.config (full path) it's obvious where it needs to go.
* Modify virtual host (or create a new one, or whatever)

{% highlight apache %}

<VirtualHost *:80>
  ServerName mercurial
  ServerAlias mercurial.mydomain.com
  ServerAdmin webmaster
  DirectoryIndex index.html index.htm index.php index.cgi index.shtml
  DocumentRoot /var/www/html

  ScriptAlias /hg-web "/var/www/mercurial/hgweb.cgi"
  <Directory /var/www/mercurial/>
      Options ExecCGI FollowSymLinks
      AllowOverride None
  </Directory>
  <Location /hg-web>
    AuthType Digest
    AuthName "Mercurial repositories"
    AuthDigestProvider file
    AuthUserFile /var/www/mercurial/hgusers
    Require valid-user
  </Location>
</VirtualHost>
{% endhighlight %}

* Create / clone a repo from somewhere (into /var/www/mercurial if you like)
* Modify hgweb.config to add in a path for your repository; there's other things you can do here, like infer all the repositories based on a root directory, but we're going to keep it simple.

{% highlight ini %}
[paths]
awesome_code = /var/www/mercurial/awesome_code
{% endhighlight %}

* Create the users file (that's your AuthUserFile from the virtual host location directory above)

{% highlight console %}
htdigest -c hgusers "Mercurial repositories" trex
{% endhighlight %}

* You'll need to change the ''.hg/hgrc'' file for each repository and add in various bits and bobs for the repository. This can be done in hgweb.config if you want the contact details to be inherited by all repositories that you're making available

{% highlight ini %}
[web]
# (shows up when you browse to the web page only)
contact = T. Rex
#(shows up when you browse to the web page only)
description = My Awesome code
#(do not force https for pushing)
push_ssl = false
# (use * for all users, otherwise only Mr Rex can push changes)
allow_push = trex
{% endhighlight %}

After all of that, restarting apache is a snap, and you should be able to point your browser to the apache installation and view the repository. You can also clone the thing now, and push changes.

{% highlight console %}
$ hg clone http://192.168.1.1/hg-web/awesome_code
http authorization required
realm: Mercurial repositories
user: trex
password:
destination directory: awesome_code
requesting all changes
adding changesets
 (boring stuff skipped)

$ hg push
pushing to http://192.168.1.1/hg-web/awesome_code
http authorization required
realm: Mercurial repositories
user:  trex
password:
searching for changes
remote: adding changesets
remote: adding manifests
remote: adding file changes
remote: added 1 changesets with 1 changes to 1 files
{% endhighlight %}


[http://hginit.com]: http://hginit.com
