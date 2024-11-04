#!/usr/bin/env pwsh

# Set the script to exit on any error
$ErrorActionPreference = 'Stop'

Write-Output "Outputting environment variables to .env file..."
azd env get-values > .env

# Retrieve service names, resource group name, and other values from environment variables
# $resourceGroupName = $env:AZURE_RESOURCE_GROUP
# $searchService = $env:AZURE_SEARCH_NAME
# $openAiService = $env:AZURE_OPENAI_NAME
# $subscriptionId = $env:AZURE_SUBSCRIPTION_ID

$resourceGroupName = 'rg-creative-writer'
$searchService = 'srch-i4vxuuwe4p5ds'
$openAiService = 'aoai-i4vxuuwe4p5ds'
$subscriptionId = '4b38a515-6e51-4263-8404-0fb7646cf176'
$AZURE_SEARCH_ENDPOINT = 'https://srch-i4vxuuwe4p5ds.search.windows.net/'
$WEB_SERVICE_ACA_URI = 'https://agent-web.purplebeach-99b0d6a5.canadaeast.azurecontainerapps.io'

Write-Output "hello1"

# Ensure all required environment variables are set
if ([string]::IsNullOrEmpty($resourceGroupName) -or [string]::IsNullOrEmpty($searchService) -or [string]::IsNullOrEmpty($openAiService) -or [string]::IsNullOrEmpty($subscriptionId)) {
    Write-Host "One or more required environment variables are not set."
    Write-Host "Ensure that AZURE_RESOURCE_GROUP, AZURE_SEARCH_NAME, AZURE_OPENAI_NAME, AZURE_SUBSCRIPTION_ID are set."
    exit 1
}

Write-Output "hello2"

# Set additional environment variables expected by app
# TODO: Standardize these and remove need for setting here
azd env set AZURE_OPENAI_API_VERSION 2023-03-15-preview
azd env set AZURE_OPENAI_CHAT_DEPLOYMENT gpt-35-turbo
azd env set AZURE_SEARCH_ENDPOINT $AZURE_SEARCH_ENDPOINT
azd env set REACT_APP_API_BASE_URL $WEB_SERVICE_ACA_URI

Write-Output "hello3"
# Setup to run notebooks
# Retrieve the internalId of the Cognitive Services account
$INTERNAL_ID = az cognitiveservices account show `
    --name $openAiService `
    --resource-group $resourceGroupName `
    --query "properties.internalId" -o tsv

# Construct the URL
$COGNITIVE_SERVICE_URL = "https://oai.azure.com/portal/$INTERNAL_ID?tenantid=$env:AZURE_TENANT_ID"

Write-Host "--- ✅ | 1. Post-provisioning - env configured ---"

# Setup to run notebooks
Write-Host 'Installing dependencies from "requirements.txt"'
python -m pip install -r src/api/requirements.txt > $null
python -m pip install ipython ipykernel > $null      # Install ipython and ipykernel
ipython kernel install --name=python3 --user > $null # Configure the IPython kernel
jupyter kernelspec list > $null                      # Verify kernelspec list isn't empty
Write-Host "--- ✅ | 2. Post-provisioning - ready to execute notebooks ---"

# Populate data
Write-Host "Populating data ...."
jupyter nbconvert --execute --to python --ExecutePreprocessor.timeout=-1 data/create-azure-search.ipynb > $null

Write-Host "--- ✅ | 3. Post-provisioning - populated data ---"