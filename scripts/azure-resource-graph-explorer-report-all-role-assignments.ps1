<#
The script will generate a csv file with all role assignments on Azure resources and resource containers.
The script also attempts to find display name and type for each principalId
Output is limited to 1000 assignments



Dependencies:
Azure PowerShell
Az.ResourceGraph Module
AzureAD Module

Reader access to Tenant Root Group
Active authenticated Azure Powershell session (Connect-AzAccount) and
Active authenticated Azure AD (Entra ID) session (Connect-AzureAD)

Helpful links:
https://learn.microsoft.com/en-us/powershell/azure/install-azps-windows?view=azps-12.0.0&tabs=powershell&pivots=windows-psgallery
https://learn.microsoft.com/en-us/azure/governance/resource-graph/first-query-powershell

#>

$queryText=@'
authorizationresources
| where type =~ 'microsoft.authorization/roleassignments'
| extend roleDefinitionId= tolower(tostring(properties.roleDefinitionId))
| extend principalType = properties.principalType
| extend principalId = properties.principalId
| extend scope = properties.scope
| where properties.createdBy != ""
| join kind = inner (
authorizationresources
| where type =~ 'microsoft.authorization/roledefinitions'
| extend roleDefinitionId = tolower(id), roleName = tostring(properties.roleName)
//| where properties.type =~ 'BuiltInRole'
| project roleDefinitionId,roleName
) on roleDefinitionId
| project principalId,roleName,roleDefinitionId, scope
| extend subscriptionId = iff(indexof(scope,'/subscriptions/')>=0,tostring(substring(scope,indexof(scope,'/subscriptions')+strlen('/subscriptions')+1,36)),tostring(''))
| join kind=leftouter (ResourceContainers 
    | where type == 'microsoft.resources/subscriptions' 
    | project SubscriptionName=name, subscriptionId
) on subscriptionId
| project principalId,roleName,roleDefinitionId, scope, subscriptionId, SubscriptionName
'@


$roleAssignments=Search-AzGraph -Query $queryText -First 1000 -UseTenantScope

$queueTable = New-Object System.Data.DataTable
$queueTable.Columns.Add("PrincipalDisplayName",[string]) | Out-Null
$queueTable.Columns.Add("Type",[string]) | Out-Null
$queueTable.Columns.Add("RoleName",[string]) | Out-Null
$queueTable.Columns.Add("SubscriptionName",[string]) | Out-Null
$queueTable.Columns.Add("Scope",[string]) | Out-Null
$queueTable.Columns.Add("RoleDefinitionId",[string]) | Out-Null
$queueTable.Columns.Add("SubscriptionId",[string]) | Out-Null
$queueTable.Columns.Add("PrincipalId",[string]) | Out-Null

ForEach ($roleAssignment in $roleAssignments) { 
	$principal = Get-AzureADObjectByObjectId -ObjectId $roleAssignment.principalId
	$queueTable.Rows.Add($principal.DisplayName,$principal.ObjectType,$roleAssignment.roleName, $roleAssignment.subscriptionName, $roleAssignment.scope, $roleAssignment.roleDefinitionId, $roleAssignment.subscriptionId, $roleAssignment.principalId)  | Out-Null 
}

$queueTable | Export-Csv -path .\azure-role-assignments-report.csv -NoTypeInformation
