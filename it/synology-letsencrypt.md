# Updating Let's Encrypt certificate on Synology DSM

## The case

Synology NAS is behind the router and although the ports are forwarded properly, it will disallow connecting via port 80 or 443. Some bits and pieces of information are available on the internet thou, but hard to find in all the trash around, suggesting you go through GUI and stumble upon the very same certificate update error message, which simply does not tell you anything.

## The analysis

First bits of knowledge needed to diagnose the problem are available from Let's Encrypt (who might have guessed...) and one of the hints is pointing exactly to port redirection:

> Your **external** port 80 needs to be open and your NAS needs to **externally** respond via HTTP over port 80 or redirect to **externally** respond via HTTPS over port 443 (even with a wrong/expired certificate). The ports that your NAS uses internally (such as 5001) are **irrelevant**. If your NAS tries to redirect to **externally** respond over port 5001, this will **not** work for satisfying an http-01 challenge. To make things absolutely clear, "external" means "exposed to the public internet" while "internal" means "within your private network". Go to [redirect-checker.org](//redirect-checker.org) 244 to see what's going on **externally** with your NAS.

Source: [Clarification of Synology NAS DiskStation Manager (DSM) Documentation of Let’s Encrypt Integration](https://community.letsencrypt.org/t/clarification-of-synology-nas-diskstation-manager-dsm-documentation-of-lets-encrypt-integration/142511).

And of course, the redirect checker shows my port 80 is redirected to 5000 with response HTTP/302. This, however, poins to a reason, but not to a cure.

The next bits of knowledge are found as [a 6 years old post](https://bluescreengenerator.de/blog/synology-let%27s-encrypt-zertifikat-manuell-erneuern) on BlueScreenGenerator.de which talks about manual update of SSL certificates for Synology. 

> Schritte zum manuellen Erneuern eines Let’s Encrypt Zertifikats auf einem Synology NAS in Kurzform:
>
>  1. Wenn Port 80 zum NAS nicht dauerhaft geöffnet ist: Port freigeben
>  2. per SSH als admin auf NAS einloggen
>  3. mit `sudo -s` zum root werden
>  4. `/usr/syno/sbin/syno-letsencrypt renew-all -vv`
>  5. Webserverdienst neu starten oder alternativ NAS neu starten

I see two problems here, however. Having local access to Synology NAS and port 80 open to external access is not that good idea, so in case of remote access I'd rather prefer VPN and then "kind-of-local" access to NAs. In my case the access is local, within the network, at least one problem solved.

The second problem is - normally your SSH is off. You can turn it on, as described on Synology website: [Wie kann ich mich über SSH mit Root-Berechtigung bei DSM/SRM anmelden?](https://kb.synology.com/de-de/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet).

## The Cure

Last step is as described above, but with a minor change: the `-vv` option outputs massive amount of data, I find `-v` a bit better. So:

```bash
#log in to Synology via SSH
sudo -i
/usr/syno/sbin/syno-letsencrypt renew-all -v
```

And reboot the NAS. Done.