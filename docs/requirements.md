# EARS Requirements — Bhargava

Requirements for the **Bhargava** junior-engineer tutor operating over the OpenTelemetry Astronomy Shop and Elastic Observability.

## Functional requirements

### Astronomy Shop (telemetry source)

- When the Astronomy Shop demo is running, the system shall emit OTLP traces, logs, and metrics from instrumented microservices.
- When a user browses the shop UI, the `frontend` service shall initiate HTTP/gRPC calls to downstream services.
- When a user completes checkout, the system shall produce a distributed trace spanning `frontend`, `checkout`, and downstream services (`payment`, `cart`, `shipping`, `email`, `currency`, and others).
- When load is generated, the `load-generator` shall produce synthetic user traffic through the `frontend-proxy`.

### Elastic Observability (telemetry sink)

- When OTLP data is received, Elastic Observability shall index traces, logs, and metrics for APM analysis.
- When a service is instrumented, Elastic APM shall expose service health, topology, dependencies, and trace documents searchable by the agent tools.

### Bhargava tutor agent

- When a junior engineer opens Agent Builder chat, the system shall allow conversation with the `bhargava-tutor` agent.
- When asked about architecture, the agent shall use observability tools to describe live services and topology — not static documentation alone.
- When asked to explain a user action (e.g. Place Order), the agent shall retrieve a recent checkout trace and narrate the request path span-by-span.
- When citing a trace or service, the agent shall include Kibana deep links using the configured base URL.
- When teaching, the agent shall follow the Bhargava method: Orient → Map → Walk trace → Connect logs → Quiz.
- When no telemetry exists in the requested window, the agent shall instruct the user to generate traffic and retry.
- When a quiz is requested, the agent shall ask check-for-understanding questions based on explored data.

### Agent tools

- When mapping architecture, the agent shall use `observability.get_services` and `observability.get_service_topology`.
- When explaining dependencies, the agent shall use `observability.get_downstream_dependencies`.
- When walking traces, the agent shall use `observability.get_traces`.
- When correlating logs, the agent shall use `observability.search_logs` or `observability.get_correlated_logs`.
- When ad-hoc analysis is needed, the agent may use `platform.core.execute_esql` and `platform.core.list_indices`.

## Non-functional requirements

- The system shall be demonstrable within 15 minutes of Kibana and Docker being available.
- The tutor shall respond within a hack-night-friendly latency (interactive chat, not batch).
- The agent shall not invent trace IDs, service names, or metrics — only cite tool-backed data.
- The agent shall default to a 30-minute lookback window for teaching sessions.
- The agent shall keep responses under 400 words unless a deep dive is explicitly requested.
- The system shall operate without Claude Code when Elastic Agent Builder UI is used directly.
- The architecture shall support Docker Compose deployment for local hack-night use and Elastic Cloud for observability backend.
- The tutor persona shall remain encouraging and precise; Parasurama references shall be brief and non-preachy.

## Out of scope (hack night)

- Automated remediation or alerting workflows
- Custom microservice code changes to Astronomy Shop
- Multi-tenant user authentication for the tutor
- Production-grade agent versioning and CI

## Traceability

| Requirement area | HLD section | LLD section |
|------------------|-------------|-------------|
| Checkout trace walkthrough | Tutoring flow | Agent instructions, `get_traces` |
| Kibana links | Presentation layer | URL templates in instructions |
| Service topology teaching | Observability integration | Tool assignments |
| Guru quiz | Tutoring flow | Response format § Check your understanding |
