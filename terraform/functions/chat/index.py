import json
import boto3
import os
import time
import jwt
import uuid
from datetime import datetime, timezone
from decimal import Decimal

# Initialize Bedrock Agent Runtime client
bedrock_agent_runtime = boto3.client(
    'bedrock-agent-runtime',
    region_name=os.environ.get('BEDROCK_REGION', os.environ.get('AWS_REGION', 'us-east-1'))
)

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['CHAT_SESSIONS_TABLE_NAME'])

# JWT configuration
JWT_SECRET = os.environ.get('JWT_SECRET', 'your-secret-key-change-in-production')


def handler(event, context):
    """
    Lambda handler for chat with Bedrock Agents.
    Returns immediately with sessionId for polling approach.
    Processes agent streaming in background and updates DynamoDB.
    
    NOTE: Always returns 200 status with error details in body for API Gateway compatibility.
    """
    print(f'Chat request received: {json.dumps(event)}')
    
    try:
        # Verify authentication
        try:
            user_id = verify_token(event)
            if not user_id:
                return create_response(200, {
                    'success': False,
                    'error': 'Authentication required',
                    'errorType': 'auth'
                })
        except Exception as auth_error:
            print(f'Auth error: {str(auth_error)}')
            return create_response(200, {
                'success': False,
                'error': str(auth_error),
                'errorType': 'auth'
            })
        
        # Parse request
        body = json.loads(event.get('body', '{}'))
        message = body.get('message', '')
        session_id = body.get('sessionId') or str(uuid.uuid4())
        requested_agent_type = body.get('agentType', 'supervisor')
        
        if not message:
            return create_response(200, {
                'success': False,
                'error': 'Message is required',
                'errorType': 'validation'
            })
        
        # Always use Supervisor Agent (it has collaborators for delegation)
        agent_id = os.environ.get('SUPERVISOR_AGENT_ID')
        agent_alias_id = os.environ.get('SUPERVISOR_AGENT_ALIAS_ID')
        
        if not agent_id or not agent_alias_id:
            return create_response(200, {
                'success': False,
                'error': 'Agent service is not configured properly',
                'errorType': 'config'
            })
        
        # Initialize session in DynamoDB with status 'processing'
        table.put_item(Item={
            'sessionId': session_id,
            'userId': user_id,
            'status': 'processing',
            'requestedAgentType': requested_agent_type,
            'message': message,
            'response': '',
            'chunks': [],
            'createdAt': datetime.now(timezone.utc).isoformat(),
            'ttl': int(time.time()) + 86400
        })
        
        # Process the agent response
        try:
            process_agent_streaming(
                agent_id=agent_id,
                agent_alias_id=agent_alias_id,
                session_id=session_id,
                message=message
            )
            
            # Return success with sessionId for polling
            return create_response(200, {
                'success': True,
                'sessionId': session_id,
                'status': 'processing',
                'message': 'Response is being processed. Poll /api/chat/status/{sessionId} for updates.'
            })
            
        except Exception as agent_error:
            error_str = str(agent_error)
            print(f'Agent processing error: {error_str}')
            
            # Check if it's a throttling error
            is_throttling = 'throttlingException' in error_str or 'ThrottlingException' in error_str or 'rate' in error_str.lower()
            
            # Update DynamoDB with error
            table.update_item(
                Key={'sessionId': session_id},
                UpdateExpression='SET #status = :status, errorMessage = :error',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'error',
                    ':error': error_str
                }
            )
            
            # Return user-friendly error message (still 200 status for API Gateway)
            if is_throttling:
                return create_response(200, {
                    'success': False,
                    'error': 'Too many requests. The AI service is temporarily rate-limited. Please wait a minute and try again.',
                    'errorType': 'throttling',
                    'sessionId': session_id,
                    'retryAfter': 60
                })
            else:
                return create_response(200, {
                    'success': False,
                    'error': f'Unable to process your request. Please try again.',
                    'errorType': 'agent_error',
                    'sessionId': session_id,
                    'details': error_str
                })
            
    except Exception as e:
        print(f'Error: {str(e)}')
        import traceback
        traceback.print_exc()
        return create_response(200, {
            'success': False,
            'error': 'An unexpected error occurred. Please try again.',
            'errorType': 'internal',
            'details': str(e)
        })


def verify_token(event):
    """Verify JWT token"""
    try:
        auth_header = event.get('headers', {}).get('authorization') or event.get('headers', {}).get('Authorization')
        if not auth_header:
            raise Exception('No authorization header')
        
        token = auth_header.replace('Bearer ', '').replace('bearer ', '')
        decoded = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
        return decoded.get('userId')
        
    except jwt.ExpiredSignatureError:
        raise Exception('Token expired')
    except jwt.InvalidTokenError:
        raise Exception('Invalid token')
    except Exception as e:
        raise Exception(f'Auth failed: {str(e)}')


def process_agent_streaming(agent_id, agent_alias_id, session_id, message):
    """
    Process Bedrock Agent streaming response.
    Updates DynamoDB progressively with chunks.
    
    The Supervisor Agent will automatically delegate to specialist agents:
    - Coding questions → Coding Agent
    - Financial questions → Financial Agent  
    - General questions → Generic Agent
    """
    print(f'Invoking Supervisor Agent: {agent_id[:8]}... (will delegate to specialists)')
    
    # Invoke the Supervisor Agent with streaming
    response = bedrock_agent_runtime.invoke_agent(
        agentId=agent_id,
        agentAliasId=agent_alias_id,
        sessionId=session_id,
        inputText=message,
        enableTrace=False
    )
    
    full_response = ''
    chunks = []
    chunk_index = 0
    
    event_stream = response.get('completion', [])
    
    for event in event_stream:
        if 'chunk' in event:
            chunk = event['chunk']
            if 'bytes' in chunk:
                chunk_text = chunk['bytes'].decode('utf-8')
                full_response += chunk_text
                chunks.append(chunk_text)
                chunk_index += 1
                
                print(f'Chunk {chunk_index}: {chunk_text[:50]}...')
                
                # Update DynamoDB every 3 chunks
                if chunk_index % 3 == 0:
                    try:
                        table.update_item(
                            Key={'sessionId': session_id},
                            UpdateExpression='SET chunks = :chunks, #resp = :resp, lastUpdated = :lastUpdated',
                            ExpressionAttributeNames={'#resp': 'response'},
                            ExpressionAttributeValues={
                                ':chunks': chunks,
                                ':resp': full_response,
                                ':lastUpdated': datetime.now(timezone.utc).isoformat()
                            }
                        )
                        print(f'Updated DynamoDB with {len(chunks)} chunks')
                    except Exception as db_error:
                        print(f'DynamoDB update error: {db_error}')
    
    # Final update
    table.update_item(
        Key={'sessionId': session_id},
        UpdateExpression='SET #status = :status, chunks = :chunks, #resp = :resp, completedAt = :completedAt',
        ExpressionAttributeNames={
            '#status': 'status',
            '#resp': 'response'
        },
        ExpressionAttributeValues={
            ':status': 'completed',
            ':chunks': chunks,
            ':resp': full_response,
            ':completedAt': datetime.now(timezone.utc).isoformat()
        }
    )
    
    print(f'Agent response completed. Total chunks: {len(chunks)}, Total length: {len(full_response)}')


def create_response(status_code, body):
    """Create HTTP response with CORS headers (always 200 for API Gateway compatibility)"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
        },
        'body': json.dumps(body, default=str)
    }
