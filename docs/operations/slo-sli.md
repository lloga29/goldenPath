# SLOs and SLIs

Service Level Objectives turn platform reliability into measurable expectations.

## Definitions

- **SLI** — a measured indicator such as successful request ratio or deployment success rate.
- **SLO** — a target for an SLI over a defined window.
- **Error budget** — the allowed unreliability implied by the SLO.

## Application examples

Common SLIs include availability, latency, successful transaction ratio, queue processing delay, and data freshness. The correct SLI must represent user-visible service behavior rather than only host health.

## Platform examples

A Golden Path can measure:

- successful GitOps reconciliation rate;
- platform deployment success rate;
- median service bootstrap time;
- CI queue/runtime for paved-road repositories;
- secret synchronization success;
- certificate renewal success;
- time to detect and remediate drift;
- platform control-plane availability.

## Error-budget use

Error budgets support tradeoffs between delivery speed and reliability. Persistent budget exhaustion should trigger corrective work, not merely dashboard reporting.

## Ownership

Every production SLO requires an owner, measurement query, window, target, dashboard, alert strategy, and review cadence.

## DORA metrics

DORA metrics complement SLOs but do not replace them. Track deployment frequency, lead time for changes, change failure rate, and mean time to restore at a level where teams can act on the results.
