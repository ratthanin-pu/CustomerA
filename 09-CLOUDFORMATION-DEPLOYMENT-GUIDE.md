# E-commerce-3 Platform - CloudFormation Deployment Guide

**Project:** CustomerA E-commerce Platform  
**IaC Tool:** AWS CloudFormation  
**Region:** ap-southeast-1 (Thailand)  
**Budget:** $20,000/month ($14,497 base + 15% contingency)  
**Timeline:** 12 weeks  
**Team:** 3 engineers  
**SLA:** 99.95% uptime

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Stack Architecture](#stack-architecture)
3. [Deployment Process](#deployment-process)
4. [Parameters Configuration](#parameters-configuration)
5. [Updating Stacks](#updating-stacks)
6. [Monitoring & Troubleshooting](#monitoring--troubleshooting)
7. [Cost Management](#cost-management)
8. [Disaster Recovery](#disaster-recovery)

---

## Prerequisites

### AWS Credentials & Permissions
```bash
# Configure AWS CLI
aws configure
# AWS Access Key ID: [YOUR_ACCESS_KEY]
# AWS Secret Access Key: [YOUR_SECRET_KEY]
# Default region: ap-southeast-1
# Default output format: json

# Verify credentials
aws sts get-caller-identity
```

### Required AWS Services Access
- CloudFormation
- EC2 (VPC, Security Groups, Instances, ASG)
- RDS (Aurora MySQL)
- ElastiCache (Redis)
- Elastic Load Balancing (ALB)
- S3
- CloudFront
- SQS, SNS
- KMS
- CloudTrail, CloudWatch
- IAM

### Local Tools
```bash
# AWS CLI v2
aws --version  # >= 2.13.0

# Optional but recommended
# AWS CloudFormation Linter
pip install cfn-lint
cfn-lint cloudformation-templates/

# AWS SAM CLI
brew install aws-sam-cli  # macOS
```

### Prepare AWS Account

#### 1. Create S3 bucket for CloudFormation templates
```bash
aws s3api create-bucket \
  --bucket ecommerce-3-cf-templates-$(aws sts get-caller-identity --query Account --output text) \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ecommerce-3-cf-templates-$(aws sts get-caller-identity --query Account --output text) \
  --versioning-configuration Status=Enabled

# Block public access
aws s3api put-public-access-block \
  --bucket ecommerce-3-cf-templates-$(aws sts get-caller-identity --query Account --output text) \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

#### 2. Upload CloudFormation templates to S3
```bash
# Copy all nested stack templates to S3
for template in cloudformation/*.yaml; do
  aws s3 cp "$template" \
    s3://ecommerce-3-cf-templates-$(aws sts get-caller-identity --query Account --output text)/
done
```

#### 3. Retrieve or create SSL certificate
```bash
# Request SSL certificate if not exists
aws acm request-certificate \
  --domain-name yourdomain.com \
  --subject-alternative-names "*.yourdomain.com" \
  --validation-method DNS \
  --region ap-southeast-1

# Get certificate ARN
aws acm list-certificates --region ap-southeast-1 --query 'CertificateSummaryList[0].CertificateArn'
```

#### 4. Create Secrets Manager secrets
```bash
# RDS password
aws secretsmanager create-secret \
  --name ecommerce-3-rds-password \
  --description "RDS Master Password" \
  --secret-string "YourSecurePassword123!@#$%^&*()_+="

# Redis auth token (minimum 32 characters)
aws secretsmanager create-secret \
  --name ecommerce-3-redis-token \
  --description "Redis Auth Token" \
  --secret-string "YourRedisTokenMinimum32Characters!@#$%"
```

---

## Stack Architecture

### Nested Stacks Hierarchy

```
Master Stack
│
├── VPC Stack
│   ├── VPC (10.0.0.0/16)
│   ├── Public Subnets (2-3)
│   ├── Private Subnets (2-3)
│   ├── Database Subnets (2-3)
│   ├── NAT Gateways
│   ├── Internet Gateway
│   └── Security Groups
│
├── KMS Stack
│   └── Customer-managed KMS key
│
├── RDS Stack
│   ├── Aurora MySQL Cluster
│   ├── Cluster Parameter Group
│   ├── CloudWatch Alarms
│   └── IAM Monitoring Role
│
├── ElastiCache Stack
│   ├── Redis Cluster (Multi-AZ)
│   ├── Parameter Group
│   └── CloudWatch Alarms
│
├── ALB Stack
│   ├── Application Load Balancer
│   ├── Target Group
│   ├── HTTPS Listener
│   └── Health Checks
│
├── EC2 ASG Stack
│   ├── Launch Template
│   ├── Auto Scaling Group
│   ├── IAM Instance Role
│   └── CloudWatch Monitoring
│
├── Messaging Stack
│   ├── SQS Queues (Inventory, Orders)
│   ├── SNS Topic
│   └── Dead-Letter Queues
│
├── Storage Stack
│   ├── S3 Buckets (Products, Assets, Logs)
│   ├── CloudFront Distribution
│   ├── Lifecycle Policies
│   └── Encryption Configuration
│
└── Monitoring Stack
    ├── CloudTrail Trail
    ├── CloudWatch Log Groups
    ├── VPC Flow Logs
    └── Security Alarms
```

### Stack Dependencies

**Deployment Order (handled by master stack):**
1. VPC Stack (base network)
2. KMS Stack (encryption keys)
3. RDS Stack (depends on VPC, KMS)
4. ElastiCache Stack (depends on VPC, KMS)
5. ALB Stack (depends on VPC)
6. EC2 ASG Stack (depends on VPC, ALB, KMS)
7. Messaging Stack (depends on KMS)
8. Storage Stack (depends on KMS)
9. Monitoring Stack (depends on VPC, KMS, Storage)

---

## Deployment Process

### Phase 1: Validation (Week 1)

#### Step 1: Validate CloudFormation templates
```bash
# Lint all templates
cfn-lint cloudformation-templates/*.yaml

# Validate with AWS CloudFormation
for template in cloudformation/*.yaml; do
  aws cloudformation validate-template \
    --template-body file://"$template" \
    --region ap-southeast-1
done
```

#### Step 2: Create change set for review
```bash
# Create change set
aws cloudformation create-change-set \
  --stack-name ecommerce-3-prod \
  --change-set-name ecommerce-3-prod-changeset-1 \
  --template-body file://cloudformation/master-stack.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=ecommerce-3 \
    ParameterKey=Environment,ParameterValue=production \
    ParameterKey=VpcCIDR,ParameterValue=10.0.0.0/16 \
    ParameterKey=DBMasterPassword,ParameterValue='YourSecurePassword123!@#$%' \
    ParameterKey=RedisAuthToken,ParameterValue='YourRedisTokenMinimum32Characters!@#$%' \
    ParameterKey=EC2InstanceType,ParameterValue=t3.xlarge \
    ParameterKey=ACMCertificateArn,ParameterValue='arn:aws:acm:ap-southeast-1:...' \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ap-southeast-1

# View change set
aws cloudformation describe-change-set \
  --change-set-name ecommerce-3-prod-changeset-1 \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1
```

### Phase 2: Infrastructure Deployment (Weeks 2-4)

#### Step 3: Execute change set
```bash
# Execute after team approval
aws cloudformation execute-change-set \
  --change-set-name ecommerce-3-prod-changeset-1 \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1

# Monitor stack creation
aws cloudformation wait stack-create-complete \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1
```

#### Step 4: Monitor stack events
```bash
# Watch stack progress (real-time)
aws cloudformation describe-stack-events \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1 \
  --query 'StackEvents[0:20]' \
  --output table

# Check stack status
aws cloudformation describe-stacks \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1 \
  --query 'Stacks[0].[StackName,StackStatus,CreationTime]' \
  --output table
```

**Expected deployment time:** 45-60 minutes

#### Step 5: Retrieve outputs
```bash
# Get all stack outputs
aws cloudformation describe-stacks \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1 \
  --query 'Stacks[0].Outputs' \
  --output table

# Get specific output
RDS_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`RDSEndpoint`].OutputValue' \
  --output text)

echo "RDS Endpoint: $RDS_ENDPOINT"
```

### Phase 3: Verification (After deployment)

#### Step 6: Verify all components
```bash
# Test RDS connectivity
mysql -h $RDS_ENDPOINT -u admin -p -e "SELECT VERSION();"

# Test ElastiCache connectivity
redis-cli -h $ELASTICACHE_ENDPOINT -p 6379 -a $REDIS_TOKEN ping

# Verify ALB
curl -I https://$ALB_DNS/

# Check EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:aws:cloudformation:stack-name,Values=ecommerce-3-prod" \
  --region ap-southeast-1

# Verify S3 buckets
aws s3 ls | grep ecommerce-3

# Check CloudFront distribution
aws cloudfront list-distributions \
  --query "DistributionList.Items[?Comment=='ecommerce-3']"
```

---

## Parameters Configuration

### Master Stack Parameters File

Create `parameters.json`:

```json
[
  {
    "ParameterKey": "ProjectName",
    "ParameterValue": "ecommerce-3"
  },
  {
    "ParameterKey": "Environment",
    "ParameterValue": "production"
  },
  {
    "ParameterKey": "CostCenter",
    "ParameterValue": "engineering"
  },
  {
    "ParameterKey": "VpcCIDR",
    "ParameterValue": "10.0.0.0/16"
  },
  {
    "ParameterKey": "AvailabilityZones",
    "ParameterValue": "2"
  },
  {
    "ParameterKey": "DBMasterUsername",
    "ParameterValue": "admin"
  },
  {
    "ParameterKey": "DBMasterPassword",
    "ParameterValue": "YourSecurePassword123!@#$%^&*()"
  },
  {
    "ParameterKey": "DBInstanceClass",
    "ParameterValue": "db.r6g.large"
  },
  {
    "ParameterKey": "RedisAuthToken",
    "ParameterValue": "YourRedisTokenMinimum32Characters!@#$%"
  },
  {
    "ParameterKey": "RedisNodeType",
    "ParameterValue": "cache.r6g.large"
  },
  {
    "ParameterKey": "EC2InstanceType",
    "ParameterValue": "t3.xlarge"
  },
  {
    "ParameterKey": "ASGMinSize",
    "ParameterValue": "2"
  },
  {
    "ParameterKey": "ASGMaxSize",
    "ParameterValue": "10"
  },
  {
    "ParameterKey": "ASGDesiredCapacity",
    "ParameterValue": "3"
  },
  {
    "ParameterKey": "ACMCertificateArn",
    "ParameterValue": "arn:aws:acm:ap-southeast-1:ACCOUNT_ID:certificate/CERT_ID"
  }
]
```

### Using Parameters File
```bash
aws cloudformation create-change-set \
  --stack-name ecommerce-3-prod \
  --change-set-name ecommerce-3-prod-changeset-1 \
  --template-body file://cloudformation/master-stack.yaml \
  --parameters file://parameters.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ap-southeast-1
```

---

## Updating Stacks

### Update Nested Stack
```bash
# Update specific nested stack
aws cloudformation update-stack \
  --stack-name ecommerce-3-prod-ec2-asg \
  --template-body file://cloudformation/ec2-asg-stack.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=ecommerce-3 \
    ParameterKey=EC2InstanceType,UsePreviousValue=true \
    ParameterKey=ASGDesiredCapacity,ParameterValue=5 \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ap-southeast-1

# Monitor update
aws cloudformation wait stack-update-complete \
  --stack-name ecommerce-3-prod-ec2-asg \
  --region ap-southeast-1
```

### Update Master Stack
```bash
# To update all nested stacks
aws cloudformation update-stack \
  --stack-name ecommerce-3-prod \
  --template-body file://cloudformation/master-stack.yaml \
  --parameters file://parameters-updated.json \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ap-southeast-1
```

### Rollback on Failure
```bash
# CloudFormation automatically rolls back failed updates
# Monitor rollback progress
aws cloudformation describe-stacks \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1 \
  --query 'Stacks[0].StackStatus'
```

---

## Monitoring & Troubleshooting

### CloudFormation Stack Events
```bash
# View recent events
aws cloudformation describe-stack-events \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'

# Get detailed error messages
aws cloudformation describe-stack-resources \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1 \
  --query 'StackResources[?ResourceStatus==`CREATE_FAILED`]'
```

### Check Resource Status
```bash
# List all stack resources
aws cloudformation list-stack-resources \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1 \
  --output table

# Check nested stack status
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --region ap-southeast-1 \
  --query "StackSummaries[?contains(StackName, 'ecommerce-3')]"
```

### Common Issues & Solutions

#### Issue 1: SSL Certificate Not Found
```bash
# Verify certificate exists
aws acm list-certificates \
  --region ap-southeast-1 \
  --query "CertificateSummaryList[?DomainName=='yourdomain.com']"

# If not found, create new certificate
aws acm request-certificate \
  --domain-name yourdomain.com \
  --validation-method DNS \
  --region ap-southeast-1
```

#### Issue 2: Insufficient Capacity in AZ
```bash
# Retry stack creation or update
# CloudFormation handles transient capacity issues

# Check AZ availability
aws ec2 describe-instance-type-offerings \
  --filters "Name=location,Values=ap-southeast-1a" \
  --query "InstanceTypeOfferings[0:5]"
```

#### Issue 3: IAM Permission Denied
```bash
# Ensure IAM user has CloudFormation permissions
aws iam get-user-policy \
  --user-name your-iam-user \
  --policy-name CloudFormationAccess

# Add policy if needed
aws iam put-user-policy \
  --user-name your-iam-user \
  --policy-name CloudFormationAccess \
  --policy-document file://iam-policy.json
```

---

## Cost Management

### Monitor Stack Costs
```bash
# Estimate costs
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter file://filter.json \
  --group-by Type=DIMENSION,Key=SERVICE

# View detailed costs by resource
aws cloudformation describe-stacks \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1 \
  --query 'Stacks[0].Outputs'
```

### Cost Optimization
```bash
# Reduce capacity during dev/test
# Update ASG desired capacity
aws cloudformation update-stack \
  --stack-name ecommerce-3-prod-ec2-asg \
  --template-body file://cloudformation/ec2-asg-stack.yaml \
  --parameters \
    ParameterKey=ASGDesiredCapacity,ParameterValue=1 \
  --region ap-southeast-1

# Use smaller instance types for non-prod
# Modify parameters in parameters-dev.json
```

---

## Disaster Recovery

### Backup Strategy
```bash
# RDS automatic backups (configured in template)
# Retention: 7 days

# Manual snapshot before major changes
aws rds create-db-cluster-snapshot \
  --db-cluster-snapshot-identifier ecommerce-3-backup-2026-01-01 \
  --db-cluster-identifier ecommerce-3-aurora-cluster \
  --region ap-southeast-1

# S3 versioning (enabled in template)
# All objects protected with version history
```

### Restore from Backup
```bash
# Restore RDS from snapshot
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier ecommerce-3-restore \
  --snapshot-identifier ecommerce-3-backup-2026-01-01 \
  --engine aurora-mysql \
  --region ap-southeast-1

# Restore S3 object
aws s3api get-object \
  --bucket ecommerce-3-products \
  --key path/to/object \
  --version-id versionId \
  localfile.txt
```

### Delete Stack (Caution!)
```bash
# Delete entire stack (removes all resources)
aws cloudformation delete-stack \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1

# Create final snapshot before deletion
aws rds create-db-cluster-snapshot \
  --db-cluster-snapshot-identifier ecommerce-3-final-backup \
  --db-cluster-identifier ecommerce-3-aurora-cluster \
  --region ap-southeast-1

# Monitor deletion
aws cloudformation wait stack-delete-complete \
  --stack-name ecommerce-3-prod \
  --region ap-southeast-1
```

---

## Next Steps

1. **Week 5-8:** Application deployment
2. **Week 9-10:** Load testing & compliance validation
3. **Week 11-12:** Production cutover & handoff

---

**Questions or support needed?** Contact: infrastructure-team@company.com
