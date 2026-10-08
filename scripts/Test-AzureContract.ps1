[CmdletBinding()]
param(
    [string]$HelmCommand = 'helm',
    [switch]$RunNegativeTests
)

$ErrorActionPreference = 'Stop'
$chart = Join-Path (Split-Path -Parent $PSScriptRoot) 'helm/getlink-dtd'
$overlayPath = Join-Path $chart 'values-azure.yaml'
$overlay = Get-Content -LiteralPath $overlayPath -Raw

function Assert-Contract {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "Azure contract failed: $Message" }
}

function Test-ImageTags {
    param([string]$Values)
    $tags = [regex]::Matches($Values, '(?m)^\s+tag:\s*["'']?([a-f0-9]{40})["'']?\s*$')
    Assert-Contract ($tags.Count -eq 4) 'all four Azure image tags must be full lowercase commit SHAs, not placeholders/latest'
    $tag = $tags[0].Groups[1].Value
    foreach ($match in $tags) {
        Assert-Contract ($match.Groups[1].Value -ceq $tag) 'all four application images must use the same source SHA'
    }
    return $tag
}

function Get-Resource {
    param([string[]]$Documents, [string]$Kind, [string]$Name)
    $kindPattern = '(?m)^kind:\s*' + [regex]::Escape($Kind) + '\r?$'
    $namePattern = '(?m)^  name:\s*' + [regex]::Escape($Name) + '\r?$'
    $found = @($Documents | Where-Object { $_ -match $kindPattern -and $_ -match $namePattern })
    Assert-Contract ($found.Count -eq 1) "expected exactly one $Kind/$Name"
    return $found[0]
}

function Assert-Line {
    param([string]$Text, [string]$Line, [string]$Message)
    $pattern = '(?m)^\s*' + [regex]::Escape($Line) + '\s*\r?$'
    Assert-Contract ($Text -match $pattern) $Message
}

$tag = Test-ImageTags $overlay
if ($RunNegativeTests) {
    foreach ($invalid in @(
        ($overlay -replace [regex]::Escape($tag), 'latest'),
        ($overlay -replace [regex]::Escape($tag), 'replace-with-your-image-tag'),
        ([regex]::new([regex]::Escape($tag)).Replace($overlay, ('0' * 40), 1))
    )) {
        $rejected = $false
        try { $null = Test-ImageTags $invalid } catch { $rejected = $true }
        Assert-Contract $rejected 'image-tag guard must reject a mutable/placeholder/mixed release'
    }
}

$renderedLines = @(& $HelmCommand template getlink-dtd $chart --namespace getlink-dtd `
    -f (Join-Path $chart 'values.yaml') -f $overlayPath)
if ($LASTEXITCODE -ne 0) { throw "Helm render failed with exit code $LASTEXITCODE" }
$rendered = $renderedLines -join "`n"
$documents = @([regex]::Split($rendered, '(?m)^---\s*\r?\n') | Where-Object { $_.Trim() })

$config = Get-Resource $documents 'ConfigMap' 'getlink-dtd-config'
Assert-Line $config 'FRONTEND_BASE_URL: "https://getlink-azure.dongtaiduc.me"' 'the existing public app URL must be retained'
Assert-Line $config 'REFRESH_COOKIE_SECURE: "true"' 'refresh cookies must remain secure'
Assert-Line $config 'API_GATEWAY_URL: http://getlink-dtd-api-gateway:8080' 'frontend-to-gateway service identity must be retained'
Assert-Line $config 'AUTH_SERVICE_URL: http://getlink-dtd-auth-service:8081' 'auth service identity must be retained'
Assert-Line $config 'LINK_SERVICE_URL: http://getlink-dtd-link-service:8082' 'link service identity must be retained'

foreach ($component in @('frontend', 'api-gateway', 'auth-service', 'link-service')) {
    $deployment = Get-Resource $documents 'Deployment' "getlink-dtd-$component"
    Assert-Line $deployment "image: `"ghcr.io/dongtaiduc04-star/getlink-dtd-${component}:$tag`"" "existing $component GHCR package must be retained"
    Assert-Line $deployment 'app.kubernetes.io/instance: getlink-dtd' 'the existing release selector must be retained'
    Assert-Line $deployment '- name: ghcr-pull-secret' 'the existing registry Secret reference must be retained'
    $null = Get-Resource $documents 'Service' "getlink-dtd-$component"
    if ($component -in @('auth-service', 'link-service')) {
        Assert-Line $deployment 'name: getlink-dtd-secrets' 'the existing application Secret reference must be retained'
        Assert-Line $deployment 'key: jwt-secret' 'the JWT Secret key must be retained'
    }
}

$auth = Get-Resource $documents 'Deployment' 'getlink-dtd-auth-service'
Assert-Line $auth 'value: "jdbc:mysql://getlink-dtd-mysql:3306/authdb"' 'the existing auth database service/name must be retained'
Assert-Line $auth 'key: auth-db-password' 'the auth database Secret key must be retained'
$link = Get-Resource $documents 'Deployment' 'getlink-dtd-link-service'
Assert-Line $link 'value: "jdbc:mysql://getlink-dtd-mysql:3306/linkdb"' 'the existing link database service/name must be retained'
Assert-Line $link 'key: link-db-password' 'the link database Secret key must be retained'
Assert-Line $link 'claimName: getlink-dtd-avatars' 'the existing avatar PVC must be retained'
Assert-Line $link 'replicas: 1' 'Link Service must retain one replica for the ReadWriteOnce avatar volume'

$mysql = Get-Resource $documents 'StatefulSet' 'getlink-dtd-mysql'
Assert-Line $mysql 'serviceName: getlink-dtd-mysql' 'the existing MySQL StatefulSet identity must be retained'
Assert-Line $mysql 'name: getlink-dtd-secrets' 'the existing MySQL Secret reference must be retained'
Assert-Line $mysql 'key: mysql-root-password' 'the MySQL root Secret key must be retained'
Assert-Line $mysql '- name: data' 'the existing MySQL claim template name must be retained'
Assert-Line $mysql 'storageClassName: "local-path"' 'MySQL must retain local-path storage'
Assert-Line $mysql 'storage: 8Gi' 'the recorded MySQL volume size must be retained'
Assert-Line $mysql '- ReadWriteOnce' 'the recorded MySQL access mode must be retained'

$avatars = Get-Resource $documents 'PersistentVolumeClaim' 'getlink-dtd-avatars'
Assert-Line $avatars 'storageClassName: "local-path"' 'avatars must retain local-path storage'
Assert-Line $avatars 'storage: 2Gi' 'the recorded avatar volume size must be retained'
Assert-Line $avatars '- ReadWriteOnce' 'the recorded avatar access mode must be retained'
Assert-Line $avatars 'helm.sh/resource-policy: keep' 'the avatar retention annotation must be retained'
Assert-Line $avatars 'argocd.argoproj.io/sync-options: Delete=false' 'the avatar Argo retention annotation must be retained'

$ingress = Get-Resource $documents 'Ingress' 'getlink-dtd'
Assert-Line $ingress 'ingressClassName: traefik' 'the existing Traefik ingress class must be retained'
Assert-Line $ingress 'traefik.ingress.kubernetes.io/router.entrypoints: web' 'the existing Cloudflare-to-Traefik entrypoint must be retained'
Assert-Line $ingress '- host: "getlink-azure.dongtaiduc.me"' 'the existing hostname must be retained'
Assert-Contract ($ingress -notmatch '(?m)^\s+tls:') 'TLS terminates at the existing Cloudflare Tunnel, not a new chart TLS Secret'
Assert-Contract ($rendered -notmatch '(?m)^kind:\s*(?:Secret|Namespace)\s*$') 'the chart must not create a replacement namespace or credential Secret'
Assert-Contract ($rendered -notmatch 'example-owner|replace-with-your-image-tag|getlink-dtd-v1') 'the Azure render must not contain publication placeholders or a second v1 resource identity'

Write-Output 'AZURE HELM CONTRACT PASSED: existing getlink-dtd resources; one immutable image SHA; no cluster, registry or cloud calls.'
if ($RunNegativeTests) { Write-Output 'AZURE HELM NEGATIVE TESTS PASSED: latest, placeholder and mixed-SHA releases rejected.' }
