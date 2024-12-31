# Enterprise Scale AI Factory - GH template

Welcome to the Enterprise Scale AIFactory solution acceleratpor! This project provides a ready-to-run github repo, bootstrapped and connected to the AI Factory Github submodule. 
- This repo connected to the AI Factory submodule and leverages resources/templates from the ESML AI Factory submodule. 
- This repo is where you defined your variables, and where copies of templates are located for your code to customize the AIFactory project types.
 
## Highlights

- Bootstrap your project in under an hour, including enterprise grade security
- Enteprise grade security and networking (private link).
- Provision resources with IaC (BICEP)
- Automate IaC with (Github Actions or Azure Devops)
- Easy-to-configure and extend templates: DataOps, MLOps, GenAIOps
- AI Factory project types
    - ESGenAI: GenAI: Azure AI Foundry with RAG using Azure AI Search
        - Enterprise secrurity: 
            A) Networking: Either fully private mode (private link for also the Azure AI Studio) or private link with AI Studio accessible from certain IP
            B) Role-based access control, EntraID for all sercice-to-servcice and user-to-service connections. 
                - E.g. not using any keys (since global keys have full permission to services, it is not recommended)
    - ESML: DataOps and MLOps with notebooks templates - both Databricks (Pyspark) and Jupyter notebooks(Python). Mix compute & tech, while using same MLOps pipeline

## How-to

1. [Bootstrapping a new AIFactory](documentation/bootstrapping.md)
2. [Bootstrapping a new AIFactory project (Type: ESGenAI or ESML)](documentation/bootstrapping.md)
3. [Delivering a new Feature: CI/CD with MLOps or GenAIOps](documentation/delivering_new_feature.md)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
