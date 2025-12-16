import json
import os
import boto3
import bcrypt
import jwt
from datetime import datetime, timedelta
from decimal import Decimal

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
users_table_name = os.environ.get('USERS_TABLE_NAME', 'ai-agents-platform-users-dev')
users_table = dynamodb.Table(users_table_name)

# JWT configuration
JWT_SECRET = os.environ.get('JWT_SECRET', 'your-secret-key-change-in-production')
EMAIL_DOMAIN = os.environ.get('EMAIL_DOMAIN', 'blumenfeld.com')

def handler(event, context):
    """
    Lambda handler for user login with JWT authentication.
    
    Validates credentials against DynamoDB users table and returns JWT token.
    Passwords are stored as bcrypt hashes for security.
    """
    print(f'Login request received: {json.dumps(event)}')
    
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        email = body.get('email', '').strip()
        password = body.get('password', '')
        
        # Validate input
        if not email or not password:
            return create_response(400, {
                'success': False,
                'error': 'Email and password are required'
            })
        
        # Query user from DynamoDB by email
        user = get_user_by_email(email)
        
        if not user:
            # User not found - return generic error for security
            return create_response(401, {
                'success': False,
                'error': 'Invalid email or password'
            })
        
        # Verify password using bcrypt
        password_hash = user.get('password_hash') or user.get('passwordHash', '')
        
        if not verify_password(password, password_hash):
            # Password mismatch
            return create_response(401, {
                'success': False,
                'error': 'Invalid email or password'
            })
        
        # Generate JWT token
        token = generate_jwt_token(user)
        
        # Update last login time
        update_last_login(user['userId'])
        
        return create_response(200, {
            'success': True,
            'token': token,
            'user': {
                'id': user['userId'],
                'email': user['email'],
                'name': user.get('name', email.split('@')[0])
            }
        })
        
    except Exception as error:
        print(f'Error in login handler: {str(error)}')
        return create_response(500, {
            'success': False,
            'error': 'Internal server error'
        })


def get_user_by_email(email):
    """
    Query user from DynamoDB by email using GSI.
    
    Args:
        email: User's email address
        
    Returns:
        User dict if found, None otherwise
    """
    try:
        response = users_table.query(
            IndexName='email-index',
            KeyConditionExpression='email = :email',
            ExpressionAttributeValues={
                ':email': email
            },
            Limit=1
        )
        
        items = response.get('Items', [])
        return items[0] if items else None
        
    except Exception as error:
        print(f'Error querying user by email: {str(error)}')
        return None


def verify_password(plain_password, password_hash):
    """
    Verify password against bcrypt hash.
    
    Args:
        plain_password: Plain text password from user
        password_hash: Bcrypt hash from database
        
    Returns:
        True if password matches, False otherwise
    """
    try:
        # Convert string hash to bytes if needed
        if isinstance(password_hash, str):
            password_hash = password_hash.encode('utf-8')
        
        # Convert plain password to bytes
        plain_password_bytes = plain_password.encode('utf-8')
        
        # Verify password
        return bcrypt.checkpw(plain_password_bytes, password_hash)
        
    except Exception as error:
        print(f'Error verifying password: {str(error)}')
        return False


def generate_jwt_token(user):
    """
    Generate JWT token for authenticated user.
    
    Args:
        user: User dict from database
        
    Returns:
        JWT token string
    """
    payload = {
        'userId': user['userId'],
        'email': user['email'],
        'iat': datetime.utcnow(),
        'exp': datetime.utcnow() + timedelta(hours=24)
    }
    
    token = jwt.encode(payload, JWT_SECRET, algorithm='HS256')
    return token


def update_last_login(user_id):
    """
    Update user's last login timestamp in DynamoDB.
    
    Args:
        user_id: User's ID
    """
    try:
        users_table.update_item(
            Key={'userId': user_id},
            UpdateExpression='SET lastLogin = :timestamp',
            ExpressionAttributeValues={
                ':timestamp': datetime.utcnow().isoformat()
            }
        )
    except Exception as error:
        print(f'Error updating last login: {str(error)}')


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
