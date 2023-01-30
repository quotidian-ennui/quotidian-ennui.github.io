---
layout: post
title: "Mercurial / HTTPS with Password Authentication"
date: 2011-11-11 08:58
comments: false
published: true
#categories: [tech, development, scm]
tags: [tech, development, scm]
description: "Setting up mercurial with apache https"
keywords: "mercurial, https, dvcs, apache, linux"
excerpt_separator: <!-- more -->
---

You care about being compliant with various regulatory regimes that say you can't ever remember private 172.16.x.x IP addresses and say them out loud (or write them down); and yet they will happily use Winzip to password protect a zip file with an easy to remember password (sometimes to maintain "compatibility" they use encryption that can be extracted by earlier versions).

Given that it takes approximately 1hr 15 minutes to brute force a 6 character password ([http://blog.itsecurityexpert.co.uk/2008/01/winzip-encryption-password-security.html][]) wouldn't you say that was somewhat sub-optimal?

<!-- more -->

If we cared about security, then we would be validating the clients certificate (and so you wouldn't need to have a password based access to your mercurial repositories); and you would be installing a valid certificate onto your server, you know the type signed by a root CA like Verisign or Thawte and all that.

None of that matters, we have established that we only care that the traffic is encrypted. This secures apache with a self-signed certificate and builds on [Mercurial/HTTP using password authentication][]. It's basically just a list of things you could cut and paste, if you are using cut and paste, then do vanilla HTTP first.

First of all we need to generate some certificates, openssl is probably installed if it's a standard CentOS 5.6 - there are other ways of generating certificates, but openssl is pretty quick and simple.

```console
# Generate private key
openssl genrsa -out myserver.key 1024
# Generate CSR
openssl req -new -key myserver.key -out myserver.csr
# Generate Self Signed Key that's valid for 10 years!!
openssl x509 -req -days 3650 -in myserver.csr -signkey myserver.key -out myserver.crt
# Copy the files to the correct locations.
cp myserver.crt /etc/pki/tls/certs/myserver.crt
cp myserver.key /etc/pki/tls/private/myserver.key
cp myserver.csr /etc/pki/tls/private/myserver.csr
```

Once all that's done you can create your SSL Virtual host.

```apache
<VirtualHost 172.16.1.1:443>
  ServerName classified:443
  ServerAdmin webmaster
  DirectoryIndex index.html index.htm index.php index.cgi index.shtml
  DocumentRoot /var/www/html
  Options +Indexes +FollowSymLinks +ExecCGI +Includes
  ErrorLog logs/ssl_errors_log_classified
  TransferLog logs/ssl_access_log_classified
  LogLevel warn
  SSLEngine on
  SSLCipherSuite ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP
  SSLCertificateFile /etc/pki/tls/certs/myserver.crt
  SSLCertificateKeyFile /etc/pki/tls/private/myserver.key
  <Files ~ "\.(cgi|shtml|phtml|php3?)$">
      SSLOptions +StdEnvVars
  </Files>
  SetEnvIf User-Agent ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0
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

```

Snap! you're now able to clone the self same repository as last time, only use a HTTPS URL. Of course, you know that you're using a self-signed certificate, and nothing will trust it by default...

```console
$ hg clone --insecure https://172.16.1.1/hg-web/awesome_code
warning: 172.16.1.1 certificate with fingerprint c1:34:89:f9:2b:4f:c0:e3:77:7e:5b:21:17:86:2c:ad:56:05:23:a7 not verified (check hostfingerprints or web.cacerts config setting)
http authorization required
realm: Mercurial repositories
user: trex
password:
warning: 172.16.1.1 certificate with fingerprint c1:34:89:f9:2b:4f:c0:e3:77:7e:5b:21:17:86:2c:ad:56:05:23:a7 not verified (check hostfingerprints or web.cacerts config setting)
adding changesets
adding manifests
adding file changes
added 39 changesets with 428 changes to 389 files
```

Nevertheless, your traffic is now encrypted yet still insecure.


[http://blog.itsecurityexpert.co.uk/2008/01/winzip-encryption-password-security.html]: http://blog.itsecurityexpert.co.uk/2008/01/winzip-encryption-password-security.html
[Mercurial/HTTP using password authentication]: {{site.baseurl}}/blog/2011/08/11/mercurial-http-using-password-authentication/
