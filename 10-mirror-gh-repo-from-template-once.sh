#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 01. Setup and Preparation
echo -e "${YELLOW}01. Copy environment variables locally to Github environments${NC}"
# Read the variables from the .env file
set -a # Enable export of all variables
source .env # Source the .env file
set +a # Disable export of all variables

if [ -f ".env" ]; then
    if [ -z "$GITHUB_USERNAME" ]; then
        echo -e "${RED}Failed to read the first variable,GITHUB_USERNAME, from .env.${NC}"
        exit 1
    else
        echo -e "${GREEN}Successfully read the first variable GITHUB_USERNAME=${GITHUB_USERNAME}, from .env file${NC}"
    fi
else
    echo -e "${RED}.env file does not exist.${NC}"
    exit 1
fi

# Define the temporary directory within the current directory
current_dir=$(pwd)

#temp_dir="$current_dir/temp"
temp_dir="../temp"

# Create the temporary directory
rm -rf "$temp_dir"
mkdir -p "$temp_dir"

# Ensure the temporary directory is removed on script exit
trap "rm -rf $temp_dir" EXIT

# Change to the temporary directory
cd "$temp_dir"

# Setup additional variables
if [ "$GITHUB_USE_SSH" = "true" ]; then
    github_template_repo_uri="git@github.com:${GITHUB_TEMPLATE_REPO}.git"
else
    github_template_repo_uri="https://github.com/${GITHUB_TEMPLATE_REPO}.git"
fi
if [ "$GITHUB_USE_SSH" = "true" ]; then
    github_new_repo_uri="git@github.com:${GITHUB_NEW_REPO}.git"
else
    github_new_repo_uri="https://github.com/${GITHUB_NEW_REPO}.git"
fi
github_new_repo_name=${GITHUB_NEW_REPO##*/}
github_template_repo_name=${GITHUB_TEMPLATE_REPO##*/}
destination_dir="../$github_new_repo_name"

# Get the GitHub CLI version
gh_version=$(gh --version | grep -oP '\d+\.\d+\.\d+')

# Function to compare versions
version_lt() {
    [ "$1" != "$2" ] && [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}

# Check if gh_version is below 2.64.0
if version_lt "$gh_version" "2.64.0"; then
    echo -e "${RED}Error: GitHub CLI version 2.64.0 or higher is required. Current version: $gh_version${NC}"
    echo -e "${YELLOW}Tip: If you have lower version than 2.14.1 you need to uninstall Git, and remove the folder manually on Windows: C:\Program Files\Git manually, and reinstall https://git-scm.com/downloads/win ${NC}"
    exit 1
fi

echo -e "${GREEN}Github CLI Version: ${gh_version} ${NC}"

echo -e "\e[33mBootstraping Parameters\e[0m"
echo -e "\e[36mGitHub Username:\e[0m $GITHUB_USERNAME"
echo -e "\e[36mGitHub Use SSH:\e[0m $GITHUB_USE_SSH"
echo -e "\e[36mGitHub Template Repo:\e[0m $GITHUB_TEMPLATE_REPO"
echo -e "\e[36mGitHub Template Repo name:\e[0m $github_template_repo_name"
echo -e "\e[36mGitHub Template Repo URI:\e[0m $github_template_repo_uri"
echo -e "\e[36mGitHub New Repo:\e[0m $GITHUB_NEW_REPO"
echo -e "\e[36mGitHub New Repo name:\e[0m $github_new_repo_name"
echo -e "\e[36mGitHub New Repo URI:\e[0m $github_new_repo_uri"
echo -e "\e[36mGitHub New Repo Visibility:\e[0m $GITHUB_NEW_REPO_VISIBILITY"
echo -e "\e[36mGitHub New Repo local path destination:\e[0m $destination_dir"

# Remove the existing local folder if it exists
if [ -d "$destination_dir" ]; then
    read -p "It seems like you already have initialized a repo, since local folder exsits at $destination_dir. Do you want to delete folder, and re-initalize(Y/n)? " choice
    if [[ "$choice" == "n" || "$choice" == "N" ]]; then
        echo "Exiting script."
        exit 1
    fi
    rm -rf "$destination_dir"
fi

# Check if the user is already logged in to GitHub
echo -e "${GREEN}Checking GitHub authentication status...${NC}"
gh auth status
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Not logged in to GitHub. Logging in...${NC}"
    gh auth login
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to log in to GitHub.${NC}"
        exit 1
    else
        echo -e "${GREEN}Successfully logged in to GitHub.${NC}"
    fi
else
    echo -e "${GREEN}Already logged in to GitHub.${NC}"
fi

# Check if login was successful
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to log in to GitHub.${NC}"
    exit 1
else
    echo -e "${GREEN}Successfully logged in to GitHub.${NC}"
fi
# Prompt the user for confirmation
read -p "Continue (Y/n)? " choice
if [[ "$choice" == "n" || "$choice" == "N" ]]; then
    echo "Exiting script."
    exit 1
fi

# 02. Repository Creation and Initialization
echo -e "${YELLOW}02. New GitHub Repository Creation and Initialization.${NC}"

echo -e "$Current directory (for tempfiles): $(pwd) ${NC}"
echo -e "$Destination directory(for your repo locally): $(destination_dir) ${NC}"

# Remove the existing local folder if it exists
if [ -d "$github_new_repo_name" ]; then
    rm -rf "$github_new_repo_name"
fi

# Check if the repository already exists
repo_exists=$(gh repo view "$GITHUB_NEW_REPO" > /dev/null 2>&1; echo $?)

if [ $repo_exists -ne 0 ]; then
    # Create a new GitHub repository
    echo -e "${YELLOW}Creating a new GitHub repository.${NC}"
    gh repo create "$GITHUB_NEW_REPO" --$github_new_repo_visibility
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create new GitHub repository.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}New GitHub repository already exists.${NC}"
    git remote -v
fi

# Prompt the user for confirmation
#read -p "Continue (Y/n)? " choice
#if [[ "$choice" == "n" || "$choice" == "N" ]]; then
#    echo "Exiting script."
#    exit 1
#fi

# Clone the template repository
echo -e "${YELLOW}Cloning template repository.${NC}"
git clone --bare "$github_template_repo_uri"
cd $github_template_repo_name.git

# Mirror-push to the new repository
git push --mirror "$github_new_repo_uri"
if [[ $? -ne 0 ]]; then
  if [[ "$GITHUB_USE_SSH" == "true" ]]; then
    echo "ERROR: Permission denied to GitHub repo. GITHUB_USE_SSH is true. Please look at this reference:"
    echo "https://docs.github.com/en/get-started/getting-started-with-git/about-remote-repositories#cloning-with-https-urls"
  else
    echo "ERROR: Permission denied to GitHub repo. GITHUB_USE_SSH is false, you are using HTTPS. Please look at this reference:"
    echo "https://docs.github.com/en/get-started/getting-started-with-git/about-remote-repositories#cloning-with-ssh-urls"    
  fi
  exit 1
fi

cd ..
rm -rf $template_project_repo_name.git

# Create dev branch "if not exists"
if ! git ls-remote --exit-code --heads origin dev; then
  # Create the develop branch if it does not exist
  git checkout -b dev
  git push origin dev
else
  echo "Branch 'dev' already exists."
fi

# Set the default branch to develop
gh repo edit $GITHUB_NEW_REPO --default-branch dev

# Setting default branch
echo -e "${YELLOW}Setting default branch in the new repository.${NC}"
gh repo edit $GITHUB_NEW_REPO --default-branch dev

# dev branch protection rule
# NOTE: removed to make it more flexible in the workshop
# gh api \
#   --method PUT \
#   -H "Accept: application/vnd.github+json" \
#   -H "X-GitHub-Api-Version: 2022-11-28" \
#   repos/$GITHUB_NEW_REPO/branches/dev/protection \
#   -F "required_status_checks[strict]=true" \
#   -F "required_status_checks[contexts][]=evaluate-flow" \
#   -F "enforce_admins=true" \
#   -F "required_pull_request_reviews[dismiss_stale_reviews]=false" \
#   -F "required_pull_request_reviews[require_code_owner_reviews]=false" \
#   -F "required_pull_request_reviews[required_approving_review_count]=0" \
#   -F "required_pull_request_reviews[require_last_push_approval]=false" \
#   -F "allow_force_pushes=true" \
#   -F "allow_deletions=true" \
#   -F "block_creations=true" \
#   -F "required_conversation_resolution=true" \
#   -F "lock_branch=false" \
#   -F "allow_fork_syncing=true" \
#   -F "restrictions=null"


echo -e "${YELLOW}Bootstraps config from .env as Github environment variables and secrets. ${NC}"

# Define environments
environments=("dev" "stage" "prod")

# AI Factory globals: variables and secrets
for env in "${environments[@]}"; do
    echo -e "${YELLOW}Setting variables and secrets for environment: $env${NC}"
    
    # Global: Variables
    gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/$env/variables -f name=AIFACTORY_LOCATION -f value="$AIFACTORY_LOCATION"
    gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/$env/variables -f name=AIFACTORY_LOCATION_SHORT -f value="$AIFACTORY_LOCATION_SHORT"
    
    # Global: Secrets
    gh secret set AIFACTORY_SEEDING_KEYVAULT_SUBSCRIPTION_ID --repo $GITHUB_NEW_REPO --env $env --body "$AIFACTORY_SEEDING_KEYVAULT_SUBSCRIPTION_ID"
    
    # Project Specifics (1st project bootstrap): Secrets
    gh secret set PROJECT_MEMBERS --repo $GITHUB_NEW_REPO --env $env --body "$PROJECT_MEMBERS"
    gh secret set PROJECT_MEMBERS_EMAILS --repo $GITHUB_NEW_REPO --env $env --body "$PROJECT_MEMBERS_EMAILS"
    gh secret set PROJECT_MEMBERS_IP_ADDRESS --repo $GITHUB_NEW_REPO --env $env --body "$PROJECT_MEMBERS_IP_ADDRESS"
done

# DEV variables
gh api --method PUT -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/dev
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/dev/variables -f name=AZURE_ENV_NAME -f value="$DEV_NAME"
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/dev/variables -f name=AZURE_LOCATION -f value="$AIFACTORY_LOCATION"
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/dev/variables -f name=GH_CLI_VERSION -f value="$gh_version"

# DEV: Secrets
gh secret set AZURE_SUBSCRIPTION_ID --repo $GITHUB_NEW_REPO --env dev --body "$DEV_SUBSCRIPTION_ID"
gh secret set AZURE_CREDENTIALS --repo $GITHUB_NEW_REPO --env dev --body "replace_with_dev_sp_credencials"

# STAGE variables
gh api --method PUT -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/stage
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/stage/variables -f name=AZURE_ENV_NAME -f value="$STAGE_NAME"
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/stage/variables -f name=AZURE_LOCATION -f value="AIFACTORY_LOCATION"

# STAGE: Secrets
gh secret set AZURE_SUBSCRIPTION_ID --repo $GITHUB_NEW_REPO --env stage --body "$STAGE_SUBSCRIPTION_ID"
gh secret set AZURE_CREDENTIALS --repo $GITHUB_NEW_REPO --env stage --body "replace_with_stage_sp_credencials"

# PROD variables
gh api --method PUT -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/prod
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/prod/variables -f name=AZURE_ENV_NAME -f value="$PROD_NAME"
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/prod/variables -f name=AZURE_LOCATION -f value="AIFACTORY_LOCATION"

# PROD:Secrets 
gh secret set AZURE_SUBSCRIPTION_ID --repo $GITHUB_NEW_REPO --env prod --body "$PROD_SUBSCRIPTION_ID"
gh secret set AZURE_CREDENTIALS --repo $GITHUB_NEW_REPO --env prod --body "replace_with_prod_sp_credencials"

# TODO Future: dev.env / stage.env / prod.env
# gh secret set -f prod.env --env prod

echo -e "${GREEN}New repository created successfully.${NC}"

echo -e "${GREEN}Access your new repo in: \nhttps://github.com/$GITHUB_NEW_REPO ${NC}"

# Clone the new repository
echo -e "${YELLOW}Cloning the new GitHub repository${NC}"
echo -e "${GREEN}Local path: $destination_dir ${NC}"

git clone "$github_new_repo_uri" "$destination_dir"

active_dir=$(pwd)

cd "$destination_dir"

# Init subodule
echo -e "${YELLOW}Running init script 11-init-template-files-once.sh in new repo, to refresh submodule. ${NC}"
git submodule update --init --recursive
git submodule foreach 'git checkout main || git checkout -b main origin/main'
# ./11-init-template-files-once.sh

# Clean GIT history
git checkout --orphan cleaned-history
git add -A
git commit -m "Initial commit with cleaned history"
git branch -D main
git branch -m main
git push -f origin main

#gh api -X PATCH "repos/$GITHUB_USERNAME/$GITHUB_NEW_REPO" -f description="Your repository. Your Enteprise Scale AI Factory."
#gh repo edit https://github.com/jostrm/azure-enterprise-scale-ml-usage-2 --description "Your Enteprise Scale AI Factory.Your repository.Created from the Azure Enterprise Scale ML template."

# Open VS Code
cd "$active_dir"
echo -e "${YELLOW}Now trying to open an new VS Code window with your new repo at $destination_dir....${NC}"
code "$destination_dir"
