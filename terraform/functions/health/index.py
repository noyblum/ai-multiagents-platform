import json
from datetime import datetime

def handler(event, context):
    """
    Lambda handler for health check endpoint.
    
    Returns simple health status without authentication.
    """
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
        },
        'body': json.dumps({
            'status': 'healthy',
            'service': 'AI Agents Platform',
            'timestamp': datetime.utcnow().isoformat(),
            'version': '1.0.0'
        })
    }
