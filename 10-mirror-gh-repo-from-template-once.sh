#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 01. Setup and Preparation
echo -e "${YELLOW}01. Copy environment variables locally to Github environments${NC}"

# Read the variables from the .env file
if [ -f ../.env ]; then
    export $(grep -v '^#' ../.env | xargs)
    if [ -z "$GITHUB_USERNAME" ]; then
        echo -e "${RED}Failed to read the first variable,GITHUB_USERNAME, from .env.${NC}"
        exit 1
    fi
else
    echo -e "${RED}.env file does not exist.${NC}"
    exit 1
fi

github_your_repo_uri="https://github.com/${GITHUB_NEW_REPO}.git"

echo -e "\e[36mAZD Dev name:\e[0m $DEV_NAME"
echo -e "\e[36mGitHub New Repo URI:\e[0m $github_your_repo_uri"

gh api --method PUT -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/dev
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/dev/variables -f name=AZURE_ENV_NAME -f value="$DEV_NAME"
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/dev/variables -f name=AZURE_SUBSCRIPTION_ID -f value="$DEV_SUBSCRIPTION_ID"
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/dev/variables -f name=AZURE_LOCATION -f value="$AIFACTORY_LOCATION"
gh secret set AZURE_CREDENTIALS --repo $GITHUB_NEW_REPO --env dev --body "replace_with_dev_sp_credencials"

echo -e "${GREEN}02. Success!${NC}"

# Define the temporary directory within the current directory
current_dir=$(pwd)
temp_dir="$current_dir/temp"

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

echo -e "\e[33mBootstraping Parameters\e[0m"
echo -e "\e[36mGitHub Username:\e[0m $github_username"
echo -e "\e[36mGitHub Use SSH:\e[0m $github_use_ssh"
echo -e "\e[36mGitHub Template Repo:\e[0m $GITHUB_TEMPLATE_REPO"
echo -e "\e[36mGitHub Template Repo name:\e[0m $github_template_repo_name"
echo -e "\e[36mGitHub Template Repo URI:\e[0m $github_template_repo_uri"
echo -e "\e[36mGitHub New Repo:\e[0m $GITHUB_NEW_REPO"
echo -e "\e[36mGitHub New Repo name:\e[0m $github_new_repo_name"
echo -e "\e[36mGitHub New Repo URI:\e[0m $github_new_repo_uri"
echo -e "\e[36mGitHub New Repo Visibility:\e[0m $GITHUB_NEW_REPO_VISIBILITY"

# 02. Repository Creation and Initialization
echo -e "${YELLOW}02. New GitHub Repository Creation and Initialization.${NC}"

# Remove the existing local folder if it exists
if [ -d "$new_project_repo" ]; then
    rm -rf "$new_project_repo"
fi

# Check if the repository already exists
repo_exists=$(gh repo view "$GITHUB_NEW_REPO" > /dev/null 2>&1; echo $?)

if [ $repo_exists -ne 0 ]; then
    # Create a new GitHub repository
    echo -e "${YELLOW}Creating a new GitHub repository.${NC}"
    gh repo create "$GITHUB_NEW_REPO" --$GITHUB_NEW_REPO_VISIBILITY
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to create new GitHub repository.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}New GitHub repository already exists.${NC}"
fi

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

# Create GitHub environment named DEV with specified variables
gh api --method PUT -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/dev
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/dev/variables -f name=AZURE_ENV_NAME -f value="$dev_name"
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/dev/variables -f name=AZURE_SUBSCRIPTION_ID -f value="$dev_subscription_id"
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/dev/variables -f name=AZURE_LOCATION -f value="$aifactory_location"
gh secret set AZURE_CREDENTIALS --repo $GITHUB_NEW_REPO --env dev --body "replace_with_dev_sp_credencials"

# Create placeholders for GitHub environment STAGE variables
gh api --method PUT -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/stage
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/stage/variables -f name=AZURE_ENV_NAME -f value="stage_name"
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/stage/variables -f name=AZURE_SUBSCRIPTION_ID -f value="stage_subscription_id"
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/stage/variables -f name=AZURE_LOCATION -f value="aifactory_location"
gh secret set AZURE_CREDENTIALS --repo $GITHUB_NEW_REPO --env qa --body "replace_with_stage_sp_credencials"

# Create placeholders for GitHub environment PROD variables
gh api --method PUT -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/prod
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/prod/variables -f name=AZURE_ENV_NAME -f value="prod_name"
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/prod/variables -f name=AZURE_SUBSCRIPTION_ID -f value="prod_subscription_id"
gh api --method POST -H "Accept: application/vnd.github+json" repos/$GITHUB_NEW_REPO/environments/prod/variables -f name=AZURE_LOCATION -f value="aifactory_location"
gh secret set AZURE_CREDENTIALS --repo $GITHUB_NEW_REPO --env prod --body "replace_with_prod_sp_credencials"

echo -e "${GREEN}New repository created successfully.${NC}"

echo -e "${GREEN}Access your new repo in: \nhttps://github.com/$GITHUB_NEW_REPO ${NC}"

# Clone the new repository
echo -e "${YELLOW}Cloning the new GitHub repository${NC}"
git clone "$github_new_repo_uri"
#cd "$github_new_repo_name" 