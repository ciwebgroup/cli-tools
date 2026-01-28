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
  elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "mingw"* ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo "Detected Windows (Git Bash/MSYS/Cygwin)."
    echo ""
    echo "⚠️  You're running this script in a bash environment, but git is not available."
    echo "   This is unusual since Git Bash typically includes git."
    echo ""
    echo "   Please install Git for Windows from:"
    echo "   https://git-scm.com/download/win"
    echo ""
    echo "   Or install via winget:"
    echo "   winget install --id Git.Git -e --source winget"
    exit 1
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
  elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "mingw"* ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo "Detected Windows (Git Bash/MSYS/Cygwin)."
    echo ""

    # Try winget first (Windows Package Manager - built into Windows 10/11)
    if command -v winget &> /dev/null; then
      echo "Installing gh via winget..."
      winget install --id GitHub.cli -e --source winget

      # winget installs to a location that may not be in the current PATH
      echo ""
      echo "✓ GitHub CLI installed via winget"
      echo ""
      echo "⚠️  You may need to restart your terminal for 'gh' to be available in PATH."
      echo "   After restarting, run this script again."
      exit 0
    # Try chocolatey
    elif command -v choco &> /dev/null; then
      echo "Installing gh via Chocolatey..."
      choco install gh -y

      echo ""
      echo "✓ GitHub CLI installed via Chocolatey"
      echo ""
      echo "⚠️  You may need to restart your terminal for 'gh' to be available in PATH."
      echo "   After restarting, run this script again."
      exit 0
    # Try scoop
    elif command -v scoop &> /dev/null; then
      echo "Installing gh via Scoop..."
      scoop install gh

      echo ""
      echo "✓ GitHub CLI installed via Scoop"
    else
      echo "No supported package manager found (winget, chocolatey, or scoop)."
      echo ""
      echo "Please install GitHub CLI manually using one of these methods:"
      echo ""
      echo "  Option 1 - winget (recommended, built into Windows 10/11):"
      echo "    winget install --id GitHub.cli -e --source winget"
      echo ""
      echo "  Option 2 - Download installer:"
      echo "    https://cli.github.com"
      echo ""
      echo "  Option 3 - Install Chocolatey first, then gh:"
      echo "    https://chocolatey.org/install"
      echo "    choco install gh"
      echo ""
      echo "  Option 4 - Install Scoop first, then gh:"
      echo "    https://scoop.sh"
      echo "    scoop install gh"
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

# Check if editor (cursor or code) is installed
echo ""
echo "Checking for code editor..."

# Detect which editor the user is likely using
# Check if Cursor is running or if cursor command exists
PREFERRED_EDITOR=""
if command -v cursor &> /dev/null; then
  PREFERRED_EDITOR="cursor"
  echo "✓ Cursor is installed"
elif command -v code &> /dev/null; then
  PREFERRED_EDITOR="code"
  echo "✓ VS Code is installed"
elif [[ -n "$CURSOR_APP" ]] || pgrep -x "Cursor" &> /dev/null || [[ "$TERM_PROGRAM" == "vscode" ]]; then
  # User is likely using Cursor but command not in PATH
  PREFERRED_EDITOR="cursor"
  echo "⚠️  Cursor detected but 'cursor' command not in PATH"
elif [[ "$TERM_PROGRAM" == "vscode" ]] || pgrep -x "Code" &> /dev/null; then
  # User is likely using VS Code but command not in PATH
  PREFERRED_EDITOR="code"
  echo "⚠️  VS Code detected but 'code' command not in PATH"
fi

# If no editor found, try to install based on OS
if [ -z "$PREFERRED_EDITOR" ]; then
  echo "⚠️  No code editor command found (cursor or code)"
  echo ""
  
  # Try to detect which one to install
  # Default to cursor if we can't determine, but ask user
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Detected macOS."
    echo ""
    read -p "Install Cursor? (Y/n): " install_cursor
    
    if [[ ! "$install_cursor" =~ ^[Nn]$ ]]; then
      PREFERRED_EDITOR="cursor"
      echo ""
      echo "Installing Cursor..."
      
      if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      
      brew install --cask cursor
      echo ""
      echo "✓ Cursor installed successfully"
    else
      echo ""
      read -p "Install VS Code? (Y/n): " install_code
      
      if [[ ! "$install_code" =~ ^[Nn]$ ]]; then
        PREFERRED_EDITOR="code"
        echo ""
        echo "Installing VS Code..."
        
        if ! command -v brew &> /dev/null; then
          echo "Homebrew not found. Installing Homebrew first..."
          /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        brew install --cask visual-studio-code
        echo ""
        echo "✓ VS Code installed successfully"
      else
        echo ""
        echo "⚠️  No editor will be installed. You can open the repository manually."
      fi
    fi
  elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Detected Linux."
    echo ""
    read -p "Install Cursor? (Y/n): " install_cursor
    
    if [[ ! "$install_cursor" =~ ^[Nn]$ ]]; then
      PREFERRED_EDITOR="cursor"
      echo ""
      echo "Installing Cursor..."
      
      # Cursor installation for Linux varies by distribution
      if command -v curl &> /dev/null || command -v wget &> /dev/null; then
        if command -v apt-get &> /dev/null; then
          # Debian/Ubuntu
          echo "Downloading Cursor for Debian/Ubuntu..."
          CURSOR_DEB="/tmp/cursor.deb"
          curl -L "https://downloader.cursor.sh/linux/deb" -o "$CURSOR_DEB" 2>/dev/null || \
          wget -O "$CURSOR_DEB" "https://downloader.cursor.sh/linux/deb" 2>/dev/null || {
            echo "⚠️  Could not download Cursor automatically."
            echo "   Please download and install manually from: https://cursor.sh"
            PREFERRED_EDITOR=""
          }
          
          if [ -n "$PREFERRED_EDITOR" ] && [ -f "$CURSOR_DEB" ]; then
            sudo dpkg -i "$CURSOR_DEB" 2>/dev/null || sudo apt-get install -f -y
            rm -f "$CURSOR_DEB"
            echo ""
            echo "✓ Cursor installed successfully"
          fi
        elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
          # RHEL/Fedora
          echo "Downloading Cursor for RHEL/Fedora..."
          CURSOR_RPM="/tmp/cursor.rpm"
          curl -L "https://downloader.cursor.sh/linux/rpm" -o "$CURSOR_RPM" 2>/dev/null || \
          wget -O "$CURSOR_RPM" "https://downloader.cursor.sh/linux/rpm" 2>/dev/null || {
            echo "⚠️  Could not download Cursor automatically."
            echo "   Please download and install manually from: https://cursor.sh"
            PREFERRED_EDITOR=""
          }
          
          if [ -n "$PREFERRED_EDITOR" ] && [ -f "$CURSOR_RPM" ]; then
            sudo rpm -i "$CURSOR_RPM" 2>/dev/null || sudo dnf install -y "$CURSOR_RPM" 2>/dev/null || sudo yum install -y "$CURSOR_RPM"
            rm -f "$CURSOR_RPM"
            echo ""
            echo "✓ Cursor installed successfully"
          fi
        else
          echo "⚠️  Unsupported Linux distribution for automatic installation."
          echo "   Please install Cursor manually from: https://cursor.sh"
          PREFERRED_EDITOR=""
        fi
      else
        echo "⚠️  curl or wget not found. Please install Cursor manually:"
        echo "   https://cursor.sh"
        PREFERRED_EDITOR=""
      fi
    else
      echo ""
      read -p "Install VS Code? (Y/n): " install_code
      
      if [[ ! "$install_code" =~ ^[Nn]$ ]]; then
        PREFERRED_EDITOR="code"
        echo ""
        echo "Installing VS Code..."
        
        if command -v apt-get &> /dev/null; then
          curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
          echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
          sudo apt-get update && sudo apt-get install -y code
        elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
          sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
          sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
          sudo dnf install -y code 2>/dev/null || sudo yum install -y code
        else
          echo "⚠️  Could not detect package manager. Please install VS Code manually:"
          echo "   https://code.visualstudio.com/download"
          PREFERRED_EDITOR=""
        fi
        
        if [ -n "$PREFERRED_EDITOR" ]; then
          echo ""
          echo "✓ VS Code installed successfully"
        fi
      else
        echo ""
        echo "⚠️  No editor will be installed. You can open the repository manually."
      fi
    fi
  else
    echo "⚠️  Unsupported OS. Please install an editor manually:"
    echo "   Cursor: https://cursor.sh"
    echo "   VS Code: https://code.visualstudio.com/download"
  fi
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

# Validate that it's a domain (contains a dot), not just a slug
if [[ ! "$prod_domain" =~ \. ]]; then
  echo ""
  echo "⚠️  Warning: '${prod_domain}' doesn't look like a full domain (missing TLD)."
  echo "   Did you mean '${prod_domain}.com'?"
  read -p "Use '${prod_domain}.com' instead? (Y/n): " use_com
  
  if [[ ! "$use_com" =~ ^[Nn]$ ]]; then
    prod_domain="${prod_domain}.com"
    echo "✓ Using domain: ${prod_domain}"
  else
    echo "⚠️  Continuing with '${prod_domain}' as provided"
  fi
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
echo "Step 2: Cloning repository"
echo "=============================================="

# Determine clone directory (parent of current directory)
clone_dir="../${repo_name}"
skip_clone=false

if [ -d "${clone_dir}" ]; then
  echo "⚠️  Directory ${clone_dir} already exists"
  read -p "Remove and re-clone? (y/N): " reclone
  
  if [[ "$reclone" =~ ^[Yy]$ ]]; then
    rm -rf "${clone_dir}"
  else
    echo "Skipping clone. Using existing directory."
    skip_clone=true
  fi
fi

if [ "$skip_clone" = false ]; then
  echo "Running: gh repo clone ${full_repo} ${clone_dir}"
  echo ""

  # Use gh repo clone which respects gh auth login credentials
  gh repo clone "${full_repo}" "${clone_dir}"

  echo ""
  echo "✓ Repository cloned to ${clone_dir}"
else
  echo "✓ Using existing directory: ${clone_dir}"
fi

# Check workflow requirements before pushing
echo ""
echo "Checking workflow runner requirements..."
cd "${clone_dir}"

# Check if workflows require self-hosted runners
REQUIRES_SELF_HOSTED=false
if [ -d ".github/workflows" ]; then
  for workflow_file in .github/workflows/*.yml .github/workflows/*.yaml; do
    if [ -f "$workflow_file" ]; then
      if grep -q "runs-on:" "$workflow_file" && grep -q "self-hosted" "$workflow_file"; then
        REQUIRES_SELF_HOSTED=true
        echo "  Found workflow requiring self-hosted runner: $(basename "$workflow_file")"
      fi
    fi
  done
fi

if [ "$REQUIRES_SELF_HOSTED" = true ]; then
  echo ""
  echo "⚠️  Workflows require self-hosted runners"
  echo ""

  # Check if organization has self-hosted runners
  # Handle API errors gracefully (user may not have org admin permissions)
  ORG_RUNNERS="unknown"
  if ORG_RUNNERS_RESPONSE=$(gh api "orgs/${GITHUB_ORG}/actions/runners" 2>&1); then
    if echo "$ORG_RUNNERS_RESPONSE" | grep -q '"total_count"'; then
      # Extract total_count using grep and sed (works without jq)
      ORG_RUNNERS=$(echo "$ORG_RUNNERS_RESPONSE" | grep -o '"total_count":[0-9]*' | head -1 | sed 's/"total_count"://')
      ORG_RUNNERS=${ORG_RUNNERS:-0}
    fi
  fi

  REPO_RUNNERS="unknown"
  if REPO_RUNNERS_RESPONSE=$(gh api "repos/${full_repo}/actions/runners" 2>&1); then
    if echo "$REPO_RUNNERS_RESPONSE" | grep -q '"total_count"'; then
      REPO_RUNNERS=$(echo "$REPO_RUNNERS_RESPONSE" | grep -o '"total_count":[0-9]*' | head -1 | sed 's/"total_count"://')
      REPO_RUNNERS=${REPO_RUNNERS:-0}
    fi
  fi

  # Only show "no runners" warning if we confirmed both have 0 (not unknown)
  if [ "$ORG_RUNNERS" = "0" ] && [ "$REPO_RUNNERS" = "0" ]; then
    echo "❌ No self-hosted runners found for organization '${GITHUB_ORG}' or repository '${full_repo}'"
    echo ""
    echo "   Self-hosted runners can be configured at:"
    echo "   - Organization level: https://github.com/organizations/${GITHUB_ORG}/settings/actions/runners"
    echo "   - Repository level: https://github.com/${full_repo}/settings/actions/runners"
    echo ""
    echo "   Organization-level runners are recommended for multiple repositories."
    echo ""
    echo "   To set up a self-hosted runner:"
    echo "   1. Go to Settings > Actions > Runners"
    echo "   2. Click 'New runner'"
    echo "   3. Follow the setup instructions"
    echo ""
    read -p "Continue anyway? Workflows will be queued until runners are available. (y/N): " continue_no_runners
    
    if [[ ! "$continue_no_runners" =~ ^[Yy]$ ]]; then
      echo "Aborted. Set up runners first, then run this script again."
      cd - > /dev/null
      exit 0
    fi
  else
    if [ "$ORG_RUNNERS" = "unknown" ]; then
      echo "  ℹ️  Cannot check organization runners (requires org admin permissions)"
    elif [ "$ORG_RUNNERS" != "0" ]; then
      echo "✓ Found ${ORG_RUNNERS} organization-level runner(s)"
    fi
    if [ "$REPO_RUNNERS" = "unknown" ]; then
      echo "  ℹ️  Cannot check repository runners (insufficient permissions)"
    elif [ "$REPO_RUNNERS" != "0" ]; then
      echo "✓ Found ${REPO_RUNNERS} repository-level runner(s)"
    fi

    # If we couldn't check either, assume runners exist at org level
    if [ "$ORG_RUNNERS" = "unknown" ] || [ "$REPO_RUNNERS" = "unknown" ]; then
      echo ""
      echo "  Assuming self-hosted runners are configured at the organization level."
      echo "  If workflows get stuck, check runner availability."
    fi
  fi
else
  echo "✓ Workflows use GitHub-hosted runners (no self-hosted runners required)"
fi

cd - > /dev/null

echo ""
echo "=============================================="
echo "Step 3: Setting repository variables"
echo "=============================================="

# Set PROD_DOMAIN variable (ensure it's the full domain, not slug)
echo "Setting PROD_DOMAIN to: ${prod_domain}"
echo "Running: gh variable set PROD_DOMAIN --body \"${prod_domain}\" --repo ${full_repo}"
echo ""

gh variable set PROD_DOMAIN --body "${prod_domain}" --repo "${full_repo}"

echo ""
echo "✓ PROD_DOMAIN variable set to ${prod_domain}"

echo ""
echo "=============================================="
echo "Step 4: Running infrastructure initialization"
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
WORKFLOW_RUN_ID=""
if gh workflow view init.yml --repo "${full_repo}" &> /dev/null; then
  echo "Running: gh workflow run init.yml --repo ${full_repo}"
  echo ""
  
  if gh workflow run init.yml --repo "${full_repo}"; then
    echo ""
    echo "✓ Infrastructure initialization workflow triggered"
    
    # Get the workflow run ID
    echo "Waiting for workflow run to start..."
    sleep 5
    
    # Get the most recent workflow run
    max_wait=30
    wait_count=0
    while [ $wait_count -lt $max_wait ]; do
      WORKFLOW_RUN_ID=$(gh run list --workflow=init.yml --repo "${full_repo}" --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null)
      if [ -n "$WORKFLOW_RUN_ID" ] && [ "$WORKFLOW_RUN_ID" != "null" ]; then
        break
      fi
      sleep 2
      wait_count=$((wait_count + 1))
    done
    
    if [ -n "$WORKFLOW_RUN_ID" ] && [ "$WORKFLOW_RUN_ID" != "null" ]; then
      echo "✓ Workflow run ID: ${WORKFLOW_RUN_ID}"
    fi
  else
    echo ""
    echo "⚠️  Could not trigger workflow. Run manually:"
    echo "   gh workflow run init.yml --repo ${full_repo}"
  fi
fi

echo ""
echo "=============================================="
echo "Step 5: Waiting for WordPress multisite creation"
echo "=============================================="

if [ -n "$WORKFLOW_RUN_ID" ] && [ "$WORKFLOW_RUN_ID" != "null" ]; then
  echo "Waiting for workflow to complete..."
  echo "This may take several minutes..."
  echo ""
  
  # Wait for workflow to complete (max 15 minutes)
  max_wait=90
  wait_count=0
  last_status=""
  stuck_warning_shown=false
  
  while [ $wait_count -lt $max_wait ]; do
    # Get workflow status using gh's built-in jq (works without standalone jq)
    CURRENT_STATUS=$(gh run view "${WORKFLOW_RUN_ID}" --repo "${full_repo}" --json status --jq '.status' 2>/dev/null)
    
    # Check if workflow is stuck waiting for a runner
    if [ "$CURRENT_STATUS" = "queued" ] || [ "$CURRENT_STATUS" = "in_progress" ]; then
      # Check job details to see if waiting for runner
      JOBS_INFO=$(gh run view "${WORKFLOW_RUN_ID}" --repo "${full_repo}" --json jobs --jq '[.jobs[]? | {name: .name, status: .status}]' 2>/dev/null)
      
      # Check logs for "Waiting for a runner" message
      if [ $wait_count -ge 6 ]; then  # After 1 minute, check for stuck jobs
        RUNNER_CHECK=$(gh run view "${WORKFLOW_RUN_ID}" --repo "${full_repo}" --log 2>/dev/null | grep -i "waiting for.*runner" | head -n 1)
        
        if [ -n "$RUNNER_CHECK" ] && [ "$stuck_warning_shown" = false ]; then
          echo ""
          echo "⚠️  WARNING: Workflow appears to be stuck waiting for a self-hosted runner!"
          echo ""
          echo "   The workflow is queued but no runner is available to pick it up."
          echo ""
          echo "   Self-hosted runners can be configured at:"
          echo "   - Organization level (recommended): https://github.com/organizations/${GITHUB_ORG}/settings/actions/runners"
          echo "   - Repository level: https://github.com/${full_repo}/settings/actions/runners"
          echo ""
          echo "   Ensure self-hosted runners are:"
          echo "   - Running and connected to GitHub"
          echo "   - Have the correct labels (check workflow file for 'runs-on' requirements)"
          echo "   - Are not at capacity"
          echo ""
          echo "   Workflow URL: https://github.com/${full_repo}/actions/runs/${WORKFLOW_RUN_ID}"
          echo ""
          echo "   You can continue monitoring or exit and check later."
          read -p "   Continue waiting? (Y/n): " continue_wait
          if [[ "$continue_wait" =~ ^[Nn]$ ]]; then
            echo ""
            echo "   Exiting early. Check workflow status later:"
            echo "   gh run view ${WORKFLOW_RUN_ID} --repo ${full_repo}"
            break
          fi
          stuck_warning_shown=true
        fi
      fi
    fi
    
    if [ "$CURRENT_STATUS" = "completed" ]; then
      CONCLUSION=$(gh run view "${WORKFLOW_RUN_ID}" --repo "${full_repo}" --json conclusion --jq '.conclusion' 2>/dev/null)
      echo ""
      echo "✓ Workflow completed with status: ${CONCLUSION}"
      break
    elif [ "$CURRENT_STATUS" = "cancelled" ]; then
      echo ""
      echo "⚠️  Workflow was cancelled"
      break
    elif [ "$CURRENT_STATUS" = "failure" ]; then
      echo ""
      echo "❌ Workflow failed"
      echo "   Check the logs: gh run view ${WORKFLOW_RUN_ID} --repo ${full_repo} --log"
      break
    fi
    
    # Show progress every 30 seconds
    if [ $((wait_count % 6)) -eq 0 ] && [ $wait_count -gt 0 ]; then
      echo "  Still waiting... Status: ${CURRENT_STATUS} (${wait_count}/${max_wait} checks, ~$((wait_count * 10 / 60))m elapsed)"
    fi
    
    sleep 10
    wait_count=$((wait_count + 1))
    last_status="$CURRENT_STATUS"
  done
  
  if [ $wait_count -ge $max_wait ]; then
    echo ""
    echo "⚠️  Workflow is taking longer than expected (15+ minutes)."
    echo ""
    
    # Check if still waiting for runner
    FINAL_STATUS=$(gh run view "${WORKFLOW_RUN_ID}" --repo "${full_repo}" --json status --jq '.status' 2>/dev/null)
    RUNNER_CHECK=$(gh run view "${WORKFLOW_RUN_ID}" --repo "${full_repo}" --log 2>/dev/null | grep -i "waiting for.*runner" | head -n 1)
    
    if [ -n "$RUNNER_CHECK" ] || [ "$FINAL_STATUS" = "queued" ]; then
      echo "   ⚠️  WORKFLOW IS STUCK: Waiting for a self-hosted runner!"
      echo ""
      echo "   The workflow cannot proceed because no self-hosted runner is available."
      echo ""
      echo "   Self-hosted runners can be configured at:"
      echo "   - Organization level (recommended): https://github.com/organizations/${GITHUB_ORG}/settings/actions/runners"
      echo "   - Repository level: https://github.com/${full_repo}/settings/actions/runners"
      echo ""
      echo "   Please ensure:"
      echo "   1. Self-hosted runners are running and connected"
      echo "   2. Runners have the correct labels (check workflow file for 'runs-on')"
      echo "   3. Runners are not at capacity"
      echo ""
    fi
    
    echo "   Workflow URL: https://github.com/${full_repo}/actions/runs/${WORKFLOW_RUN_ID}"
    echo ""
    echo "   Check status manually:"
    echo "   gh run view ${WORKFLOW_RUN_ID} --repo ${full_repo}"
    echo ""
  fi
else
  echo "⚠️  No workflow run ID available."
  echo "   Please check workflow runs manually:"
  echo "   gh run list --repo ${full_repo}"
fi

echo ""
echo "=============================================="
echo "Step 6: Pushing to stage branch to trigger CI/CD"
echo "=============================================="

cd "${clone_dir}"

# First, ensure remote is set correctly
if ! git remote get-url origin &> /dev/null; then
  echo "Setting remote origin..."
  git remote add origin "git@github.com:${full_repo}.git" 2>/dev/null || \
    git remote set-url origin "git@github.com:${full_repo}.git"
fi

# Fetch all branches and commits from origin (workflow may have pushed files)
echo "Fetching from origin..."
git fetch origin --prune

# Get the default branch name from remote
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$DEFAULT_BRANCH" ]; then
  # Try to detect default branch from remote
  if git ls-remote --heads origin main | grep -q main; then
    DEFAULT_BRANCH="main"
  elif git ls-remote --heads origin master | grep -q master; then
    DEFAULT_BRANCH="master"
  else
    # Get the first branch from remote
    DEFAULT_BRANCH=$(git ls-remote --heads origin | head -n 1 | sed 's@.*refs/heads/@@' || echo "main")
  fi
fi

echo "Default branch: ${DEFAULT_BRANCH}"

# Check if we have any commits locally
if ! git rev-parse --verify HEAD &> /dev/null; then
  # Local repo is empty, checkout from origin
  echo "Local repository is empty, checking out ${DEFAULT_BRANCH} from origin..."
  if git ls-remote --heads origin "${DEFAULT_BRANCH}" | grep -q "${DEFAULT_BRANCH}"; then
    git checkout -b "${DEFAULT_BRANCH}" "origin/${DEFAULT_BRANCH}" 2>/dev/null || \
      git checkout "${DEFAULT_BRANCH}" 2>/dev/null || \
      git checkout -b "${DEFAULT_BRANCH}" "origin/${DEFAULT_BRANCH}"
  else
    echo "⚠️  Default branch ${DEFAULT_BRANCH} not found on remote yet."
    echo "   Repository may still be empty. Waiting a moment..."
    sleep 3
    git fetch origin
    if git ls-remote --heads origin "${DEFAULT_BRANCH}" | grep -q "${DEFAULT_BRANCH}"; then
      git checkout -b "${DEFAULT_BRANCH}" "origin/${DEFAULT_BRANCH}"
    else
      echo "⚠️  Repository appears to be empty. Skipping stage branch creation."
      echo "   You can create it manually later:"
      echo "   cd ${clone_dir}"
      echo "   git checkout -b stage"
      echo "   git push -u origin stage"
      cd - > /dev/null
      exit 0
    fi
  fi
else
  # We have local commits, make sure we're on the right branch
  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
  if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
    git checkout "${DEFAULT_BRANCH}" 2>/dev/null || \
      git checkout -b "${DEFAULT_BRANCH}" "origin/${DEFAULT_BRANCH}" 2>/dev/null || true
  fi
  # Pull latest changes
  git pull origin "${DEFAULT_BRANCH}" 2>/dev/null || true
fi

# Check if stage branch exists remotely
if git ls-remote --heads origin stage | grep -q stage; then
  echo "Stage branch exists remotely, fetching and checking out..."
  git fetch origin stage
  git checkout -B stage origin/stage 2>/dev/null || git checkout -b stage origin/stage
else
  echo "Creating stage branch from ${DEFAULT_BRANCH}..."
  # Delete local stage if it exists (might be stale)
  git branch -D stage 2>/dev/null || true
  # Create fresh stage branch from current branch (which should be default)
  git checkout -b stage "${DEFAULT_BRANCH}" 2>/dev/null || git checkout -b stage
fi

# Push to trigger workflows
echo "Pushing to origin stage..."
if ! git push -u origin stage 2>&1; then
  echo "⚠️  Push failed. This might be because:"
  echo "   1. The repository is still being populated"
  echo "   2. Authentication issues"
  echo ""
  echo "   You can try manually:"
  echo "   cd ${clone_dir}"
  echo "   git push -u origin stage"
fi

echo ""
echo "✓ Pushed to stage branch - CI/CD workflow triggered"
if [ "$REQUIRES_SELF_HOSTED" = true ]; then
  echo ""
  echo "Note: CI/CD workflows require self-hosted runners. If workflows get stuck,"
  echo "      ensure runners are running and have the correct labels."
fi

cd - > /dev/null

echo ""
echo "=============================================="
echo "Step 7: Opening repository in editor"
echo "=============================================="

# Use the preferred editor we detected/installed earlier, or try to find one
if [ -n "$PREFERRED_EDITOR" ] && command -v "$PREFERRED_EDITOR" &> /dev/null; then
  echo "Opening in ${PREFERRED_EDITOR}..."
  "$PREFERRED_EDITOR" "${clone_dir}"
  echo "✓ Repository opened in ${PREFERRED_EDITOR}"
elif command -v cursor &> /dev/null; then
  echo "Opening in Cursor..."
  cursor "${clone_dir}"
  echo "✓ Repository opened in Cursor"
elif command -v code &> /dev/null; then
  echo "Opening in VS Code..."
  code "${clone_dir}"
  echo "✓ Repository opened in VS Code"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  echo "Opening in default application..."
  open "${clone_dir}"
  echo "✓ Repository opened"
else
  echo "⚠️  Could not detect editor. Please open manually:"
  echo "   cd ${clone_dir}"
fi

echo ""
echo "=============================================="
echo "✅ Repository Setup Complete!"
echo "=============================================="
echo ""
echo "Repository URL: https://github.com/${full_repo}"
echo "Local directory: ${clone_dir}"
echo ""
echo "Repository variables set:"
echo "  - PROD_DOMAIN: ${prod_domain}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Check workflow status:"
if [ -n "$WORKFLOW_RUN_ID" ] && [ "$WORKFLOW_RUN_ID" != "null" ]; then
  echo "     gh run view ${WORKFLOW_RUN_ID} --repo ${full_repo}"
else
  echo "     gh run list --repo ${full_repo}"
fi
echo ""
