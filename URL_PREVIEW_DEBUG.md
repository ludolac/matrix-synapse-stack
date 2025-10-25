# URL Preview Debugging Guide

## Current Status ✅

- Synapse configuration: `url_preview_enabled: true` ✅
- NetworkPolicy: HTTP (80) and HTTPS (443) egress allowed ✅
- Element Web: URL preview defaults configured ✅
- No duplicate configuration ✅
- Chart version: 1.4.12 ✅

## Step-by-Step Testing Procedure

### Step 1: Enable URL Previews in Element Web

URL previews in Matrix/Element are **PER-ROOM settings**. You MUST enable them manually:

#### A. Enable in User Settings (Global Preference)
1. Open https://element.waadoo.ovh
2. Click your avatar → **All settings**
3. Go to **Preferences** tab
4. Scroll to **Timeline** section
5. Enable these toggles:
   - ✅ **"Show previews for links in messages"**
   - ✅ **"Show inline URL previews"**
6. Click **Save**

#### B. Enable in Room Settings (Per-Room)
1. Open any room
2. Click room name → **Settings**
3. Go to **General** tab (NOT Security & Privacy!)
4. Enable:
   - ✅ **"Enable URL previews for this room"**

**IMPORTANT**: URL previews will **NOT work** unless BOTH settings above are enabled!

### Step 2: Test with a URL

1. In the room where you enabled previews, send:
   ```
   https://github.com
   ```

2. **Wait 2-10 seconds** (first fetch takes time)

3. **Expected behavior**:
   - Loading spinner appears
   - Preview card shows up with:
     - GitHub logo
     - Title: "GitHub: Let's build from here"
     - Description
     - Preview image

4. **If nothing happens**, proceed to Step 3

### Step 3: Check Browser Console for Errors

1. Press **F12** to open browser DevTools
2. Go to **Console** tab
3. Clear the console
4. Send a URL in the room again
5. Look for errors containing:
   - `preview`
   - `_matrix/media`
   - `403` or `401` or `500`

**Copy any errors you see!**

### Step 4: Test Synapse API Directly

This tests if Synapse's URL preview endpoint works:

1. **Get your access token** from Element:
   - Settings → Help & About
   - Scroll down to **Advanced**
   - Click **Access Token** → Copy it

2. **Test the API** (replace `YOUR_TOKEN_HERE`):
   ```bash
   TOKEN='YOUR_TOKEN_HERE'
   curl -H "Authorization: Bearer $TOKEN" \
     'https://matrix.waadoo.ovh/_matrix/media/r0/preview_url?url=https://github.com' | jq .
   ```

3. **Expected output**:
   ```json
   {
     "og:title": "GitHub: Let's build from here",
     "og:description": "...",
     "og:image": "https://github.githubassets.com/...",
     "matrix:image:size": 123456
   }
   ```

4. **If you get an error**, copy the full error message

### Step 5: Monitor Synapse Logs

While testing, watch Synapse logs for preview activity:

```bash
# In one terminal, watch logs:
kubectl logs deployment/matrix-synapse-synapse -n matrix -f | grep -i preview

# In another terminal/browser:
# Send a URL in Element Web
```

**What to look for**:
- `GET /_matrix/media/r0/preview_url` - Request received ✅
- Errors mentioning `preview`, `spider`, or `media`
- HTTP status codes (200=success, 403=forbidden, 500=error)

## Common Issues & Solutions

### Issue: "Nothing happens when I send a URL"

**Cause**: Room/user settings not enabled

**Solution**:
1. Check **Settings → Preferences** - enable "Show previews for links"
2. Check **Room Settings → General** tab - enable "Enable URL previews for this room"
3. **Hard refresh** Element: Ctrl+Shift+R (or Cmd+Shift+R on Mac)
4. Try again

### Issue: "Preview shows loading spinner forever"

**Cause**: Network connectivity or Synapse can't fetch the URL

**Test**:
```bash
# Test if Synapse can reach the internet:
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  curl -I https://github.com
```

**Expected**: `HTTP/2 200`

If this fails, check NetworkPolicy.

### Issue: "403 Forbidden" or "401 Unauthorized"

**Cause**: Access token missing or invalid

**Solution**:
1. Log out of Element
2. Log back in
3. Try again

### Issue: "Some URLs work, others don't"

**Cause**: Some websites block bot/scraper requests

**Examples of sites that often block scrapers**:
- LinkedIn
- Facebook
- Instagram
- Some news sites with paywalls

**Try known-working sites**:
- https://github.com
- https://youtube.com
- https://reddit.com
- https://wikipedia.org

### Issue: "Previews work in unencrypted rooms but not encrypted ones"

**Cause**: This is expected behavior for E2EE rooms

**Explanation**:
- URL previews expose metadata to the server
- In E2EE rooms, this might be disabled for privacy
- Check room encryption status

## Verification Checklist

Run these commands to verify configuration:

```bash
# 1. Verify Synapse config (should show url_preview_enabled: true)
kubectl exec deployment/matrix-synapse-synapse -n matrix -- \
  grep "url_preview_enabled" /config/homeserver-override.yaml

# 2. Verify NetworkPolicy allows HTTP/HTTPS
kubectl get networkpolicy matrix-synapse-synapse -n matrix -o yaml | \
  grep -A 10 "egress:" | grep -E "port: (80|443)"

# 3. Check Element config
kubectl exec deployment/matrix-synapse-element -n matrix -- \
  cat /app/config.json | jq '.setting_defaults'

# 4. Verify Synapse is running
kubectl get pods -n matrix -l app.kubernetes.io/component=synapse
```

## Still Not Working?

If you've tried everything above and previews still don't work:

1. **Collect this information**:
   ```bash
   # Get Synapse logs (last 200 lines)
   kubectl logs deployment/matrix-synapse-synapse -n matrix --tail=200 > synapse-logs.txt

   # Get Element config
   kubectl exec deployment/matrix-synapse-element -n matrix -- \
     cat /app/config.json > element-config.json

   # Test API manually (with your token)
   TOKEN='your-token'
   curl -v -H "Authorization: Bearer $TOKEN" \
     'https://matrix.waadoo.ovh/_matrix/media/r0/preview_url?url=https://github.com' \
     > api-test-output.txt 2>&1
   ```

2. **Check browser console** (F12) for errors when sending a URL

3. **Share**:
   - Browser console errors
   - API test output
   - Synapse logs showing preview-related lines

## Matrix Spec Reference

URL previews are defined in the Matrix spec:
- Endpoint: `GET /_matrix/media/r0/preview_url`
- Requires: Valid access token
- Parameters: `url` (the URL to preview)
- Returns: OpenGraph metadata

The client (Element) is responsible for:
1. Checking if previews are enabled (user + room settings)
2. Calling the preview endpoint with authentication
3. Rendering the preview card

The server (Synapse) is responsible for:
1. Fetching the URL
2. Extracting metadata (title, description, image)
3. Caching the result
4. Returning JSON response
