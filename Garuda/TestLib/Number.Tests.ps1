[CmdletBinding()]
param
(
    [Parameter(Mandatory = $true)]
    [Int32]
    $Number1,

    [Parameter(Mandatory = $true)]
    [Int32]
    $Number2
)

Describe 'This is the first number check' -Tags Sum {
    Context 'This is a negative sum context' {
        It 'The sum should be less than 20' {
            $Number1 + $Number2 | Should -BeLessThan 20 
        }

        It 'The sum should be greater than 10' {
            $Number1 + $Number2 | Should -BeGreaterThan 10 
        }
    }
}

Describe 'This is the second number check' -Tags Subtract {
    Context 'This is a negative subtract context' {
        It 'Number 2 should be greater than Number 1' {
            $Number2 | Should -BeGreaterThan $Number1
        }

        It 'The difference should be less than 5' {
            $Number2 - $Number1 | Should -BeLessThan 5 
        }

        It 'The differnce should be greater than 2' {
            $Number2 - $Number1 | Should -BeGreaterThan 2 
        }
    }
}
