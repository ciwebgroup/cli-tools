# CI Web Group CLI Tools

Command-line tools for CI Web Group project automation.

## create-repo.sh

Creates a new client website repository from the template and initializes infrastructure.

### Quick Run

```bash
bash <(curl -s https://raw.githubusercontent.com/ciwebgroup/cli-tools/main/create-repo.sh)
```

### What it does

1. **Checks prerequisites** - Installs git and GitHub CLI if needed
2. **Authenticates** - Prompts for GitHub login if not authenticated
3. **Creates repository** - Creates `ciwebgroup/client-{slug}` from template
4. **Sets variables** - Configures `PROD_DOMAIN` in GitHub Actions
5. **Triggers initialization** - Runs the `init.yml` workflow

### Usage

```bash
./create-repo.sh
```

You'll be prompted for:
- **Production domain** (e.g., `acme-hvac.com`)

The client slug is automatically derived from the domain (e.g., `acme-hvac`).

### Install as alias (optional)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
alias create-client-repo='bash <(curl -s https://raw.githubusercontent.com/ciwebgroup/cli-tools/main/create-repo.sh)'
```

Then run:

```bash
create-client-repo
```
