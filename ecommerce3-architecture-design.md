# Architecture Design Document
## E-Commerce-3 Platform — AWS Landing Zone (ap-southeast-7, Thailand)
**Version:** 1.0 | **Date:** 2026-05-26 | **Prepared by:** AWS Solutions Architect

---

## 1. Executive Summary

| Item | Detail |
|------|--------|
| **Project Name** | E-Commerce-3 Platform |
| **Objective** | Production-grade e-commerce platform for 5,000 concurrent users with 1 million product catalog, real-time async inventory, Stripe payment processing |
| **Region** | ap-southeast-7 (Thailand) |
| **Availability Target** | 99.95% uptime (HA across 3 AZs) |
| **Budget** | $20,000/month (estimated infra: ~$8,850/month) |
| **Timeline** | 12 weeks |
| **Team** | 2 engineers |
| **Architecture Pattern** | AWS Landing Zone + Multi-tier EC2/ECS on EC2 (no serverless) |

**Key Business Drivers:**
- Thai market presence requiring local data residency (ap-southeast-7)
- 99.95% SLA mandates multi-AZ active-active architecture
- Real-time inventory accuracy for 1M+ products via async SQS
- PCI DSS-compatible payment processing via Stripe HTTPS integration
- Total infrastructure cost ~$8,850/month — $11,150/month budget buffer for growth

---

## 2. Use Case Analysis

### 2.1 Functional Requirements

| # | Requirement | Priority |
|---|-------------|----------|
| F1 | Product catalog browsing (1M+ products, search, filter) | CRITICAL |
| F2 | User registration, authentication, session management | CRITICAL |
| F3 | Shopping cart management | CRITICAL |
| F4 | Order placement and management | CRITICAL |
| F5 | Real-time inventory check and async update | CRITICAL |
| F6 | Payment processing via Stripe | CRITICAL |
| F7 | Product image delivery (CDN) | HIGH |
| F8 | Admin dashboard and reporting | MEDIUM |
| F9 | Order history and tracking | HIGH |

### 2.2 Non-Functional Requirements

| Category | Target | Solution |
|----------|--------|----------|
| **Concurrency** | 5,000 simultaneous users | ECS on EC2 (6+ nodes) + ALB + ElastiCache |
| **Availability** | 99.95% uptime | 3-AZ active-active, Multi-AZ Aurora & Redis |
| **Product Scale** | 1M products | OpenSearch 3-node cluster |
| **Inventory** | Real-time async | SQS queues + ECS consumers |
| **Response Time** | < 200ms API, < 2s page load | CloudFront + ElastiCache Redis |
| **RTO** | < 15 minutes | Multi-AZ automatic failover |
| **RPO** | < 1 minute | Aurora continuous replication |
| **Compute** | No serverless | ECS on EC2 + EC2 Auto Scaling |

### 2.3 Constraints & Assumptions

- No AWS Lambda or serverless services (as specified)
- All workloads deployed in ap-southeast-7 (Thailand)
- Stripe used for all payment processing; no local payment gateway in scope for v1
- Team of 2 engineers — architecture must be operationally manageable
- Infrastructure managed via AWS CloudFormation or Terraform
- Source code stored in AWS CodeCommit or GitHub

---

## 3. Proposed Architecture

### 3.1 AWS Landing Zone Account Structure

The platform uses AWS Control Tower to enforce a Landing Zone with 4 account types:

```
Root (Management Account)
├── Control Tower + Organizations + IAM Identity Center + SCPs
├── Log Archive Account
│   └── S3 Central Logs, CloudTrail (Org-level), Config Aggregator
├── Audit / Security Account
│   └── Security Hub, GuardDuty, Inspector v2, IAM Access Analyzer, Config
├── Shared Services Account
│   └── Transit Gateway, Route 53 Resolver, Network Firewall, Direct Connect
└── E-Commerce Production Account
    └── All workloads (VPC, ECS, RDS, ElastiCache, OpenSearch, etc.)
```

### 3.2 Service Selection Rationale

| AWS Service | Role | Why Selected |
|------------|------|--------------|
| **ECS on EC2** | Microservices compute | Containerized, scalable, no serverless constraint |
| **EC2 Auto Scaling (m5.2xlarge)** | ECS node fleet | 8 vCPU / 32GB per node, right-sized for 5K users |
| **Aurora PostgreSQL Multi-AZ** | Primary database | Managed, Multi-AZ, read replicas, automatic failover |
| **ElastiCache Redis (r6g.xlarge)** | Session store + cache | Sub-ms latency, Multi-AZ, reduces DB load |
| **OpenSearch Service (m6g.2xlarge x3)** | Product search | 1M product catalog, full-text search, faceted filtering |
| **Amazon SQS** | Async inventory + orders | Decoupled async messaging, no serverless required |
| **CloudFront + WAF** | CDN + edge security | Global caching, DDoS protection, OWASP rules |
| **ALB** | Load balancing | Path-based routing to microservices, health checks |
| **S3** | Static assets + images | Durable, cheap, CDN-compatible |
| **ECR** | Container registry | Integrated with ECS, image scanning |
| **CodePipeline + CodeBuild** | CI/CD | Fully managed build/deploy pipeline |
| **Transit Gateway** | Cross-account networking | Centralized routing between all Landing Zone accounts |

### 3.3 Network Design

**VPC CIDR:** 10.0.0.0/16

| Subnet Type | AZ-7a | AZ-7b | AZ-7c |
|------------|-------|-------|-------|
| Public (ALB, NAT GW) | 10.0.1.0/24 | 10.0.2.0/24 | 10.0.3.0/24 |
| Private App (ECS) | 10.0.10.0/24 | 10.0.11.0/24 | 10.0.12.0/24 |
| Private DB (RDS/Redis/OS) | 10.0.20.0/24 | 10.0.21.0/24 | 10.0.22.0/24 |

**Traffic Flow:**
```
Internet Users
  → Shield Standard (DDoS)
  → Route 53 (DNS)
  → CloudFront CDN (Edge cache, WAF)
  → Application Load Balancer (Public, spans 3 AZs)
  → ECS Tasks / EC2 ASG (Private App Subnets)
  → Aurora PostgreSQL / ElastiCache Redis / OpenSearch (Private DB Subnets)
  → SQS Queues (Async inventory / order events)
  → Stripe HTTPS API (outbound via NAT Gateway)
```

### 3.4 Compute Design (ECS on EC2)

**ECS Cluster Configuration:**
- Launch Type: EC2 (no Fargate serverless)
- Instance type: m5.2xlarge (8 vCPU, 32 GB RAM)
- Minimum nodes: 2 per AZ = 6 total
- Auto Scaling: Scale up at 70% CPU, scale down at 30%
- Max capacity: 12 nodes (4 per AZ)

**Microservices (ECS Tasks):**

| Service | Function | Replicas |
|---------|----------|---------|
| Product Catalog Service | CRUD + search index sync | 3+ |
| Order Management Service | Order lifecycle | 3+ |
| Auth / User Service | Registration, login, JWT | 3+ |
| Inventory Consumer Service | SQS consumer, async updates | 3+ |
| Payment Service | Stripe API integration | 3+ |
| Cart & Session Service | Redis-backed cart | 3+ |
| Search Proxy Service | OpenSearch query proxy | 3+ |

### 3.5 Database Design

**Aurora PostgreSQL:**
- Version: Aurora PostgreSQL 15.x
- Writer instance: db.r6g.2xlarge (AZ-7a)
- Read Replicas: 2 (AZ-7b, AZ-7c)
- Storage: Auto-scaling, gp3, encrypted with KMS
- Backup: 7-day automated + S3 export weekly
- Failover: Automatic (< 30 seconds)

**ElastiCache Redis:**
- Version: Redis 7.x
- Primary: cache.r6g.xlarge (AZ-7a)
- Replicas: 2 (AZ-7b, AZ-7c)
- Use cases: Session store, product cache, cart data, rate limiting

**OpenSearch:**
- Version: 2.x
- Node type: m6g.2xlarge
- Node count: 3 (one per AZ)
- Index: 1M product documents with faceted search

### 3.6 Async Inventory Architecture

```
Product Service → SQS Inventory Queue → Inventory Consumer (ECS)
                                           ↓
Order Service   → SQS Order Queue    → Aurora + OpenSearch update
                                           ↓
                                      ElastiCache cache invalidation
```

SQS queues provide:
- Dead-letter queues (DLQ) for failed messages
- Visibility timeout: 30 seconds
- Message retention: 14 days
- FIFO ordering per product ID

---

## 4. Security & Compliance

### 4.1 Encryption Strategy

| Layer | Implementation |
|-------|---------------|
| **In-Transit** | TLS 1.2+ enforced on ALB, CloudFront, RDS, ElastiCache |
| **At-Rest** | AWS KMS CMK for Aurora, ElastiCache, S3, EBS, SQS |
| **Key Rotation** | Automatic annual rotation via KMS |
| **Stripe Communication** | HTTPS only, Stripe.js (PCI-compliant tokenization) |

### 4.2 Authentication & Authorization

- IAM roles with least-privilege policies for all ECS tasks
- IAM Identity Center (SSO) for engineer access across accounts
- No long-lived IAM access keys; use instance roles exclusively
- MFA enforced for all human IAM users via IAM Identity Center
- Service-to-service auth via IAM roles (no hardcoded credentials)
- All secrets stored in AWS Secrets Manager, rotated automatically

### 4.3 Network Security

| Control | Implementation |
|---------|---------------|
| **WAF** | OWASP Top 10, rate limiting, SQL injection, XSS rules |
| **Security Groups** | Least-privilege per tier; DB only from App SG |
| **NACLs** | Stateless rules at subnet boundary |
| **VPC Flow Logs** | All VPC traffic logged to S3 Log Archive account |
| **Shield Standard** | Automatic DDoS protection on CloudFront + ALB |
| **Network Firewall** | Centralized in Shared Services account via TGW |

### 4.4 Audit & Logging

| Service | What's Logged |
|---------|--------------|
| **CloudTrail** | All API calls (org-level, delivered to Log Archive S3) |
| **CloudWatch** | Application metrics, custom dashboards, alarms |
| **VPC Flow Logs** | Network traffic flows |
| **ALB Access Logs** | HTTP requests, response codes, latency |
| **Aurora Audit Logs** | Database queries (CloudWatch) |
| **X-Ray** | Distributed tracing across microservices |

---

## 5. Cost Estimation

### 5.1 Monthly Cost Breakdown

| Service | Specification | Est. Monthly Cost (USD) |
|---------|--------------|------------------------|
| EC2 (ECS nodes) | 6x m5.2xlarge On-Demand | $2,800 |
| Aurora PostgreSQL | db.r6g.2xlarge writer + 2 readers | $1,800 |
| ElastiCache Redis | cache.r6g.xlarge + 2 replicas | $650 |
| OpenSearch Service | 3x m6g.2xlarge | $1,200 |
| Application Load Balancer | 3 nodes, ~50K LCUs | $250 |
| CloudFront CDN | ~10TB transfer + requests | $300 |
| NAT Gateway | 3 AZs, ~5TB data | $350 |
| S3 (assets + logs) | ~5TB storage + requests | $200 |
| SQS Queues | ~100M messages/month | $50 |
| ECR | 5 images, scanning enabled | $50 |
| WAF | ~10M requests/month | $150 |
| Shield Standard | Included in CloudFront | $0 |
| ACM Certificates | Public certs | $0 |
| CloudWatch | Metrics, logs, dashboards | $200 |
| X-Ray | Traces | $100 |
| KMS | CMK operations | $50 |
| Secrets Manager | ~10 secrets | $10 |
| CodePipeline + CodeBuild | CI/CD pipeline | $100 |
| Data Transfer | Inter-AZ + outbound | $500 |
| **TOTAL INFRASTRUCTURE** | | **~$8,810/month** |
| **Budget Buffer** | | **~$11,190/month** |

### 5.2 Cost Optimization Recommendations

1. **Reserved Instances**: Convert EC2 and RDS to 1-year reserved after 3 months → save ~35% (~$1,600/month)
2. **Savings Plans**: Compute Savings Plans for EC2 → additional 20% savings
3. **S3 Intelligent-Tiering**: Auto-move old product images to cheaper tiers
4. **CloudFront Cache Hit Rate**: Target >90% to minimize origin requests
5. **Auto Scaling**: Scale down ECS nodes during off-peak hours (midnight–6am Thai time)

---

## 6. Implementation Roadmap

### Phase 1: Landing Zone & Infrastructure (Weeks 1–3)
- Deploy AWS Control Tower and set up 4-account Landing Zone
- Configure VPC, subnets, Security Groups, NACLs in ap-southeast-7
- Set up Transit Gateway and account peering
- Configure CloudTrail, Config, GuardDuty, Security Hub
- Deploy Aurora PostgreSQL Multi-AZ cluster
- Deploy ElastiCache Redis cluster
- Deploy OpenSearch 3-node cluster

### Phase 2: Application Platform (Weeks 4–7)
- Set up ECS clusters on EC2 (all 3 AZs)
- Deploy ECR repositories and push base images
- Configure ALB with target groups and health checks
- Deploy CloudFront distribution + WAF rules
- Configure SQS queues (inventory + order events) with DLQs
- Set up Secrets Manager for all credentials
- Deploy CI/CD pipeline (CodePipeline + CodeBuild)

### Phase 3: Microservices Deployment (Weeks 8–10)
- Deploy and configure all 7 microservices on ECS
- Integrate Stripe payment service (HTTPS + webhook)
- Configure OpenSearch product indexing (1M products)
- Set up ElastiCache session management
- Implement SQS-based inventory async flow
- End-to-end integration testing

### Phase 4: Hardening & Go-Live (Weeks 11–12)
- Load testing: simulate 5,000 concurrent users (Apache JMeter / k6)
- Security pen testing on WAF rules and application
- Tune Auto Scaling policies
- Configure CloudWatch dashboards and SNS alerts
- DR drill: test Aurora failover, ECS node failure
- Production cutover and monitoring

---

## 7. Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| ap-southeast-7 service gaps (new region) | MEDIUM | HIGH | Verify all required services available; fallback to ap-southeast-1 |
| Aurora failover > 30s causing timeout | LOW | HIGH | Configure connection pooling (PgBouncer on ECS) |
| OpenSearch indexing lag for 1M products | MEDIUM | MEDIUM | Pre-index during deployment; incremental updates via SQS |
| ECS node unavailability during scale events | LOW | MEDIUM | Minimum 2 nodes per AZ; overlap during scale-in |
| Stripe API outage | LOW | HIGH | Implement retry with exponential backoff + SQS order queue |
| Budget overrun due to data transfer | MEDIUM | MEDIUM | CloudFront cache tuning; VPC endpoint for S3 |
| 2-engineer team capacity | HIGH | MEDIUM | Use managed services (Aurora, ElastiCache, OpenSearch) to reduce ops overhead |
| SQS DLQ overflow | LOW | MEDIUM | Alert on DLQ depth > 100; auto-remediation runbook |
