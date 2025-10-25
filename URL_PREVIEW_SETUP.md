# URL Preview Setup Guide

## Current Status

✅ **Configuration Added** - URL preview settings committed to chart
✅ **Deployed** - Helm chart upgraded successfully
✅ **NetworkPolicy Fixed** - HTTP/HTTPS egress enabled for URL fetching
✅ **Ready to Test** - Configuration active in Synapse

## Verification Commands

```bash
# 1. Verify configuration in pod
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  cat /config/homeserver-override.yaml | grep -A 35 "url_preview"

# 2. Check NetworkPolicy allows outbound HTTP/HTTPS
kubectl get networkpolicy matrix-synapse-synapse -n matrix -o yaml | grep -A 30 "egress:"

# 3. Verify Synapse is running
kubectl get pods -n matrix -l app.kubernetes.io/component=synapse
```

## How to Test URL Previews

URL previews work automatically once configured. No API testing needed - just use Element Web!

## Testing in Element Client

### Step 1: Enable URL Previews in User Settings
1. **Open Element Web** (https://element.waadoo.ovh)
2. Click your avatar → **All settings**
3. Go to **Preferences** tab
4. Scroll to **Timeline** section
5. Enable:
   - ✅ **"Show previews for links in messages"**
   - ✅ **"Show inline URL previews"**

### Step 2: Enable URL Previews in Room Settings
1. **Go to any room**
2. Click room name → **Settings**
3. Go to **General** tab
4. Enable:
   - ✅ **"Enable URL previews for this room"**

### Step 3: Test with a Link
1. **Send a link** to a public website in that room:
   - `https://github.com`
   - `https://youtube.com`
   - `https://reddit.com`
   - `https://news.ycombinator.com`

2. **Wait 2-5 seconds** - Preview should appear below the message with:
   - Page title
   - Description
   - Image/thumbnail (if available)

**Note**: URL previews are **per-room settings**. You must enable them in each room where you want previews to appear.

## Troubleshooting

### Issue: No previews appear

**Check 1: User Settings**
- Element Settings → Preferences → Timeline section
- Enable "Show previews for links in messages"
- Enable "Show inline URL previews"

**Check 2: Room Settings** ⚠️ **IMPORTANT**
- In Element: Room Settings → **General** tab (NOT Security & Privacy!)
- Enable "Enable URL previews for this room"
- You must do this **for each room** where you want previews

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

- [x] Helm chart upgraded to 1.4.12
- [x] NetworkPolicy updated to allow HTTP/HTTPS egress
- [x] Synapse pods running
- [x] URL preview config verified in pod (no duplicates)
- [x] Element Web config includes URL preview defaults
- [ ] Element user settings: Enable "Show previews for links" (Settings → Preferences → Timeline)
- [ ] Element room settings: Enable "Enable URL previews for this room" (Room Settings → **General** tab)
- [ ] Test with public URL (github.com, youtube.com, etc.)
- [ ] Preview appears in ~2-5 seconds

---

## What Was Fixed

### Issue 1: NetworkPolicy blocking outbound connections
**Problem**: NetworkPolicy was blocking HTTP connections needed for URL preview fetching.

**Solution**: Updated NetworkPolicy template (`templates/networkpolicy.yaml`) to allow:
- Port 80 (HTTP) - for sites that use HTTP-to-HTTPS redirects
- Port 443 (HTTPS) - for fetching preview metadata
- No `to:` selector - allows egress to any external destination

### Issue 2: Duplicate URL preview configuration
**Problem**: `url_preview_enabled` was defined twice in `synapse-configmap.yaml`:
- Line 70: Conditional configuration (respects values.yaml)
- Line 277: Hardcoded configuration (always enabled)

This duplication could cause config parsing issues or override intended settings.

**Solution**:
- Removed duplicate hardcoded section (lines 275-307)
- Enhanced primary configuration with complete IP blacklist and `max_spider_size`
- Single source of truth now respects values.yaml settings

### Issue 3: Element Web missing URL preview defaults
**Problem**: Element config didn't enable URL previews by default for new users.

**Solution**: Added to `element-configmap.yaml`:
```json
"setting_defaults": {
  "urlPreviewsEnabled": true,
  "UIFeature.urlPreviews": true
}
```

**Chart Versions**:
- v1.4.10: NetworkPolicy fix
- v1.4.11: Configuration deduplication + Element defaults

---

**Status**: ✅ URL previews are fully configured and ready to use!
