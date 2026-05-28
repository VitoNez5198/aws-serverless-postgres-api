#!/bin/bash
# ==============================================================================
# Script de CI/CD Efímero (Troubleshooting de Dependencias AWS Lambda)
# Propósito: Resolver el error Runtime.ImportModuleError empaquetando psycopg2 
# específicamente para Python 3.11 y actualizando Lambda vía AWS CLI.
# ==============================================================================

# 1. Preparar el entorno temporal
cd /tmp
mkdir mi-lambda && cd mi-lambda

# 2. Instalar explícitamente Python 3.11 para coincidir con el runtime de Lambda
# Esto previene problemas de binarios compilados para versiones antiguas (ej. Python 3.9)
dnf install -y python3.11 python3.11-pip zip

# 3. Descargar la librería de PostgreSQL (psycopg2) en el directorio actual
pip3.11 install psycopg2-binary -t .

# 4. Descargar el código fuente (Asumiendo que se crea el archivo aquí)
cat << 'EOF' > lambda_function.py
import json, psycopg2, os
def lambda_handler(event, context):
    try:
        conn = psycopg2.connect(
            host=os.environ['DB_HOST'], database=os.environ['DB_NAME'], 
            user=os.environ['DB_USER'], password=os.environ['DB_PASS']
        )
        cur = conn.cursor()
        cur.execute("SELECT version();")
        db_version = cur.fetchone()[0]
        cur.close(); conn.close()
        return {'statusCode': 200, 'body': json.dumps({'mensaje': 'Exito', 'version_bd': db_version})}
    except Exception as e:
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}
EOF

# 5. Comprimir todo en un Deployment Package (.zip)
zip -r ../paquete-lambda.zip .

# 6. Actualizar la función Lambda a la fuerza usando AWS CLI
aws lambda update-function-code \
    --function-name fetch-postgres-data \
    --zip-file fileb://../paquete-lambda.zip \
    --region us-west-2