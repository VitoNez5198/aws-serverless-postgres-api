import json
import psycopg2
import os

def lambda_handler(event, context):
    try:
        # 1. Recuperar secretos y configuraciones desde las Variables de Entorno de Lambda
        # Esto evita hardcodear (escribir directamente) contraseñas en el código
        db_host = os.environ['DB_HOST']
        db_name = os.environ['DB_NAME']
        db_user = os.environ['DB_USER']
        db_pass = os.environ['DB_PASS']
        
        # 2. Establecer la conexión con Amazon RDS (PostgreSQL)
        conn = psycopg2.connect(
            host=db_host, 
            database=db_name, 
            user=db_user, 
            password=db_pass
        )
        cur = conn.cursor()
        
        # 3. Ejecutar consulta de prueba para validar la conectividad
        cur.execute("SELECT version();")
        db_version = cur.fetchone()[0]
        
        # 4. Cerrar conexiones para no saturar la base de datos
        cur.close()
        conn.close()
        
        # 5. Retornar respuesta HTTP 200 (Éxito) con formato JSON
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*' # Permite peticiones desde cualquier origen (CORS)
            },
            'body': json.dumps({
                'mensaje': '¡Conexión Serverless exitosa a RDS PostgreSQL!',
                'version_bd': db_version
            })
        }
        
    except Exception as e:
        # En caso de error (timeout, credenciales inválidas, etc.), retornar HTTP 500
        return {
            'statusCode': 500, 
            'body': json.dumps({'error': str(e)})
        }