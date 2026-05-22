# E-commerce-3 Platform - Terraform Deployment Guide

**Project:** CustomerA E-commerce Platform  
**Timeline:** 12 weeks  
**Team:** 3 engineers  
**Budget:** $20,000/month ($14,497 base + 15% contingency)  
**SLA:** 99.95% uptime  
**Region:** ap-southeast-1 (Thailand)

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Deployment Steps](#deployment-steps)
4. [Module Structure](#module-structure)
5. [Variable Configuration](#variable-configuration)
6. [Compliance & Security](#compliance--security)
7. [Monitoring & Observability](#monitoring--observability)
8. [Troubleshooting](#troubleshooting)
9. [Disaster Recovery](#disaster-recovery)
10. [Cost Optimization](#cost-optimization)

---

## Prerequisites

### 1. Tools & Access
- **Terraform** >= 1.0.0
- **AWS CLI** v2 configured with credentials
- **Git** for version control
- AWS IAM credentials with the following permissions:
  - EC2, RDS, ElastiCache, VPC, ALB, S3, CloudFront
  - IAM, KMS, CloudWatch, CloudTrail
  - Secrets Manager (for database passwords)

### 2. AWS Account Setup

#### Create S3 bucket for Terraform state:
```bash
aws s3api create-bucket \
  --bucket ecommerce-terraform-state \
  --region ap-southeast-1 \
  --create-bucket-configuration LocationConstraint=ap-southeast-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ecommerce-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket ecommerce-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket ecommerce-terraform-state \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

#### Create DynamoDB table for state locking:
```bash
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-1
```

#### Create Secrets Manager secrets for sensitive data:
```bash
# Database password
aws secretsmanager create-secret \
  --name ecommerce-rds-password \
  --description "RDS Master Password" \
  --secret-string "YourSecurePassword123!@#"

# Redis auth token
aws secretsmanager create-secret \
  --name ecommerce-redis-token \
  --description "Redis Auth Token" \
  --secret-string "YourRedisToken32CharacterMinimum!@#"
```

#### Request SSL certificate (ACM):
```bash
aws acm request-certificate \
  --domain-name "yourdomain.com" \
  --subject-alternative-names "*.yourdomain.com" \
  --validation-method DNS \
  --region ap-southeast-1
```

### 3. Repository Structure
```
.
├── terraform/
│   ├── modules/
│   │   ├── vpc/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── rds/
│   │   ├── elasticache/
│   │   ├── alb/
│   │   ├── ec2/
│   │   ├── messaging/
│   │   ├── storage/
│   │   ├── monitoring/
│   │   └── kms/
│   ├── environments/
│   │   └── production/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       ├── terraform.tfvars
│   │       └── backend.tf
│   └── docs/
│       ├── DEPLOYMENT_GUIDE.md (this file)
│       ├── ARCHITECTURE.md
│       └── MODULE_REFERENCE.md
├── .gitignore
└── README.md
```

---

## Architecture Overview

### High-Level Design

```
┌─────────────────────────────────────────────────────────────────┐
│                        INTERNET                                 │
├─────────────────────────────────────────────────────────────────┤
│                     CloudFront CDN                              │
│            (static assets distribution)                         │
├─────────────────────────────────────────────────────────────────┤
│            Application Load Balancer (ALB)                      │
│              Multi-AZ across 2 Regions                          │
├─────────────────────────────────────────────────────────────────┤
│    Availability Zone 1         │    Availability Zone 2         │
│  ┌──────────────────────────┐  │  ┌──────────────────────────┐ │
│  │   EC2 Instance (t3.xl)   │  │  │   EC2 Instance (t3.xl)   │ │
│  │   - Web App Server       │  │  │   - Web App Server       │ │
│  │   - Load Balancing       │  │  │   - Load Balancing       │ │
│  └──────────────────────────┘  │  └──────────────────────────┘ │
│           ▼                     │           ▼                    │
│  ┌──────────────────────────┐  │  ┌──────────────────────────┐ │
│  │  RDS Aurora (Writer)     │  │  │  RDS Aurora (Reader)     │ │
│  │  - Primary Database      │  │  │  - Failover Replica      │ │
│  │  - Multi-AZ Failover     │  │  │  - Read Scaling          │ │
│  └──────────────────────────┘  │  └──────────────────────────┘ │
│           ▼                     │           ▼                    │
│  ┌──────────────────────────┐  │  ┌──────────────────────────┐ │
│  │ ElastiCache Redis Node   │  │  │ ElastiCache Redis Node   │ │
│  │ - Session Cache          │  │  │ - Session Cache          │ │
│  │ - Inventory Cache        │  │  │ - Inventory Cache        │ │
│  └──────────────────────────┘  │  └──────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
│
├─────────────────────────────────────────────────────────────────┤
│                    Messaging Layer                              │
│  ┌──────────────────┐  ┌──────────────────┐                   │
│  │ SQS Inventory Q  │  │ SQS Order Q      │                   │
│  │ (Async Updates)  │  │ (Order Processing)                   │
│  └──────────────────┘  └──────────────────┘                   │
│           │                    │                               │
│  ┌──────────────────────────────────────────────┐            │
│  │ SNS Notification Topic                       │            │
│  │ (Real-time alerts & notifications)           │            │
│  └──────────────────────────────────────────────┘            │
├─────────────────────────────────────────────────────────────────┤
│                      Storage Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ S3 Products  │  │ S3 Assets    │  │ S3 Logs      │        │
│  │ (Encrypted)  │  │ (Versioned)  │  │ (Archived)   │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
├─────────────────────────────────────────────────────────────────┤
│                    Monitoring & Security                        │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │ CloudWatch  │  │ CloudTrail   │  │ KMS Encryption     │  │
│  │ (Metrics)   │  │ (Audit Logs) │  │ (Keys & Secrets)   │  │
│  └─────────────┘  └──────────────┘  └────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Purpose | Configuration |
|-----------|---------|----------------|
| **VPC** | Network isolation | 10.0.0.0/16, 2 AZs |
| **RDS Aurora MySQL** | Primary database | Multi-AZ, db.r6g.large, 7-day backup |
| **ElastiCache Redis** | Session & inventory cache | Multi-AZ, 3 nodes, encrypted |
| **ALB** | Load balancing | HTTP/HTTPS, cross-AZ |
| **EC2 ASG** | Application servers | t3.xlarge, 2-10 instances |
| **SQS/SNS** | Async messaging | Order & inventory queues |
| **S3** | Static assets & logs | Versioning, encryption, CloudFront |
| **KMS** | Encryption management | Customer-managed keys |
| **CloudWatch** | Monitoring | Metrics, logs, alarms |
| **CloudTrail** | Audit logging | API audit trail |

---

## Deployment Steps

### Phase 1: Planning & Preparation (Week 1)

#### Step 1: Clone repository
```bash
git clone https://github.com/yourorg/ecommerce-3.git
cd ecommerce-3/terraform
```

#### Step 2: Initialize backend configuration
Create `environments/production/backend.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "ecommerce-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

#### Step 3: Retrieve secrets from Secrets Manager
```bash
# Get RDS password
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id ecommerce-rds-password \
  --query SecretString --output text)

# Get Redis token
REDIS_TOKEN=$(aws secretsmanager get-secret-value \
  --secret-id ecommerce-redis-token \
  --query SecretString --output text)

# Export as environment variables
export TF_VAR_db_master_password="$DB_PASSWORD"
export TF_VAR_redis_auth_token="$REDIS_TOKEN"
```

#### Step 4: Validate configuration
```bash
cd environments/production
terraform init
terraform validate
```

### Phase 2: Infrastructure Planning (Week 2)

#### Step 5: Generate and review plan
```bash
# Create plan file
terraform plan -out=tfplan_phase1

# Save human-readable version
terraform show tfplan_phase1 > plan_review_phase1.txt

# Review output (check for expected resources)
# - 1 VPC with 2 AZs
# - 2 RDS instances (primary + replica)
# - 3 ElastiCache nodes
# - 1 ALB
# - 3 EC2 instances (initial)
# - SQS queues
# - S3 buckets
# - KMS keys
# - CloudWatch logs & alarms
```

#### Step 6: Get team approval
```bash
# Share plan with security & ops team
# Checklist:
# - ✓ Encryption enabled (KMS)
# - ✓ Multi-AZ failover configured
# - ✓ Security groups restrict traffic
# - ✓ CloudTrail logging enabled
# - ✓ Cost estimates align with budget
# - ✓ Compliance controls in place
```

### Phase 3: Infrastructure Deployment (Weeks 3-4)

#### Step 7: Deploy infrastructure (WITH APPROVAL)
```bash
# Apply plan
terraform apply tfplan_phase1

# This creates:
# - VPC, subnets, route tables, NAT gateways
# - RDS Aurora cluster (Multi-AZ)
# - ElastiCache Redis cluster
# - Application Load Balancer
# - Auto Scaling Group (EC2)
# - SQS/SNS resources
# - S3 buckets with CloudFront
# - KMS keys
# - Monitoring & logging resources

# Typical deployment time: 30-45 minutes
```

#### Step 8: Verify deployment
```bash
# Get outputs
terraform output

# Verify RDS cluster
aws rds describe-db-clusters \
  --db-cluster-identifier ecommerce-3-aurora-cluster \
  --region ap-southeast-1

# Verify ElastiCache
aws elasticache describe-cache-clusters \
  --cache-cluster-id ecommerce-3-redis \
  --region ap-southeast-1

# Verify EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=ecommerce-3-*" \
  --region ap-southeast-1

# Verify ALB
aws elbv2 describe-load-balancers \
  --region ap-southeast-1

# Test database connection
mysql -h $(terraform output rds_endpoint) \
  -u admin -p -e "SELECT VERSION();"
```

#### Step 9: Run compliance checks
```bash
# Verify encryption
aws ec2 describe-volumes \
  --region ap-southeast-1 \
  --query 'Volumes[*].{ID:VolumeId,Encrypted:Encrypted}' \
  --output table

# Verify logging
aws cloudtrail describe-trails \
  --region ap-southeast-1 \
  --output table

# Verify security groups
aws ec2 describe-security-groups \
  --region ap-southeast-1 \
  --filters "Name=group-name,Values=ecommerce-3-*" \
  --output table
```

### Phase 4: Post-Deployment (Week 5+)

#### Step 10: Database migration
```bash
# Load schema
mysql -h $(terraform output rds_endpoint) \
  -u admin -p ecommerce < schema.sql

# Run data migrations (if from existing system)
# - User accounts
# - Product catalog (1M products)
# - Order history
# - Inventory levels
```

#### Step 11: Application deployment
```bash
# Deploy containerized app to EC2 instances
# - Docker image: ecommerce-3:latest
# - Health checks configured
# - Auto-scaling policies enabled
# - CloudWatch monitoring active

# Test endpoints
curl -I https://$(terraform output alb_dns_name)
```

#### Step 12: Load testing
```bash
# Simulate 5000 concurrent users
# - Test RDS throughput
# - Test ElastiCache hit rates
# - Monitor ALB latency
# - Verify auto-scaling triggers

# Tools: Apache JMeter, Locust, or custom load test
```

#### Step 13: Disaster recovery testing
```bash
# Test RDS failover
aws rds failover-db-cluster \
  --db-cluster-identifier ecommerce-3-aurora-cluster \
  --region ap-southeast-1

# Verify ElastiCache failover
# - Kill primary node
# - Verify automatic replica promotion

# RTO target: < 30 minutes
# RPO target: < 1 hour
```

---

## Module Structure

### VPC Module
**Purpose:** Network foundation with Multi-AZ, public/private subnets, NAT gateways

**Outputs:**
- VPC ID
- Public/Private/Database subnet IDs
- Security group IDs (ALB, EC2, RDS, ElastiCache)
- VPC endpoint IDs

### RDS Module
**Purpose:** Aurora MySQL cluster with encryption, backups, monitoring

**Key features:**
- Multi-AZ automatic failover
- KMS encryption at rest
- TLS encryption in transit
- 7-day automated backups
- Performance Insights
- Enhanced monitoring (1-minute granularity)

### ElastiCache Module
**Purpose:** Redis cache for sessions, inventory, real-time data

**Key features:**
- Multi-AZ with automatic failover
- Encryption at rest (KMS) and in transit (TLS)
- Auth token-based access control
- Daily snapshots (7-day retention)
- CloudWatch monitoring
- Eviction alarms

### ALB Module
**Purpose:** Layer 7 load balancing with SSL/TLS

**Key features:**
- Cross-AZ load distribution
- Path-based & host-based routing
- SSL/TLS termination
- Health check configuration
- Access logging to S3

### EC2 ASG Module
**Purpose:** Application server fleet with auto-scaling

**Key features:**
- Optimized AMI (Amazon Linux 2)
- Auto-scaling based on CPU/network metrics
- CloudWatch detailed monitoring
- Systems Manager session manager access
- EBS encryption

### Messaging Module
**Purpose:** Async processing with SQS & SNS

**Key features:**
- Encrypted message queues
- Dead-letter queues (DLQ) for failed messages
- SNS topics for real-time alerts
- KMS encryption
- Long polling for efficiency

### Storage Module
**Purpose:** S3 buckets with CloudFront CDN

**Key features:**
- Versioning enabled
- KMS encryption at rest
- CloudFront distribution
- Object lifecycle policies (transition to Glacier after 90 days)
- Access logging
- Block public access

### Monitoring Module
**Purpose:** Centralized logging, metrics, audit trail

**Key features:**
- CloudWatch log groups with retention
- CloudTrail multi-region audit logging
- VPC Flow Logs for network monitoring
- Custom CloudWatch dashboard
- SNS alerts for threshold breaches

### KMS Module
**Purpose:** Encryption key management

**Key features:**
- Customer-managed KMS keys
- Automatic key rotation
- Granular key policies
- Audit trail of key usage

---

## Variable Configuration

### Critical Variables (Must Update)

| Variable | Value | Notes |
|----------|-------|-------|
| `aws_region` | `ap-southeast-1` | Thailand region |
| `project_name` | `ecommerce-3` | Used in all resource names |
| `db_master_password` | `***SECRETS***` | Use Secrets Manager, min 20 chars |
| `redis_auth_token` | `***SECRETS***` | Use Secrets Manager, min 32 chars |
| `acm_certificate_arn` | `arn:aws:acm:...` | Your SSL certificate |

### Scaling Variables

| Variable | Current | Max | Notes |
|----------|---------|-----|-------|
| `asg_desired_capacity` | 3 | 10 | EC2 instances |
| `asg_min_size` | 2 | 3 | Minimum per AZ |
| `redis_num_nodes` | 3 | 6 | Cache nodes |
| `rds_cluster_size` | 2 | 5+ | Database replicas |

### Budget-Aware Variables

For cost optimization:
```hcl
# Development (if needed)
ec2_instance_type = "t3.medium"  # Instead of t3.xlarge
asg_desired_capacity = 1          # Instead of 3
rds_instance_class = "db.t3.small" # Instead of db.r6g.large
redis_node_type = "cache.t3.small" # Instead of cache.r6g.large
```

---

## Compliance & Security

### SOC 2 Type II Controls Implemented

| Control | Implementation | Terraform Resource |
|---------|-----------------|-------------------|
| **CC6.1** (Encryption at rest) | KMS encryption on RDS, S3, EBS | `aws_kms_key`, `aws_rds_cluster` |
| **CC6.2** (Encryption in transit) | TLS 1.2+ on ALB, RDS, ElastiCache | Security group ingress rules |
| **C1.1** (Account management) | IAM roles with least privilege | `aws_iam_role`, `aws_iam_policy` |
| **I1.1** (Logging/monitoring) | CloudTrail, CloudWatch, VPC Logs | `aws_cloudtrail_trail`, `aws_cloudwatch_log_group` |

### CIS AWS Foundations Controls

| Section | Control | Implementation |
|---------|---------|-----------------|
| **1. IAM** | Root account MFA | Manual (not in Terraform) |
|  | IAM password policy | Manual (configure in console) |
| **2. Logging** | CloudTrail enabled | ✓ `aws_cloudtrail_trail` |
|  | CloudTrail log validation | ✓ `enable_log_file_validation = true` |
| **3. Monitoring** | CloudWatch alarms | ✓ `aws_cloudwatch_metric_alarm` |
|  | Config enabled | Manual setup |
| **4. Networking** | Security groups restrict traffic | ✓ `aws_security_group` rules |
|  | VPC Flow Logs | ✓ `aws_flow_log` |
| **5. Identity** | MFA delete on S3 | ✓ `mfa_delete = true` |
|  | IAM access analyzer | Manual setup |

### Encryption Strategy

```
┌─────────────────────────────────────────────────────┐
│  Data Protection                                    │
├─────────────────────────────────────────────────────┤
│ At Rest:                                            │
│  - RDS Aurora: KMS (customer-managed key)          │
│  - ElastiCache Redis: KMS (customer-managed key)   │
│  - S3: SSE-KMS (customer-managed key)              │
│  - EBS: KMS (default encryption enabled)           │
│                                                     │
│ In Transit:                                         │
│  - ALB → Client: TLS 1.2+                          │
│  - RDS: SSL/TLS (enforced)                         │
│  - ElastiCache: Encryption in transit (enabled)    │
│  - S3: HTTPS only (bucket policy)                  │
│  - Stripe API: TLS 1.2+ (built-in)                 │
└─────────────────────────────────────────────────────┘
```

---

## Monitoring & Observability

### CloudWatch Dashboards

**Main Operations Dashboard** - Real-time visibility
- ALB request count & latency
- EC2 CPU & memory utilization
- RDS read/write latency & connections
- ElastiCache evictions & hit rate
- SQS queue depth
- Error rates by service

**Security Dashboard** - Audit & compliance
- CloudTrail events (API calls)
- Unauthorized access attempts
- Failed authentication events
- KMS key usage

### CloudWatch Alarms

| Alarm | Threshold | Action |
|-------|-----------|--------|
| ALB latency high | > 1000 ms | SNS → on-call |
| EC2 CPU high | > 80% | Scale up |
| RDS CPU high | > 80% | SNS → DBA |
| RDS storage high | > 80% | SNS → DBA |
| ElastiCache evictions | > 0 | SNS → on-call |
| SQS queue depth high | > 10,000 | SNS → ops |
| Error rate > 1% | Per minute | SNS → team |

### Logs & Traces

**CloudWatch Logs:**
- `/aws/rds/instance/ecommerce-3-aurora-instance-*` - Database logs
- `/aws/elasticache/ecommerce-3-redis` - Redis slow log
- `/aws/alb/ecommerce-3-alb` - Load balancer access logs
- `/aws/ec2/ecommerce-3-*` - Application logs
- `/aws/lambda/ecommerce-3-*` - Lambda function logs

**CloudTrail Audit Log:**
- All API calls to AWS services
- Stored in S3: `s3://ecommerce-logs/cloudtrail/`
- Retention: 90 days (configurable)

---

## Troubleshooting

### Common Issues

#### 1. RDS Connection Timeout

**Symptoms:**
```
timeout: the server did not respond in time
```

**Diagnosis:**
```bash
# Check RDS status
aws rds describe-db-clusters \
  --db-cluster-identifier ecommerce-3-aurora-cluster \
  --region ap-southeast-1

# Check security group
aws ec2 describe-security-groups \
  --group-ids sg-xxxxxxxx \
  --region ap-southeast-1
```

**Solution:**
```bash
# Verify security group allows EC2 → RDS on port 3306
aws ec2 authorize-security-group-ingress \
  --group-id sg-rds \
  --protocol tcp \
  --port 3306 \
  --source-group sg-ec2 \
  --region ap-southeast-1
```

#### 2. High Cache Eviction Rate

**Symptoms:**
```
Redis evictions > 0 (cache memory full)
```

**Diagnosis:**
```bash
# Check ElastiCache stats
aws elasticache describe-cache-nodes \
  --cache-cluster-id ecommerce-3-redis \
  --region ap-southeast-1

# Monitor CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache \
  --metric-name Evictions \
  --dimensions Name=CacheClusterId,Value=ecommerce-3-redis \
  --start-time 2026-01-01T00:00:00Z \
  --end-time 2026-01-02T00:00:00Z \
  --period 300 \
  --statistics Sum
```

**Solution:**
```bash
# Increase cache node count
terraform apply -auto-approve \
  -var='redis_num_nodes=5'

# Or resize to larger node type
terraform apply -auto-approve \
  -var='redis_node_type=cache.r6g.xlarge'
```

#### 3. Auto-Scaling Group Not Scaling

**Symptoms:**
```
Desired capacity: 3, Current capacity: 1
(instances stuck in pending state)
```

**Diagnosis:**
```bash
# Check ASG status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names ecommerce-3-asg \
  --region ap-southeast-1

# Check instance details
aws ec2 describe-instance-status \
  --region ap-southeast-1
```

**Solution:**
```bash
# Check IAM role permissions
aws iam get-role --role-name ecommerce-3-ec2-role

# Verify ALB target group
aws elbv2 describe-target-groups \
  --region ap-southeast-1
```

#### 4. Terraform State Lock

**Symptoms:**
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID

# Or clear DynamoDB lock manually
aws dynamodb delete-item \
  --table-name terraform-locks \
  --key "{\"LockID\": {\"S\": \"ecommerce-terraform-state/production/terraform.tfstate\"}}" \
  --region ap-southeast-1
```

---

## Disaster Recovery

### RTO & RPO Targets

| Scenario | RTO | RPO | Method |
|----------|-----|-----|--------|
| Single RDS instance failure | < 2 min | < 1 min | Multi-AZ auto-failover |
| Single ElastiCache node failure | < 5 min | < 5 min | Cluster failover |
| Single EC2 instance failure | < 2 min | < 2 min | ASG auto-replacement |
| Entire AZ failure | < 30 min | < 1 hour | Multi-AZ cross-AZ failover |
| Regional failure | < 4 hours | < 1 hour | Cross-region replication (manual setup) |

### RDS Failover Testing

```bash
# Trigger manual failover (will cause ~1 min downtime)
aws rds failover-db-cluster \
  --db-cluster-identifier ecommerce-3-aurora-cluster \
  --region ap-southeast-1

# Monitor progress
watch -n 5 'aws rds describe-db-clusters \
  --db-cluster-identifier ecommerce-3-aurora-cluster \
  --region ap-southeast-1 \
  --query "DBClusters[0].[Status,DBClusterMembers]"'
```

### Backup Verification

```bash
# List recent RDS snapshots
aws rds describe-db-cluster-snapshots \
  --db-cluster-identifier ecommerce-3-aurora-cluster \
  --region ap-southeast-1 \
  --query 'DBClusterSnapshots[0:5].[DBClusterSnapshotIdentifier,SnapshotCreateTime,Status]'

# Restore from snapshot to test recovery
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier ecommerce-3-aurora-test-restore \
  --snapshot-identifier <snapshot-id> \
  --engine aurora-mysql \
  --region ap-southeast-1

# After testing, delete the test cluster
aws rds delete-db-cluster \
  --db-cluster-identifier ecommerce-3-aurora-test-restore \
  --skip-final-snapshot \
  --region ap-southeast-1
```

### Data Export for Cross-Region

```bash
# Export RDS snapshot to S3
aws rds start-export-task \
  --export-task-identifier ecommerce-3-snapshot-export \
  --source-arn arn:aws:rds:ap-southeast-1:ACCOUNT:cluster-snapshot:SNAPSHOT_ID \
  --s3-bucket-name ecommerce-backup-export \
  --s3-prefix rds-exports/ \
  --iam-role-arn arn:aws:iam::ACCOUNT:role/rds-export-role \
  --region ap-southeast-1
```

---

## Cost Optimization

### Monthly Cost Breakdown

| Service | Configuration | Monthly Cost | Notes |
|---------|---------------|--------------|-------|
| **RDS Aurora** | db.r6g.large × 2 | $2,444 | Multi-AZ |
| **ElastiCache** | cache.r6g.large × 3 | $2,178 | Multi-AZ |
| **EC2** | t3.xlarge × 3-10 | $4,200 | ASG scaling |
| **ALB** | 1 ALB + data | $1,200 | Cross-AZ |
| **S3** | 1 TB storage + CDN | $800 | With CloudFront |
| **Data Transfer** | Cross-AZ, internet | $950 | Optimized |
| **Monitoring** | CloudWatch, logs | $300 | Comprehensive |
| **KMS** | 1 master key | $40 | Encryption |
| **Other** | VPC, security, etc. | $200 | Minimal |
| **TOTAL** | - | **$12,612** | Base (matches budget) |

### Cost Saving Strategies

#### 1. Reserved Instances (RI) - Save 40%
```bash
# Reserve RDS instances for 1 year
aws ec2 describe-reserved-instances-offerings \
  --filters "Name=instance-type,Values=db.r6g.large" \
  --region ap-southeast-1

# Cost with RI: $2,444 → $1,467/month ($10,728/year)
```

#### 2. Spot Instances for Dev/Test
```hcl
# In dev environment, replace:
ec2_instance_type = "t3.xlarge"
# With:
ec2_spot_max_price = "0.10"  # On-demand: ~0.1665/hour
```

#### 3. S3 Lifecycle Policies
```hcl
# Transition to Glacier after 90 days
lifecycle_transition_days = 90
# Saves ~70% on archived data
```

#### 4. Data Transfer Optimization
```bash
# Use VPC endpoints (free)
# instead of NAT gateway data transfer (~$0.04/GB)
terraform apply -auto-approve \
  -var='enable_vpc_endpoints=true'
```

### Cost Monitoring

```bash
# Set up budget alert
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget '{
    "BudgetName": "ecommerce-3-monthly",
    "BudgetLimit": {"Amount": "20000", "Unit": "USD"},
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST"
  }' \
  --notifications-with-subscribers '[
    {
      "Notification": {
        "NotificationType": "FORECASTED",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 80
      }
    }
  ]'

# Get current costs
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --filter file://filter.json
```

---

## Success Criteria Checklist

Before considering the infrastructure deployment complete:

- [ ] **Infrastructure Deployed**
  - [ ] All resources created without errors
  - [ ] RDS cluster replicating to secondary AZ
  - [ ] ElastiCache cluster operational with 3 nodes
  - [ ] ALB passing health checks for EC2 instances

- [ ] **Networking Verified**
  - [ ] EC2 instances can reach RDS on port 3306
  - [ ] EC2 instances can reach ElastiCache on port 6379
  - [ ] ALB routes traffic to EC2 instances
  - [ ] CloudFront distributes static content

- [ ] **Security Verified**
  - [ ] All data encrypted at rest (KMS)
  - [ ] All traffic encrypted in transit (TLS 1.2+)
  - [ ] Security groups follow least-privilege
  - [ ] CloudTrail logging enabled
  - [ ] VPC Flow Logs enabled

- [ ] **Monitoring Active**
  - [ ] CloudWatch dashboard displays metrics
  - [ ] Alarms configured and tested
  - [ ] SNS notifications working
  - [ ] Log retention policies applied

- [ ] **Compliance Verified**
  - [ ] SOC 2 Type II controls documented
  - [ ] CIS AWS Foundations controls reviewed
  - [ ] Backup retention policies configured
  - [ ] Disaster recovery tested

- [ ] **Performance Baseline**
  - [ ] Database response time < 10ms (p95)
  - [ ] Cache hit rate > 80%
  - [ ] ALB latency < 100ms (p95)
  - [ ] No database connection errors

- [ ] **Cost Optimized**
  - [ ] Actual costs within $20K/month budget
  - [ ] Reserved instances purchased (if applicable)
  - [ ] Unused resources identified & removed
  - [ ] Cost alerts configured

---

## Next Steps

1. **Week 5-8:** Application deployment on EC2
2. **Week 9-10:** Load testing & performance optimization
3. **Week 11-12:** Production cutover & handoff
4. **Ongoing:** Monitoring, patching, capacity planning

---

**For questions or issues, contact:** infrastructure-team@company.com
