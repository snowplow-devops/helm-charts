# Avalanche Helm Chart

Progressive load-testing framework for Snowplow data pipelines.

## Sizing presets

The chart's resource defaults are driven by a top-level `sizingPreset` value. This avoids consumers having to override per-component CPU/memory/replicas/workers just to lift the injector above the smoke-test ceiling.

```yaml
sizingPreset: medium  # small | medium | large
```

| Preset | Injector CPU / mem (limit) | Injector replicas / workers | Intent |
| --- | --- | --- | --- |
| `small` | 500m / 256Mi | 1 / 3 | Smoke tests, kind / docker-desktop. Equivalent to the pre-0.3.0 chart defaults. |
| `medium` (default) | 2000m / 2Gi | 1 / 50 | Sustained multi-k RPS. Designed for ~2000 RPS at the collector, validated with single-injector-pod headroom around 8% CPU at 400 RPS. |
| `large` | 4000m / 4Gi | 1 / 100 | High-throughput perf baselines. Single injector pod with maximum CPU/memory/workers. Multi-replica orchestration is tracked separately — all presets currently pin `injector.replicas` to 1. |

Non-injector components (controller, observer, correlator, adjudicator, aggregator, observerKubernetes, aggregatorKubernetes, nats) scale roughly proportionally across the three presets — see `presets:` in `values.yaml` for the full table. `mockTarget`, `aggregatorKinesisStream` and `aggregatorSignals` are **not** preset-driven — they keep their own `replicas`/`resources` defaults regardless of `sizingPreset`.

### Overriding per component

Per-component `<component>.resources`, `<component>.replicas`, and `injector.config.workers` overrides win over the preset whenever they're set to a non-zero / non-empty value. The override is **all-or-nothing** — if you override `<component>.resources`, you replace the entire preset block, not just one field.

```yaml
# Use the medium preset for everything except injector — pin injector explicitly.
sizingPreset: medium
injector:
  replicas: 5
  config:
    workers: 200
  resources:
    requests: { cpu: "1500m", memory: "1Gi" }
    limits:   { cpu: "3000m", memory: "3Gi" }
```

### Adding a new preset

Add an entry to `presets:` in your values override and point `sizingPreset` at it:

```yaml
sizingPreset: my-custom

presets:
  my-custom:
    injector:
      replicas: 2
      workers: 75
      resources:
        requests: { cpu: "750m", memory: "768Mi" }
        limits:   { cpu: "3000m", memory: "3Gi" }
    # … other components …
```

The chart resolves preset values via the `avalanche.componentResources`, `avalanche.componentReplicas`, and `avalanche.injectorWorkers` helpers in `templates/_helpers.tpl`.

## http injector requests

From 0.16.0 the chart passes `injector.config.headers` and `injector.config.requests` through to the injector config verbatim, for the `http` injector type (avalanche 0.21.0 or later). Without them the injector sends its legacy fixed POST to `endpoint`, and every other injector type renders exactly as before.

```yaml
injector:
  config:
    type: "http"
    endpoint: "http://iglu.example.com"
    headers:
      apikey: "<key>"
    requests:
      - method: GET
        path: /api/schemas/com.acme/click/jsonschema/1-0-0
        weight: 3
      - method: GET
        path: /api/schemas/com.acme/view/jsonschema/1-0-0
        weight: 1
```

Keys, defaults, header precedence and validation are documented in avalanche `docs/HTTP_INJECTOR.md`. The chart does no validation of its own: a bad value fails when the injector starts, with an error naming the key.

## Harness affinity

From 0.19.0, `harnessAffinity` sets a Kubernetes `affinity` on every harness Deployment: nats, injector, all observers, correlator, adjudicator, controller, the aggregators and mockTarget. mockTarget counts as harness because it is a downstream sink (for example, a Snowbridge HTTP target's destination) and loads whichever node it lands on. A non-empty `<component>.affinity` replaces it for that one component; the two are not merged. Only the fluent-bit DaemonSet is left alone, since it must run on every node. With both values unset the chart renders exactly as 0.18.0 did.

Harness pods that land on the system under test's node inflate its measured CPU. To keep them off it, set a pod anti-affinity on its labels:

```yaml
harnessAffinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/name: snowbridge
        namespaces: ["<its namespace>"]   # omit if it shares the release namespace
        topologyKey: kubernetes.io/hostname
```

A `required` rule leaves harness pods `Pending` if the cluster has no other node with room for them; use `preferredDuringSchedulingIgnoredDuringExecution` where that matters more than a clean measurement.

## Background

The pre-0.3.0 chart shipped a single set of resource defaults sized for demos, not for load generation. At 500 RPS the injector OOMKilled, took a heartbeat-miss restart, then fell off the NATS rate update. Consumers (snowman sandbox path, DS4 collector tests) carried per-field overrides in their own values.yaml templates to work around this. Presets centralise the sizing decision in the chart so consumers can pick a preset and stop carrying overrides — see ticket QA-780 for the full design and the calibration data behind these numbers.
