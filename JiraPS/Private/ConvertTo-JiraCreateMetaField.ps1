function ConvertTo-JiraCreateMetaField {
    [CmdletBinding()]
    param(
        [Parameter( ValueFromPipeline )]
        [PSObject[]]
        $InputObject
    )

    process {
        Write-Debug "[$($MyInvocation.MyCommand.Name)] Converting `$InputObject to custom object"
        foreach ($field in $InputObject) {
            Write-Debug "[$($MyInvocation.MyCommand.Name)] Processing $($field.name)"

            $props = @{
                'Id'              = $field.fieldId
                'Name'            = $field.name
                'HasDefaultValue' = [System.Convert]::ToBoolean($field.hasDefaultValue)
                'Required'        = [System.Convert]::ToBoolean($field.required)
                'Schema'          = $field.schema
                'Operations'      = $field.operations
            }

            if ($field.allowedValues) {
                $props.AllowedValues = $field.allowedValues
            }

            if ($field.autoCompleteUrl) {
                $props.AutoCompleteUrl = $field.autoCompleteUrl
            }

            foreach ($extraProperty in (Get-Member -InputObject $field -MemberType NoteProperty).Name) {
                if ($null -eq $props.$extraProperty) {
                    $props.$extraProperty = $field.$extraProperty
                }
            }

            $result = New-Object -TypeName PSObject -Property $props
            $result.PSObject.TypeNames.Insert(0, 'JiraPS.CreateMetaField')
            $result | Add-Member -MemberType ScriptMethod -Name "ToString" -Force -Value {
                Write-Output "$($this.Name)"
            }

            Write-Output $result
        }
    }
}
