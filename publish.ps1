# publish.ps1 — cria o repo MFerrettiGit/hub e faz push
param([string]$Message = "Atualiza hub")

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot

Set-Location $Root

# Inicializa git se necessário
if(!(Test-Path "$Root\.git")){
    git init
    git branch -M main
}

# Configura remote se necessário
$remotes = git remote 2>$null
if($remotes -notcontains 'origin'){
    # Cria o repo via API do GitHub (lendo token do Cred Manager)
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $credTarget = 'git:https://github.com'
    $cred = [System.Net.CredentialCache]::DefaultNetworkCredentials
    try {
        $cm = New-Object -ComObject 'WScript.Shell'
        $token = (cmdkey /list:$credTarget 2>$null | Where-Object {$_ -match 'User:'} | Select-Object -First 1) -replace '.*User:\s*',''
    } catch {}

    # Lê o token via CredRead (mesmo método dos outros publish.ps1)
    $credBytes = [byte[]]::new(0)
    $credStr = ''
    try {
        $creds = git credential fill 2>$null
    } catch {}

    # Método direto: usa a credencial já salva no git
    $apiBody = '{"name":"hub","description":"Hub central de aplicativos Ferretti","private":false,"auto_init":false}'
    try {
        $pat = (git credential fill << "EOF"
protocol=https
host=github.com
EOF
) 2>$null | Where-Object {$_ -match '^password='} | ForEach-Object {$_ -replace 'password=',''}
        if($pat){
            Invoke-RestMethod -Uri 'https://api.github.com/user/repos' -Method Post -Body $apiBody `
                -Headers @{Authorization="token $pat"; 'Content-Type'='application/json'; 'User-Agent'='PowerShell'} | Out-Null
            Write-Host "Repo criado no GitHub."
        }
    } catch { Write-Host "Repo provavelmente ja existe ou criacao manual necessaria." }

    git remote add origin https://github.com/MFerrettiGit/hub.git
}

# .nojekyll para o GitHub Pages servir arquivos com _
if(!(Test-Path "$Root\.nojekyll")){ '' | Out-File "$Root\.nojekyll" -Encoding ascii }

git add -A
git commit -m $Message 2>$null
if(!$?){ Write-Host "Nada novo para commitar."; exit 0 }
git push -u origin main
Write-Host ""
Write-Host "Hub publicado em: https://mferrettigit.github.io/hub/"
