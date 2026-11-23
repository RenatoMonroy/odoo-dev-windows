# Entorno de desarrollo de Odoo 20 para Windows

Una configuracion pequeña y sencilla para Windows que permite crear y probar addons de Odoo. Utiliza contenedores de Microsoft WSL y esta diseñada para pasar desde un clon nuevo a una instancia local de Odoo en ejecucion usando solamente comandos de PowerShell.

Odoo estara disponible en [http://localhost:8069](http://localhost:8069) despues de completar la configuracion y el inicio.

## Que incluye

- **Odoo 20.0** ejecutandose en el contenedor `odoo_app`
- **PostgreSQL 18** ejecutandose en el contenedor `odoo_data`
- Una red aislada `odoo_network` para los contenedores
- Una carpeta local [addons](./addons/) para los addons personalizados
- Una [configuracion compartida de Odoo](./config/odoo.conf)
- Scripts de PowerShell para la configuracion y el uso diario

## Requisitos previos

Necesitas:

- Windows con WSL y los contenedores de WSL habilitados
- `wslc.exe` disponible en `PATH` (se instala con los contenedores de WSL)
- Acceso a Internet para descargar las imagenes de contenedor de Odoo y PostgreSQL

Puedes comprobar la interfaz de linea de comandos de contenedores abriendo PowerShell y ejecutando:

```powershell
wslc.exe --version
```

Manten PowerShell abierto en el directorio del repositorio porque los scripts usan el directorio actual para las carpetas montadas.

## Inicio rapido

1. Clona este repositorio y abre una terminal de PowerShell en su carpeta raiz.

   ```powershell
   git clone <url-del-repositorio>
   cd odoo
   ```

2. Crea los contenedores.

   ```powershell
   .\setup.ps1
   ```

   Esto crea la red, inicia PostgreSQL 18 y crea el contenedor de Odoo 20.0. Puedes ejecutar la configuracion varias veces: los contenedores y la red existentes se omiten.

3. Abre [http://localhost:8069](http://localhost:8069) y crea una base de datos o conectate a una existente.

## Comandos diarios

Ejecuta estos comandos desde la raiz del repositorio.

| Comando | Proposito |
| --- | --- |
| `.\setup.ps1` | Crea la red y los contenedores en una configuracion nueva o añade los elementos que falten. |
| `.\start.ps1` | Inicia ambos contenedores despues de haberlos detenido. |
| `.\stop.ps1` | Detiene ambos contenedores sin eliminar los datos. |
| `.\restore.ps1` | Elimina los contenedores de Odoo y PostgreSQL y la red compartida. |

Los nombres de los contenedores son `odoo_app`, `odoo_data` y `odoo_network`.

## Desarrollo de addons

Coloca cada addon en su propia carpeta dentro de [addons](./addons/). Esta carpeta se monta dentro del contenedor de Odoo, por lo que los cambios en los archivos estan disponibles de inmediato.

Un addon nuevo necesita la estructura normal de addons de Odoo, por ejemplo:

```text
addons/
└── mi_addon/
    ├── __init__.py
    └── __manifest__.py
```

Despues de añadir o cambiar un addon:

1. Abre Odoo en [http://localhost:8069](http://localhost:8069).
2. Activa el modo desarrollador.
3. Abre **Apps**, actualiza la lista de aplicaciones y luego instala o actualiza el addon.

Tambien puedes usar las opciones **`-u`** y **`-d`** de Odoo desde una terminal del contenedor si prefieres las actualizaciones por linea de comandos. Usa `wslc.exe logs odoo_app` para ver el registro de la aplicacion.

## Estructura del repositorio

```text
.
├── addons/          Codigo fuente de addons personalizados montado en Odoo
├── config/
│   └── odoo.conf    Configuracion de la base de datos y los addons de Odoo
├── setup.ps1        Crea la red y los contenedores de la base de datos y la aplicacion
├── start.ps1        Inicia los contenedores existentes
├── stop.ps1         Detiene los contenedores existentes
├── restore.ps1      Elimina los contenedores y la red para una reconstruccion limpia
└── README.md
```

## Configuracion predeterminada de la base de datos

La configuracion de desarrollo utiliza estos valores locales:

| Parametro | Valor |
| --- | --- |
| Host | `odoo_data` (dentro de la red de contenedores) |
| Usuario de la base de datos | `odoo` |
| Contraseña de la base de datos | `odoo` |
| Puerto de PostgreSQL | `5432` |
| Puerto de Odoo | `8069` |

Estas credenciales son solo para desarrollo local. Cambialas antes de usar esta configuracion fuera de un entorno de desarrollo aislado.

## Reinicio del entorno

Para eliminar los contenedores y la red y empezar de nuevo:

```powershell
.\restore.ps1
.\setup.ps1
```

**Advertencia:** `restore.ps1` detiene y elimina `odoo_app`, `odoo_data` y `odoo_network`. No elimina el repositorio ni el codigo fuente de los addons, pero si elimina el contenido de las bases de datos que esta dentro de los contenedores.

## Solucion de problemas

### `wslc.exe no se encontro en PATH`

Abre una nueva ventana de PowerShell despues de instalar o habilitar los contenedores de WSL y confirma que `wslc.exe --version` funciona.

### Faltan contenedores

Ejecuta `.\setup.ps1` desde la raiz del repositorio. La configuracion puede recrear los contenedores que faltan sin modificar los contenedores existentes que encuentre.

### El puerto 8069 ya esta en uso

Deten el proceso o contenedor que esta usando el puerto local `8069`, o cambia la asignacion del puerto de Odoo en `setup.ps1`.

### Odoo o PostgreSQL no inicia

Comprueba el estado de los contenedores y los registros:

```powershell
wslc.exe list --all
wslc.exe logs odoo_app
wslc.exe logs odoo_data
```
