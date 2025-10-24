# Traefik Configuration for TURN Server

To enable TURN server routing through Traefik, you need to add UDP and TCP entrypoints for TURN ports.

## Required Traefik Entrypoints

Add these arguments to your Traefik DaemonSet configuration:

```yaml
# TURN TCP port 3478
- --entryPoints.turn-tcp.address=:3478/tcp

# TURN UDP port 3478
- --entryPoints.turn-udp.address=:3478/udp

# TURNS TCP port 5349 (secure)
- --entryPoints.turns-tcp.address=:5349/tcp

# TURNS UDP port 5349 (secure)
- --entryPoints.turns-udp.address=:5349/udp
```

## Update Traefik Service

Your Traefik service also needs to expose these ports:

```yaml
ports:
  - name: turn-tcp
    port: 3478
    protocol: TCP
    targetPort: 3478
  - name: turn-udp
    port: 3478
    protocol: UDP
    targetPort: 3478
  - name: turns-tcp
    port: 5349
    protocol: TCP
    targetPort: 5349
  - name: turns-udp
    port: 5349
    protocol: UDP
    targetPort: 5349
```

## Verify Configuration

After updating Traefik, verify the entrypoints:

```bash
kubectl exec -n traefik traefik-xxxxx -- traefik version
kubectl logs -n traefik traefik-xxxxx | grep entryPoints
```

## Apply Helm Chart

Once Traefik is configured, upgrade the Matrix Synapse chart:

```bash
helm upgrade matrix-synapse ./matrix-synapse -n matrix -f ./matrix-synapse/values-prod.yaml
```

This will create the IngressRouteTCP and IngressRouteUDP resources that route TURN traffic through Traefik.
