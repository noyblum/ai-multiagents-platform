# AI Multi-Agents Platform

> **Author:** Noy Blumenfeld  
> **Repository:** [ai-multiagents-platform](https://github.com/noyblum/ai-multiagents-platform)  
> **📹 Demo Video:** [Watch the platform in action](https://drive.google.com/file/d/1RIhXt4n8l4NFaw3EXpJodSHqWKkNhmCo/view?usp=sharing)

A production-ready serverless platform leveraging AWS Bedrock Agents to create an intelligent multi-agent system. The platform features a Supervisor Agent that intelligently delegates tasks to specialized agents (Coding, Financial, and Generic) based on user queries, providing accurate and context-aware responses through a modern web interface.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [System Workflow](#system-workflow)
- [Key Features](#key-features)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Configure Environment Variables](#2-configure-environment-variables)
  - [3. Deploy Infrastructure](#3-deploy-infrastructure)
  - [4. Access the Application](#4-access-the-application)
- [API Reference](#api-reference)
- [Agent Architecture](#agent-architecture)
- [Error Handling](#error-handling)
- [Performance Considerations](#performance-considerations)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Architecture Overview

![System Architecture](architecture.png)

The platform is built on a serverless architecture using AWS managed services:

- **Frontend Layer:** Single-Page Application (SPA) hosted on CloudFront + S3
- **API Layer:** API Gateway HTTP API with JWT authentication
- **Compute Layer:** AWS Lambda functions (Python 3.12)
- **Data Layer:** DynamoDB for session management and user storage
- **AI Layer:** AWS Bedrock Agents with multi-agent orchestration
- **Security Layer:** AWS Secrets Manager, IAM roles, and JWT tokens

---

## System Workflow

### 1. User Authentication
- User accesses the frontend via CloudFront
- Login request sent to API Gateway → Login Lambda
- Lambda validates credentials against DynamoDB Users table
- JWT token generated and returned to client

### 2. Chat Request Flow (Polling Architecture)
```
User → CloudFront → API Gateway → Chat Lambda
                                      ↓
                                 Create Session (DynamoDB)
                                      ↓
                                 Invoke Supervisor Agent
                                      ↓
                                 Return sessionId immediately
                                      ↓
User polls /chat/status/{sessionId} ← Chat Status Lambda ← DynamoDB
```

### 3. Agent Delegation
The Supervisor Agent analyzes the user's query and delegates to the appropriate specialist:
- **Coding queries** → Coding Agent (programming, algorithms, code review)
- **Financial queries** → Financial Agent (market analysis, calculations, advice)
- **General queries** → Generic Agent (general knowledge, conversations)

### 4. Response Streaming
The Bedrock Agent streams responses in chunks, which are:
- Progressively written to DynamoDB (every 3 chunks)
- Retrieved by the frontend through polling
- Displayed in real-time to the user

---

## Key Features

✅ **Multi-Agent Intelligence:** Supervisor-based delegation to specialized agents  
✅ **Real-time Updates:** Progressive response streaming via polling mechanism  
✅ **Secure Authentication:** JWT-based token authentication with session management  
✅ **Scalable Architecture:** Serverless design with automatic scaling  
✅ **Error Resilience:** Comprehensive error handling with user-friendly messages  
✅ **Infrastructure as Code:** Complete Terraform automation for reproducible deployments  
✅ **Cross-Region Support:** Uses US-based inference profiles to optimize performance  

---

## Technology Stack

### Backend
- **AWS Lambda** (Python 3.12) - Serverless compute
- **AWS Bedrock Agents** - AI agent orchestration
- **Amazon DynamoDB** - NoSQL database for sessions and users
- **Amazon API Gateway** - HTTP API with AWS_PROXY integration
- **AWS Secrets Manager** - Secure credential storage

### Frontend
- **Vanilla JavaScript** - No framework dependencies
- **Amazon CloudFront** - Global CDN
- **Amazon S3** - Static website hosting

### Infrastructure
- **Terraform** - Infrastructure as Code
- **AWS IAM** - Identity and access management
- **CloudWatch** - Logging and monitoring

---

## Prerequisites

- **AWS Account** with appropriate permissions
- **Terraform** >= 1.0
- **AWS CLI** configured with credentials
- **Python** 3.12 (for local Lambda development)
- **Git** for version control

---

## Getting Started

### 1. Clone the Repository

```bash
git clone git@github.com:noyblum/ai-multiagents-platform.git
cd ai-multiagents-platform
```

### 2. Configure Environment Variables

Create or edit the Terraform variables file:

```bash
cd terraform
cp env/dev.tfvars.example env/dev.tfvars  # If example exists
# OR edit directly:
nano env/dev.tfvars
```

**Required variables in `env/dev.tfvars`:**

```hcl
# Project Configuration
project_name = "ai-agents-platform"
environment  = "dev"
aws_region   = "us-east-1"
account_id   = "YOUR_AWS_ACCOUNT_ID"  # Replace with your account ID

# Authentication Configuration
email_domain = "yourdomain.com"  # Domain for user emails

# Bedrock Models - Using cross-region inference profiles
model_generic    = "us.anthropic.claude-3-5-sonnet-20241022-v2:0"
model_coding     = "us.anthropic.claude-3-5-sonnet-20241022-v2:0"
model_financial  = "us.anthropic.claude-3-5-sonnet-20241022-v2:0"
model_supervisor = "us.anthropic.claude-3-5-sonnet-20241022-v2:0"
```

**How to find your AWS Account ID:**
```bash
aws sts get-caller-identity --query Account --output text
```

### 3. Deploy Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan -var-file=env/dev.tfvars -var="account_id=$(aws sts get-caller-identity --query Account --output text)"

# Deploy the infrastructure
terraform apply -var-file=env/dev.tfvars -var="account_id=$(aws sts get-caller-identity --query Account --output text)" -auto-approve
```

**Deployment typically takes 5-10 minutes** and creates:
- 4 Bedrock Agents (Supervisor, Coding, Financial, Generic)
- 5 Lambda functions (Login, Chat, Chat Status, Health, List Agents)
- API Gateway HTTP API
- 2 DynamoDB tables (Users, Chat Sessions)
- CloudFront distribution with S3 bucket
- IAM roles and policies
- CloudWatch log groups

### 4. Access the Application

After deployment, Terraform outputs the URLs:

```bash
# View outputs
terraform output

# Key outputs:
# frontend_url         = "https://d1mlww2uh8x6yo.cloudfront.net"
# api_endpoint         = "https://3wowpl5onl.execute-api.us-east-1.amazonaws.com/prod"
# supervisor_agent_id  = "SCXJ11IU28"
```

**Access the frontend:**
```bash
open $(terraform output -raw frontend_url)
```

**Default test user credentials:**
- Email: `noyblum@blumenfeld.com`
- Password: `1Kgg$wMgX(g{:+Qc}`

*(Note: Change these in production by updating the seed users module)*

---

## API Reference

### Authentication

**POST** `/api/login`
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "userId": "uuid",
    "email": "user@example.com"
  }
}
```

### Chat

**POST** `/api/chat`
```bash
curl -X POST "https://API_ENDPOINT/prod/api/chat" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"message": "What is Python?", "agentType": "supervisor"}'
```

**Response:**
```json
{
  "success": true,
  "sessionId": "uuid-session-id",
  "status": "processing",
  "message": "Response is being processed. Poll /api/chat/status/{sessionId} for updates."
}
```

### Chat Status (Polling)

**GET** `/api/chat/status/{sessionId}`
```bash
curl "https://API_ENDPOINT/prod/api/chat/status/uuid-session-id" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Response (Processing):**
```json
{
  "success": true,
  "status": "processing",
  "response": "Partial response...",
  "chunks": ["chunk1", "chunk2"]
}
```

**Response (Completed):**
```json
{
  "success": true,
  "status": "completed",
  "response": "Full agent response...",
  "chunks": ["chunk1", "chunk2", "chunk3"]
}
```

---

## Agent Architecture

### Supervisor Agent
- **Role:** Query analysis and task delegation
- **Collaborators:** Coding Agent, Financial Agent, Generic Agent
- **Behavior:** Intelligently routes queries based on intent and context

### Coding Agent
- **Specialization:** Software development, algorithms, code review
- **Use Cases:** Programming questions, debugging, best practices
- **Model:** Claude 3.5 Sonnet (cross-region inference profile)

### Financial Agent
- **Specialization:** Financial analysis, market insights, calculations
- **Use Cases:** Investment queries, financial planning, market trends
- **Model:** Claude 3.5 Sonnet (cross-region inference profile)

### Generic Agent
- **Specialization:** General knowledge and conversations
- **Use Cases:** General questions, explanations, casual conversations
- **Model:** Claude 3.5 Sonnet (cross-region inference profile)

---

## Error Handling

The platform implements comprehensive error handling with user-friendly messages:

### Throttling Errors
When AWS Bedrock rate limits are reached:
```json
{
  "success": false,
  "error": "Too many requests. The AI service is temporarily rate-limited. Please wait a minute and try again.",
  "errorType": "throttling",
  "sessionId": "uuid",
  "retryAfter": 60
}
```

**Frontend handling:**
- Displays user-friendly message
- Suggests retry after specified duration
- Session ID preserved for retry

### Authentication Errors
```json
{
  "success": false,
  "error": "Authentication required",
  "errorType": "auth"
}
```

### Validation Errors
```json
{
  "success": false,
  "error": "Message is required",
  "errorType": "validation"
}
```

---

## Performance Considerations

### Response Streaming Architecture

**Challenge:** Initially implemented Server-Sent Events (SSE) for real-time streaming, but encountered compatibility issues with API Gateway HTTP APIs (which don't support streaming responses natively).

**Solution:** Evolved to a polling-based architecture that provides near-real-time updates while maintaining compatibility:

1. **Immediate Response:** Chat endpoint returns sessionId instantly
2. **Progressive Updates:** Agent responses written to DynamoDB in chunks (every 3 chunks)
3. **Client Polling:** Frontend polls `/chat/status/{sessionId}` at intervals
4. **Efficient Storage:** DynamoDB with TTL (24 hours) for automatic cleanup

**Benefits:**
- ✅ Compatible with API Gateway HTTP API
- ✅ Scalable and cost-effective
- ✅ Progressive response updates
- ✅ Session persistence for retry scenarios
- ✅ No websocket management overhead

### Cross-Region Inference Profiles

Uses US-based Bedrock inference profiles (`us.anthropic.claude-3-5-sonnet-20241022-v2:0`) to:
- Reduce latency through regional optimization
- Improve quota distribution
- Enhance reliability

### DynamoDB Optimization

- Point-in-time recovery enabled
- TTL for automatic session cleanup (24 hours)
- On-demand capacity for cost optimization
- Projection expressions for efficient queries

---

## Troubleshooting

### Issue: "Internal Server Error" from API

**Solution:** Ensure all Lambda functions return status code 200 with error details in the response body (API Gateway HTTP API requirement).

### Issue: Bedrock Throttling

**Symptoms:**
```json
{
  "errorType": "throttling",
  "error": "Too many requests..."
}
```

**Solutions:**
1. Wait 1-2 minutes between requests during testing
2. Request quota increase via AWS Service Quotas
3. Implement exponential backoff in client
4. Use cross-region inference profiles (already configured)

### Issue: JWT Token Expired

**Symptoms:**
```json
{
  "success": false,
  "error": "Token expired"
}
```

**Solution:** Re-authenticate via `/api/login` endpoint

### Issue: Terraform Apply Fails

**Common causes:**
- Missing AWS credentials: `aws configure`
- Incorrect account_id: Check with `aws sts get-caller-identity`
- Missing variables: Verify `env/dev.tfvars`
- Resource limits: Check AWS service quotas

**Debug commands:**
```bash
# Check Terraform state
terraform show

# View specific resource
terraform state show module.chat_lambda.aws_lambda_function.this

# Force recreate specific resource
terraform taint module.chat_lambda.aws_lambda_function.this
terraform apply -var-file=env/dev.tfvars -var="account_id=YOUR_ACCOUNT_ID"
```

### Issue: CloudFront Takes Long to Update

CloudFront distributions take 15-20 minutes to propagate changes. To invalidate cache:

```bash
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

---

## Project Structure

```
ai-agents-platform/
├── README.md
├── architecture.png
├── frontend/
│   ├── index.html           # Main SPA
│   └── config.js            # API configuration
├── terraform/
│   ├── main.tf              # Root module
│   ├── variables.tf         # Variable definitions
│   ├── outputs.tf           # Output values
│   ├── api-gateway.tf       # API Gateway configuration
│   ├── lambdas.tf           # Lambda function definitions
│   ├── lambda-layers.tf     # Shared Lambda layers
│   ├── secrets.tf           # Secrets Manager
│   ├── env/
│   │   ├── dev.tfvars       # Development environment
│   │   └── prod.tfvars      # Production environment
│   ├── functions/
│   │   ├── chat/
│   │   │   ├── index.py
│   │   │   └── requirements.txt
│   │   ├── chat-status/
│   │   ├── login/
│   │   ├── health/
│   │   └── list-agents/
│   └── modules/
│       ├── bedrock-agents/  # Agent configurations
│       ├── dynamodb/        # DynamoDB tables
│       ├── iam/             # IAM roles and policies
│       ├── lambda/          # Lambda module
│       ├── lambda-layer/    # Shared dependencies
│       ├── s3-cloudfront/   # Frontend hosting
│       └── seed-users/      # User initialization
└── tests/
    └── integration_tests.sh # End-to-end tests
```

---

## Deployment Checklist

- [ ] AWS account configured with appropriate permissions
- [ ] Terraform installed and initialized
- [ ] `env/dev.tfvars` configured with correct values
- [ ] AWS CLI credentials configured
- [ ] Bedrock model access enabled in AWS account
- [ ] Infrastructure deployed successfully
- [ ] Frontend accessible via CloudFront URL
- [ ] Test user can login
- [ ] Chat functionality working
- [ ] Agent delegation functioning correctly
- [ ] CloudWatch logs enabled for debugging

---

## Security Best Practices

1. **JWT Secret:** Rotate regularly via AWS Secrets Manager
2. **IAM Policies:** Follow least-privilege principle
3. **API Keys:** Never commit to version control
4. **User Passwords:** Use bcrypt hashing (implemented)
5. **CORS:** Restrict to specific domains in production
6. **DynamoDB:** Enable point-in-time recovery
7. **CloudWatch:** Monitor for suspicious activity
8. **VPC:** Consider VPC integration for sensitive workloads

---

## Cost Optimization

- **Lambda:** Only charged for execution time (serverless)
- **DynamoDB:** On-demand pricing, auto-cleanup with TTL
- **Bedrock:** Pay-per-token usage with cross-region optimization
- **CloudFront:** Free tier for first 1TB/month
- **API Gateway:** $1 per million requests (HTTP API)

**Estimated monthly cost for low-traffic development:** $10-30

---

## Future Enhancements

- [ ] WebSocket support for true real-time streaming
- [ ] Agent conversation history and context retention
- [ ] Multi-turn dialogue optimization
- [ ] Custom agent creation via UI
- [ ] Advanced analytics dashboard
- [ ] A/B testing for agent performance
- [ ] Multi-language support
- [ ] Voice input/output integration

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License. See LICENSE file for details.

---

## Acknowledgments

- **AWS Bedrock** for providing powerful foundation models
- **Anthropic Claude** for intelligent agent capabilities
- **Terraform** for infrastructure automation
- **AWS Community** for extensive documentation and support

---

## Contact

**Noy Blumenfeld**  
GitHub: [@noyblum](https://github.com/noyblum)  
Repository: [ai-multiagents-platform](https://github.com/noyblum/ai-multiagents-platform)

---

*Built with ❤️ using AWS Serverless Technologies*
