# Hledger Dashboard

> [!WARNING]
> Do not expose this dashboard to the open internet! 
> If you want to do that, you should read the docs on how to add the necessary protections.

Personal finance dashboard using `Grafana` and `Prometheus`. Simpler graphs can be obtained using [hledger's graphs](https://hledger.org/charts.html).
This dashboard is based on [barrucadu](https://memo.barrucadu.co.uk/personal-finance.html)'s work.

## Setup

1. Start Prometheus and Grafana using Docker.

```bash
docker compose up -d
```

2. Publish some data using ... `cron`?

3. Go to `http://localhost:3000` and log in. The default username and password is `admin` + `admin`. You will be asked to change your password after logging in for the first time.

## Files

- `dashboard.json` configures the actual dashboard.
- `prometheus.yml` configures Prometheus.
    - Since we rarely update our finances, we will send data to the `pushgateway` defined in `compose.yml`. (Usually, Prometheus pulls data from running services.)
    - If you do not want that, you will have to look into more complex options like `Cortex` or `Thanos`.
- `provisioning/` contains Grafana settings.
- `exporters/` contains the data publisher scripts. 

## TODO

- [x] Docker file setup.
- [x] Load dashboard as default.
- [ ] Rework export script.
- [ ] Check dashboard.

