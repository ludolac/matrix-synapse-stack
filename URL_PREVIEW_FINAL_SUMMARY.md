# URL Preview Setup - Final Summary ✅

## Status: WORKING! 🎉

URL previews are now fully functional on your Matrix Synapse deployment.

## What Was Fixed

### Server-Side Issues (Fixed in Helm Chart v1.4.12)

1. **NetworkPolicy blocking HTTP** (v1.4.10)
   - Added port 80 egress rule for HTTP redirects
   - Port 443 HTTPS already allowed

2. **Duplicate Synapse configuration** (v1.4.11)
   - Removed duplicate `url_preview_enabled` in configmap
   - Single clean configuration now

3. **Element Web missing defaults** (v1.4.12)
   - Added URL preview feature flags to Element config
   - Set `urlPreviewsEnabled: true` by default

### Client-Side Configuration Required

**CRITICAL**: URL previews are **per-room settings** that users must enable manually!

## How to Enable URL Previews (For Users)

### Step 1: User Settings (One Time)
1. Element Web → Click avatar → **All settings**
2. **Preferences** tab
3. **Timeline** section
4. Enable:
   - ✅ "Show previews for links in messages"
   - ✅ "Show inline URL previews"

### Step 2: Room Settings (Per Room)
1. Open room → Click room name → **Settings**
2. **General** tab ⚠️ **(NOT Security & Privacy!)**
3. Enable:
   - ✅ "Enable URL previews for this room"

### Step 3: Test
Send a link: `https://github.com`

Preview appears in 2-5 seconds with title, description, and image!

## Configuration Summary

### Synapse (Server)
```yaml
url_preview_enabled: true
url_preview_ip_range_blacklist:
  # Complete SSRF protection IP blacklist
  - '127.0.0.0/8'      # Localhost
  - '10.0.0.0/8'       # Private networks
  - '172.16.0.0/12'    # Private networks
  - '192.168.0.0/16'   # Private networks
  # ... (full list in config)
max_spider_size: 10M
```

### NetworkPolicy
```yaml
egress:
  - ports:
    - port: 80   # HTTP (for redirects)
    - port: 443  # HTTPS
    - port: 8448 # Matrix federation
```

### Element Web
```json
{
  "setting_defaults": {
    "urlPreviewsEnabled": true,
    "UIFeature.urlPreviews": true
  },
  "features": {
    "feature_url_previews": "enable"
  }
}
```

## Chart Versions

- **v1.4.10**: NetworkPolicy HTTP egress fix
- **v1.4.11**: Removed duplicate Synapse config
- **v1.4.12**: Added Element Web defaults
- **Current**: v1.4.12 ✅

## Files Modified

1. `templates/networkpolicy.yaml`
   - Added HTTP port 80 egress

2. `templates/synapse-configmap.yaml`
   - Removed duplicate URL preview config (lines 275-307)
   - Enhanced primary config with full IP blacklist

3. `templates/element-configmap.yaml`
   - Added `urlPreviewsEnabled` and feature flags

4. `Chart.yaml`
   - Bumped version to 1.4.12

## Documentation Created

1. `URL_PREVIEW_SETUP.md` - Complete setup guide
2. `URL_PREVIEW_DEBUG.md` - Troubleshooting guide
3. `URL_PREVIEW_FINAL_SUMMARY.md` - This file

## Key Learnings

### Why It Didn't Work Initially

1. **NetworkPolicy** was blocking HTTP (only HTTPS allowed)
2. **Duplicate config** in Synapse template caused conflicts
3. **Element defaults** weren't set
4. **Most importantly**: Users must manually enable previews in:
   - User preferences (global)
   - Each room's settings (per-room)

### Important Notes

- URL previews are **PER-ROOM settings**
- They must be enabled in **Room Settings → General tab**
- NOT in Security & Privacy (common mistake!)
- First preview fetch takes 2-10 seconds
- Subsequent previews are instant (cached)
- Some sites block bot scrapers (LinkedIn, Facebook, etc.)

## Testing

### Verification Commands
```bash
# Check Synapse config (should return 1, not 2)
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  cat /config/homeserver-override.yaml | grep -c "url_preview_enabled"

# Check Element config
kubectl exec deployment/matrix-synapse-element -n matrix -- \
  cat /app/config.json | jq '.setting_defaults'

# Monitor preview requests
kubectl logs deployment/matrix-synapse-synapse -n matrix -f | grep preview
```

### Test URLs (Known to Work)
- https://github.com
- https://youtube.com
- https://reddit.com
- https://wikipedia.org
- https://news.ycombinator.com

## Rollout Instructions

If deploying this chart fresh:

```bash
# 1. Deploy chart
helm install matrix-synapse . -n matrix -f values-prod.yaml

# 2. Wait for pods
kubectl rollout status deployment/matrix-synapse-synapse -n matrix

# 3. Inform users to enable URL previews:
#    - User Settings → Preferences → Timeline
#    - Room Settings → General → Enable URL previews
```

## Support

If URL previews stop working:

1. Check room settings (General tab)
2. Check user preferences (Timeline section)
3. Hard refresh browser (Ctrl+Shift+R)
4. Check Synapse logs: `kubectl logs deployment/matrix-synapse-synapse -n matrix --tail=100 | grep preview`
5. Consult `URL_PREVIEW_DEBUG.md`

---

**Status**: ✅ URL previews fully operational!
**Chart Version**: 1.4.12
**Last Updated**: 2025-10-25
