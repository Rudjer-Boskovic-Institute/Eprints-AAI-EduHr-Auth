EPrints webserver + SAML authentication inspired by Shibboleth example:
http://wiki.eprints.org/w/Webserver_authentication#Add_the_login_script


INSTALLATION INSTRUCTIONS

*** Backup everything first.. I cannot be responsible for eventual damage.

Requirements
- webserver authentication in place: http://wiki.eprints.org/w/Webserver_authentication
- simplesamlphp SP part in place and connected to AAI@EduHr SSO IdP: http://developer.aaiedu.hr/faq/8.html
- auth_memcookie installed and configured: http://authmemcookie.sourceforge.net/
- simplesamlphp authmemcookie enabled: http://simplesamlphp.org/docs/1.5/simplesamlphp-advancedfeatures#section_6

After installing/configuring requirements put "login" script somewhere in your archive directory
eg. $EPRINTS_ROOT/archives/$ARCHIVE_ID/aaieduhr/login

Configure apache to 'secure' that location:
eg.

---
        Alias /aaieduhr /usr/share/eprints3/archives/ARCHIVE_ID/aaieduhr
        <Directory "/usr/share/eprints3/archives/ARCHIVE_ID/aaieduhr">
                SetHandler perl-script
                PerlHandler ModPerl::Registry
                PerlSendHeader Off
                Options ExecCGI FollowSymLinks


                Auth_memCookie_Memcached_AddrPort "127.0.0.1:11211"

                Auth_memCookie_Authoritative on

                Auth_memCookie_SessionTableSize "40"

                AuthType Cookie
                AuthName "Eprints@ARCHIVE_ID"

                ErrorDocument 401 "/simplesaml/authmemcookie.php"

                Require valid-user

        </Directory>
---

Restart, test..

