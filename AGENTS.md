# AOSC Agent Guide

This guide is for AI agents and automation working in the public AOSC
repository. For project architecture, build commands, and contribution flow,
read `README.md` and `CONTRIBUTING.md` first.

## OpenSearch API Compatibility

AOSC currently targets OpenSearch 2.x. Keep code compatible with the lowest
supported 2.x minor in `release/os2.properties`, and do not introduce
OpenSearch 3.x-only APIs on the 2.x line.

Common 2.x imports:

```java
import org.opensearch.client.Client;
import org.opensearch.core.action.ActionListener;
import org.opensearch.action.ActionType;
import org.opensearch.action.support.ActionFilters;
import org.opensearch.action.support.HandledTransportAction;
```

Do not replace these with `org.opensearch.transport.client.Client` on the 2.x
line.

OpenSearch 2.x plugins use the legacy positional `createComponents` signature,
not the OpenSearch 3.x single-services-object signature:

```java
@Override
public Collection<Object> createComponents(
    Client client,
    ClusterService clusterService,
    ThreadPool threadPool,
    ResourceWatcherService resourceWatcherService,
    ScriptService scriptService,
    NamedXContentRegistry xContentRegistry,
    Environment environment,
    NodeEnvironment nodeEnvironment,
    NamedWriteableRegistry namedWriteableRegistry,
    IndexNameExpressionResolver indexNameExpressionResolver,
    Supplier<RepositoriesService> repositoriesServiceSupplier
) {
    ...
}
```

Use `org.apache.lucene.tests.util.LuceneTestCase.AwaitsFix` for ignored/flaky
test annotations. Do not import `com.carrotsearch.randomizedtesting.annotations.AwaitsFix`.

## Structured Logging

AOSC uses `AoscLogger` for structured context. When a constructor receives an
`AoscLogger`, bind it to the concrete class:

```java
this.logger = Objects.requireNonNull(logger, "logger").forClass(MyClass.class);
```

Use `LC` constants for structured field keys. Keep log messages static and put
values in `kv()` fields:

```java
import static com.atlassian.opensearch.aosc.utils.AoscLogger.kv;

logger.info("Gradient decrease", kv(LC.EVENT, "gradient_decrease"), kv(LC.GRADIENT, gradient));
```

Do not introduce direct `LogManager.getLogger()` or `Loggers.getLogger()` calls
in AOSC components.

## Async Patterns

OpenSearch transport actions use `ActionListener<T>` callbacks. Propagate
failures with `ActionListener.onFailure()` and do not hold locks while invoking
callbacks.

Prefer explicit OpenSearch thread-pool scheduling over Java common-pool helpers
in test-sensitive code. In particular, avoid `CompletableFuture.delayedExecutor`
inside OpenSearch tests; the common pool is blocked by the test security manager.
Use project utilities that schedule through the OpenSearch `ThreadPool`.

## Core Safety Invariants

- Translog snapshots must be closed in a `finally` block or equivalent cleanup path.
- Bulk writes use idempotent index operations, not create-only writes.
- Source write blocking must use the OpenSearch add-block API so in-flight writes drain before cutover.
- Retention leases must not be released while a migration still needs source operation history.
- Background async failures must be surfaced to the migration state machine or caller; do not swallow them in logs only.

## Tests

Use targeted validation while developing:

```bash
./gradlew :aosc-plugin:fastCheck -Dopensearch.version=2.19.0
./gradlew :aosc-plugin:yamlRestTest -Dopensearch.version=2.19.0
./gradlew :aosc-plugin:itTest -Dopensearch.version=2.19.0
mkdocs build --strict
```

Use `--no-daemon` for longer integration runs when debugging stale Gradle
workers:

```bash
./gradlew --no-daemon :aosc-plugin:itTest -Dopensearch.version=2.19.0
```

Run broader version matrix checks before release or compatibility-sensitive
changes. The supported OpenSearch versions are declared in `release/os2.properties`.

## Documentation

Update documentation for any change to:

- REST API request or response fields
- migration phases or state transitions
- configuration settings
- operational behavior
- compatibility guarantees
- public extension points

Avoid unsupported performance claims. If a timing or scale statement is
included, state the observed conditions.

Keep public docs free of internal Atlassian systems, private links, internal
deployment process, and local-machine assumptions.
