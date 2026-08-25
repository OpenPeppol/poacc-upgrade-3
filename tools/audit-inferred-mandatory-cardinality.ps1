[CmdletBinding()]
param(
    [string]$OutputPath = 'target/generated/inferred-cardinality-namespace-audit.csv',
    [string]$SchematronOutputDirectory = 'rules/sch/parts',
    [string]$GeneratedSchematronDirectory = 'target/generated',
    [string]$ExclusionLogPath = 'target/generated/inferred-cardinality-excluded.csv'
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$syntaxDirectory = Join-Path $repositoryRoot 'structure/syntax'
$namespaceDirectory = Join-Path $repositoryRoot 'structure/namespace'

function Read-XmlDocument {
    param([string]$Path)

    $document = [System.Xml.XmlDocument]::new()
    $document.Load($Path)
    return $document
}

function Get-ChildElementsByLocalName {
    param(
        [System.Xml.XmlNode]$Node,
        [string]$LocalName
    )

    return @($Node.ChildNodes | Where-Object {
        $_.NodeType -eq [System.Xml.XmlNodeType]::Element -and $_.LocalName -eq $LocalName
    })
}

function Get-FirstChildText {
    param(
        [System.Xml.XmlNode]$Node,
        [string]$LocalName
    )

    if (-not $Node) {
        return $null
    }

    $child = $Node.SelectSingleNode("*[local-name()='$LocalName']")
    if (-not $child) {
        return $null
    }

    return $child.InnerText.Trim()
}

function ConvertTo-XmlAttribute {
    param([string]$Value)

    return ((($Value -replace '&', '&amp;') -replace '"', '&quot;') -replace '<', '&lt;') -replace '>', '&gt;'
}

function ConvertFrom-NamespaceFile {
    param([string]$Path)

    $document = Read-XmlDocument $Path
    $identifierNode = $document.SelectSingleNode("/*[local-name()='Namespace']/*[local-name()='Identifier']")
    $elements = @{}

    foreach ($element in @($document.SelectNodes("/*[local-name()='Namespace']/*[local-name()='Element']"))) {
        $name = $element.GetAttribute('name')
        if (-not $name) {
            continue
        }

        $refs = @{}
        foreach ($ref in (Get-ChildElementsByLocalName -Node $element -LocalName 'Ref')) {
            $term = $ref.InnerText.Trim()
            if (-not $term) {
                continue
            }

            $refs[$term] = if ($ref.HasAttribute('card')) { $ref.GetAttribute('card') } else { $null }
        }

        $elements[$name] = $refs
    }

    return [pscustomobject]@{
        Path = $Path
        FileName = [System.IO.Path]::GetFileName($Path)
        Identifier = if ($identifierNode) { $identifierNode.InnerText.Trim() } else { $null }
        Prefix = if ($identifierNode -and $identifierNode.HasAttribute('prefix')) { $identifierNode.GetAttribute('prefix') } else { $null }
        Elements = $elements
    }
}

function ConvertFrom-AllNamespaceFiles {
    $files = @{}
    foreach ($file in @(Get-ChildItem -Path $namespaceDirectory -Filter '*.xml' -File)) {
        $files[$file.Name] = ConvertFrom-NamespaceFile $file.FullName
    }
    return $files
}

function Resolve-DocumentNamespace {
    param(
        [hashtable]$NamespaceFiles,
        [string]$SyntaxFileName,
        [string]$DocumentUri,
        [string]$RootLocalName
    )

    if ($NamespaceFiles.ContainsKey($SyntaxFileName)) {
        return $NamespaceFiles[$SyntaxFileName]
    }

    $matches = @(
        $NamespaceFiles.Values |
            Where-Object { $_.Identifier -eq $DocumentUri -and $_.Elements.ContainsKey($RootLocalName) } |
            Sort-Object { $_.FileName.Length }
    )

    if ($matches.Count -gt 0) {
        return $matches[0]
    }

    return $null
}

function Get-IncludedElements {
    param([string]$IncludePath)

    $includeDocument = Read-XmlDocument $IncludePath
    if ($includeDocument.DocumentElement.LocalName -eq 'Element') {
        return @($includeDocument.DocumentElement)
    }

    return @(Get-ChildElementsByLocalName -Node $includeDocument.DocumentElement -LocalName 'Element')
}

function Get-NamespaceCardinality {
    param(
        [hashtable]$Indexes,
        [string]$ParentPrefix,
        [string]$ParentName,
        [string]$Term
    )

    if (-not $ParentPrefix -or -not $ParentName -or -not $Indexes.ContainsKey($ParentPrefix)) {
        return 'UNRESOLVED'
    }

    $parentRefs = $Indexes[$ParentPrefix].Elements[$ParentName]
    if (-not $parentRefs -or -not $parentRefs.ContainsKey($Term) -or [string]::IsNullOrWhiteSpace($parentRefs[$Term])) {
        return 'UNRESOLVED'
    }

    return $parentRefs[$Term]
}

function ConvertTo-SchematronContext {
    param([string]$ElementPath)

    $segments = @($ElementPath -split '/')
    if ($segments.Count -lt 2) {
        return $segments[0]
    }

    return ($segments[0..($segments.Count - 2)] -join '/')
}

function ConvertTo-NormalizedSchematronContext {
    param([string]$Context)

    if ([string]::IsNullOrWhiteSpace($Context)) {
        return ''
    }

    return $Context.Trim().TrimStart('/')
}

function ConvertFrom-GeneratedMandatoryTest {
    param([string]$Test)

    if ([string]::IsNullOrWhiteSpace($Test)) {
        return $null
    }

    $normalized = [regex]::Replace($Test.Trim(), '\s+', ' ')

    if ($normalized -match '^count\(\s*([A-Za-z_][\w.-]*:[A-Za-z_][\w.-]*)\s*\)\s*(=|eq)\s*1$') {
        return [pscustomobject]@{
            Child = $Matches[1]
            Strictness = 'repeatability'
            StrictnessLabel = 'strict on repeatability (exactly one)'
        }
    }

    if ($normalized -match '^exists\(\s*([A-Za-z_][\w.-]*:[A-Za-z_][\w.-]*)\s*\)$') {
        return [pscustomobject]@{
            Child = $Matches[1]
            Strictness = 'existence'
            StrictnessLabel = 'existence only (not strict on repeatability)'
        }
    }

    if ($normalized -match '^count\(\s*([A-Za-z_][\w.-]*:[A-Za-z_][\w.-]*)\s*\)\s*(>|>=|gt|ge)\s*(0|1)$') {
        return [pscustomobject]@{
            Child = $Matches[1]
            Strictness = 'existence'
            StrictnessLabel = 'existence only (not strict on repeatability)'
        }
    }

    if ($normalized -match '^([A-Za-z_][\w.-]*:[A-Za-z_][\w.-]*)$') {
        return [pscustomobject]@{
            Child = $Matches[1]
            Strictness = 'existence'
            StrictnessLabel = 'existence only (not strict on repeatability)'
        }
    }

    return $null
}

function Get-GeneratedMandatoryCoverage {
    param(
        [string]$GeneratedDirectory,
        [string]$TransactionId
    )

    $coverage = @{}
    $path = Join-Path $GeneratedDirectory "$TransactionId-basic.sch"
    if (-not (Test-Path -LiteralPath $path)) {
        return $coverage
    }

    $document = Read-XmlDocument $path
    foreach ($rule in @($document.SelectNodes("//*[local-name()='rule']"))) {
        $context = ConvertTo-NormalizedSchematronContext $rule.GetAttribute('context')
        if (-not $context) {
            continue
        }

        foreach ($assert in @($rule.SelectNodes("*[local-name()='assert']"))) {
            $parsed = ConvertFrom-GeneratedMandatoryTest -Test $assert.GetAttribute('test')
            if (-not $parsed) {
                continue
            }

            $key = "$context|$($parsed.Child)"
            $entry = [pscustomobject]@{
                Id = $assert.GetAttribute('id')
                Test = $assert.GetAttribute('test')
                Child = $parsed.Child
                Strictness = $parsed.Strictness
                StrictnessLabel = $parsed.StrictnessLabel
            }

            if (-not $coverage.ContainsKey($key)) {
                $coverage[$key] = $entry
            }
            elseif ($entry.Strictness -eq 'repeatability' -and $coverage[$key].Strictness -ne 'repeatability') {
                $coverage[$key] = $entry
            }
        }
    }

    return $coverage
}

function Write-InferredCardinalitySchematron {
    param(
        [string]$Path,
        [string]$TransactionId,
        [object[]]$AssertionRows
    )

    if (-not $AssertionRows) {
        $AssertionRows = @()
    }

    $rules = @(
        $AssertionRows |
            Group-Object Context |
            ForEach-Object {
                $context = ConvertTo-XmlAttribute $_.Name
                $assertions = $_.Group | ForEach-Object {
                    $id = ConvertTo-XmlAttribute $_.Id
                    $child = ConvertTo-XmlAttribute $_.Child
                    "    <assert id=`"$id`" test=`"count($child) = 1`" flag=`"fatal`">[$id]-$context MUST contain exactly one $child.</assert>"
                }
                "  <rule context=`"$context`">`n$($assertions -join "`n")`n  </rule>"
            }
    )

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines(
        $Path,
        @(
            '<?xml version="1.0" encoding="UTF-8"?>'
            "<pattern xmlns=`"http://purl.oclc.org/dsdl/schematron`" id=`"PEPPOL-M-$TransactionId-I`">"
            $rules
            '</pattern>'
        ),
        $utf8NoBom
    )

    return $rules.Count
}

function Resolve-StructureElements {
    param(
        [System.Xml.XmlNode[]]$Nodes,
        [string]$DocumentName,
        [string]$TransactionId,
        [string]$RulePrefix,
        [string]$SourceFile,
        [string]$Path,
        [string]$ParentCardinality,
        [string]$ParentPrefix,
        [string]$ParentName,
        [hashtable]$Indexes,
        [System.Collections.Generic.List[object]]$Rows
    )

    foreach ($node in $Nodes) {
        if ($node.LocalName -eq 'Include') {
            $includePath = Join-Path (Split-Path -Parent ([Uri]$node.BaseURI).LocalPath) $node.InnerText.Trim()
            Resolve-StructureElements `
                -Nodes (Get-IncludedElements $includePath) `
                -DocumentName $DocumentName `
                -TransactionId $TransactionId `
                -RulePrefix $RulePrefix `
                -SourceFile $SourceFile `
                -Path $Path `
                -ParentCardinality $ParentCardinality `
                -ParentPrefix $ParentPrefix `
                -ParentName $ParentName `
                -Indexes $Indexes `
                -Rows $Rows
            continue
        }

        if ($node.LocalName -ne 'Element') {
            continue
        }

        $term = Get-FirstChildText -Node $node -LocalName 'Term'
        if (-not $term) {
            continue
        }

        $elementPath = if ($Path) { "$Path/$term" } else { $term }
        $namespaceCardinality = Get-NamespaceCardinality -Indexes $Indexes -ParentPrefix $ParentPrefix -ParentName $ParentName -Term $term
        $cardinality = if ($node.Attributes['cardinality']) { $node.Attributes['cardinality'].Value } else { '1..1' }

        if (-not $node.Attributes['cardinality']) {
            $references = @(
                $node.SelectNodes("*[local-name()='Reference' and @type='BUSINESS_TERM']") |
                    ForEach-Object { $_.InnerText.Trim() }
            ) -join ', '

            $Rows.Add([pscustomobject]@{
                Document = $DocumentName
                TransactionId = $TransactionId
                RulePrefix = $RulePrefix
                SourceFile = $SourceFile
                Path = $elementPath
                BusinessTerms = $references
                SyntaxExplicitCardinality = 'NO'
                SyntaxGeneratedCardinality = '1..1'
                ParentSyntaxCardinality = $ParentCardinality
                NamespaceCardinality = $namespaceCardinality
                NamespaceDiffersFromGeneratedMandatory = if ($namespaceCardinality -eq '1..1') { 'NO' } else { 'YES' }
            })
        }

        $childPrefix = $ParentPrefix
        $childName = $ParentName
        if ($term.Contains(':')) {
            $childPrefix = $term.Split(':')[0]
            $childName = $term.Split(':')[-1]
        }

        Resolve-StructureElements `
            -Nodes @($node.ChildNodes) `
            -DocumentName $DocumentName `
            -TransactionId $TransactionId `
            -RulePrefix $RulePrefix `
            -SourceFile $SourceFile `
            -Path $elementPath `
            -ParentCardinality $cardinality `
            -ParentPrefix $childPrefix `
            -ParentName $childName `
            -Indexes $Indexes `
            -Rows $Rows
    }
}

$namespaceFiles = ConvertFrom-AllNamespaceFiles
$cacNamespace = $namespaceFiles['ubl-cac.xml']
$cbcNamespace = $namespaceFiles['ubl-cbc.xml']
if (-not $cacNamespace -or -not $cbcNamespace) {
    throw "Missing shared namespace files ubl-cac.xml and/or ubl-cbc.xml in $namespaceDirectory"
}

$rows = [System.Collections.Generic.List[object]]::new()
$processedTransactionIds = [System.Collections.Generic.List[string]]::new()

foreach ($syntaxPath in @(Get-ChildItem -Path $syntaxDirectory -Filter '*.xml' -File | ForEach-Object { $_.FullName } | Sort-Object)) {
    $structure = Read-XmlDocument $syntaxPath
    $root = $structure.SelectSingleNode("/*[local-name()='Structure']/*[local-name()='Document']")
    if (-not $root) {
        Write-Warning "Skipping $syntaxPath because it has no Document element."
        continue
    }

    $documentName = Get-FirstChildText -Node $structure.DocumentElement -LocalName 'Term'
    $rulePrefixNode = $structure.SelectSingleNode("/*[local-name()='Structure']/*[local-name()='Property' and @key='sch:prefix']")
    $rulePrefix = if ($rulePrefixNode) { $rulePrefixNode.InnerText.Trim() } else { $null }
    $identifierNode = $structure.SelectSingleNode("/*[local-name()='Structure']/*[local-name()='Property' and @key='sch:identifier']")
    $identifier = if ($identifierNode) { $identifierNode.InnerText.Trim() } else { $null }
    $transactionId = if ($identifier) {
        $identifier -replace '-basic$', ''
    } elseif ($rulePrefix -match 'T\d+$') {
        $Matches[0]
    } else {
        $documentName
    }
    $processedTransactionIds.Add($transactionId)
    $documentTerm = Get-FirstChildText -Node $root -LocalName 'Term'
    $documentUri = $structure.SelectSingleNode("/*[local-name()='Structure']/*[local-name()='Namespace' and @prefix='ubl']").InnerText.Trim()
    $rootLocalName = $documentTerm.Split(':')[-1]
    $syntaxFileName = [System.IO.Path]::GetFileName($syntaxPath)
    $documentNamespace = Resolve-DocumentNamespace -NamespaceFiles $namespaceFiles -SyntaxFileName $syntaxFileName -DocumentUri $documentUri -RootLocalName $rootLocalName
    if (-not $documentNamespace) {
        throw "Could not resolve a namespace file for $syntaxFileName ($documentUri / $rootLocalName)."
    }

    $indexes = @{
        ubl = $documentNamespace
        cac = $cacNamespace
        cbc = $cbcNamespace
    }
    if ($documentNamespace.Prefix -and -not $indexes.ContainsKey($documentNamespace.Prefix)) {
        $indexes[$documentNamespace.Prefix] = $documentNamespace
    }

    $relativeSource = $syntaxPath.Substring((Join-Path $repositoryRoot '').Length)
    Resolve-StructureElements `
        -Nodes @($root.ChildNodes) `
        -DocumentName $documentName `
        -TransactionId $transactionId `
        -RulePrefix $rulePrefix `
        -SourceFile $relativeSource `
        -Path $documentTerm `
        -ParentCardinality '(root)' `
        -ParentPrefix 'ubl' `
        -ParentName $rootLocalName `
        -Indexes $indexes `
        -Rows $rows
}

$destination = Join-Path $repositoryRoot $OutputPath
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $destination) | Out-Null
$rows | Sort-Object Document, Path | Export-Csv -NoTypeInformation -Encoding utf8 -Path $destination
Write-Host "Wrote $($rows.Count) inferred-cardinality rows to $destination"

$generatedDirectory = Join-Path $repositoryRoot $GeneratedSchematronDirectory
$transactionIds = @($processedTransactionIds | Select-Object -Unique | Sort-Object)
$generatedCoverageByTransaction = @{}
foreach ($transactionId in $transactionIds) {
    $generatedFile = Join-Path $generatedDirectory "$transactionId-basic.sch"
    $generatedCoverageByTransaction[$transactionId] = Get-GeneratedMandatoryCoverage -GeneratedDirectory $generatedDirectory -TransactionId $transactionId
    if (-not (Test-Path -LiteralPath $generatedFile)) {
        Write-Warning "Generated Schematron not found: $generatedFile. Inferred rules for $transactionId will not be compared for exclusion."
    }
    else {
        Write-Host "Loaded $($generatedCoverageByTransaction[$transactionId].Count) generated mandatory/existence asserts from $generatedFile"
    }
}

$prefixCounters = @{}
$exclusionRows = [System.Collections.Generic.List[object]]::new()
$assertionRows = @(
    $rows |
        Where-Object { $_.NamespaceDiffersFromGeneratedMandatory -eq 'YES' -and $_.NamespaceCardinality -ne 'UNRESOLVED' } |
        Sort-Object TransactionId, Path |
        ForEach-Object {
            if (-not $prefixCounters.ContainsKey($_.RulePrefix)) {
                $prefixCounters[$_.RulePrefix] = 140
            }

            $id = "$($_.RulePrefix)-R$($prefixCounters[$_.RulePrefix])"
            $prefixCounters[$_.RulePrefix]++
            $pathSegments = $_.Path -split '/'
            $context = ConvertTo-SchematronContext -ElementPath $_.Path
            $child = $pathSegments[-1]
            $coverageKey = "$(ConvertTo-NormalizedSchematronContext $context)|$child"
            $generatedCoverage = $generatedCoverageByTransaction[$_.TransactionId]
            $coveringAssert = if ($generatedCoverage -and $generatedCoverage.ContainsKey($coverageKey)) { $generatedCoverage[$coverageKey] } else { $null }

            if ($coveringAssert) {
                $reason = "Already covered by generated $($coveringAssert.Id) test='$($coveringAssert.Test)' [$($coveringAssert.StrictnessLabel)]."
                Write-Host "Excluded $id $($_.Path): $reason"
                $exclusionRows.Add([pscustomobject]@{
                    TransactionId = $_.TransactionId
                    InferredId = $id
                    Path = $_.Path
                    Context = $context
                    Child = $child
                    GeneratedId = $coveringAssert.Id
                    GeneratedTest = $coveringAssert.Test
                    Strictness = $coveringAssert.Strictness
                    Reason = $reason
                })
                return
            }

            [pscustomobject]@{
                Document = $_.Document
                TransactionId = $_.TransactionId
                RulePrefix = $_.RulePrefix
                Id = $id
                Context = $context
                Child = $child
            }
        }
)

$exclusionDestination = Join-Path $repositoryRoot $ExclusionLogPath
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $exclusionDestination) | Out-Null
$exclusionRows | Sort-Object TransactionId, InferredId | Export-Csv -NoTypeInformation -Encoding utf8 -Path $exclusionDestination
Write-Host "Wrote $($exclusionRows.Count) inferred-cardinality exclusions to $exclusionDestination"

$existenceCount = @($exclusionRows | Where-Object Strictness -eq 'existence').Count
$repeatabilityCount = @($exclusionRows | Where-Object Strictness -eq 'repeatability').Count
Write-Host "Exclusion strictness: $existenceCount existence only, $repeatabilityCount strict on repeatability (exactly one)."

$schematronDirectory = Join-Path $repositoryRoot $SchematronOutputDirectory
New-Item -ItemType Directory -Force -Path $schematronDirectory | Out-Null

foreach ($transactionId in $transactionIds) {
    $transactionAssertions = @($assertionRows | Where-Object TransactionId -eq $transactionId)
    $transactionExclusions = @($exclusionRows | Where-Object TransactionId -eq $transactionId)
    $schematronDestination = Join-Path $schematronDirectory "PEPPOL-M-$transactionId-I.sch"
    $ruleCount = Write-InferredCardinalitySchematron -Path $schematronDestination -TransactionId $transactionId -AssertionRows $transactionAssertions
    Write-Host "Wrote $($transactionAssertions.Count) cardinality assertions in $ruleCount parent-context rules to $schematronDestination (excluded $($transactionExclusions.Count) already covered by $transactionId-basic.sch)"
}
