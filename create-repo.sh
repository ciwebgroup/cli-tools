#!/bin/bash
# ===========================================
# Create Client Repository Script
# ===========================================
# Quickly creates a new client repo from the template
# and initializes the infrastructure.
# ===========================================

set -e

echo "=============================================="
echo "Create Client Repository"
echo "=============================================="
echo ""

# ===========================================
# Prerequisites Check
# ===========================================

echo "Checking prerequisites..."
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
  echo "❌ Git is not installed."
  echo ""
  
  # Detect OS and install git
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS. Installing git via Homebrew..."
    if ! command -v brew &> /dev/null; then
      echo "Homebrew not found. Installing Homebrew first..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install git
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected Linux."
    if command -v apt-get &> /dev/null; then
      echo "Installing git via apt..."
      sudo apt-get update && sudo apt-get install -y git
    elif command -v yum &> /dev/null; then
      echo "Installing git via yum..."
      sudo yum install -y git
    elif command -v dnf &> /dev/null; then
      echo "Installing git via dnf..."
      sudo dnf install -y git
    else
      echo "❌ Could not detect package manager. Please install git manually."
      exit 1
    fi
  else
    echo "❌ Unsupported OS. Please install git manually:"
    echo "   https://git-scm.com/downloads"
    exit 1
  fi
  
  echo ""
  echo "✓ Git installed successfully"
else
  echo "✓ Git is installed ($(git --version))"
fi

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
  echo ""
  echo "❌ GitHub CLI (gh) is not installed."
  echo ""
  
  # Detect OS and install gh
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS. Installing gh via Homebrew..."
    if ! command -v brew &> /dev/null; then
      echo "Homebrew not found. Installing Homebrew first..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install gh
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected Linux. Installing gh..."
    if command -v apt-get &> /dev/null; then
      # Add GitHub CLI repository
      curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
      sudo apt-get update && sudo apt-get install -y gh
    elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
      sudo dnf install -y 'dnf-command(config-manager)' 2>/dev/null || true
      sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
      sudo dnf install -y gh 2>/dev/null || sudo yum install -y gh
    else
      echo "❌ Could not detect package manager. Please install gh manually:"
      echo "   https://cli.github.com/manual/installation"
      exit 1
    fi
  else
    echo "❌ Unsupported OS. Please install gh manually:"
    echo "   https://cli.github.com/manual/installation"
    exit 1
  fi
  
  echo ""
  echo "✓ GitHub CLI installed successfully"
else
  echo "✓ GitHub CLI is installed ($(gh --version | head -n 1))"
fi

# Check if gh is authenticated
echo ""
echo "Checking GitHub authentication..."

if ! gh auth status &> /dev/null; then
  echo ""
  echo "⚠️  You are not logged in to GitHub CLI."
  echo ""
  echo "Please authenticate with GitHub to continue."
  echo "This will open a browser window for authentication."
  echo ""
  read -p "Press Enter to start authentication..."
  
  gh auth login
  
  echo ""
  echo "✓ GitHub authentication complete"
else
  echo "✓ Authenticated to GitHub"
fi

echo ""
echo "✓ All prerequisites met!"
echo ""

# ===========================================
# Repository Creation
# ===========================================

# Fixed values
GITHUB_ORG="ciwebgroup"
TEMPLATE_REPO="ciwebgroup/client-site-template"

# Prompt for production domain
read -p "Production domain (e.g., acme-hvac.com): " prod_domain

if [ -z "$prod_domain" ]; then
  echo "❌ Production domain is required"
  exit 1
fi

# Derive client slug from domain (remove TLD)
# Handles .com, .net, .org, .co.uk, etc.
client_slug=$(echo "$prod_domain" | sed -E 's/\.(com|net|org|io|co|biz|info|us|uk|ca|au|de|fr|es|it|nl|be|ch|at|co\.uk|com\.au|co\.nz)$//i')

# Construct repo name
repo_name="client-${client_slug}"
full_repo="${GITHUB_ORG}/${repo_name}"

# Confirm before proceeding
echo ""
echo "=============================================="
echo "Summary"
echo "=============================================="
echo "  Domain:      ${prod_domain}"
echo "  Client slug: ${client_slug}"
echo "  Repository:  ${full_repo}"
echo "  Template:    ${TEMPLATE_REPO}"
echo "=============================================="
echo ""
read -p "Proceed with repository creation? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "=============================================="
echo "Step 1: Creating repository from template"
echo "=============================================="

# Check if repo already exists
if gh repo view "${full_repo}" &> /dev/null; then
  echo "⚠️  Repository ${full_repo} already exists"
  echo ""
  read -p "Continue with existing repository? (y/N): " use_existing
  
  if [[ ! "$use_existing" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
  
  echo ""
  echo "✓ Using existing repository: https://github.com/${full_repo}"
else
  echo "Running: gh repo create ${full_repo} --template ${TEMPLATE_REPO} --private"
  echo ""
  
  gh repo create "${full_repo}" --template "${TEMPLATE_REPO}" --private
  
  echo ""
  echo "✓ Repository created: https://github.com/${full_repo}"
fi

echo ""
echo "=============================================="
echo "Step 2: Setting PROD_DOMAIN variable"
echo "=============================================="
echo "Running: gh variable set PROD_DOMAIN --body \"${prod_domain}\" --repo ${full_repo}"
echo ""

gh variable set PROD_DOMAIN --body "${prod_domain}" --repo "${full_repo}"

echo ""
echo "✓ PROD_DOMAIN variable set"

echo ""
echo "=============================================="
echo "Step 3: Running infrastructure initialization"
echo "=============================================="
echo "Waiting for workflow to be available..."

# Wait for workflow to be available (GitHub needs time to copy template files)
max_attempts=12
attempt=1
while [ $attempt -le $max_attempts ]; do
  if gh workflow view init.yml --repo "${full_repo}" &> /dev/null; then
    echo "✓ Workflow found"
    break
  fi
  
  if [ $attempt -eq $max_attempts ]; then
    echo ""
    echo "⚠️  Workflow not available yet. You can run it manually later:"
    echo "   gh workflow run init.yml --repo ${full_repo}"
    echo ""
    break
  fi
  
  echo "  Waiting... (attempt ${attempt}/${max_attempts})"
  sleep 5
  attempt=$((attempt + 1))
done

# Try to run the workflow if it's available
if gh workflow view init.yml --repo "${full_repo}" &> /dev/null; then
  echo "Running: gh workflow run init.yml --repo ${full_repo}"
  echo ""
  
  if gh workflow run init.yml --repo "${full_repo}"; then
    echo ""
    echo "✓ Infrastructure initialization workflow triggered"
  else
    echo ""
    echo "⚠️  Could not trigger workflow. Run manually:"
    echo "   gh workflow run init.yml --repo ${full_repo}"
  fi
fi

echo ""
echo "=============================================="
echo "✅ Repository Setup Complete!"
echo "=============================================="
echo ""
echo "Repository URL: https://github.com/${full_repo}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Clone the repository:"
echo "     git clone git@github.com:${full_repo}.git && cd ${repo_name}"
echo ""
echo "  2. Deploy to staging:"
echo "     git push origin stage"
echo ""
echo "  3. Check workflow status:"
echo "     gh run list --repo ${full_repo}"
echo ""
