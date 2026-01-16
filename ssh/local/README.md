# SSH Local Configurations

This directory contains SSH configurations that are conditionally loaded based on environment markers.

## How It Works

1. Base SSH config (`ssh/config`) includes `~/.ssh/config.d/*`
2. Conditional configs are stored here in `ssh/local/`
3. The layered bash configuration system creates symlinks to `~/.ssh/config.d/` when conditions are met

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

1. Create a new file in `ssh/local/config-<conditions>`
2. Add conditional symlinking logic in the appropriate bash config layer:
   - Context-specific: `bash/local/context-work` or `context-home`
   - Environment-specific: `bash/local/environment-wsl` or `environment-cloud`
   - Project-specific: `bash/local/project-<name>`
3. Use the pattern:
   ```bash
   if [[ <conditions> ]]; then
       mkdir -p ~/.ssh/config.d
       if [[ ! -L ~/.ssh/config.d/<name> ]] && [[ ! -f ~/.ssh/config.d/<name> ]]; then
           ln -s ~/env/ssh/local/config-<name> ~/.ssh/config.d/<name> 2>/dev/null
           [[ "$VERBOSE_ENV_LOADING" == "true" ]] && echo "Linked: ~/.ssh/config.d/<name>"
       fi
   fi
   ```

## Why This Pattern?

- Keeps work-specific configs out of the public repo (ssh/local/ is gitignored)
- Maintains clean git status (no dirty index files)
- Automatically adapts SSH config based on environment
- Easy to understand and maintain with clear conditional logic
