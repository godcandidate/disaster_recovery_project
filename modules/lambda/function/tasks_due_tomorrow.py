import pymysql
import os
import datetime
import json

# Environment Variables
DB_HOST = os.environ['DB_HOST']
DB_USER = os.environ['DB_USER']
DB_PASSWORD = os.environ['DB_PASSWORD']
DB_NAME = os.environ['DB_NAME']
ENABLED = os.environ.get('ENABLED', 'true').lower() == 'true'

def lambda_handler(event, context):
    # Check if the function is enabled (for DR region, this will be set to false)
    if not ENABLED:
        print("Function is disabled in this region")
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Function is disabled in this region"})
        }
    
    connection = pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )
    
    due_date = (datetime.date.today() + datetime.timedelta(days=1)).isoformat()
    
    try:
        with connection.cursor() as cursor:
            sql = "SELECT * FROM tasks WHERE date = %s"
            cursor.execute(sql, (due_date,))
            result = cursor.fetchall()
            
            # Convert datetime objects to strings for JSON serialization
            for task in result:
                for key, value in task.items():
                    if isinstance(value, datetime.datetime):
                        task[key] = value.isoformat()
                    elif isinstance(value, datetime.date):
                        task[key] = value.isoformat()
            
            return {
                "statusCode": 200,
                "body": json.dumps(result)
            }
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
    finally:
        connection.close()
