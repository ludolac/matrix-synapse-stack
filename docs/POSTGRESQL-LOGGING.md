# PostgreSQL Logging Configuration Guide

## Quick Start - Production Settings

Your `values-prod.yaml` is already configured with optimized logging settings:

```yaml
postgresql:
  config:
    # Log slow queries (> 2 seconds)
    logMinDurationStatement: 2000

    # Disable connection noise
    logConnections: false
    logDisconnections: false

    # Don't log statements (production)
    logStatement: "none"

    # Only warnings and above
    logStatementLevel: "warning"

    # Log performance issues
    logLockWaits: true                # Lock contentions
    logTempFiles: 10240               # Temp files > 10MB
    logAutovacuumMinDuration: 5000    # Autovacuum > 5s
```

Apply changes:
```bash
helm upgrade matrix-synapse . \
  -f values-prod.yaml \
  --namespace matrix
```

## Logging Configuration Options

### 1. Slow Query Logging

Log queries that take longer than a threshold:

```yaml
postgresql:
  config:
    logMinDurationStatement: 2000  # milliseconds
```

| Value | Meaning | Use Case |
|-------|---------|----------|
| `-1` | Disabled | Never log slow queries |
| `0` | All queries | Development/debugging (VERY verbose!) |
| `100` | > 100ms | Performance tuning |
| `1000` | > 1 second | Default for development |
| `2000` | > 2 seconds | **Production** (recommended) |
| `5000` | > 5 seconds | Only very slow queries |

**Production recommendation:** `2000` (2 seconds)

### 2. Connection Logging

Control logging of database connections/disconnections:

```yaml
postgresql:
  config:
    logConnections: false      # Don't log new connections
    logDisconnections: false   # Don't log disconnections
```

**When to enable:**
- Debugging connection pool issues
- Tracking connection leaks
- Security auditing

**When to disable (production):**
- Reduces log noise significantly
- Synapse opens/closes many connections
- Can generate 100+ log lines per minute

### 3. Statement Logging

Log specific types of SQL statements:

```yaml
postgresql:
  config:
    logStatement: "none"  # Options: none, ddl, mod, all
```

| Option | What Gets Logged | Volume | Use Case |
|--------|------------------|--------|----------|
| `none` | Nothing | Low | **Production** ✅ |
| `ddl` | Schema changes (CREATE, ALTER, DROP) | Low | Track schema migrations |
| `mod` | Data modifications (INSERT, UPDATE, DELETE) | High | Debugging data changes |
| `all` | Every SQL statement | Very High | Deep debugging only |

**Production recommendation:** `none`

### 4. Log Level

Minimum severity level to log:

```yaml
postgresql:
  config:
    logStatementLevel: "warning"  # Options: debug5...panic
```

Log levels (least to most severe):
- `debug5`, `debug4`, `debug3`, `debug2`, `debug1` - Very verbose debugging
- `info` - Informational messages
- `notice` - Default PostgreSQL level (helpful notices)
- `warning` - **Production recommendation** ⚠️
- `error` - Only errors
- `log` - Server operational messages
- `fatal` - Fatal errors causing session abort
- `panic` - Fatal errors causing server shutdown

**Production recommendation:** `warning` (reduces noise while keeping important info)

### 5. Error Verbosity

Amount of detail in error messages:

```yaml
postgresql:
  config:
    logErrorVerbosity: "default"  # Options: terse, default, verbose
```

| Option | Description | Use Case |
|--------|-------------|----------|
| `terse` | Error only | Minimal logging |
| `default` | Error + detail | **Production** ✅ |
| `verbose` | Error + detail + hint + context | Debugging |

### 6. Performance & Diagnostic Logging

#### Lock Waits
```yaml
logLockWaits: true  # Log when queries wait for locks
```

**Why enable in production:**
- Identifies lock contention issues
- Helps diagnose slow queries
- Low overhead, high value

**Example log:**
```
2025-10-25 10:15:23 [1234]: LOG: process 1234 still waiting for ShareLock on transaction 5678 after 1000.123 ms
```

#### Temp Files
```yaml
logTempFiles: 10240  # Log temp files larger than 10MB (in KB)
```

**Why enable:**
- Temp files indicate queries that exceed `work_mem`
- Large temp files slow down queries significantly
- Helps identify queries needing optimization

**Example log:**
```
2025-10-25 10:20:15 [5678]: LOG: temporary file: path "base/pgsql_tmp/pgsql_tmp5678.0", size 15728640
```

**When you see this:** Consider increasing `work_mem` or optimizing the query.

#### Autovacuum
```yaml
logAutovacuumMinDuration: 5000  # Log autovacuum taking > 5 seconds
```

**Why enable:**
- Monitor database maintenance
- Identify tables needing tuning
- Track bloat issues

**Example log:**
```
2025-10-25 11:00:00 [9999]: LOG: automatic vacuum of table "synapse.public.events": index scans: 1
        pages: 0 removed, 125000 remain, 10000 scanned (8.00% scanned)
        tuples: 50000 removed, 500000 remain, 0 are dead but not yet removable
        avg read rate: 15.234 MB/s, avg write rate: 5.123 MB/s
        system usage: CPU: user: 12.34 s, system: 5.67 s, elapsed: 8.90 s
```

### 7. Log Format

Customize log line prefix:

```yaml
postgresql:
  config:
    logLinePrefix: "%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h "
```

**Format specifiers:**
- `%t` - Timestamp
- `%p` - Process ID
- `%l` - Log line number
- `%u` - Username
- `%d` - Database name
- `%a` - Application name
- `%h` - Client hostname/IP

**Example output:**
```
2025-10-25 10:30:45 [1234]: [1-1] user=synapse,db=synapse_prod,app=psycopg2,client=10.42.0.5 LOG: duration: 2500.123 ms  statement: SELECT ...
```

## Log Volume Comparison

### Before Optimization (Default + 100ms slow query)
```
2025-10-25 10:00:01 [1001]: connection authorized: user=synapse database=synapse_prod
2025-10-25 10:00:01 [1001]: LOG: duration: 120.5 ms  statement: SELECT ...
2025-10-25 10:00:02 [1002]: connection authorized: user=synapse database=synapse_prod
2025-10-25 10:00:02 [1002]: LOG: duration: 150.2 ms  statement: UPDATE ...
2025-10-25 10:00:02 [1001]: disconnection: session time: 0:00:01.234
2025-10-25 10:00:03 [1003]: connection authorized: user=synapse database=synapse_prod
... (100+ lines per minute)
```

**Estimated volume:** 500-1000 log lines/minute

### After Optimization (Production Settings)
```
2025-10-25 10:15:23 [1234]: WARNING: could not obtain lock on row in relation "events"
2025-10-25 10:20:15 [5678]: LOG: temporary file: path "base/pgsql_tmp5678.0", size 15728640
2025-10-25 10:25:45 [1234]: LOG: duration: 2500.123 ms  statement: SELECT * FROM events WHERE ...
2025-10-25 11:00:00 [9999]: LOG: automatic vacuum of table "synapse.public.events": ...
... (5-20 lines per minute, only actionable items)
```

**Estimated volume:** 5-20 log lines/minute (95% reduction!)

## Environment-Specific Configurations

### Development
```yaml
postgresql:
  config:
    logMinDurationStatement: 100   # Log queries > 100ms
    logConnections: true           # Debug connection issues
    logDisconnections: true
    logStatement: "mod"            # Log data changes
    logStatementLevel: "info"      # Verbose
    logErrorVerbosity: "verbose"   # Full error details
```

### Staging/Testing
```yaml
postgresql:
  config:
    logMinDurationStatement: 1000  # Log queries > 1s
    logConnections: false
    logDisconnections: false
    logStatement: "ddl"            # Log schema changes
    logStatementLevel: "notice"
    logErrorVerbosity: "default"
    logLockWaits: true
```

### Production (Recommended)
```yaml
postgresql:
  config:
    logMinDurationStatement: 2000      # Log queries > 2s
    logConnections: false              # Reduce noise
    logDisconnections: false
    logStatement: "none"               # Don't log statements
    logStatementLevel: "warning"       # Warnings and above
    logErrorVerbosity: "default"
    logLockWaits: true                 # Important diagnostics
    logTempFiles: 10240                # > 10MB
    logAutovacuumMinDuration: 5000     # > 5s
```

## Monitoring PostgreSQL Logs

### View Real-Time Logs
```bash
# Get PostgreSQL pod name
PG_POD=$(kubectl get pods -n matrix -l app.kubernetes.io/component=postgresql -o name | head -1)

# Follow logs
kubectl logs -n matrix $PG_POD --tail=100 -f
```

### Filter for Important Events

#### Slow Queries
```bash
kubectl logs -n matrix $PG_POD | grep "duration:"
```

#### Errors Only
```bash
kubectl logs -n matrix $PG_POD | grep -E "ERROR|FATAL|PANIC"
```

#### Lock Waits
```bash
kubectl logs -n matrix $PG_POD | grep "waiting for.*Lock"
```

#### Temp File Usage
```bash
kubectl logs -n matrix $PG_POD | grep "temporary file"
```

#### Autovacuum Activity
```bash
kubectl logs -n matrix $PG_POD | grep "automatic vacuum"
```

### Analyze Slow Queries
```bash
# Extract and sort slow queries by duration
kubectl logs -n matrix $PG_POD | \
  grep "duration:" | \
  sed 's/.*duration: \([0-9.]*\).*/\1/' | \
  sort -rn | \
  head -20
```

## Troubleshooting

### Issue: Too Many Logs

**Symptoms:**
- High log volume
- Logs filling up storage
- Hard to find important errors

**Solution:**
```yaml
postgresql:
  config:
    logMinDurationStatement: 5000   # Increase threshold
    logConnections: false            # Disable connection logging
    logStatement: "none"             # Disable statement logging
    logStatementLevel: "error"       # Only errors
```

### Issue: Missing Important Information

**Symptoms:**
- Can't diagnose slow queries
- No visibility into database issues

**Solution:**
```yaml
postgresql:
  config:
    logMinDurationStatement: 1000   # Lower threshold
    logLockWaits: true              # Enable lock logging
    logTempFiles: 5120              # Lower temp file threshold (5MB)
    logStatementLevel: "warning"    # Include warnings
```

### Issue: Need to Debug Specific Issue

**Temporary debugging configuration:**
```yaml
postgresql:
  config:
    logMinDurationStatement: 0      # Log ALL queries (TEMPORARY!)
    logConnections: true
    logStatement: "all"
    logStatementLevel: "debug1"
```

**⚠️ WARNING:** Revert to production settings after debugging! This configuration generates massive log volume.

## Performance Impact

| Setting | Performance Impact | Log Volume |
|---------|-------------------|------------|
| `logMinDurationStatement: 2000` | Negligible | Low |
| `logConnections: false` | Zero | N/A |
| `logStatement: "none"` | Zero | N/A |
| `logLockWaits: true` | Very Low | Low |
| `logTempFiles: 10240` | Very Low | Low |
| `logAutovacuumMinDuration: 5000` | Zero | Low |
| **Production Total** | **< 1%** | **Very Low** |

Logging all queries (`logMinDurationStatement: 0`) can impact performance by 5-15%.

## Best Practices

✅ **DO:**
- Use `logMinDurationStatement: 2000` in production
- Disable connection logging in production
- Enable `logLockWaits` to catch performance issues
- Monitor autovacuum activity
- Keep `logErrorVerbosity: "default"` for useful error context

❌ **DON'T:**
- Set `logMinDurationStatement: 0` in production (logs everything!)
- Enable `logStatement: "all"` in production (massive volume)
- Set log level below `warning` in production (too noisy)
- Ignore lock wait warnings (indicates contention)
- Leave debugging settings enabled permanently

## Integration with Monitoring

### Prometheus Metrics (Recommended)

Instead of verbose logging, use PostgreSQL exporter:

```yaml
postgresql:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
```

Metrics provide:
- Query performance statistics
- Connection pool status
- Lock wait times
- Autovacuum activity

**Benefits over logs:**
- No performance impact
- Historical trending
- Automated alerting
- Better visualization

### Log Aggregation

If using log aggregation (ELK, Loki, etc.), consider:

```yaml
postgresql:
  config:
    logMinDurationStatement: 1000   # Slightly more verbose
    logLockWaits: true
    logTempFiles: 5120              # Lower threshold
```

Parse logs to extract:
- Slow query patterns
- Lock contention trends
- Temp file usage over time

## Related Configuration

```yaml
postgresql:
  # Memory settings affect when temp files are created
  config:
    work_mem: "16MB"  # Increase to reduce temp file usage

    # More connections = more connection logs
    maxConnections: 500
```

## References

- [PostgreSQL Logging Documentation](https://www.postgresql.org/docs/16/runtime-config-logging.html)
- PostgreSQL config template: `templates/postgresql-configmap.yaml`
- Default values: `values.yaml` (lines 512-549)
- Production values: `values-prod.yaml` (lines 312-331)
