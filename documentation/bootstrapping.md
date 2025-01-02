# Bootstrapping a new AIFactory and an AI Project

## Prerequisites

* [BICEP (.bicep)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) - to create (IaC) Azure resources
* [Powershell (.ps1)](https://aka.ms/install-powershell) - to orchestrate creation (IaC) of Azure resources
* [Azure CLI (az)](https://aka.ms/install-az) - to manage Azure resources
* [GitHub CLI (gh)](https://cli.github.com/) - to create GitHub repo.
* [Git](https://git-scm.com/downloads) - to update repository contents.

You will also need:
* [Azure Subscription](https://azure.microsoft.com/free/) - sign up for a free account.
* [GitHub Account](https://github.com/signup) - sign up for a free account.
* Permissions to create a Service Principal (SP) in your Azure AD Tenant.
* Permissions to assign the Owner role to the SP within the subscription.

## Steps to Bootstrap a Project

1. **Run `start-init-once.sh`**
This will add the submodule to your repo. 
Then it will copy templates and files from the *Enterprise Scale AIFactory* submodule.
At the end of its execution, the script will have created and initialized files and templates under a root folder called `aifactory` locally in your repo. You will end up with 2 folders in the repository with new files:
 - **submodule**: will appear as a folder called `azure-enterprise-scale-ml` in your Github repo at root
 - **templates**: will appear as a folder called `aifactory` in your Github repo at root

2. **Create a Service Principal**

   Create a service principal using the following command:

   ```sh
   az ad sp create-for-rbac --name "<your-service-principal-name>" --role Owner --scopes /subscriptions/<your-subscription-id> --sdk-auth
   ```

   > Ensure that the output information (Application ID,Object Id, Secret) created, is properly saved for future use. 
   >
   > Recommendation: Store it in a Azure Keyvault as secrets.
     ```sh
        aifactory-common-sp-id="qwerty-asdf-asd1123dfsdf-asdf123ds" // clientId or appId
        aifactory-common-sp-oid="asdf-asdf-asd1123dfsdf-asdf123ds" // ObjectId of service principal (not application itself)
        aifactory-common-sp-secret="afsdASDF!@asdf123"
        tenant-id="123as-df1231q-dsadar-123qe133"
     ```

2. **Define Properties for Bootstrapping**

    In your root directory.
   Create a copy of the `.env.template` file with this filename `.env`

    ```sh
    cp .env.template .env
    ```

    Open the `.env` with a text editor and update it with the following information:

    - **GitHub Repo** (related to the new repository to be created)
        - `github_your_repo`: The current repo, your bootstrapped project repo. Ex *placerda/my-rag-project*.
            - "<your_github_user_or_organization_id>/<new-repo-name>"
    - **AIFactory Global variables** (Per AIFactory)
        - `aifactory_location`: The Azure region for your environments. Ex: *eastus2*.
    - **AIFactory: Dev, Stage, Prod** (Per environment)
        - `dev_subscription_id`: Your Azure subscription ID for Dev environment
        - `stage_subscription_id`: Your Azure subscription ID for Stage environment
        - `prod_subscription_id`: Your Azure subscription ID for Prod environment
    - **AIFactory Project specific variables** (Per AIFactory project)
        - `project_type`="esgenai" # esml, esgenai
        - `project_number`="001" # unique number per aifactory
        - `project_members`="objectId1,objectId2,objectId3" # ObjectID in a commas separated list, without space
        - `project_service_principal_appid`="appId" # AppId of the service principal
        - `project_service_principal_oid`="ObjectID123" # ObjectID of the service principal

   Here is an example of the `.env` file (note that you can use the same subscription for all environments)

   ```python
    # Github info
    GITHUB_USERNAME="jostrm"
    GITHUB_USE_SSH="false"
    GITHUB_TEMPLATE_REPO="jostrm/azure-enterprise-scale-ml-usage" # "<template_github_user_or_organization_id>/<template-repo-name>"
    GITHUB_NEW_REPO="<your_github_user_or_organization_id>/<new-repo-name>" # "<your_github_user_or_organization_id>/<new-repo-name>"
    GITHUB_NEW_REPO_VISIBILITY="public" # public, private, internal

    # AI Factory - Globals
    AIFACTORY_LOCATION="eastus2"
    AIFACTORY_COMMON_ONLY_DEV_ENVIRONMENT="true" # true only Dev will be created. false - it will create Dev, Stage, Prod environments in Azure

    # AI Factory - Environments: Dev, Stage, Prod
    DEV_NAME="dev"
    STAGE_NAME="test" # Note: Can be anything, but choose `test` to align with ESML
    PROD_NAME="prod"
    DEV_SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789098"
    STAGE_SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789098"
    PROD_SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789098"

    # AI Factory - Projects
    PROJECT_TYPE="esgenai" # esml, esgenai
    PROJECT_NUMBER="001" # unique number per aifactory
    PROJECT_MEMBERS="objectId1,objectId2,objectId3" # ObjectID in a commas separated list, without space
    PROJECT_MEMBERS_IP_ADDRESS="90.12.3.1,192.12.3.1,192.12.3.1" # IP adresses in a commas separated list, without space, to whitelist to UI in Azure
    PROJECT_SERVICE_PRINCIPAL_APPID="appId" # AppId of the service principal
    PROJECT_SERVICE_PRINCIPAL_OID="ObjectID123" # ObjectID of the service principal

    # AI Factory - Projects:Security
    NETWORKING_GENAI_PRIVATE_PRIVATE_UI="true" # false, the UI in AI Studio will be publicly accessible for specific IP addresses via IPRules (service endpoints)
   ```

3. **Authenticate with Azure and GitHub**
You need to login via `Azure CLI` and `Github CLI`, but recommendation is to also test login via `Powershell`. 
    - NB! Recommendation is to use a service principal when logging in. Not your user id.
    - The Service Principal should have OWNER permission to all 3 subscriptions (Dev, Test, Prod)
    - Test the login for all 3 subscriptions using `az cli` and `powershell` as below: 

   a) Log in to Azure CLI with your user ID, to a specific tenant

   ```sh
   az login --tenant $tenantId
   ```

   b) Log in to Azure CLI with a service princiapl, to a specific tenant

   ```sh
    # Define the variables
    clientId="your-client-id"
    clientSecret="your-client-secret"
    tenantId="your-tenant-id"
    subscriptionId="your-subscription-id"
    
    az login --service-principal -u $clientId -p $clientSecret --tenant $tenantId
    az account set --subscription $subscriptionId
   ```

   c) Log in to Azure Powershell to a specific Subscription

    ```powershell
    # Define the service principal credentials
    $tenantId = "your-tenant-id"
    $clientId = "your-client-id"
    $clientSecret = "your-client-secret"

    # Log in using the service principal
    $securePassword = ConvertTo-SecureString $clientSecret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($clientId, $securePassword)
    Connect-AzAccount -ServicePrincipal -TenantId $tenantId -Credential $credential

    # Set the subscription context
    $context = Get-AzSubscription -SubscriptionId "asdf1234-234b-33a4-b356-qwerty1234"
    Set-AzContext $context
    ```
   
   d) Log in to GitHub CLI:

   ```sh
    gh auth login -u your-github-username
   ```
    
4. **Run the Bootstrap Script**

   The bootstrap script is available in root folder (`bootstrap.sh`). 
   It will also read environment variables from .env locally and copy them to the Github Repo environment, using the [GitHub CLI (gh)](https://cli.github.com/) 

   **For Bash:**

   ```sh
   ./bootstrap.sh
   ```

    At the end of its execution, the script will have created Azure resources and 1 AIFactory project, of type ESGenAI (which is the default type)


6. **Set GitHub Environment Variables**

   a) Go to the Github repository and validate the following GitHub environment variables for three environments: `DEV`, `STAGE`, and `PRODUCTION`.
   
   - **Environment Variables:**
     - `AZURE_ENV_NAME`
     - `AZURE_LOCATION`
     - `AZURE_SUBSCRIPTION_ID`
   
   b) You need to manually set the credentiials including secret for three environments: `DEV`, `STAGE`, and `PRODUCTION`. Note: 
   
   - **Secret:**
     - `AZURE_CREDENTIALS`

   The `AZURE_CREDENTIALS` secret should be formatted as follows:
    
   ```json
   {
       "clientId": "your-client-id-aka-appId",
       "clientSecret": "your-client-secret-aka-servicPrincipalSecret",
       "subscriptionId": "your-subscription-id",
       "tenantId": "your-tenant-id"
   }
   ```

   > **Note:** If you are only interested in experimenting with this accelerator, you can use the same subscription, varying only `AZURE_ENV_NAME` for each enviornment, and use the same service principal for all three environments. 
   > **Note:**  You can choose to have three different service principals, one per environment, but then you need to set the OWNER permissions on the respective service principal

7. **Enable GitHub Actions**

   Ensure that GitHub Actions are enabled in your repository, as in some cases, organizational policies may not have this feature enabled by default. To do this, simply click the button indicated in the figure below:

DONE!