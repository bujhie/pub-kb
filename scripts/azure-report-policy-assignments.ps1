$results = @()
$resHashTable =@{}

foreach($subscription in (Get-AzSubscription -WarningAction SilentlyContinue)) {

    foreach($assignment in (Get-AzPolicyAssignment -Scope "/subscriptions/$subscription" `
        | Select-Object -Property * -ExcludeProperty properties -ExpandProperty properties  `
        | Select-Object -Property * -ExcludeProperty metadata -ExpandProperty metadata `
        | Select-Object -Property DisplayName, Scope, PolicyDefinitionId, EnforcementMode, assignedBy, updatedBy, PolicyAssignmentId)) {
            $resHashTable[$assignment.PolicyAssignmentId]=$assignment
        }   

}

foreach ($h in $resHashTable.GetEnumerator()) {
    $results +=$h.Value
}

$results | ConvertTo-Csv