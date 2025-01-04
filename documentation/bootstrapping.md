# Bootstrapping a new AIFactory and an AI Project

## Prerequisites

* [Azure CLI (az)](https://aka.ms/install-az) - to manage Azure resources
* [GitHub CLI (gh) version >=2.64.0](https://cli.github.com/) - to create GitHub repo and create environment variables and secrets
    - Install: Git for Windows (Git Bash terminal in VS Cide) with CLI 2.64.0 https://git-scm.com/downloads/win

### Nice to have (Prerequisites if you want to DEBUG)
* [BICEP (.bicep)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) - to create (IaC) Azure resources
* [Powershell (.ps1)](https://aka.ms/install-powershell) - to orchestrate creation (IaC) of Azure resources

### You will also need:
* [Azure Subscription](https://azure.microsoft.com/free/) - sign up for a free account.
* Permissions to create a Service Principal (SP) in your Azure AD Tenant.
* Permissions to assign the Owner role to the SP within the subscription.
* [GitHub Account](https://github.com/signup) - sign up for a free account.

## BOOTSTRAP Option A) Bring-Your-Own-Repo

1. **Run `11-init-template-files-once.sh`**
This will add the submodule to your repo. 
Then it will copy templates and files from the *Enterprise Scale AIFactory* submodule.
At the end of its execution, the script will have created and initialized files and templates under a root folder called `aifactory` locally in your repo. You will end up with 2 folders in the repository with new files:
 - **submodule**: will appear as a folder called `azure-enterprise-scale-ml` in your Github repo at root
 - **templates**: will appear as a folder called `aifactory` in your Github repo at root

2. **Run `12-add-aifactory-pipelines-once.sh`**
This will copy the templates for Github Actions, into your repo's .github/workflows/github-actions. <br>
Note that it will first delete the folder `.github/workflows` if exists.

3. **Create a Service Principal**

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

4. **Define Properties for Bootstrapping**

    In your root directory.
   Create a copy of the `.env.template` file with this filename `.env`

    ```sh
    cp .env.template .env
    ```

    Open the `.env` with a text editor and update the variables:

    Here is an example of the `.env` file (note that you can use the same subscription for all environments)

   ```python
   # Github info
    GITHUB_USERNAME="jostrm"
    GITHUB_USE_SSH="false"
    GITHUB_TEMPLATE_REPO="jostrm/azure-enterprise-scale-ml-usage"
    GITHUB_NEW_REPO="jostrm/azure-enterprise-scale-ml-usage-2" # "<your_github_user_or_organization_id>/<new-repo-name>"
    GITHUB_NEW_REPO_VISIBILITY="public" # public, private, internal

    # AI Factory - Globals
    AIFACTORY_LOCATION="swedencentral"
    AIFACTORY_LOCATION_SHORT="sdc"
    USE_COMMON_ACR_FOR_PROJECTS="true" # true, all projects will use the same Azure Container Registry, false, each project will have its own ACR (more expensive)
    AIFACTORY_COMMON_ONLY_DEV_ENVIRONMENT="true" # true only Common-Dev will be created. false - it will create Dev, Stage, Prod environments in Azure
    AIFACTORY_SEEDING_KEYVAULT_SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789098" # [GH-Secret]

    # AI Factory - Environments: Dev, Stage, Prod
    DEV_NAME="dev"
    STAGE_NAME="test"
    PROD_NAME="prod"
    DEV_SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789098" # [GH-Secret]
    STAGE_SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789098" # [GH-Secret]
    PROD_SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789098" # [GH-Secret]

    # AI Factory - Projects (ESML, ESGenAI, ESAgentic)
    PROJECT_TYPE="genai-1" # esml, genai-1,genai-2
    PROJECT_NUMBER="001" # unique number per aifactory
    PROJECT_MEMBERS="objectId1,objectId2,objectId3" #[GH-Secret] ObjectID in a commas separated list, without space
    PROJECT_MEMBERS_EMAILS="email1,email2, email3" #[GH-Secret] Email adresses in a commas separated list, mapping to above ObjectID list
    PROJECT_MEMBERS_IP_ADDRESS="192.x.x.x,90.x.x.x" # [GH-Secret] IP adresses in a commas separated list, without space, to whitelist to acccess UI in Azure

    # AI Factory - Projects:Security
    NETWORKING_GENAI_PRIVATE_PRIVATE_UI="true" # false, UI will be publicly accessible for PROJECT_MEMBERS_IP_ADDRESS via IPRules (service endpoints)
   ```

5. **Authenticate with Azure and GitHub**
You need to login via `Azure CLI` and `Github CLI`, but recommendation is to also test login via `Powershell`. 
    - NB! Recommendation is to use a service principal when logging in. Not your user id.
    - The Service Principal should have OWNER permission to all 3 subscriptions (Dev, Test, Prod)
    - Test the login for all 3 subscriptions using `az cli` and `powershell` as below: 

   a) Log in to Azure CLI with your user ID, to a specific tenant

   ```sh
   az login --tenant $tenantId
   ```

   b) Log in to Azure CLI with a service principal, to a specific tenant

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
    gh auth login
   ```


6. **Verify/Edit the GitHub Environment Variables/Secrets**

   a) Go to the Github repository and validate the following GitHub environment variables for three environments: `DEV`, `STAGE`, and `PRODUCTION`.
   
   - **Secrets - all environments:**
    - `AIFACTORY_SEEDING_KEYVAULT_SUBSCRIPTION_ID`
    - `PROJECT_MEMBERS`
    - `PROJECT_MEMBERS_EMAILS`
    - `PROJECT_MEMBERS_IP_ADDRESS`
    - `AIFACTORY_SEEDING_KEYVAULT_SUBSCRIPTION_ID`
   - **Variables - all environments**
    - `AIFACTORY_LOCATION`
    - `AIFACTORY_LOCATION_SHORT`
  
   - **Secrets - per environment**
    - `AZURE_SUBSCRIPTION_ID`
    - `AZURE_CREDENTIALS`  -> Needs to be set
   
   - **Variables - per environment:**
    - `AZURE_SUBSCRIPTION_ID`
    - `AZURE_ENV_NAME`

> [!IMPORTANT]
> You need to manually set the `AZURE_CREDENTIALS` including secret for three environments: `DEV`, `STAGE`, and `PRODUCTION`. Note: 
>

   The `AZURE_CREDENTIALS` secret should be formatted as follows:
    
   ```json
   {
       "clientId": "your-client-id-aka-appId",
       "clientSecret": "your-client-secret-aka-servicPrincipalSecret",
       "subscriptionId": "your-subscription-id",
       "tenantId": "your-tenant-id"
   }
   ```

   > **Note:** If you are only interested in experimenting with this accelerator, you can use the same subscription, varying only `AZURE_ENV_NAME` for each environment, and use the same service principal for all three environments.<br>
   > - In production we recommend to have three different service principals, one per environment. And set the OWNER permissions on the respective service principal to each Azure subscription.

7. **Run GitHub Actions**

    > [!NOTE]
    > Ensure that GitHub Actions are enabled in your repository, as in some cases, organizational policies may not have this feature enabled by default. To do 
    > this, simply click the button indicated in the figure below. 
   
    Run [13-setup-infra-aifactory.sh](../13-setup-infra-aifactory.sh)
    
    - This will execute a Github Action workflow, that sets up Azure infrastructure, for only the DEV environment in this case.
    - It will also setup the first project of type `esgenai-1` - containing Azure services for RAG such as Azure OpenAI, Azure AI Foundry, Azure AI Search.
    - It will also create all networking, private endpoints, role-based-access control for the services to be able to talk to each other, and for the `PROJECT_MEMBERS` to be able to access the Azure services.
  
   **For Bash:**

   ```sh
   ./13-setup-infra-aifactory.sh
   ```
    > **Note:** If you also want to setup the infrastructure for STAGE and PROD environemnt, simpy edit the variable in the script called `dev_stage_prod=dev` to `stage` or `prod` and re-run the script.

## BOOTSTRAP Option B) Mirror-repo
Step 1,2 is not nessesary here. 
But make sure you have done step 3,4,5,6,7 mentioned in section [## BOOTSTRAP Option A) Bring-Your-Own-Repo](#bootstrap-option-a-bring-your-own-repo)

1. **Bootstrap (mirror-repo) - Run the Scripts**
Make sure you have edited the env. file 

    Run [10-mirror-gh-repo-from-template-once.sh](../10-mirror-gh-repo-from-template-once.sh)
  
   **For Bash:**

   ```sh
   ./10-mirror-gh-repo-from-template-once.sh
   ```

    This bootstrap script will create a mirror-repo, your own repo, and open VS Code to the local representation, and provide a link to your Github repo
    At the end of its execution, the script will have created Azure resources and 1 AIFactory project, of type ESGenAI (which is the default type)

DONE!