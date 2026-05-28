# ☁️ Serverless Postgres API con Workarounds Zero-Trust

Este repositorio documenta la arquitectura, el despliegue y la resolución de problemas (troubleshooting) de una API Serverless gestionada en AWS. El proyecto integra **AWS Lambda (Python 3.11)** y **Amazon RDS (PostgreSQL)** para crear un backend robusto.

Más allá de ser un despliegue estándar, este proyecto demuestra habilidades avanzadas de ingeniería en la nube al sortear políticas de seguridad restrictivas (IAM Zero-Trust) y problemas de dependencias en tiempo de ejecución.

---

## 🏗️ Arquitectura y Flujo de Datos

A continuación se detalla la arquitectura implementada, incluyendo el flujo efímero utilizado para sortear los bloqueos de empaquetado:

```mermaid
graph LR
    User((🌐 Cliente / Navegador))
    
    subgraph AWS_Cloud ["AWS Cloud"]
        
        subgraph CI_CD ["Workaround CI/CD (Efímero)"]
            EC2["💻 EC2 Instance<br>Amazon Linux"] -.->|"1. Empaqueta psycopg2 (Py 3.11)<br>2. AWS CLI update-code"| Lambda
        end
        
        Lambda["⚡ AWS Lambda<br>Capa de Cómputo"]
        
        subgraph VPC ["Amazon VPC (Red)"]
            SG["🛡️ Security Group<br>Inbound: TCP 5432"]
            RDS[("🐘 Amazon RDS<br>PostgreSQL")]
        end
        
    end

    User -- "HTTPS<br>(Lambda Function URL)" --> Lambda
    Lambda -- "Petición SQL<br>(Variables de Entorno)" --> SG
    SG --> RDS

    style EC2 stroke-dasharray: 5 5
```

### 🛠️ Tecnologías Utilizadas
*   **Capa de Cómputo:** `AWS Lambda` (Python 3.11).
*   **Capa de Datos:** `Amazon RDS` (PostgreSQL, Single-AZ, `db.t3.micro`).
*   **Orquestación CI/CD:** `Amazon EC2` (Temporal) & `AWS CLI`.
*   **Red y Seguridad:** `VPC Security Groups`, `Lambda Environment Variables` (manejo de secretos).
*   **Exposición Web:** `AWS Lambda Function URLs` (HTTPS nativo).

---

## 🚧 Retos de Arquitectura y Soluciones (Troubleshooting)

Durante el despliegue en un entorno con políticas IAM estrictas, surgieron bloqueos que impidieron el flujo tradicional.

### 1. Bloqueo de Dependencias y `Runtime.ImportModuleError`
*   **El Problema:** El entorno bloqueó la descarga de Lambda Layers públicas y el acceso a CloudShell. Además, el OS de compilación generaba binarios de `psycopg2` para Python 3.9, lo que provocaba un error crítico (`Runtime.ImportModuleError`) al ejecutarse en la Lambda configurada con Python 3.11.
*   **La Solución:** Se diseñó un flujo de CI/CD efímero. Se aprovisionó una instancia EC2 temporal con el script de [User Data Bash](scripts/ec2_user_data.sh). Este script instaló explícitamente Python 3.11, descargó la librería correcta (`psycopg2-binary`), comprimió el código de la [función Lambda](src/lambda_function.py) en un Deployment Package y forzó la actualización de la Lambda mediante AWS CLI. Tras el éxito, la instancia fue destruida.

### 2. Bloqueo de Amazon API Gateway
*   **El Problema:** Denegación de permisos (`apigateway:POST` denied) al intentar crear la API pública.
*   **La Solución:** Se pivotó la arquitectura hacia **AWS Lambda Function URLs**, logrando exponer el backend a internet mediante un endpoint HTTPS nativo, sin depender del servicio bloqueado y reduciendo la latencia de red.

---

## 📸 Evidencia de Configuración y Despliegue (Principal)

### 1. Base de Datos RDS Desplegada
Instancia PostgreSQL en estado "Available" con su respectivo Endpoint y Security Group (Puerto 5432).

![RDS Endpoint Desplegado](assets/1_rds_endpoint.1.png)
![RDS Endpoint Desplegado](assets/1_rds_endpoint.2.png)

### 2. Inyección Segura de Credenciales
Uso de Variables de Entorno en AWS Lambda para conectar la lógica backend con la base de datos sin exponer contraseñas en el código fuente.

![Variables de Entorno Lambda](assets/2_lambda_env_vars.png)

### 3. Validación Final (Éxito)
Petición HTTP a la Function URL desde el navegador, retornando la versión exacta del motor PostgreSQL y demostrando conectividad Serverless total.

![Respuesta de éxito del API](assets/3_success_response.png)

---

## 📂 Galería de Evidencia Extendida (Proceso y Errores)

Para ver la documentación visual detallada de los errores de IAM y el Troubleshooting, consulta las capturas correspondientes abajo:

<details>
<summary><b>❌ Error 1: Denegación de creación en Amazon API Gateway</b></summary>

Muestra el bloqueo de permisos al intentar crear una REST API de API Gateway (`err_apigateway.png`).
![Error API Gateway](assets/err_apigateway.png)
</details>

<details>
<summary><b>❌ Error 2: Bloqueo de entorno AWS CloudShell</b></summary>

Muestra el mensaje de denegación al intentar iniciar CloudShell en la consola de AWS (`err_cloudshell.png`).
![Error CloudShell](assets/err_cloudshell.png)
</details>

<details>
<summary><b>❌ Error 3: Bloqueo de uso de Lambda Layers externas</b></summary>

Bloqueo de seguridad al intentar adjuntar una capa ARN pública (`err_lambda_layer.png`).
![Error Lambda Layer](assets/err_lambda_layer.png)
</details>

<details>
<summary><b>❌ Error 4: Error de Servidor Interno (Incompatibilidad de psycopg2)</b></summary>

Error `Runtime.ImportModuleError` en los logs de CloudWatch debido a incompatibilidad de dependencias compiladas (`err_internal_server.png`).
![Error Internal Server](assets/err_internal_server.png)
</details>

<details>
<summary><b>✅ Solución: Configuración Exitosa de Lambda Function URL</b></summary>

Ajustes de la Function URL con tipo de autorización `NONE` para saltarse las restricciones de API Gateway (`sol_function_url.png`).
![Solución Function URL](assets/sol_function_url.png)
</details>

---

## 🚀 Lecciones Aprendidas y Habilidades Demostradas

*   **Resiliencia Arquitectónica:** Capacidad para rediseñar infraestructuras sobre la marcha usando alternativas nativas (Function URLs vs API Gateway).
*   **Resolución de Problemas Backend:** Diagnóstico profundo de incompatibilidades de ejecución (`Runtime.ImportModuleError`) e igualación de entornos de empaquetado/ejecución con Python y SQL.
*   **Automatización e Infraestructura:** Uso de Bash Scripting en el User Data para convertir una instancia EC2 en un servidor de despliegue automatizado.
*   **Seguridad en la Nube:** Aplicación de principios de seguridad gestionando el tráfico con Security Groups y resguardando credenciales con Environment Variables.