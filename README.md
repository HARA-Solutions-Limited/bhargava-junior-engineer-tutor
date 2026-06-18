# Bhargava — Junior Engineer Tutor

An Elastic Agent Builder tutor named **Bhargava** (after Lord Parasurama) that onboards junior engineers to the **OpenTelemetry Astronomy Shop** using live traces, service topology, and Kibana deep links.

Built for the DevOps Society × Elastic London Hack Night.

## Quick start

```bash
chmod +x bootstrap.sh
./bootstrap.sh

# After Elastic Cloud credentials are in .env:
cd vendor/elastic-opentelemetry-demo
docker compose up -d

# Create agent in Kibana (UI) or:
../scripts/create-agent.sh

# Generate shop traffic, then chat with bhargava-tutor in Agent Builder
open http://localhost:8080
```

## Project layout

```
bhargava-junior-engineer-tutor/
├── README.md
├── TLDR.md
├── Architecture.md
├── bootstrap.sh
├── docker-compose.yml
├── .env.example
├── agent/
│   ├── instructions.txt
│   └── bhargava-tutor-agent.json
├── scripts/
│   ├── create-agent.sh
│   └── generate-traffic.sh
└── docs/
    ├── requirements.md
    ├── hld.md
    ├── lld.md
    ├── runbook.md
    ├── implementation-tasks.md
    └── uml/
```

## Documentation

| Doc | Description |
|-----|-------------|
| [TLDR.md](TLDR.md) | One-page overview |
| [Architecture.md](Architecture.md) | C4 + reverse-engineered Astronomy Shop |
| [docs/runbook.md](docs/runbook.md) | Hack-night copy-paste spec |
| [docs/requirements.md](docs/requirements.md) | EARS requirements |
| [docs/hld.md](docs/hld.md) | High-level design |
| [docs/lld.md](docs/lld.md) | Agent tools, API, contracts |
| [docs/elastic-cloud-setup.md](docs/elastic-cloud-setup.md) | Step-by-step Elastic Cloud configuration |
| [docs/simulation-scenarios/](docs/simulation-scenarios/) | Easy / medium / hard training exercises |

## Demo question

> *I just clicked Place Order. Walk me through what happened using a real checkout trace from the last 30 minutes. Include Kibana links.*

## Related

[ArthaLedger Buyside](../README.md) — separate buyside diligence toolkit in this monorepo (`ch_finance/`).
