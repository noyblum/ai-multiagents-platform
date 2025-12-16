import json

def handler(event, context):
    """
    Lambda handler for API documentation endpoint.
    
    Returns API documentation and available endpoints.
    """
    documentation = {
        'service': 'AI Agents Platform API',
        'version': '1.0.0',
        'description': 'Serverless API for AI Agent interactions powered by AWS Bedrock',
        'endpoints': {
            'GET /': {
                'description': 'API documentation (this page)',
                'authentication': False
            },
            'GET /health': {
                'description': 'Health check endpoint',
                'authentication': False
            },
            'POST /api/login': {
                'description': 'User authentication',
                'authentication': False,
                'body': {
                    'email': 'string (required)',
                    'password': 'string (required)'
                },
                'response': {
                    'success': 'boolean',
                    'token': 'JWT token string',
                    'user': {
                        'id': 'string',
                        'email': 'string',
                        'name': 'string'
                    }
                }
            },
            'GET /api/agents': {
                'description': 'List available AI agents',
                'authentication': True,
                'headers': {
                    'Authorization': 'Bearer <jwt_token>'
                },
                'response': {
                    'success': 'boolean',
                    'agents': 'array of agent objects'
                }
            },
            'POST /api/chat': {
                'description': 'Chat with AI agents',
                'authentication': True,
                'headers': {
                    'Authorization': 'Bearer <jwt_token>'
                },
                'body': {
                    'agentType': 'string (generic|coding|financial|supervisor)',
                    'message': 'string (required)',
                    'sessionId': 'string (optional, for conversation context)'
                },
                'response': {
                    'success': 'boolean',
                    'response': 'string (agent response)',
                    'sessionId': 'string',
                    'agentType': 'string'
                }
            }
        },
        'agents': [
            {
                'id': 'generic',
                'name': 'Generic Agent',
                'description': 'General conversation and questions',
                'icon': '💬'
            },
            {
                'id': 'coding',
                'name': 'Coding Agent',
                'description': 'Programming and software development',
                'icon': '💻'
            },
            {
                'id': 'financial',
                'name': 'Financial Agent',
                'description': 'Financial advice and planning',
                'icon': '💰'
            },
            {
                'id': 'supervisor',
                'name': 'Supervisor Agent',
                'description': 'Auto-routes to the best agent',
                'icon': '🎯'
            }
        ],
        'authentication': {
            'type': 'JWT (JSON Web Token)',
            'header': 'Authorization: Bearer <token>',
            'expiry': '24 hours',
            'note': 'Obtain token via POST /api/login'
        },
        'test_accounts_note': 'Test accounts are seeded during deployment. Contact your administrator for credentials.',
        'cors': {
            'enabled': True,
            'allowed_origins': '*',
            'allowed_methods': 'GET, POST, OPTIONS',
            'allowed_headers': 'Content-Type, Authorization'
        },
        'infrastructure': {
            'compute': 'AWS Lambda (Python 3.12)',
            'api': 'AWS API Gateway (HTTP API)',
            'ai': 'AWS Bedrock (Claude 3 Sonnet)',
            'database': 'Amazon DynamoDB',
            'frontend': 'S3 + CloudFront',
            'authentication': 'JWT with bcrypt password hashing'
        }
    }
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
        },
        'body': json.dumps(documentation, indent=2)
    }
