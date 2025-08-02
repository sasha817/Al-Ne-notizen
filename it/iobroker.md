# Installing ioBroker

## Problem statement

ioBroker is needed to build a bridge between Homematic IP and Apple Home, as AH can't connect to HM-IP directly.

## Solution

Installing [ioBroker](https://iobroker.net/www/) as described [in Documentation](https://www.iobroker.net/#de/documentation/install/linux.md) works rather straightforward, until old version of nodejs found in official Ubuntu repo kicks in.

Troubleshooting is cumbersome and the only hint is executing `apt policy nodejs`, where faulty output looks like:

```bash
nodejs:
  Installed: (none)
  Candidate: 12.22.9~dfsg-1ubuntu3.6
  Version table:
     12.22.9~dfsg-1ubuntu3.6 500
        500 http://de.archive.ubuntu.com/ubuntu jammy-updates/universe amd64 Packages
        500 http://de.archive.ubuntu.com/ubuntu jammy-security/universe amd64 Packages
     12.22.9~dfsg-1ubuntu3 500
        500 http://de.archive.ubuntu.com/ubuntu jammy/universe amd64 Packages


## Your nodejs-Installation seems to be faulty. Shall we try to fix it?
```

[!] Installing node version 18 or later using nvm _does not do the trick_, the solution is to execute `iob nodejs-update`.
