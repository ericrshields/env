# SSH Conditional Configurations

This directory contains **versioned** SSH configurations that are conditionally loaded based on environment markers.

## How It Works

1. Base SSH config (`ssh/config`) includes `~/.ssh/config.d/*`
2. Conditional configs are **versioned here** in `ssh/configs/`
3. The layered bash configuration system creates symlinks from `~/.ssh/config.d/` to configs here when conditions are met

## Current Configurations

### config-work-grafana

**Conditions:**
- `.env-marker-work` exists (work context)
- `.env-marker-project-grafana` exists (grafana project)
- `.env-marker-cloud` does NOT exist (not on cloud server)

**Contains:**
- AWS SSM dev-cloud host configuration

**Loaded by:** `bash/local/project-grafana`

## Adding New Conditional Configs

1. Create a new file in `ssh/configs/config-<name>` (versioned in git)
2. Add conditional symlinking logic in the appropriate bash config layer:
   - Context-specific: `bash/local/context-work` or `context-home`
   - Environment-specific: `bash/local/environment-wsl` or `environment-cloud`
   - Project-specific: `bash/local/project-<name>`
3. Use the pattern:
   ```bash
   if [[ <conditions> ]]; then
       mkdir -p ~/.ssh/config.d
       if [[ ! -L ~/.ssh/config.d/<name> ]]; then
           ln -sf ~/env/ssh/configs/config-<name> ~/.ssh/config.d/<name>
           [[ "$VERBOSE_ENV_LOADING" == "true" ]] && echo "Linked: ~/.ssh/config.d/<name>"
       fi
   fi
   ```

## Secret Configs

If you have configs with secrets (private keys, sensitive hostnames):
- Place them directly in `~/.ssh/config.d/` (unversioned)
- They'll still be loaded by SSH via the Include directive

## Why This Pattern?

- Configs are versioned and sync across machines
- Automatically adapts SSH config based on environment markers
- Easy to understand and maintain with clear conditional logic
- Supports both versioned and secret configs
