# Fix-DockerKubernetes.ps1
# Script para solucionar el problema de Kubernetes en Docker Desktop v4.58.0
# Uso: .\Fix-DockerKubernetes.ps1

Write-Host "Deteniendo Docker Desktop..." -ForegroundColor Yellow
Stop-Process -Name "Docker Desktop" -Force -ErrorAction SilentlyContinue

Write-Host "Esperando a que termine completamente..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "Limpiando configuración corrupta..." -ForegroundColor Yellow
Remove-Item -Path "$env:APPDATA\Docker" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:LOCALAPPDATA\Docker" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:USERPROFILE\.kube" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Iniciando Docker Desktop..." -ForegroundColor Yellow
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

Write-Host "`nDocker Desktop reiniciado." -ForegroundColor Green
Write-Host "Espera 2-3 minutos y luego:" -ForegroundColor Cyan
Write-Host "1. Abre Docker Desktop" -ForegroundColor Cyan
Write-Host "2. Ve a Settings → Kubernetes" -ForegroundColor Cyan
Write-Host "3. Activa 'Enable Kubernetes'" -ForegroundColor Cyan
Write-Host "4. Espera 5-10 minutos a que descargue e inicie" -ForegroundColor Cyan
