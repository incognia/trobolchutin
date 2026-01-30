# Troubleshooting: Kubernetes en Docker Desktop no inicia

**Fecha**: 27 de enero de 2026, 22:57 CST  
**Sistema**: Windows 11  
**Docker Desktop**: v4.58.0 (216728)  
**Kubernetes**: v1.34.1

## Síntomas

- Kubernetes habilitado en Docker Desktop pero no termina de iniciar
- `kubectl cluster-info` se queda colgado sin respuesta
- `kubectl get nodes` falla con timeout y errores EOF
- Múltiples resets de Kubernetes desde la interfaz de Docker Desktop no resuelven el problema

## Diagnóstico

### 1. Verificación inicial

```powershell
docker version  # ✓ Docker funciona correctamente
kubectl version --client  # ✓ kubectl instalado (v1.34.1)
kubectl cluster-info  # ✗ Se cuelga indefinidamente
```

### 2. Verificación de conectividad

```powershell
# El puerto 6443 está escuchando
netstat -ano | Select-String ":6443"
# Resultado: Puerto en LISTENING (proceso 30932)

# Múltiples conexiones en TIME_WAIT indican intentos fallidos
TCP    127.0.0.1:6443         127.0.0.1:52523        TIME_WAIT
```

### 3. Inspección dentro de la VM de Docker Desktop

```powershell
# Acceso a la VM
docker run --rm --privileged --pid=host alpine:latest nsenter -t 1 -m -u -n -i -- sh

# Verificación de pods
crictl pods
# Resultado: Sin pods corriendo (solo encabezados)

# Verificación de kubelet
ps aux | grep kubelet
# Resultado: ✗ kubelet NO está corriendo

# Verificación de manifiestos estáticos
ls -la /etc/kubernetes/manifests/
# Resultado: ✓ Manifiestos presentes (etcd, apiserver, controller, scheduler)
```

### 4. Análisis de logs

```powershell
# Logs de inicialización de la VM
Get-Content "$env:LOCALAPPDATA\Docker\log\vm\init.log" -Tail 50

# Resultado: Loop infinito verificando que pods de Kubernetes estén corriendo
# "checking kubernetes pods are running: map[coredns:... kube-apiserver:... kube-controller-manager:...]"
```

### 5. Causa raíz identificada

**Kubelet no está siendo iniciado por Docker Desktop**, lo que impide que:
- Los pods estáticos definidos en `/etc/kubernetes/manifests/` se ejecuten
- El API server arranque
- El cluster funcione

Esto es causado por **corrupción en la configuración de Docker Desktop**.

## Solución aplicada

### Limpieza completa de configuración

```powershell
# 1. Detener Docker Desktop
Stop-Process -Name "Docker Desktop" -Force

# 2. Esperar a que termine completamente
Start-Sleep -Seconds 3

# 3. Eliminar toda la configuración
Remove-Item -Path "$env:APPDATA\Docker" -Recurse -Force
Remove-Item -Path "$env:LOCALAPPDATA\Docker" -Recurse -Force
Remove-Item -Path "$env:USERPROFILE\.kube" -Recurse -Force

# 4. Reiniciar Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# 5. Esperar 2-3 minutos a que Docker Desktop inicie
# 6. Habilitar Kubernetes desde Settings → Kubernetes → Enable Kubernetes
# 7. Esperar 5-10 minutos a que descargue e inicie por primera vez
```

## Verificación de la solución

```powershell
# Verificar cluster
kubectl cluster-info
# Resultado: ✓ Kubernetes control plane is running at https://kubernetes.docker.internal:6443

# Verificar nodos
kubectl get nodes
# Resultado: ✓ docker-desktop   Ready    control-plane   15s   v1.34.1

# Verificar pods del sistema
kubectl get pods -A
# Resultado: ✓ Todos los pods iniciando correctamente
# - coredns: Running
# - etcd: Running
# - kube-apiserver: Running
# - kube-controller-manager: Running
# - kube-scheduler: Running
# - kube-proxy: Running
```

## Alternativas no funcionales

Las siguientes acciones NO resolvieron el problema:
- Reset de Kubernetes desde la interfaz de Docker Desktop (múltiples intentos)
- Reinicio de Docker Desktop sin limpiar configuración
- Deshabilitar y reactivar Kubernetes

## Soluciones alternativas

Si la limpieza de configuración no funciona:

### Opción 1: Desinstalación completa de Docker Desktop

```powershell
# Desinstalar desde Configuración → Aplicaciones
# Reinstalar desde https://www.docker.com/products/docker-desktop
```

### Opción 2: Alternativas a Docker Desktop para Kubernetes

- **minikube**: Cluster local de Kubernetes
- **kind** (Kubernetes in Docker): Clusters en contenedores
- **k3d**: k3s en Docker
- **Rancher Desktop**: Alternativa completa a Docker Desktop

## Comandos útiles para diagnóstico

```powershell
# Ver procesos de Docker
Get-Process | Where-Object {$_.ProcessName -like "*docker*"}

# Ver logs recientes de Docker Desktop
Get-Content "$env:LOCALAPPDATA\Docker\log\host\*.log" -Tail 50

# Verificar puerto del API server
netstat -ano | Select-String ":6443"

# Acceder a la VM de Docker Desktop
docker run --rm --privileged --pid=host alpine:latest nsenter -t 1 -m -u -n -i -- sh

# Dentro de la VM: verificar pods
crictl pods

# Dentro de la VM: verificar procesos de Kubernetes
ps aux | grep kube
```

## Lecciones aprendidas

1. Los resets desde la interfaz de Docker Desktop no siempre limpian la configuración corrupta
2. La ausencia de kubelet es invisible desde Windows, requiere inspección de la VM
3. Los logs de `init.log` muestran loops de verificación pero no el error raíz
4. La limpieza manual de directorios de configuración es más efectiva que los resets integrados
5. El puerto 6443 puede estar escuchando pero el API server no funcional (zombie process)

## Referencias

- Docker Desktop para Windows: https://docs.docker.com/desktop/windows/
- Kubernetes en Docker Desktop: https://docs.docker.com/desktop/kubernetes/
- crictl (Container Runtime Interface CLI): https://github.com/kubernetes-sigs/cri-tools
