# Avalanche Helm Chart

Progressive load-testing framework for Snowplow data pipelines.

## Sizing presets

The chart's resource defaults are driven by a top-level `sizingPreset` value. This avoids consumers having to override per-component CPU/memory/replicas/workers just to lift the injector above the smoke-test ceiling.

```yaml
sizingPreset: medium  # small | medium | large
```

| Preset | Injector CPU / mem | Injector replicas / workers | Intent |
| --- | --- | --- | --- |
| `small` | 500m / 256Mi | 1 / 3 | Smoke tests, kind / docker-desktop. Equivalent to the pre-0.3.0 chart defaults. |
| `medium` (default) | 2000m / 2Gi | 1 / 50 | Sustained multi-k RPS. Designed for ~2000 RPS at the collector, validated with single-injector-pod headroom around 8% CPU at 400 RPS. |
| `large` | 4000m / 4Gi | 1 / 100 | High-throughput perf baselines. Single injector pod with maximum CPU/memory/workers. Multi-replica orchestration is tracked separately — all presets currently pin `injector.replicas` to 1. |

Non-injector components (controller, observer, correlator, adjudicator, aggregator, observerKubernetes, aggregatorKubernetes, nats) scale roughly proportionally across the three presets — see `presets:` in `values.yaml` for the full table. `mockTarget` and `aggregatorKinesisStream` are **not** preset-driven — they keep their own `replicas`/`resources` defaults regardless of `sizingPreset`.

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

## Background

The pre-0.3.0 chart shipped a single set of resource defaults sized for demos, not for load generation. At 500 RPS the injector OOMKilled, took a heartbeat-miss restart, then fell off the NATS rate update. Consumers (snowman sandbox path, DS4 collector tests) carried per-field overrides in their own values.yaml templates to work around this. Presets centralise the sizing decision in the chart so consumers can pick a preset and stop carrying overrides — see ticket QA-780 for the full design and the calibration data behind these numbers.
