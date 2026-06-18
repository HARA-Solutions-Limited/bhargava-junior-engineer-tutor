# Architecture — Bhargava & Astronomy Shop

C4-model architecture for the **Bhargava** tutor system and reverse-engineered **OpenTelemetry Astronomy Shop** demo.

## Document map

| C4 level | Diagram | Scope |
|----------|---------|-------|
| L1 System Context | [c4-system-context.puml](docs/uml/c4-system-context.puml) | Bhargava + users + external systems |
| L2 Containers | [c4-containers.puml](docs/uml/c4-containers.puml) | Shop, collector, Elastic, Agent Builder |
| L3 Components | [c4-component-bhargava.puml](docs/uml/c4-component-bhargava.puml) | Agent tools & tutoring logic |
| Reverse-engineered shop | [astronomy-shop-services.puml](docs/uml/astronomy-shop-services.puml) | Microservice topology |
| Runtime sequence | [sequence-tutor-session.puml](docs/uml/sequence-tutor-session.puml) | Checkout → telemetry → tutor |

Related: [hld.md](docs/hld.md) · [lld.md](docs/lld.md) · [requirements.md](docs/requirements.md)

---

## L1 — System Context

**Bhargava** helps junior engineers learn the Astronomy Shop by querying live observability data and returning guided explanations with Kibana links.

```
┌─────────────┐         ┌──────────────────────────────────────┐
│   Junior    │ chat    │           Bhargava System            │
│  Engineer   │────────▶│  (Agent Builder + Astronomy Shop     │
└─────────────┘         │   telemetry in Elastic Observability)│
                        └──────────┬─────────────┬─────────────┘
                                   │             │
                    OTLP telemetry │             │ manage / query
                                   ▼             ▼
                        ┌──────────────┐  ┌─────────────────┐
                        │ Astronomy    │  │ Elastic Cloud   │
                        │ Shop (OTel   │  │ Observability   │
                        │ Demo)        │  │ (APM + Agent    │
                        └──────────────┘  │  Builder)       │
                                          └─────────────────┘
```

**Actors**

| Actor | Role |
|-------|------|
| Junior engineer | Asks natural-language questions, clicks Kibana links |
| Demo operator | Starts Docker Compose, generates shop traffic |
| Elastic Cloud | Hosts observability backend and Agent Builder |

---

## L2 — Containers

| Container | Technology | Responsibility |
|-----------|------------|----------------|
| **Frontend proxy** | Envoy (C++) | Entry HTTP gateway `:8080` |
| **Astronomy Shop services** | Polyglot microservices | E-commerce business logic |
| **OTel Collector** | OpenTelemetry Collector | Receives OTLP, processes, exports |
| **Elastic Observability** | Elasticsearch + Kibana APM | Stores and visualises telemetry |
| **Agent Builder** | Kibana AI feature | Hosts `bhargava-tutor` agent & tools |
| **Load generator** | Locust (Python) | Synthetic traffic |

**Telemetry path (Elastic fork)**

```
Microservices ──OTLP/gRPC:4317──▶ OTel Collector ──OTLP──▶ Elastic APM
                                              └──▶ (optional local backends)
```

---

## L3 — Bhargava components

| Component | Type | Role |
|-----------|------|------|
| Chat UI | Kibana Agent Builder | User conversation surface |
| Instruction engine | Agent configuration | Persona, Bhargava method, Kibana URL templates |
| Tool orchestrator | LLM + tool routing | Selects observability tools per question |
| Observability toolset | Built-in Elastic tools | `get_services`, `get_traces`, topology, logs |
| Response formatter | Prompt contract | Big picture → walkthrough → concepts → links → quiz |

See [c4-component-bhargava.puml](docs/uml/c4-component-bhargava.puml).

---

## Reverse-engineered — Astronomy Shop

Source: [OpenTelemetry Demo architecture](https://opentelemetry.io/docs/demo/architecture/) and [elastic/opentelemetry-demo](https://github.com/elastic/opentelemetry-demo).

### Purpose

Microservice e-commerce demo ("Astronomy Shop") illustrating OpenTelemetry across languages and protocols in a realistic distributed system.

### Service catalogue

| Service | Language | Role |
|---------|----------|------|
| frontend-proxy | C++ (Envoy) | HTTP ingress, routes to UI and assets |
| frontend | TypeScript | React web storefront |
| product-catalog | Go | Product listings (gRPC) |
| product-reviews | Python | Reviews + LLM integration |
| cart | .NET | Cart state (Valkey cache) |
| checkout | Go | **Purchase orchestrator** — primary teaching anchor |
| payment | JavaScript | Payment processing |
| shipping | Rust | Shipping orchestration |
| quote | PHP | Shipping quotes (HTTP) |
| email | Ruby | Order confirmation emails |
| currency | C++ | Currency conversion (gRPC) |
| recommendation | Python | Product recommendations |
| ad | Java | Ad serving |
| fraud-detection | Kotlin | Async fraud checks (Kafka consumer) |
| accounting | .NET | Async order accounting (Kafka → PostgreSQL) |
| flagd / flagd-ui | Go / Elixir | Feature flags |
| image-provider | C++ (nginx) | Static product images |
| llm | Python | LLM for product reviews |
| load-generator | Python | Locust synthetic users |
| react-native-app | TypeScript | Mobile client (optional) |

### Infrastructure dependencies

| Component | Technology | Used by |
|-----------|------------|---------|
| Cache | Valkey | cart |
| Message queue | Kafka | checkout → accounting, fraud-detection |
| Database | PostgreSQL | accounting, product-reviews |

### Communication patterns

- **gRPC** — primary inter-service RPC (checkout → payment, cart, currency, product-catalog)
- **HTTP** — shipping, email, quote, frontend-proxy routing
- **Kafka (TCP)** — async order events from checkout

### Checkout path (critical for Bhargava)

Primary synchronous path taught to juniors:

```
User → frontend-proxy → frontend → checkout ─┬─ gRPC → cart
                                              ├─ gRPC → payment
                                              ├─ gRPC → currency
                                              ├─ gRPC → product-catalog
                                              ├─ HTTP → shipping → quote
                                              └─ HTTP → email
```

Async side effects (often second lesson):

```
checkout ── Kafka ──▶ fraud-detection
checkout ── Kafka ──▶ accounting ──▶ PostgreSQL
```

### Feature-flag coupling

Several services consult **flagd** via gRPC (`cart`, `payment`, `ad`, `recommendation`, `fraud-detection`, `frontend-proxy`, `product-reviews`, `llm`). Latency and error injections can be feature-flag driven — relevant when explaining anomalous traces.

### Telemetry instrumentation

Each service ships OTLP to the collector. Spans cover inbound HTTP/gRPC, outbound calls, DB/cache/queue operations, and exceptions. Bhargava reads the exported APM documents — not in-process hooks.

---

## Deployment views

### Hack-night (recommended)

| Item | Deployment |
|------|------------|
| Astronomy Shop + collector | Local Docker Compose |
| Elastic Observability | Elastic Cloud Serverless trial |
| Bhargava agent | Kibana Agent Builder (cloud) |

### Alternative

| Item | Deployment |
|------|------------|
| Full stack | minikube + Helm ([Elastic demo chart](https://github.com/elastic/opentelemetry-demo)) |
| Agent MCP | Claude Code + Elastic Observability MCP (optional) |

---

## Security & boundaries

- Bhargava reads observability data only — no write access to shop services
- API keys scoped to Elastic Cloud deployment
- Shop demo not exposed beyond localhost in default Docker setup
- Agent instructions embed Kibana base URL — no secrets in prompts

---

## Extensibility

| Extension | Approach |
|-----------|----------|
| On-call copilot mode | Add change-point + alert tools; swap instructions |
| Custom ES\|QL tools | Agent Builder custom tools (e.g. slow checkout query) |
| ArthaLedger bridge | Index diligence data separately; second agent |
| Quiz bank | Skill with referenced content in Agent Builder |
