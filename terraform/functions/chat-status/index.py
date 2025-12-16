import json
import boto3
import os
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['CHAT_SESSIONS_TABLE_NAME'])

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def handler(event, context):
    try:
        session_id = event['pathParameters']['sessionId']
        last_chunk_index = int(event.get('queryStringParameters', {}).get('lastChunkIndex', -1))
        
        response = table.get_item(Key={'sessionId': session_id})
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'errorMessage': 'Session not found'})
            }
        
        item = response['Item']
        all_chunks = item.get('chunks', [])
        
        # Return only new chunks since last poll
        new_chunks = all_chunks[last_chunk_index + 1:] if last_chunk_index >= 0 else all_chunks
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'status': item.get('status'),
                'routedAgentType': item.get('routedAgentType'),
                'chunks': new_chunks,
                'totalChunks': len(all_chunks),
                'response': item.get('response', ''),
                'errorMessage': item.get('errorMessage')
            }, cls=DecimalEncoder)
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'errorMessage': str(e)})
        }