# Entorno de desarrollo de Odoo 20 para Windows

Este repositorio proporciona un entorno local para desarrollar y probar módulos de Odoo 20 en Windows. Utiliza contenedores de WSL y scripts de PowerShell para crear y administrar Odoo y PostgreSQL.

La aplicación estará disponible en [http://localhost:8069](http://localhost:8069) cuando los contenedores estén en ejecución.

## Componentes

- **Odoo 20.0**, en el contenedor `odoo_app`
- **PostgreSQL 18**, en el contenedor `odoo_data`
- La red de contenedores `odoo_network`
- [addons](./addons/), para los módulos personalizados
- [config/odoo.conf](./config/odoo.conf), configuración de Odoo
- Scripts de PowerShell para configurar, iniciar, detener y eliminar el entorno

## Requisitos

- Windows con WSL y la función de contenedores de WSL habilitada
- Git
- `wslc.exe`, disponible en `PATH` después de instalar los contenedores de WSL
- Conexión a Internet para descargar las imágenes de Odoo y PostgreSQL

### Instalar WSL

En PowerShell, instala WSL sin una distribución de Linux y descarga los componentes directamente:

```powershell
wsl --install --no-distribution --web-download
```

Reinicia Windows si el instalador lo solicita. Los contenedores de WSL deberian estar habilitados, para comprobarlo, abre una nueva terminal de PowerShell y utiliza el comando:

```powershell
wslc.exe --version
```

> [!TIP]
> Si ya conoces Docker, muchos comandos de `wslc.exe` te resultarán familiares.

## Instalación e inicio

1. Clona el repositorio y cambia al directorio del proyecto:

   ```powershell
   git clone https://github.com/RenatoMonroy/odoo-dev-windows.git odoo-workspace
   cd odoo-workspace
   ```

2. Crea la red y los contenedores:

   ```powershell
   .\setup.ps1
   ```

   El script crea los recursos que faltan e informa si la red o los contenedores ya existen.

3. Inicia los contenedores que no estén en ejecución:

   ```powershell
   .\start.ps1
   ```

   Los contenedores que ya estén en ejecución se omiten.

4. Abre [http://localhost:8069](http://localhost:8069) y crea o selecciona una base de datos.

Ejecuta los scripts desde la carpeta raíz del repositorio para que las rutas de configuración y addons se resuelvan correctamente.

## Comandos diarios

| Comando | Descripción |
| --- | --- |
| `.\setup.ps1` | Crea la red y los contenedores que falten. |
| `.\start.ps1` | Inicia los contenedores detenidos; omite los que ya están en ejecución. |
| `.\stop.ps1` | Detiene los contenedores en ejecución; omite los detenidos o inexistentes. |
| `.\restore.ps1` | Detiene y elimina los contenedores existentes y elimina la red si existe. |

Los recursos se llaman `odoo_app`, `odoo_data` y `odoo_network`.

## Desarrollo de addons

Coloca cada módulo en su propia carpeta dentro de [addons](./addons/). La carpeta se monta en el contenedor de Odoo para que la aplicación pueda acceder a los archivos locales.

Estructura mínima de ejemplo:

```text
addons/
└── mi_addon/
    ├── __init__.py
    └── __manifest__.py
```

Para instalar o actualizar un módulo:

1. Abre Odoo en [http://localhost:8069](http://localhost:8069).
2. Activa el modo desarrollador.
3. En **Aplicaciones**, actualiza la lista de aplicaciones y luego instala o actualiza el módulo.

Para consultar los registros:

```powershell
wslc.exe logs odoo_app
wslc.exe logs odoo_data
```

## Configuración de la base de datos

Estos valores se usan para el entorno de desarrollo local:

| Parámetro | Valor |
| --- | --- |
| Host | `odoo_data` (desde la red de contenedores) |
| Usuario | `odoo` |
| Contraseña | `odoo` |
| Puerto de PostgreSQL | `5432` |
| Puerto de Odoo | `8069` |

Estas credenciales son únicamente para desarrollo local; no las uses en un entorno de producción.

## Recrear el entorno

Para eliminar los recursos del entorno y volver a crearlos:

```powershell
.\restore.ps1
.\setup.ps1
.\start.ps1
```

`restore.ps1` elimina los contenedores de Odoo y PostgreSQL y la red compartida. Asegúrate de respaldar cualquier dato que quieras conservar antes de ejecutarlo.

## Solución de problemas

### `wslc.exe` no se encuentra en `PATH`

Abre una nueva ventana de PowerShell después de instalar o habilitar los contenedores de WSL y comprueba que `wslc.exe --version` funciona.

### Falta un contenedor

Ejecuta `.\setup.ps1` desde la carpeta raíz para crear los recursos que faltan y luego `.\start.ps1`.

### El puerto 8069 ya está en uso

Detén el proceso o contenedor que está usando el puerto local `8069`, o modifica la asignación del puerto en `setup.ps1`.

### Odoo o PostgreSQL no inicia

Comprueba el estado y los registros de los contenedores:

```powershell
wslc.exe list --all
wslc.exe logs odoo_app
wslc.exe logs odoo_data
```

## Contribuir

¡Las contribuciones son bienvenidas! Para proponer un cambio:

1. Haz un fork del [repositorio](https://github.com/RenatoMonroy/odoo-dev-windows).
2. Crea una rama para tu cambio.
3. Realiza y prueba los cambios en tu entorno local.
4. Abre un pull request describiendo qué cambiaste y cómo lo verificaste.

Si encuentras un error o tienes una sugerencia, [abre un issue](https://github.com/RenatoMonroy/odoo-dev-windows/issues).
