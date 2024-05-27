$results = @()
$resHashTable =@{}

$spLookup = @{}

foreach($subscription in (Get-AzSubscription -WarningAction SilentlyContinue)) {

    foreach($policy in (Get-AzPolicyDefinition -Custom -SubscriptionId $subscription.Id | `
    Select-Object -Property * -ExcludeProperty properties -ExpandProperty properties | `
    Select-Object -Property * -ExcludeProperty metadata -ExpandProperty metadata | `
    Select-Object -Property DisplayName, PolicyType, PolicyDefinitionId, createdBy)) {
        $ht2 = @{}
        $policy.psobject.properties | Foreach { $ht2[$_.Name] = $_.Value }
        $principalId = $ht2["createdBy"]
        if ($spLookup.ContainsKey($principalId)) {
            $ht2["createdBy"] = $spLookup[$principalId]
        } else {
            $createdByDisplayNameUser = $(az ad user show --id $policy.createdBy 2>$null | ConvertFrom-Json | Select-Object -Property displayName)
            $createdByDisplayNameSP = $(az ad sp show --id $policy.createdBy 2>$null | ConvertFrom-Json | Select-Object -Property displayName) 
            if ($null -ne $createdByDisplayNameUser) {
                $createdByDisplayNameUser.displayName 
                $ht2["createdBy"] = $createdByDisplayNameUser.displayName 
            } else { 
                if ($null -ne $createdByDisplayNameSP) {
                    $createdByDisplayNameSP
                    $ht2["createdBy"] = $createdByDisplayNameSP.displayName
                }
            }
            $spLookup.Add($principalId,$ht2["createdBy"])
        }
            $resHashTable[$policy.PolicyDefinitionId]=$ht2
    }   

}

foreach ($h in $resHashTable.GetEnumerator()) {
    $results +=$h.Value
}

$results | ConvertTo-Csv