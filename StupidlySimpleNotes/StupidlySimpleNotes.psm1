<#
.SYNOPSIS

A stupidly simple note-taking tool

.DESCRIPTION

StupidlySimpleNotes (SSN) is a simple note-taking tool, that allows you to easily
create, display and search notes, right from your PowerShell terminal.

#>


$SsnDirectory = (Resolve-Path '~/ssn').Path


<#
.SYNOPSIS

Create a new note

.DESCRIPTION

Create a new note at the given path. The body of the note can be supplied as
arguments, or if omitted, the draft note will open in Visual Studio Code by
default. Input from the pipeline will be appended to the bottom of the note,
allowing you to easily capture the output of another command in a note.

.PARAMETER Note

The body of the note

.PARAMETER Path

The path for the note. If not supplied, the path will be automatically
generated based on the current timestamp

.PARAMETER Edit

Whether to edit the note in Visual Studio Code before saving

.PARAMETER InputObject

Allows lines of text to be appended to the note from the pipeline
#>
Function New-Note
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification='Creating a note is non-destructive')]
    [CmdletBinding()] Param(
        [Parameter(Position=0, ValueFromRemainingArguments)]
        [string]
        $Note,

        [Parameter()]
        [ArgumentCompleter({ Get-PathCompleter @args })]
        [string]
        $Path,

        [Parameter()]
        [switch]
        $Edit,

        [Parameter(ValueFromPipeline)]
        [string]
        $InputObject
    )

    Begin {
        $lines = @()
        If (-not [string]::IsNullOrWhiteSpace($Note)) { $lines += $Note,'' }
    }
    Process { $lines += $InputObject }
    End {
        If ([string]::IsNullOrWhiteSpace($Path))
        {
            $ticks = ([DateTime]::MaxValue - [DateTime]::Now).Ticks
            $Path = "$ticks.txt"
        }

        If (-not $Path.EndsWith('.txt')) { $Path = "$Path.txt" }

        $fullPath = Join-Path $SsnDirectory $Path
        $directory = [System.IO.Path]::GetDirectoryName($fullPath)
        If (-not (Test-Path $directory)) { [void](New-Item -ItemType Directory -Path $directory) }

        If ($Edit -or ($lines.Count -eq 1))
        {
            $tmp = New-TemporaryFile
            $lines | Out-File -FilePath $tmp
            Edit-NoteInternal $tmp
            Get-Content -Path $tmp | Out-File -FilePath $fullPath
        }
        Else
        {
            $lines | Out-File -FilePath $fullPath
        }
    }
}

<#
.SYNOPSIS

Show the contents of a note

.DESCRIPTION

Show the contents of a note

.PARAMETER Path

The path to the note to show
#>
Function Get-Note
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({ Get-PathCompleter @args })]
        [string]
        $Path
    )

    If (-not $Path.EndsWith('.txt')) { $Path = "$Path.txt" }

    Get-Content -Path (Join-Path $SsnDirectory $Path)
}

<#
.SYNOPSIS

Show the contents of several notes

.DESCRIPTION

Show the contents of all notes under a given path and/or within a given
timeframe

.PARAMETER Today

Show notes created today

.PARAMETER This

Show notes created this week/month/year

.PARAMETER From

Show notes created after this time

.PARAMETER To

Show notes created before this time. If omitted, will show notes up to present

.PARAMETER Path

The path to search under
#>
Function Get-Notes
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification='It gets multiple notes')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidAssignmentToAutomaticVariable', '', Justification='Call needs to be -This')]
    [CmdletBinding(DefaultParameterSetName='FromTo')]
    Param(
        [Parameter(ParameterSetName='Today')]
        [switch]
        $Today,

        [Parameter(ParameterSetName='This')]
        [ValidateSet('week', 'month', 'year')]
        [string]
        $This,

        [Parameter(ParameterSetName='FromTo')]
        [DateTime]
        $From,

        [Parameter(ParameterSetName='FromTo')]
        [DateTime]
        $To,

        [Parameter()]
        [ArgumentCompleter({ Get-PathCompleter @args })]
        [string]
        $Path
    )

    Switch ($PSCmdlet.ParameterSetName)
    {
        'Today' {
            If (-not $Today)
            {
                Write-Error "Not today!"
                Return
            }
            $From = [DateTime]::Today
            $To = [DateTime]::MaxValue
        }
        'This' {
            Switch ($This)
            {
                'week' { $date = [DateTime]::Today; $From = $date.AddDays(1-$date.DayOfWeek) }
                'month' { $date = [DateTime]::Today; $From = $date.AddDays(1-$date.Day) }
                'year' { $date = [DateTime]::Today; $From = $date.AddDays(1-$date.DayOfYear) }
            }
            $To = [DateTime]::MaxValue
        }
        'FromTo' {
            If ($null -eq $To) { $To = [DateTime]::MaxValue }
        }
    }

    If ([string]::IsNullOrWhiteSpace($Path) -and $null -eq $From)
    {
        Write-Error "Must supply either path or time range"
        Return
    }

    If ($null -eq $From) { $From = [DateTime]::MinValue }

    $Path = Join-Path $SsnDirectory $Path

    Get-ChildItem `
        -Path $Path `
        -Include '*.txt' `
        -File `
        -Recurse `
        | Where-Object { $From -le $_.LastWriteTime -and $_.LastWriteTime -lt $To } `
        | ForEach-Object {
            $file = $_
            Write-Output (Get-NoteName $file)
            Write-Output ''

            Get-Content -Path $file.FullName

            Write-Output ''
            Write-Output ''
        }
}

<#
.SYNOPSIS

Search for notes

.DESCRIPTION

Search for notes (optionally under a given path) which match the given search
pattern (regex)

.PARAMETER Search

The pattern to search for in the body of notes (regex)

.PARAMETER Path

The path to search under
#>
Function Find-Notes
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification='It gets multiple notes')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Search', Justification='False positive')]
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory, ValueFromRemainingArguments)]
        [string]
        $Search,

        [Parameter()]
        [ArgumentCompleter({ Get-PathCompleter @args })]
        [string]
        $Path
    )

    $Path = Join-Path $SsnDirectory $Path

    Get-ChildItem `
        -Path $Path `
        -File `
        -Recurse `
        | Where-Object {
            Get-Content -Path $_.FullName `
                | Where-Object { $_ -match $search }
        } `
        | ForEach-Object {
            $file = $_
            Write-Output (Get-NoteName $file)
            Write-Output ''

            Get-Content -Path $file.FullName

            Write-Output ''
            Write-Output ''
        }
}

<#
.SYNOPSIS

Edit the contents of a note

.DESCRIPTION

Edit the contents of a note

.PARAMETER Path

The path to the note to edit
#>
Function Edit-Note
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({ Get-PathCompleter @args })]
        [string]
        $Path
    )

    If (-not $Path.EndsWith('.txt')) { $Path = "$Path.txt" }
    $fullPath = Join-Path $ssnDirectory $Path

    Edit-NoteInternal $fullPath
}

<#
.SYNOPSIS

Move or rename a note

.DESCRIPTION

Move or rename a note

.PARAMETER Path

The path to the note to move or rename

.PARAMETER Destination

The new path for the note
.
#>
Function Move-Note
{
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)]
        [ArgumentCompleter({ Get-PathCompleter @args })]
        [string]
        $Path,

        [Parameter(Mandatory)]
        [ArgumentCompleter({ Get-PathCompleter @args })]
        [string]
        $Destination
    )

    If (-not $Path.EndsWith('.txt')) { $Path = "$Path.txt" }
    If (-not $Destination.EndsWith('.txt')) { $Destination = "$Destination.txt" }

    If ($PSCmdlet.ShouldProcess(
        "Performing the operation `"Move Note`" on target `"Item: $Path Destination: $Destination`"",
        "Are you sure you want to perform this action?`nPerforming the operation `"Move Note`" on target `"Item: $Path Destination: $Destination`"",
        "Confirm"
    ))
    {
        Move-Item `
            -Path (Join-Path $SsnDirectory $Path) `
            -Destination (Join-Path $SsnDirectory $Destination)
    }
}

<#
.SYNOPSIS

Get the default editor

.DESCRIPTION

Get the default editor used when creating or editing notes
#>
Function Get-NoteEditor
{
    [CmdletBinding()]
    Param()

    $editorPath = Join-Path $ssnDirectory ".editor"
    If (Test-Path $editorPath)
    {
        Get-Content -Raw $editorPath
    }
    Else
    {
        "code --wait"
    }
}


<#
.SYNOPSIS

Set the default editor

.DESCRIPTION

Set the default editor used when creating or editing notes

.PARAMETER Command

The command plus any arguments to execute to run the editor. Path will be appended automatically
#>
Function Set-NoteEditor
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Command
    )

    $editorPath = Join-Path $ssnDirectory ".editor"

    $Command | Out-File -LiteralPath $editorPath -NoNewline
}

Function Confirm-Notes
{
    $date = [DateTime]::Today
    $from = $date.AddDays(-6-$date.DayOfWeek)

    Get-ChildItem `
        -Path $SsnDirectory `
        -Include '*.txt' `
        -File `
        -Recurse `
        | Where-Object { $from -le $_.LastWriteTime } `
        | ForEach-Object {
            $file = $_
            Write-Output (Get-NoteName $file)
            Write-Output ''

            Get-Content -Path $file.FullName | more

            Write-Output ''
            Write-Output ''

            # $choice = [System.Management.Automation.Host.ChoiceDescription]

            $opts = @(
                # $choice::new("s", "Skip"),
                # $choice::new("m", "Move")
                '&Skip',
                '&Move',
                '&Edit'
            )
            $selection = $Host.UI.PromptForChoice(
                "Action",
                "Please select action",
                $opts, 0
            )
            write-host $selection
        }
}


Function Get-PathCompleter
{
    $Path = $args[2]

    $fullPath = Join-Path $SsnDirectory $Path

    $directory = [System.IO.Path]::GetDirectoryName($fullPath)
    $filename = [System.IO.Path]::GetFileName($fullPath)

    Get-ChildItem -Path $directory -Filter "$filename*" -Directory | ForEach-Object {
        Get-NoteName $_
    }

    Get-ChildItem -Path "$directory/*" -Filter "$filename*" -Include '*.txt' | ForEach-Object {
        Get-NoteName $_
    }
}

Function Get-NoteName
{
    Param(
        $FilePath
    )

    $FilePath = $FilePath.FullName

    If ((Get-Item $FilePath) -is [System.IO.DirectoryInfo])
    {
        $FilePath = "$FilePath\"
    }
    ElseIf ($FilePath.EndsWith('.txt'))
    {
        $FilePath = $FilePath.Substring(0, $FilePath.Length - 4)
    }

    $FilePath.Substring($SsnDirectory.Length)
}

Function Edit-NoteInternal
{
    Param(
        $FilePath
    )

    $editor = Get-NoteEditor

    Invoke-Expression "$editor `"$FilePath`""
}
