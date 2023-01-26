---
layout: post
title: "Upgrading to Redmine 1.4 on CentOS 5"
date: 2012-06-01 17:00
comments: false
#categories: [tech, development, linux]
tags: [tech, development, linux]

published: true
description: "Brief notes on upgrading redmine from 1.1.2 to 1.4 on CentOS 5"
keywords: "redmine, centos"

---

Recently we upgraded redmine from 1.1.2 to 1.4.2. It was an activity that I had planned for a long time, but as usual things get in the way of doing that. Redmine, perhaps ruby on rails makes that easy for you, has a very well documented path for upgrades so the upgrade itself didn't take very long, about half an hour. Of course I had run through the process already on a different machine to make sure we weren't going to hit any odd snags due to the platform / ruby versions or whatever.

<!-- more -->

First of all, of course you need to back up the redmine database, and all the attachment/wiki pages that might be in your system, so that's a mysqldump and a tar of `${redmine}/public/files`. Naturally, we already take a backup of those two things every night (not to mention the VM mirroring that goes on), so I was quite pretty relaxed about this. Of course, I always back things up before I start tinkering with production systems; I learnt that lesson well.

```console
hg clone --updaterev 1.4-stable https://bitbucket.org/redmine/redmine-all redmine-1.4
mv /var/www/redmine /var/www/redmine-1.1.2
mv /var/www/redmine-1.4 /var/www/redmine
```

I used mercurial rather than subversion to get the stable release. It was really for one reason only; you don't get _.svn_ directories scattered around the directory tree, you have a single _.hg_ directory which you can delete if you so choose. That and no-one in their right mind would choose to use subversion or CVS if they can help it anymore.

The later releases of redmine use *bundler* to handle dependencies; because we had the XLS_Export plugin installed we need to make sure an additional gem is installed via bundler.

```console
cd /var/www/redmine
(cd vendor/plugins; cp -R /var/www/redmine-1.1.2/vendor/plugins/all_my_custom_plugins .)
(cd public/files; cp -R /var/www/redmine-1.1.2/public/files/* .)
gem install bundler
echo 'gem "spreadsheet"' >> Gemfile.local
bundle install --without development test postgresql sqlite rmagick
```

Our database is mysql, so we can safely ignore postreSQL and SQLite; rmagick depends on ImageMagick, the CentOS repository version of ImageMagick isn't up-to-date enough for rmagick, so we need to ignore that as well. ImageMagick was always purely optional anyway.

Because we were upgrading from such an old version I was fully expecting to have to redo all the configuration anyway. As it turns out not too much had changed, the database settings were easily re-creatable, but the email configration was now in configuration.yml so I had edit that to use sendmail for email. I also made sure that environment.rb was forced into _production_ mode because that was what I had to do originally (for 1.0.4); I couldn't really be bothered to figure out the right way to do it.

```yaml
default:
  email_delivery:
    delivery_method: :sendmail
```

Whilst I am a big fan of the redmine logo, I did edit `./app/helpers/application_helper.rb` to point to our desired favicon image. Then after all of that, it was a case of running rake a few times. Every time I ran rake, I got some warnings about having to install RDoc 2.4.2+ (even though it was installed); annoying but acceptable enough.

```console
cd /var/www/redmine
rake generate_session_store
rake db:migrate RAILS_ENV=production
rake db:migrate_plugins RAILS_ENV=production
rake tmp:cache:clear
rake tmp:sessions:clear
```

And that was that, it was time to take down the holding page, and restore the phusion configuration in the apache configuration, and restart httpd. You might be thinking why we didn't go straight to Redmine 2.0; well, I have been toying with installing some of the modules from [RedmineCRM](http://redminecrm.com) and it only supports 1.4; That's why.




