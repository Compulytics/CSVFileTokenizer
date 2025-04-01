function HelpPage(){
	cls
	Write-Host "================================================================================"
	Write-Host "|                                   Help Menu                                  |"
	Write-Host "================================================================================"
	Write-Host "| This script is designed to convert sensitive data in CSV columns             |"
	Write-Host "| into unique tokens and provide a keyfile for later de-tokenization.          |"
	Write-Host "================================================================================"
	Write-Host "|                                Column Selection                              |"
	Write-Host "================================================================================"
	Write-Host "| - = Go to previous column header.                                            |"
	Write-Host "| + = Go to next column header.                                                |"
	Write-Host "| # = Go to specified column header (Index must be in range)                   |"
	Write-Host "| ? = Search for column header by name.                                        |"
	Write-Host "| x = Toggle column header selection.                                          |"
	Write-Host "| S = Show column header selection summary.                                    |"
	Write-Host "| . = Continue with the tokenization operation with the current selections.    |"
	Write-Host "| QUIT = End script execution.                                                 |"
	Write-Host "| H = Show this help menu.                                                     |"
	Write-Host "================================================================================"
	Write-Host "|                                Arguments Mode                                |"
	Write-Host "================================================================================"
	Write-Host "| Tokenize Mode:                                                               |"
	Write-Host "| Usage: ./CSVTokenizer.ps1 -d ',' -c '`"Name`",`"Address`",`"Phone Number`"'        |"
	Write-Host "|                                                                              |"
	Write-Host "| `"-c`" = Designate columns to tokenize in CSV format.                          |"
	Write-Host "| `"-d`" = Set delimiter to be used in processing CSV file.                      |"
	Write-Host "================================================================================"
	Write-Host "| De-tokenize Mode:                                                            |"
	Write-Host "| Usage: ./CSVTokenizer.ps1 -t *TOKENIZED_FILEPATH* *TOKEN_KEYS_FILEPATH*      |"
	Write-Host "================================================================================"
	Read-Host "ENTER TO CONTINUE..."
}
function Summary(){
	param($SelectedHeaders)
	cls
	$TotalSelected = 0
	Write-Host "================================================================================"
	Write-Host "|                        Column Header Selection Summary                       |"
	foreach ($HeaderTitle in $Headers){
		Write-Host "================================================================================"
		Write-Host "Column Title: "$HeaderTitle
		Write-Host "Index: "$([array]::indexof($Headers,$HeaderTitle) + 1)
		if ([array]::indexof($Headers, $HeaderTitle) -in $SelectedHeaders){
			Write-Host "Included: True"
			$TotalSelected++
		}
		else{
			Write-Host "Included: False"
		}
	}
	Write-Host "********************************************************************************"
	Write-Host "Total Columns in Input File: "$Headers.Length
	Write-Host "Total Columns Included: "$TotalSelected
	Write-Host "********************************************************************************".
}
function SearchColumns(){
	param($CSVCOlumnTitles)
	$QueryItems = @()
	$Query = Read-Host "Enter search query."
	if ($Query -match '^[a-zA-Z0-9._@-]{1,100}$'){
		foreach ($Title in $CSVCOlumnTitles){
			if ($Title -match $Query){
				$QueryItems += $Title
			}
		}
	}
	else{
		Write-Host "Invalid input"
		sleep 2 
		SearchColumns @($CSVCOlumnTitles) 
	}
	if ($QueryItems.Length -lt 1){
		Write-Host "No matches found for query `"$Query`"."
		sleep 2 
		SearchColumns @($CSVCOlumnTitles)
	}
	elseif ($QueryItems.Length -eq 1){
		$SelectedHeader = $CSVCOlumnTitles | where {$_ -eq $($QueryItems[0])}
		return $([array]::indexof($CSVCOlumnTitles,$SelectedHeader))
	}
	else{
		Write-Host "Multiple users found for query `"$Query`":"
		foreach ($QueryResult in $QueryItems){
			Write-Host $([array]::indexof($QueryItems,$QueryResult) + 1)". "$QueryResult 
		}
		$SelectedEntry = Read-Host "Please select an entry. (1..$($QueryItems.Length))"
		if ($SelectedEntry -in 1..$($QueryItems.Length)){
			$SelectedHeader = $CSVCOlumnTitles | where {$_ -eq $($QueryItems[$($SelectedEntry - 1)])}
			return $([array]::indexof($CSVCOlumnTitles,$SelectedHeader))
		}
		else{
			Write-Host "ERROR: Selection `"$SelectedEntry`" out of range!"
			sleep 2 
			SearchColumns @($CSVCOlumnTitles)
		}
	}
}
function TableSelection(){
	param($CSVColumnHeaders, $HeaderSelection)
	$ListMaxIndex = $($($CSVColumnHeaders.Length) - 1)
	$Index=0
	while ($Index -in 0..$ListMaxIndex){
		cls 
		$CurrentIndex = [array]::indexof($CSVColumnHeaders,($Headers | where {$_ -eq ($CSVColumnHeaders[$Index])}))
		Write-Host "================================================================================"
		Write-Host "|                               Column Selection                               |"
		Write-Host "================================================================================"
		Write-Host " Current Column Title: "$($CSVColumnHeaders[$Index]) 
		Write-Host " Current Index: $($CurrentIndex+1)"
		if ($CurrentIndex -in $HeaderSelection){
			Write-Host " Item Selected: True"
		}
		else{
			Write-Host " Item Selected: False"
		}
		Write-Host " Total Items: "$CSVColumnHeaders.Length 
		Write-Host "================================================================================"
		Write-Host "| - = Previous, + = Next, # = Go to, x = Toggle Select, H = Help, . = Done     |"
		Write-Host "================================================================================"
		$Reply = Read-Host "> "
		switch ($Reply) {
			'+' {cls; $Index++; Break}
			'-' {cls; $Index--; Break}
			'x' {cls; if($CurrentIndex -in $HeaderSelection){$HeaderSelection = ($HeaderSelection | Where-Object {$_ -ne $CurrentIndex})}else{$HeaderSelection += $CurrentIndex}; Break}
			'H' {HelpPage; Break}
			'S' {Summary($HeaderSelection); cls; Read-Host "ENTER TO CONTINUE..."; Break}
			'?' {$Index = (SearchColumns($CSVColumnHeaders)); Break}
			'#' {$DesiredIndex = Read-Host "Please enter the index you want to jump to. (1..$($Headers.Length))"; if ($DesiredIndex -in 1..$($Headers.Length)){$Index = $($DesiredIndex - 1)}else{Write-Host "ERROR: Selection `"$DesiredIndex`" is out of range!"; sleep 2}}
			'.' {cls; Summary($HeaderSelection); $ConfirmRun = Read-Host "Are you sure you want to initiate tokenization process for the currently selected columns? (y,n)"; if ($ConfirmRun -eq 'y' -or $ConfirmRun -eq 'Y'){return $HeaderSelection; exit}; Break}
			'QUIT' {$ConfirmQuit = Read-Host "Are you sure you want to exit? (y,n)"; if($ConfirmQuit -eq 'y' -or $ConfirmQuit -eq 'Y'){cls; exit}; Break}
		}
		if ($Index -gt $ListMaxIndex){
			$Index-- 
		}
		elseif ($Index -lt 0){
			$Index++ 
		}
	}
}
function FileTokenizer(){
	param($InputFilePath, $ColumnTitleData, $ColumnsToMask, $CSVDelimiter)
	$OutputFilePath = (Split-Path -Path $InputFilePath -Parent)
	$OutputCSVFileName = "Tokenized-$(Split-Path -Path $InputFilePath -Leaf)"
	Add-Type -AssemblyName Microsoft.VisualBasic
	$TokenKeyData = @{}
	$CSVFileReader = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser $InputFilePath
	$CSVFileReader.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
	$CSVFileReader.SetDelimiters($CSVDelimiter)
	$CSVFileReader.HasFieldsEnclosedInQuotes = $true
	$CSVFileWriter = [System.IO.StreamWriter]::new("$OutputFilePath\$OutputCSVFileName")
	$CSVFileWriter.WriteLine(($ColumnTitleData -join $CSVDelimiter))
	$null = $CSVFileReader.ReadFields()
	$TokenCounter = 0
	while (-not $CSVFileReader.EndOfData) {
		$RowValues = $CSVFileReader.ReadFields()
		foreach ($Column in $ColumnsToMask) {
			if ($Column -lt $RowValues.Length) {
				$OriginalValue = $RowValues[$Column]
				if(!($TokenKeyData.ContainsKey($OriginalValue))){
					$TokenKeyData[$OriginalValue] = "T[{0:X}]" -f $TokenCounter
					$TokenCounter++
				}
				$RowValues[$Column] = $TokenKeyData[$OriginalValue]
			}
		}
		$CSVFileWriter.WriteLine(($RowValues -join $CSVDelimiter))
	}
	$CSVFileReader.Close()
	$CSVFileWriter.Close()
	$KeyFileData = @{}
	foreach ($Key in $TokenKeyData.Keys){
		$Base64TextValue = ([System.Convert]::ToBase64String(([System.Text.Encoding]::UTF8.GetBytes($Key))))
		$KeyFileData["$Base64TextValue"] = $TokenKeyData[$Key]
	}
	$OutputPath = (Split-Path -Path $InputFile -Parent)
	$OutputKeyFileName = "$($(Split-Path -Path $InputFile -Leaf).TrimEnd('.csv'))-TokenKeys.JSON"
	$JSONKeyData = [PSCustomObject]$KeyFileData
	$JSONKeyData | ConvertTo-Json | Set-Content "$OutputPath\$OutputKeyFileName"
	$JSONKeyData = [PSCustomObject]$KeyFileData
}
function Detokenize(){
	param($InputTokenizedFilePath, $InputKeyFilePath)
	cls
	Write-Host "De-tokenizing file: `"$InputTokenizedFilePath`" with keyfile: `"$InputKeyFilePath`"."
	$OutputFilePath = (Split-Path -Path $InputTokenizedFilePath -Parent)
	$OutputFileName = "DeTokenized-$(Split-Path -Path $InputTokenizedFilePath -Leaf)"
	$TokenizedFileData = (Get-Content -Path $InputTokenizedFilePath)
	$TokenMapData = (Get-Content -Path $InputKeyFilePath | ConvertFrom-JSON)
	$TokenTranslations = (Get-Content -Path $InputKeyFilePath | ConvertFrom-JSON | Get-Member -MemberType NoteProperty | Select Name)
	$OutputFileContent = Get-Content -Path $InputTokenizedFilePath
	foreach ($B64Value in $TokenTranslations){
		$CurrentToken = ($TokenMapData.($B64Value.Name))
		$CurrentOriginalValue = ([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("$($B64Value.Name)")))
		$OutputFileContent = $OutputFileContent.Replace($CurrentToken,$CurrentOriginalValue)
	}
	Set-Content -Path "$OutputFilePath\$OutputFileName" -Value $OutputFileContent
	cls
	Write-Host "Successfully de-tokenized file `"$InputTokenizedFilePath`"."
}
cls
Add-Type -AssemblyName Microsoft.VisualBasic
if ($args[0]){
	if ($args[0] -eq '-t'){
		$InputTokenizedFile = [string]$args[1]
		$InputKeyFile = [string]$args[2]
		Detokenize $InputTokenizedFile $InputKeyFile
		exit
	}
	else{
		$InputFile = [string]$args[0]
		if ([string]$args[1] -eq '-d'){
			$Delimiter = [string]$args[2]
		}
		elseif ([string]$args[1] -eq '-c'){
			$SelectedColumnNames = [string]$args[2]
		}
		if ([string]$args[3] -eq '-c'){
			$SelectedColumnNames = [string]$args[4]
		}
		elseif ([string]$args[3] -eq '-d'){
			$Delimiter = [string]$args[4]
		}
		$SelectedColumnList = $SelectedColumnNames -split $Delimiter
	}
}
else{
	$InputMode = Read-Host "Would you like to tokenize or de-tokenize? (t,d)"
	if ($InputMode -eq "d" -or $ImputMode -eq "D"){
		cls
		$InputTokenizedFile = Read-Host "Please enter the full path of the file to de-tokenize"
		while (!(Test-Path $InputTokenizedFile -PathType Leaf)){
			if (!(Test-Path $InputTokenizedFile -PathType Leaf)){
				cls
				Write-Host "ERROR: $InputTokenizedFile - Path invalid."
				$InputTokenizedFile = Read-Host "Please enter the full path of the file to de-tokenize"
			}
		}
		cls
		$InputKeyFile = Read-Host "Please enter the full path of the TokenKeys file"
		while (!(Test-Path $InputKeyFile -PathType Leaf)){
			if (!(Test-Path $InputKeyFile -PathType Leaf)){
				cls
				Write-Host "ERROR: $InputKeyFile - Path invalid."
				$InputKeyFile = Read-Host "Please enter the full path of the TokenKeys file"
			}
		}
		Detokenize $InputTokenizedFile $InputKeyFile
		exit
	}
	else{
		$InputFile = Read-Host "Please enter the full path of the CSV file to tokenize"
		cls
		$Delimiter = Read-Host "Set file delimiter (default ',')"
	}
}
if (!($Delimiter)){
	$Delimiter = ','
}
$FileReaderTitle = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser $InputFile
$FileReaderTitle.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
$FileReaderTitle.SetDelimiters($Delimiter)
$FileReaderTitle.HasFieldsEnclosedInQuotes = $true
$Headers = $FileReaderTitle.ReadFields()
$FileReaderTitle.Close()
if ($args[0]){
	$SelectedColumns = @()
	foreach ($SelectedName in $SelectedColumnList){
		$SelectedColumns += ([array]::indexof($Headers,$SelectedName))
	}
}
else{
	$SelectedColumns = TableSelection $Headers @()
}
while (!(Test-Path $InputFile -PathType Leaf)){
	if (!(Test-Path $InputFile -PathType Leaf)){
		cls
		Write-Host "ERROR: $InputFile - Path invalid."
		$InputFile = Read-Host "Please enter the full path of the CSV file to tokenize"
	}
}
cls
Write-Host "Tokenizing CSV File `"$InputFile`"..."
FileTokenizer $InputFile $Headers $SelectedColumns $Delimiter
cls
Write-Host "Successfully tokenized file `"$InputFile`"."
