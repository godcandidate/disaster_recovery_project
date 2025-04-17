import os
import json
import datetime

# Environment Variables
DB_HOST = os.environ.get('DB_HOST', '')
DB_USER = os.environ.get('DB_USER', '')
DB_PASSWORD = os.environ.get('DB_PASSWORD', '')
DB_NAME = os.environ.get('DB_NAME', '')
ENABLED = os.environ.get('ENABLED', 'true').lower() == 'true'

def lambda_handler(event, context):
    # Check if the function is enabled (for DR region, this will be set to false)
    if not ENABLED:
        print("Function is disabled in this region")
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Function is disabled in this region"})
        }
    
    # Since we don't have pymysql, we'll simulate the database query
    print(f"Would connect to database at {DB_HOST} as {DB_USER}")
    print(f"Would query tasks due tomorrow from database {DB_NAME}")
    
    # Simulate database results
    tomorrow = (datetime.datetime.now() + datetime.timedelta(days=1)).strftime("%Y-%m-%d")
    
    # Mock data
    mock_tasks = [
        {"id": 1, "title": "Complete DR testing", "date": tomorrow, "status": "pending"},
        {"id": 2, "title": "Review backup strategy", "date": tomorrow, "status": "pending"},
        {"id": 3, "title": "Update documentation", "date": tomorrow, "status": "pending"}
    ]
    
    print(f"Found {len(mock_tasks)} tasks due tomorrow")
    
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "This is a simplified version without pymysql dependency",
            "db_connection": {
                "host": DB_HOST,
                "user": DB_USER,
                "database": DB_NAME
            },
            "tasks_due_tomorrow": mock_tasks
        })
    }
