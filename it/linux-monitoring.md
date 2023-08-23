# Monitoring Linux system with Prometheus & Co

## The case

I would like to have a dashboard in Grafana to understand the status of my home Linux-based server.

## The idea

Simple approach would be to have Grafana displaying some data, which will be gathered by Prometheus. Prometheus will rely on node_exporter.

*I doubt I will need this guide ever again, but if I would, maybe I'd spare some time searching for this infos again.*

## Installation

### Installing Prometheus

Basic idea is taken from [Install Prometheus Server on CentOS 7 / RHEL 7](https://computingforgeeks.com/install-prometheus-server-on-centos-rhel/?expand_article=1) article. Some adoptions apply thou.

What I liked a lot in Josphat's approach is isolating prometheus in its' own user with no shell access.

We will add a group and corresponding user:

```bash
sudo groupadd --system prometheus
sudo useradd -s /sbin/nologin --system -g prometheus prometheus
```

Then create a data directory and set permissions:

```bash
sudo mkdir /var/lib/prometheus
for i in rules rules.d files_sd; do sudo mkdir -p /etc/prometheus/${i}; done   # note to self: do we really need it?
```

Now let's install Prometheus itself.

```bash
mkdir -p /tmp/prometheus && cd /tmp/prometheus
curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest \
  | grep browser_download_url \
  | grep linux-amd64 \
  | cut -d '"' -f 4 \
  | wget -qi -

tar xvf prometheus*.tar.gz
cd prometheus*/
```

Move it to `/usr/local/bin` and config to `/etc`, consoles to prometheus dir ... :

```bash
sudo mv prometheus promtool /usr/local/bin/
sudo mv prometheus.yml  /etc/prometheus/prometheus.yml

sudo mv consoles/ console_libraries/ /etc/prometheus/
cd ~/
rm -rf /tmp/prometheus
```

#### Creating Prometheus config

```bash
sudo nano /etc/prometheus/prometheus.yml
```

The default config looks like:

```yaml
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']
```

#### systemd Service file

We need it in order to manage Prometheus with systemd:

```bash
sudo nano /etc/systemd/system/prometheus.service
```

Now the important part here is **to adjust number of vCPUs** in config - line `GOMAXPROCS=?`:

```
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/docs/introduction/overview/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
Environment="GOMAXPROCS=1"
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.external-url=

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
```

#### Permissions, firewall, service start

First setting the permissions:

```bash
for i in rules rules.d files_sd; do sudo chown -R prometheus:prometheus /etc/prometheus/${i}; done
for i in rules rules.d files_sd; do sudo chmod -R 775 /etc/prometheus/${i}; done
sudo chown -R prometheus:prometheus /var/lib/prometheus/
```

Then starting the service:

```bash
sudo systemctl start prometheus
sudo systemctl enable prometheus
```

Status check?

```bash
systemctl status prometheus
```

Opening the port in firewall:

```bash
sudo ufw allow 9090
```

Remember the original article mentions also CentOS, which has other steps, - I am working with Ubuntu.

My system is not accessible from outside world, so I will skip setting password protected access. Otherwise it can be done as described in [Secure Prometheus Server With Basic Password Authentication](https://computingforgeeks.com/secure-prometheus-server-with-basic-password-authentication/).

### Installing node_exporter

We assume that Prometheus and Grafana are already running. The base is, again [Monitor Linux Server Performance with Prometheus and Grafana in 5 minutes](https://computingforgeeks.com/monitor-linux-server-with-prometheus-grafana/?expand_article=1).

Let's get `node_exporter`:

```bash
curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep browser_download_url | grep linux-amd64 |  cut -d '"' -f 4 | wget -qi -
tar xvf node_exporter-*linux-amd64.tar.gz
```

Similar to Prometheus we will move files into appropriate locations:

```bash
cd node_exporter*/
sudo mv node_exporter /usr/local/bin/
cd ~/
```

And make sure it works:

```bash
$ node_exporter --version
node_exporter, version 1.5.0 (branch: HEAD, revision: 1b48970ffcf5630534fb00bb0687d73c66d1c959)
  build user:       root@6e7732a7b81b
  build date:       20221129-18:59:09
  go version:       go1.19.3
  platform:         linux/amd64
```

#### Configuring node_exporter to be managed by systemd

Enable the collector:

```bash
sudo nano /etc/systemd/system/node_exporter.service
```

And provide the configuration:

```
[Unit]
Description=Prometheus
Documentation=https://github.com/prometheus/node_exporter
Wants=network-online.target
After=network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/node_exporter \
    --collector.cpu \
    --collector.diskstats \
    --collector.filesystem \
    --collector.loadavg \
    --collector.meminfo \
    --collector.filefd \
    --collector.netdev \
    --collector.stat \
    --collector.netstat \
    --collector.systemd \
    --collector.uname \
    --collector.vmstat \
    --collector.time \
    --collector.mdadm \
    --collector.zfs \
    --collector.tcpstat \
    --collector.bonding \
    --collector.hwmon \
    --collector.arp \
    --web.listen-address=:9100 \
    --web.telemetry-path="/metrics"
```

Start the service and enable it:

```bash
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
```

Remember the firewall, too.

```bash
sudo ufw allow 9100
```

Make sure it works:

```bash
sudo ss -tunelp | grep 9100
```

#### Add exporter job to Prometheus

This enables Prometheus to scrap the metrics.

```bash
sudo nano /etc/prometheus/prometheus.yml

# Linux Servers
  - job_name: apache-linux-server1
    static_configs:
      - targets: ['<IP>:9100']
        labels:
          alias: server1

  - job_name: apache-linux-server2
    static_configs:
      - targets: ['<IP>:9100']
        labels:
          alias: server2
```

I need only one - but there could be multiple sections, of course.

Restart the Prometheus and make sure it is running:

```bash
sudo systemctl restart prometheus
telnet localhost 9100
```

Should return something like:

```
Trying 10.1.10.20...
Connected to 10.1.10.20.
Escape character is '^]'.
^]
```

### Adding the Dashboard to Grafana

In Grafana settings: `Dashboard -> New -> Import` (currently in dropdown menu), then import by [ID 1860](https://grafana.com/grafana/dashboards/1860-node-exporter-full/).

There are number of other options available - check [[this]](https://github.com/percona/grafana-dashboards) or [[this]](https://github.com/rfmoz/grafana-dashboards).
