# Azure Terraform Assignment
## Objective
Design and implement the infrastructure required to deploy a secure, scalable web application on Azure using Infrastructure as Code (IaC). The deployment should follow cloud architecture best practices in terms of scalability, availability, security, and cost-effectiveness.

## Scenario
You’ve been hired by a mid-sized e-commerce company to help them move their new customer-facing web application to Azure. The application is a stateless Node.js (or .NET/Java) API that serves a single-page application (SPA) frontend hosted separately.

They want to run the backend on Azure with the following requirements:

## Requirements
1. Core Infrastructure
Provision infrastructure using Terraform.

Deploy a web application backend on Azure App Service (Linux or Windows, your choice).

Use Azure Application Gateway as an entry point with SSL termination.

2. Networking & Security
All application traffic must be routed through the selected gateway.

Only the gateway should be able to communicate with the backend directly (no public access).

Protect all resources using NSGs, private endpoints, or service endpoints.

Use managed identities and Key Vault to store secrets or connection strings securely.

3. Database
Provision an Azure SQL Database.

The database should not be publicly accessible.

4. CI/CD
Create a basic CI/CD pipeline definition (e.g., GitHub Actions, Azure DevOps, etc.) for deploying the infrastructure.

Code should be clean and modular to support iterative development and automation.

## Deliverables
1. Infrastructure Code: Well-structured IaC code that provisions all required resources.

2. Architecture Diagram: Simple diagram (can be hand-drawn or diagramming tool) showing the overall solution.

3. README:

    - Description of the setup

    - Steps to deploy

    - Any assumptions or constraints

4. CI/CD File: A pipeline configuration file for provisioning infra (not the app itself).