[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [String]
    $String1,

    [Parameter(Mandatory = $true)]
    [String]
    $String2
)

Describe 'String Checks' -Tags StringIntegrity {
    Context 'String checks context' {
        It 'String 1 and String 2 should be different' {
            $String1 | Should -Not -Be $String2
        }

        It 'String 1 should be smaller in length  than String 2' {
            $String1.Length | Should -BeLessThan $String2.Length 
        }
    }
}
