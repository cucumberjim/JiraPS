function Get-JiraIssueCreateMetadata {
    # .ExternalHelp ..\JiraPS-help.xml
    [CmdletBinding()]
    param(
        [Parameter( Mandatory )]
        [String]
        $Project,

        [Parameter( Mandatory )]
        [String]
        $IssueType,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Function started"

        $server = Get-JiraConfigServer -ErrorAction Stop

    }

    process {
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] ParameterSetName: $($PsCmdlet.ParameterSetName)"
        Write-DebugMessage "[$($MyInvocation.MyCommand.Name)] PSBoundParameters: $($PSBoundParameters | Out-String)"

        $projectObj = Get-JiraProject -Project $Project -Credential $Credential -ErrorAction Stop
        $issueTypeObj = $projectObj.IssueTypes | Where-Object -FilterScript {$_.Id -eq $IssueType -or $_.Name -eq $IssueType}

        if ($null -eq $issueTypeObj.Id)
        {
            $errorMessage = @{
                Category         = "InvalidResult"
                CategoryActivity = "Validating parameters"
                Message          = "No issue types were found in the project [$Project] for the given issue type [$IssueType]. Use Get-JiraIssueType for more details."
            }
            Write-Error @errorMessage
        }

        $resourceURi = "$server/rest/api/2/issue/createmeta?projectIds=$($projectObj.Id)&issuetypeIds=$($issueTypeObj.Id)&expand=projects.issuetypes.fields"

        $parameter = @{
            URI        = $resourceURi -f $projectObj.Id, $issueTypeObj.Id
            Method     = "GET"
            Credential = $Credential
            ErrorAction = 'Stop'
        }
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Invoking JiraMethod with `$parameter"

        try {
            $rawResult = Invoke-JiraMethod @parameter
        }
        catch {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Trying the old API URI."
            $resourceURi = "$server/rest/api/2/issue/createmeta/$($projectObj.Id)/issuetypes/$($issueTypeObj.Id)"
            $parameter.URI = $resourceURi
            $rawResult = Invoke-JiraMethod @parameter
        }

        Write-Debug "[$($MyInvocation.MyCommand.Name)]`r`n$($rawResult)"
        $result = $rawResult.values
        Write-Debug "[$($MyInvocation.MyCommand.Name)]`r`n$($result)"

        if ($result) {
            if ($result.Count -eq 0) {
                $errorMessage = @{
                    Category         = "InvalidResult"
                    CategoryActivity = "Validating response"
                    Message          = "No fields were found for the given project [$($Project)] and issuetype [$($IssueType)]. Use Get-JiraProject for more details."
                }
                Write-Error @errorMessage
            }

            Write-Output (ConvertTo-JiraCreateMetaField -InputObject $result)
        }
        else {
            $exception = ([System.ArgumentException]"No results")
            $errorId = 'IssueMetadata.ObjectNotFound'
            $errorCategory = 'ObjectNotFound'
            $errorTarget = $Project
            $errorItem = New-Object -TypeName System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $errorTarget
            $errorItem.ErrorDetails = "No metadata found for project $Project and issueType $IssueType."
            Throw $errorItem
        }
    }

    end {
        Write-Verbose "[$($MyInvocation.MyCommand.Name)] Complete"
    }
}
