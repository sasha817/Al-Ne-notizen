# Monitoring Linux system with Prometheus & Co

## The case

I would like to have a dashboard in Grafana to understand the status of my home Linux-based server.

## The idea

Simple approach would be to have Grafana displaying some data, which will be gathered by Prometheus. Prometheus will rely on node_exporter.

*I doubt I will need this guide ever again, but if I would, maybe I'd spare some time searching for this infos again.*

## Installation

### Installing Prometheus

Basic idea is taken from [Install Prometheus Server on CentOS 7 / RHEL 7
](https://computingforgeeks.com/install-prometheus-server-on-centos-rhel/?expand_article=1) article. Some adoptions apply thou.

What I liked a lot in Josphat's approach is isolating prometheus in its' own user with no shell access.

We will add a group and corresponding user:

```bash
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus
```



### Installing node_exporter

