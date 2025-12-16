#!/usr/bin/env python3
"""
Seed test users into DynamoDB with secure random passwords.
Called by Terraform as a local-exec provisioner.
"""

import os
import json
import sys
import uuid
import bcrypt
import boto3
from datetime import datetime

# Get configuration from environment
dynamodb_table = os.getenv('DYNAMODB_TABLE')
aws_region = os.getenv('AWS_REGION', 'us-east-1')
test_users_json = os.getenv('TEST_USERS_JSON')

if not dynamodb_table or not test_users_json:
    print("❌ Error: Missing required environment variables")
    sys.exit(1)

try:
    test_users = json.loads(test_users_json)
except json.JSONDecodeError as e:
    print(f"❌ Error parsing TEST_USERS_JSON: {e}")
    sys.exit(1)

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb', region_name=aws_region)
table = dynamodb.Table(dynamodb_table)

print(f"Seeding test users into DynamoDB table: {dynamodb_table}")
print("=" * 80)

try:
    for user in test_users:
        email = user.get('email')
        name = user.get('name')
        password = user.get('password')

        if not all([email, name, password]):
            print(f"⚠️  Skipping incomplete user record: {user}")
            continue

        # Hash the password with bcrypt
        hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
        user_id = str(uuid.uuid4())
        timestamp = int(datetime.utcnow().timestamp() * 1000)

        # Put the user in DynamoDB
        table.put_item(Item={
            'userId': user_id,
            'email': email,
            'name': name,
            'password_hash': hashed,
            'created_at': timestamp,
            'updated_at': timestamp
        })

        print(f"✓ User created:")
        print(f"  Email:    {email}")
        print(f"  Name:     {name}")
        print(f"  Password: {password}")
        print(f"  User ID:  {user_id}")
        print("-" * 80)

    print("\n✓ All test users seeded successfully!")
    print("\n⚠️  IMPORTANT: Save these passwords securely. They cannot be recovered.")

except Exception as e:
    print(f"❌ Error seeding users: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
