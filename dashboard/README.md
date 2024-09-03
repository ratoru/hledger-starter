# Hledger Dashboard

> [!WARNING]
> Do not expose this dashboard to the open internet!
> If you want to do that, you should read the docs on how to add the necessary protections.

Personal finance dashboard using `Grafana` and `Victoria Metrics`. Simpler graphs can be obtained using [hledger's graphs](https://hledger.org/charts.html).
This dashboard is based on [barrucadu](https://memo.barrucadu.co.uk/personal-finance.html)'s work. Promscale was replaced with Victoria Metrics.
They are both long-term storage extensions for Prometheus.

## Setup

1. Start Victoria Metrics and Grafana using Docker.

```bash
docker compose up -d
```

2. Install the necessary Python dependencies. I manage my Python dependencies using [uv](https://github.com/astral-sh/uv).

3. Set your date of birth in `exporters/hledger-export-to-victoria.py`.

4. Publish some data using `just publish`.

5. Go to `http://localhost:3000` and log in. The default username and password is `admin` + `admin`. You will be asked to change your password after logging in for the first time.

## Files

- `exporters/` contains the data publisher scripts.
- `dashboards` configures the actual dashboard(s).
- `grafana-datasource.yaml` and `grafana-dashboard.yaml` set up Grafana options.

## TODO

- [x] Docker file setup.
- [x] Load dashboard as default.
- [x] Rework export script.
- [ ] Check dashboard.
