import json
import os
import jwt

# JWT configuration
JWT_SECRET = os.environ.get('JWT_SECRET', 'your-secret-key-change-in-production')

# Agent metadata
AGENTS = [
    {
        'id': 'generic',
        'name': 'Generic Agent',
        'description': 'General conversation and questions',
        'icon': '💬',
        'agentId': os.environ.get('GENERIC_AGENT_ID'),
        'aliasId': os.environ.get('GENERIC_AGENT_ALIAS_ID')
    },
    {
        'id': 'coding',
        'name': 'Coding Agent',
        'description': 'Programming and software development',
        'icon': '💻',
        'agentId': os.environ.get('CODING_AGENT_ID'),
        'aliasId': os.environ.get('CODING_AGENT_ALIAS_ID')
    },
    {
        'id': 'financial',
        'name': 'Financial Agent',
        'description': 'Financial advice and planning',
        'icon': '💰',
        'agentId': os.environ.get('FINANCIAL_AGENT_ID'),
        'aliasId': os.environ.get('FINANCIAL_AGENT_ALIAS_ID')
    },
    {
        'id': 'supervisor',
        'name': 'Supervisor Agent',
        'description': 'Auto-routes to the best agent',
        'icon': '🎯',
        'agentId': os.environ.get('SUPERVISOR_AGENT_ID'),
        'aliasId': os.environ.get('SUPERVISOR_AGENT_ALIAS_ID')
    }
]


def handler(event, context):
    """
    Lambda handler for listing available Bedrock agents.
    
    Requires JWT authentication.
    Returns list of available agents with metadata.
    """
    print(f'List agents request received: {json.dumps(event)}')
    
    try:
        # Verify JWT token
        user = verify_token(event)
        print(f'Authenticated user: {user.get("email")}')
        
        # Filter out None values from agent metadata
        agents_response = [
            {k: v for k, v in agent.items() if v is not None}
            for agent in AGENTS
        ]
        
        return create_response(200, {
            'success': True,
            'agents': agents_response
        })
        
    except jwt.ExpiredSignatureError:
        return create_response(401, {
            'success': False,
            'error': 'Token has expired'
        })
    except jwt.InvalidTokenError:
        return create_response(401, {
            'success': False,
            'error': 'Invalid token'
        })
    except ValueError as error:
        return create_response(401, {
            'success': False,
            'error': str(error)
        })
    except Exception as error:
        print(f'Error in list agents handler: {str(error)}')
        return create_response(500, {
            'success': False,
            'error': 'Internal server error'
        })


def verify_token(event):
    """
    Verify JWT token from Authorization header.
    
    Args:
        event: Lambda event dict
        
    Returns:
        Decoded token payload
        
    Raises:
        ValueError: If authorization header is missing or invalid
        jwt.InvalidTokenError: If token is invalid
    """
    # Get authorization header (case-insensitive)
    auth_header = event.get('headers', {}).get('authorization') or \
                  event.get('headers', {}).get('Authorization')
    
    if not auth_header or not auth_header.startswith('Bearer '):
        raise ValueError('Missing or invalid authorization header')
    
    # Extract token (remove 'Bearer ' prefix)
    token = auth_header[7:]
    
    # Verify and decode token
    decoded = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
    return decoded


def create_response(status_code, body):
    """
    Create HTTP response with CORS headers.
    
    Args:
        status_code: HTTP status code
        body: Response body dict
        
    Returns:
        API Gateway response dict
    """
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
