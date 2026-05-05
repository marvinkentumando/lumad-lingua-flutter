Get-ChildItem -Path lib -Filter *.dart -Recurse | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -like '*BrandCardTheme.darkGlass*') {
        $newContent = $content -replace 'BrandCardTheme.darkGlass', 'BrandCardTheme.vibrant'
        $newContent | Set-Content $_.FullName -NoNewline
        Write-Host "Fixed: $($_.FullName)"
    }
}
