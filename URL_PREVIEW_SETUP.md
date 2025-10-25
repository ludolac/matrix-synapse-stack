# URL Preview Setup Guide

## Current Status

✅ **Configuration Added** - URL preview settings committed to chart
⏳ **Not Yet Applied** - Need to upgrade Helm deployment
🔒 **Rate Limited** - Too many test authentications (wait ~3 min or upgrade)

## Step 1: Upgrade Helm Deployment

```bash
# 1. Bump chart version
sed -i 's/version: 1.4.8/version: 1.4.9/' Chart.yaml

# 2. Upgrade the deployment
helm upgrade matrix-synapse . -n matrix -f values-prod.yaml

# 3. Wait for rollout
kubectl rollout status deployment/matrix-synapse-synapse -n matrix

# 4. Verify configuration
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  cat /config/homeserver-override.yaml | grep -A 35 "url_preview"
```

## Step 2: Verify URL Previews Are Enabled

```bash
# Check Synapse logs for URL preview initialization
kubectl logs deployment/matrix-synapse-synapse -n matrix | grep -i preview

# Test the API endpoint (after rate limit clears)
# The script will tell you to wait if rate limited
bash /tmp/test_url_preview.sh
```

Expected output:
```json
{
  "og:title": "GitHub: Let's build from here",
  "og:description": "GitHub is where...",
  "og:image": "https://github.githubassets.com/...",
  "matrix:image:size": 123456
}
```

## Step 3: Test in Element Client

1. **Open Element Web** (https://element.waadoo.ovh)
2. **Go to any room**
3. **Send a link** to a public website, e.g.:
   - `https://github.com`
   - `https://youtube.com/watch?v=...`
   - `https://twitter.com/...`
   - `https://news.ycombinator.com`

4. **Wait a moment** - Preview should appear below the message with:
   - Page title
   - Description
   - Image/thumbnail (if available)

## Troubleshooting

### Issue: No previews appear

**Check 1: Room Settings**
- In Element: Room Settings → Security & Privacy
- Ensure "Enable URL previews for this room" is ON

**Check 2: User Settings**
- Element Settings → Preferences → Show previews for links: ON
- Element Settings → Preferences → Show inline URL previews: ON

**Check 3: Server Configuration**
```bash
# Verify url_preview_enabled is true
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  grep "url_preview_enabled" /config/homeserver-override.yaml
```

**Check 4: Check Synapse Logs**
```bash
# Look for URL preview errors
kubectl logs deployment/matrix-synapse-synapse -n matrix --tail=200 | grep -i "preview\|url"
```

### Issue: "URL preview failed" errors

**Possible causes:**
1. **Target site blocks bots** - Some sites block server-side preview requests
2. **HTTPS certificate issues** - Target site has invalid SSL cert
3. **Timeout** - Target site took too long to respond
4. **Blocked by IP blacklist** - Internal/private IPs are blocked for security

### Issue: Slow previews

URL previews are fetched on-demand the first time:
- First user to share a link: 1-5 second delay
- Subsequent users: Instant (cached)
- Cache duration: Configurable (default varies)

## Configuration Details

Your current URL preview configuration:

```yaml
# Enable URL previews
url_preview_enabled: true

# Security: Block private networks (SSRF protection)
url_preview_ip_range_blacklist:
  - '127.0.0.0/8'      # Localhost
  - '10.0.0.0/8'       # Private networks
  - '172.16.0.0/12'    # Private networks
  - '192.168.0.0/16'   # Private networks
  - '100.64.0.0/10'    # Carrier-grade NAT
  - '192.0.0.0/24'     # IETF Protocol Assignments
  - '169.254.0.0/16'   # Link-local
  - '192.88.99.0/24'   # IPv6 to IPv4 relay
  - '198.18.0.0/15'    # Benchmarking
  - '192.0.2.0/24'     # Documentation
  - '198.51.100.0/24'  # Documentation
  - '203.0.113.0/24'   # Documentation
  - '224.0.0.0/4'      # Multicast
  - '::1/128'          # IPv6 localhost
  - 'fe80::/10'        # IPv6 link-local
  - 'fc00::/7'         # IPv6 unique local
  - '2001:db8::/32'    # IPv6 documentation
  - 'ff00::/8'         # IPv6 multicast
  - 'fec0::/10'        # IPv6 site-local (deprecated)

# Size limit for fetched content
max_spider_size: 10M
```

## Advanced: Custom Configuration

To block specific domains (e.g., tracking sites):

```yaml
url_preview_url_blacklist:
  - username: "*"
    netloc: "google-analytics.com"
  - username: "*"
    netloc: "*.google-analytics.com"
```

To allow internal networks (NOT recommended for security):

```yaml
url_preview_ip_range_whitelist:
  - '192.168.1.0/24'  # Your specific internal network
```

## Security Notes

🔒 **IP Blacklist** prevents SSRF attacks:
- Prevents accessing internal services
- Blocks localhost and private networks
- Protects your infrastructure from reconnaissance

⚠️ **Never remove IP blacklist** unless you fully understand the security implications

## References

- [Synapse URL Preview Docs](https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html#url_preview_enabled)
- [Patrick Cloke's Guide](https://patrick.cloke.us/posts/2024/02/23/synapse-url-previews/)
- [Matrix Spec - URL Previews](https://spec.matrix.org/latest/)

## Quick Test Checklist

- [ ] Helm chart upgraded to 1.4.9
- [ ] Synapse pods restarted
- [ ] Rate limit cleared (wait 3-5 minutes)
- [ ] URL preview config verified in pod
- [ ] Element room settings: URL previews ON
- [ ] Element user settings: Show previews ON
- [ ] Test with public URL (github.com, youtube.com, etc.)
- [ ] Preview appears in ~2-5 seconds

---

**Status**: Configuration ready, waiting for Helm upgrade to apply changes.
