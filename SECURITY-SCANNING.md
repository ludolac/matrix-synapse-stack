# Security Scanning Documentation

## Overview

This Helm chart includes automated security scanning using [Trivy](https://trivy.dev/), which scans:
- Helm chart configurations
- Rendered Kubernetes manifests
- Container images (Synapse, Element Web, PostgreSQL, Coturn)

## How Version Synchronization Works

### Single Source of Truth: `values.yaml`

All image versions are defined **once** in `values.yaml`:

```yaml
synapse:
  image:
    tag: "v1.140.0"

element:
  image:
    tag: "v1.12.2"

postgresql:
  image:
    tag: "16-alpine"

coturn:
  image:
    tag: "4.6-alpine"
```

### Automatic Synchronization

The GitHub Actions workflow (`.github/workflows/trivy-scan.yml`) automatically:

1. **Extracts versions from `values.yaml`** using `yq`:
   ```bash
   SYNAPSE_VERSION=$(yq eval '.synapse.image.tag' values.yaml)
   ```

2. **Scans the correct image versions**:
   ```yaml
   image-ref: '${{ matrix.image.repo }}:${{ steps.get-tag.outputs.tag }}'
   ```

3. **Updates README.md** with the actual versions from `values.yaml`:
   ```bash
   sed -i "/^| \*\*Synapse\*\* |/c\| **Synapse** | ${SYNAPSE_VERSION} | ..."
   ```

### Benefits

✅ **No manual version updates** - Update version in `values.yaml` only
✅ **Always accurate** - Scans match deployed versions
✅ **Prevents mistakes** - No risk of version mismatch
✅ **Automated README updates** - Security scan results show correct versions

## Upgrading Image Versions

To upgrade an image version:

1. **Edit `values.yaml`** only:
   ```yaml
   synapse:
     image:
       tag: "v1.141.0"  # Update this
   ```

2. **Commit and push** to trigger automated scans:
   ```bash
   git add values.yaml
   git commit -m "chore: upgrade Synapse to v1.141.0"
   git push
   ```

3. **GitHub Actions automatically**:
   - Scans the new image version
   - Updates security badges in README.md
   - Commits the README changes

## Workflow Details

### Trivy Image Scan Job

```yaml
trivy-image-scan:
  strategy:
    matrix:
      image:
        - name: synapse
          repo: ghcr.io/element-hq/synapse
          tag_key: synapse.image.tag  # Path in values.yaml
        - name: element-web
          repo: ghcr.io/element-hq/element-web
          tag_key: element.image.tag
        # ... etc
```

For each image:
1. Extract tag from `values.yaml` using the `tag_key`
2. Scan `repo:tag` with Trivy
3. Generate SARIF, JSON, and CSV reports
4. Upload to GitHub Security tab

### Security Summary Job

After all scans complete:
1. Extract versions from `values.yaml`
2. Count vulnerabilities by severity
3. Update README.md with:
   - Current version numbers
   - Vulnerability counts
   - Links to detailed reports

## Viewing Scan Results

### GitHub Security Tab
- **URL**: `https://github.com/ludolac/matrix-synapse-stack/security/code-scanning`
- **Contents**: All vulnerabilities categorized by image
- **Filtering**: By severity, image type, status

### README.md Tables
- **Overall Status**: Configuration vs Container Image vulnerabilities
- **Per-Image Details**: Clickable badges linking to workflow runs

### Downloadable Reports
- **JSON**: Full vulnerability details
- **CSV**: Spreadsheet-friendly format with CVE IDs, affected packages, etc.
- **Location**: Workflow run artifacts

## Scan Schedule

| Trigger | Description |
|---------|-------------|
| **Daily at 2 AM UTC** | Scheduled scan for all images and configs |
| **On every push to main** | Automatic scan when changes are pushed |
| **On pull requests** | Validate security before merge |
| **Manual** | Can be triggered via GitHub Actions UI |

## Troubleshooting

### Scans show wrong version
This should not happen anymore! Versions are extracted from `values.yaml`.

If it does happen:
1. Check that `values.yaml` contains the expected version
2. Verify the GitHub Actions workflow completed successfully
3. Check the workflow logs for `yq` extraction errors

### README not updated
The README is only updated on the `main` branch. Changes to `values.yaml` on other branches won't update README until merged.

To force an update:
1. Go to Actions tab
2. Select "Trivy Security Scan"
3. Click "Run workflow"
4. Select branch: `main`

### Version mismatch between deployed and scanned
This is **impossible** with the current setup because:
- Helm chart uses versions from `values.yaml`
- Trivy scans use versions from `values.yaml`
- README shows versions from `values.yaml`

All three read from the same source!

## Technical Implementation

### Tools Used
- **[yq](https://github.com/mikefarah/yq)**: YAML processor to extract values
- **[Trivy](https://trivy.dev/)**: Security scanner
- **[jq](https://stedolan.github.io/jq/)**: JSON processor for vulnerability counts
- **sed**: Update README.md with new values

### Key Files
- `values.yaml` - Single source of truth for versions
- `.github/workflows/trivy-scan.yml` - Automated scanning workflow
- `README.md` - Auto-updated with scan results

## Contributing

When adding a new container image to the chart:

1. Add version to `values.yaml`:
   ```yaml
   myservice:
     image:
       tag: "v1.0.0"
   ```

2. Add to Trivy scan matrix in `.github/workflows/trivy-scan.yml`:
   ```yaml
   - name: myservice
     repo: docker.io/myorg/myservice
     tag_key: myservice.image.tag
   ```

3. Add to README update section:
   ```bash
   MYSERVICE_VERSION=$(yq eval '.myservice.image.tag' values.yaml | tr -d '"')
   ```

The automation will handle the rest!
