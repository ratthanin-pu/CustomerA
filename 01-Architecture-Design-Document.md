# Architecture Design Document
## E-commerce-3 Platform - AWS Thailand Region

**Project Name:** E-commerce-3 Platform  
**Objective:** Build a scalable, highly-available online retail platform on AWS supporting 5,000 concurrent users with 1M product catalog  
**Region:** ap-southeast-7 (Thailand)  
**Estimated Monthly Cost:** $18,500 USD  
**Timeline:** 12 weeks  
**Team Capacity:** 3 full-stack engineers  

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Use Case Analysis](#use-case-analysis)
3. [Proposed Architecture](#proposed-architecture)
4. [Security & Compliance](#security--compliance)
5. [Cost Estimation](#cost-estimation)
6. [Implementation Roadmap](#implementation-roadmap)
7. [Risk Assessment](#risk-assessment)
8. [Monitoring & Observability](#monitoring--observability)
9. [Disaster Recovery Plan](#disaster-recovery-plan)
10. [Post-Launch Optimization](#post-launch-optimization)

---

## Executive Summary

This document outlines a production-grade AWS architecture for an e-commerce platform in Thailand (ap-southeast-7). The design supports:

- **5,000 concurrent users** with sub-500ms response times (p95)
- **1 million products** in catalog with intelligent caching
- **Real-time inventory management** via async message queues (SQS)
- **Stripe payment integration** with PCI compliance
- **99.95% uptime SLA** (4 nines) with Multi-AZ redundancy
- **$20,000/month budget** with optimized Reserved Instances path

### Key Design Principles
- **Security-First:** Encryption at rest (KMS), in-transit (TLS 1.2+), IAM least-privilege
- **High Availability:** Multi-AZ RDS failover, EC2 ASG health checks, ALB load balancing
- **Cost-Conscious:** Right-sized instances, caching strategy, Reserved Instance commitment path
- **Compliance:** SOC 2 Type II, CIS AWS Foundations, PCI DSS Level 1 validated

---

## Use Case Analysis

### Functional Requirements

| Feature | Details |
|---------|---------|
| **Product Catalog** | Search, filter, paginate 1M products (< 500ms p95) |
| **Shopping Cart** | Real-time inventory checks, session persistence (30 min TTL) |
| **Checkout** | Stripe payment integration, order confirmation |
| **Inventory Management** | Real-time async updates via SQS (< 5 min consistency) |
| **User Management** | Registration, login (OAuth 2.0), password reset |
| **Order Tracking** | Order status updates, email/SMS notifications (SNS) |
| **Admin Panel** | Product CRUD, inventory dashboard, analytics |

### Non-Functional Requirements

| Requirement | Target | Notes |
|-------------|--------|-------|
| **Concurrency** | 5,000 simultaneous users | Peak traffic handling |
| **Throughput** | ~500 req/sec sustained | E-commerce standard |
| **Latency (p95)** | < 500ms | Acceptable for e-commerce |
| **Availability** | 99.95% uptime | = 21.6 min downtime/month |
| **Data Durability** | RPO < 1 hour | RDS automated backups |
| **Recovery Time** | RTO < 30 minutes | Multi-AZ failover |
| **Scalability** | Auto-scale ±50% spikes | ASG + load balancer |
| **Compliance** | PCI DSS Level 1, GDPR | Payment data security |

### Constraints & Assumptions

- **No Serverless:** Must use EC2 (managed services OK)
- **Budget Cap:** $20,000/month hard limit
- **Team:** 3 engineers for implementation + maintenance
- **Region:** ap-southeast-7 (Thailand), fallback ap-southeast-1 (Singapore)
- **Deployment:** Blue-green, 12-week timeline

---

## Proposed Architecture

### Architecture Overview (Layers)

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                             │
│                  (Web, Mobile, Admin Portal)                     │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS (TLS 1.2+)
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                      CDN / EDGE (CloudFront)                     │
│                  (Static Assets, Product Images)                 │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│              AWS ap-southeast-7 REGION (Primary VPC)            │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  INGRESS LAYER (Public Subnets, Multi-AZ)               │   │
│  │  • Application Load Balancer (ALB)                       │   │
│  │  • SSL/TLS Termination (ACM Certificate)                │   │
│  │  • Security: Allow 80, 443 only                         │   │
│  └─────────────────┬──────────────────────────────────────┘   │
│                    │                                             │
│  ┌─────────────────↓──────────────────────────────────────┐   │
│  │  COMPUTE LAYER (Private Subnets, Multi-AZ)            │   │
│  │  • EC2 Auto Scaling Group (c6i.2xlarge)               │   │
│  │    - Min: 2, Desired: 4, Max: 10 instances            │   │
│  │    - Distributed across 2 AZs                         │   │
│  │  • Health Checks: ELB-based (grace period 300s)       │   │
│  │  • Docker containers running application              │   │
│  │  • Security: Allow ALB → EC2 only                     │   │
│  └─────────────────┬──────────────────────────────────────┘   │
│                    │                                             │
│  ┌─────────────────┴──────────────────────────────────────┐   │
│  │  APPLICATION LAYER (EC2 Application)                   │   │
│  │  • Product Catalog API                                 │   │
│  │  • Cart Management                                     │   │
│  │  • Checkout / Payment Processing                       │   │
│  │  • Inventory Sync Consumer (SQS polling)              │   │
│  │  • Session Management (Redis-backed)                   │   │
│  └────┬─────────────┬─────────────┬───────────────────────┘   │
│       │             │             │                             │
│  ┌────↓──┐  ┌──────↓──────┐  ┌──↓─────┐  ┌────────────────┐  │
│  │ Redis │  │  RDS Aurora │  │  SQS   │  │   SNS Topics   │  │
│  │ Cache │  │   Database  │  │ Queues │  │  (Messaging)   │  │
│  └────┬──┘  └──────┬──────┘  └──┬─────┘  └────┬───────────┘  │
│       │            │            │             │                │
│  CACHE LAYER   DATABASE LAYER  MESSAGING    NOTIFICATIONS      │
│  (Multi-AZ)    (Multi-AZ)      (Async)      (Async)            │
└─────────────────────────────────────────────────────────────────┘
                           │
       ┌───────────────────┼───────────────────┐
       ↓                   ↓                   ↓
    S3 Bucket        KMS Keys            CloudWatch
  (Product          (Encryption)        (Monitoring)
   Images)

External:
   • Stripe API (Payment Processing)
   • Email Service (SES or external)
   • Backup Region (ap-southeast-1)
```

### Network Architecture

**VPC Configuration:**
- **CIDR Block:** 10.0.0.0/16
- **Availability Zones:** 2 (ap-southeast-7a, ap-southeast-7b)
- **Subnets:**
  - Public (ALB): 10.0.1.0/24, 10.0.2.0/24
  - Private (EC2): 10.0.10.0/24, 10.0.11.0/24
  - Database (RDS): 10.0.20.0/24, 10.0.21.0/24
  - Cache (ElastiCache): 10.0.30.0/24, 10.0.31.0/24

**NAT & Routing:**
- 1x NAT Gateway per AZ (for outbound traffic to Stripe)
- Private subnet routes through NAT Gateway
- VPC Endpoints for S3 (gateway), Secrets Manager (interface) to reduce NAT costs

### Compute Layer (EC2)

**Instance Sizing:**
- **Type:** c6i.2xlarge (8 vCPU, 16GB RAM)
- **Count:** 4 instances (2 per AZ) as baseline
- **Auto Scaling:** Min 2, Desired 4, Max 10
- **Scaling Policy:** Target CPU 70%, scale-up in 5 min, scale-down in 10 min
- **Root Volume:** gp3 100GB, encrypted with KMS
- **Security Group:** Inbound from ALB (80, 443), Outbound to Internet (Stripe), RDS, Redis

**Deployment:**
- AMI: Ubuntu 22.04 LTS with Docker pre-installed
- Container: Docker container running application
- Monitoring: CloudWatch agent, X-Ray daemon
- Access: AWS Systems Manager Session Manager (no SSH keys)

### Database Layer (RDS Aurora MySQL)

**Configuration:**
- **Engine:** MySQL 8.0.35
- **Instance Type:** db.r6i.2xlarge (8 vCPU, 64GB RAM)
- **High Availability:** Multi-AZ with automatic failover (standby in different AZ)
- **Storage:** Aurora Auto-scaling 100GB → 1TB
- **Backups:**
  - Automated snapshots: every 6 hours, 35-day retention
  - Copy to ap-southeast-1 daily (cross-region DR)
  - Backup window: 03:00-04:00 UTC

**Performance Optimization:**
- **Connection Pool:** max_connections=1000
- **Buffer Pool:** 48GB (for caching hot data)
- **Indexes:** Optimized for 1M product queries
  - PRIMARY KEY: product_id
  - INDEX: category, price_range, created_at
  - INDEX: order_id for transaction lookup

**Encryption:**
- **At Rest:** AWS KMS (customer-managed key)
- **In Transit:** SSL/TLS required
- **Credentials:** IAM database authentication (15-min token expiry)

### Cache Layer (ElastiCache Redis)

**Configuration:**
- **Node Type:** cache.r6g.2xlarge (8 vCPU, 52GB RAM)
- **Cluster Mode:** Disabled (simpler topology for initial scale)
- **Replication:** Multi-AZ with automatic failover
- **Data Persistence:** AOF (append-only file) enabled

**Caching Strategy:**
- **Product Data:** 24-hour TTL (hot 500K products, < 5% of 1M catalog)
- **User Sessions:** 30-minute TTL (expiry on logout)
- **Shopping Carts:** 48-hour TTL (recoverable if lost)
- **Inventory Cache:** 5-minute TTL (eventual consistency acceptable)
- **Eviction Policy:** allkeys-lru (remove least-recently-used when memory full)

**Encryption:**
- **In Transit:** TLS 1.2
- **At Rest:** AWS KMS encryption enabled

### Messaging Layer (SQS + SNS)

**SQS (Inventory Queue):**
- **Type:** Standard queue (order not critical)
- **Message Retention:** 86,400s (24 hours)
- **Visibility Timeout:** 300s (worker processes in < 5 min)
- **Dead Letter Queue:** Enabled (failed messages, max 3 retries)
- **Throughput:** ~100 messages/sec (peak)

**SNS (Order Notifications):**
- **Topics:**
  - order-created
  - order-shipped
  - order-cancelled
- **Subscribers:** Email, SMS via external service
- **Message Filtering:** By order status (reduce SNS costs)

### Storage Layer (S3 + CloudFront)

**S3 Configuration:**
- **Bucket:** ecom-products-ap-southeast-7-{account-id}
- **Objects:** Product images (JPG, PNG, WebP)
- **Versioning:** Enabled (track product image changes)
- **Encryption:** SSE-KMS (customer-managed key)
- **Lifecycle:** Archive to Glacier after 90 days (old images)
- **CORS:** Configured for web app domain
- **Access:** CloudFront origin only (bucket policy blocks direct access)

**CloudFront Distribution:**
- **Origin:** S3 bucket
- **Behaviors:**
  - Cache product images: 30 days
  - Cache product metadata: 5 minutes
- **DDoS Protection:** AWS Shield Standard (included)
- **Geo-Blocking:** Allow Thailand, ASEAN countries
- **Compression:** Enable gzip for JSON/HTML

### Security Architecture

**Encryption at Rest:**
- RDS: AWS KMS (customer-managed key)
- ElastiCache: AWS KMS
- S3: AWS KMS
- EBS volumes: AWS KMS
- Secrets Manager: AWS KMS (Stripe keys, DB passwords)

**Encryption in Transit:**
- All APIs: TLS 1.2+ (ACM certificate)
- Database connections: SSL/TLS required
- Redis connections: TLS 1.2
- S3 transfers: HTTPS only

**Access Control:**
- **IAM Roles:** Least-privilege by service
  - EC2: S3 GetObject, SQS, SNS, Secrets Manager access
  - RDS: IAM database authentication
- **Network:** Security groups restrict by port/protocol/source
- **Secrets Management:** AWS Secrets Manager with auto-rotation
- **API Keys:** Never hardcoded (stored in Secrets Manager)

**Audit & Logging:**
- CloudTrail: All API calls (stored in S3 with MFA delete)
- CloudWatch Logs: Application logs (30-day retention)
- VPC Flow Logs: Network traffic audit (14-day retention)
- RDS Audit: Enable MySQL audit plugin for GDPR
- ALB Access Logs: HTTP traffic (90-day retention)

---

## Security & Compliance

### SOC 2 Type II Controls Mapping

| Control | Requirement | AWS Implementation | Evidence |
|---------|-------------|-------------------|----------|
| **CC6.1** | Restrict access to systems | IAM roles, security groups, VPC | CloudTrail logs, IAM policy docs |
| **CC6.2** | Define access policies | IAM role-based access, MFA | Password policy, MFA device list |
| **CC6.3** | Restrict network access | TLS 1.2+, VPC endpoints | SSL certificate, VPC Flow Logs |
| **C1.1** | Confidentiality | KMS encryption, data classification | KMS key policy, encryption audit |
| **I1.1** | Data integrity | Database constraints, transactions | Schema with FK/UNIQUE, audit log |
| **A1.1** | Availability | Multi-AZ RDS, ASG, backup/restore | RTO/RPO test report, uptime metric |

### CIS AWS Foundations Controls

**Identity & Access Management (Section 1):**
- ✅ MFA enabled for all IAM users with console access
- ✅ Access keys rotated every 90 days (Secrets Manager auto-rotation)
- ✅ No credentials unused > 90 days (quarterly audit)

**Logging (Section 2):**
- ✅ CloudTrail enabled in all regions
- ✅ CloudTrail S3 bucket: public access blocked, MFA delete enabled
- ✅ CloudTrail log file integrity validation enabled
- ✅ CloudWatch Logs encrypted with KMS

**Monitoring (Section 3):**
- ✅ CloudWatch alarm for unauthorized API calls
- ✅ CloudWatch alarm for root account usage
- ✅ CloudWatch alarm for failed API calls

**Networking (Section 4):**
- ✅ VPC Flow Logs enabled
- ✅ Security groups restrict inbound to necessary ports only
- ✅ NACLs configured (defense in depth)

**Identity (Section 5):**
- ✅ IAM policies attached to groups/roles only (not users)
- ✅ Users have console password OR access keys (not both)

### PCI DSS Compliance

Since we integrate Stripe for payment processing:

- **No Raw Card Data:** Application never receives credit card numbers
- **Tokenization:** Stripe handles tokenization, app uses tokens only
- **Webhook Security:** Signature verification for all payment webhooks
- **Audit Trail:** CloudTrail logs all data access attempts
- **Encryption:** TLS 1.2+ for payment data in transit
- **Access Control:** IAM restrictions on payment-related endpoints

### Data Encryption Strategy

**At Rest (KMS):**
- Customer-managed key (separate from AWS-managed)
- Key rotation: Enabled (automatic annual)
- Cross-region backup: Key copied to ap-southeast-1

**In Transit (TLS 1.2+):**
- ALB → Client: HTTPS with ACM certificate
- EC2 → RDS: SSL/TLS (connection string parameter)
- EC2 → ElastiCache: TLS 1.2
- EC2 → S3: HTTPS only
- Stripe API: HTTPS (Stripe handles certificates)

---

## Cost Estimation

### Monthly Cost Breakdown

| Service | Configuration | Unit Price | Monthly Cost |
|---------|---------------|-----------|--------------|
| **EC2** | 4x c6i.2xlarge × 730h | $0.68/h | $1,987 |
| **RDS Aurora** | 1 primary + 1 read replica | $2.40/h | $3,504 |
| **ElastiCache** | cache.r6g.2xlarge (2 nodes) | $1.37/h | $2,001 |
| **ALB** | 1 load balancer | $16.43/month + LCU | $543 |
| **S3 Storage** | 500GB product images | $0.025/GB | $13 |
| **S3 Requests** | 10M GET/month | $0.0004/1000 | $4 |
| **CloudFront** | 50GB data transfer | $0.085/GB | $4,250 |
| **NAT Gateway** | 2x NAT × traffic | $32/month + $0.045/GB | $115 |
| **KMS** | 1 customer-managed key | $1/month | $1 |
| **CloudWatch** | Logs + metrics | $0.50/GB ingestion | $28 |
| **RDS Backups** | 100GB × 35-day retention | $0.095/GB | $10 |
| **Miscellaneous** | VPC endpoints, Systems Manager | - | $150 |
| | | **SUBTOTAL** | **$12,606** |
| | | **Buffer (15%)** | **$1,891** |
| | | **TOTAL** | **$14,497/month** |

**Within $20K budget with $5,503/month contingency**

### Cost Optimization Path

**Immediate (Week 11-12):**
- CloudFront caching optimization: -$1,000/month
- NAT Gateway consolidation: -$115/month
- RDS backup optimization: -$10/month

**Short-term (Month 2):**
- 1-year Reserved Instances (baseline): -$2,800/month
- ElastiCache reserved: -$400/month

**Medium-term (Month 3+):**
- Consider Aurora Serverless for off-peak: -$500/month
- Optimize database indices: -$500/month (fewer scans)

**Optimized Total: ~$8,200-9,000/month** (comfortable within $20K budget)

---

## Implementation Roadmap

### Phase 1: Infrastructure Foundation (Weeks 1-4)

**Week 1-2: Design & Planning**
- [ ] Architecture review & approval
- [ ] Security & compliance checklist
- [ ] Team training (AWS, Terraform)
- [ ] AWS account setup (ap-southeast-7 + ap-southeast-1)
- **Deliverable:** Architecture Design Document (signed off)

**Week 3-4: Infrastructure Deployment**
- [ ] Terraform VPC, security groups, NAT
- [ ] RDS Aurora Multi-AZ provisioned
- [ ] ElastiCache Redis deployed
- [ ] EC2 ASG + ALB configured
- [ ] Failover test: terminate 1 AZ, verify replacement
- **Deliverable:** Infrastructure operational, all services responding

### Phase 2: Application Development (Weeks 5-8)

**Week 5-6: Containerization & CI/CD**
- [ ] Dockerfile created (multi-stage build)
- [ ] GitHub Actions: build → ECR → deploy to staging
- [ ] docker-compose for local development
- [ ] Application connects to RDS, Redis, S3, SQS

**Week 7-8: Database Schema & Integrations**
- [ ] MySQL schema: products (1M rows), carts, orders, inventory_queue
- [ ] Stripe payment flow (tokenization, webhooks)
- [ ] SQS inventory worker (async consumer)
- [ ] SNS order notifications
- **Deliverable:** Application running on EC2, end-to-end flow working

### Phase 3: Testing & Hardening (Weeks 9-10)

**Week 9: Load Testing**
- [ ] JMeter: ramp 5K concurrent users over 10 min
- [ ] Sustain 5K users for 30 min, measure latency/errors
- [ ] Verify cache hit rate > 80%
- [ ] Verify auto-scaling responds to CPU spikes
- **Success:** P95 latency < 500ms, error rate < 0.1%

**Week 10: Security & Compliance**
- [ ] 3rd-party penetration test
- [ ] PCI DSS checklist validation
- [ ] Disaster recovery test (RDS failover, cross-region)
- [ ] SOC 2 Type II evidence collection
- **Success:** No CVSS 4+ vulnerabilities, all controls passed

### Phase 4: Production Cutover (Weeks 11-12)

**Week 11: Blue-Green Deployment**
- [ ] Route 10% traffic to new infra (monitor 6h)
- [ ] Route 50% traffic (monitor 12h)
- [ ] Route 100% traffic (monitor 12h)
- [ ] Rollback plan ready (auto-rollback if error rate > 1%)

**Week 12: Stabilization & Handoff**
- [ ] 24h no-incidents rule satisfied
- [ ] Team trained on runbooks
- [ ] On-call rotation activated (PagerDuty)
- [ ] Post-launch optimization roadmap documented
- **Deliverable:** Platform production-ready, team certified

---

## Risk Assessment

| Risk | Severity | Probability | Mitigation |
|------|----------|-------------|-----------|
| ap-southeast-7 has limited AZ (possibly 1 AZ) | HIGH | MEDIUM | Pre-plan failover to ap-southeast-1, test cross-region RDS replication |
| Team learning curve (AWS/Terraform/ops) | MEDIUM | HIGH | Allocate Week 0 for training, pair programming on infrastructure |
| 1M product catalog performance issues | MEDIUM | MEDIUM | Pre-tune indexes, cache hot products, load test Week 6 |
| Budget overrun | MEDIUM | LOW | AWS Budgets alerts at $15K, weekly cost review |
| Stripe API integration complexity | LOW | LOW | Use official SDK, mock payments in dev, security review early |
| Compliance (PCI) not met | HIGH | LOW | Hire external PCI auditor by Week 8, document controls |
| Team attrition during 12 weeks | MEDIUM | LOW | Cross-train all engineers on each component |

---

## Monitoring & Observability

### CloudWatch Dashboards

**Real-Time Dashboard (30-second refresh):**
- ALB target health count (should be ≥ 2)
- EC2 instance count (tracking ASG changes)
- RDS CPU, connections, query latency
- ElastiCache hit rate, evictions
- SQS queue depth
- Error rate (5xx, 4xx), latency (p50/p95/p99)

**Cost Dashboard:**
- Daily spend by service (trend vs. budget)
- Forecast for month

### CloudWatch Alarms

| Alarm | Threshold | Action |
|-------|-----------|--------|
| RDS CPU | > 80% for 5 min | SNS → on-call |
| ALB unhealthy targets | < 2 healthy | SNS → critical |
| Error rate | > 1% p95 | PagerDuty escalate |
| Unauthorized API calls | Any event | SNS → immediate |
| Root account usage | Any event | SNS → critical |
| SQS queue depth | > 1000 messages | SNS → on-call |

### Application Logging

- CloudWatch Logs: Application stdout/stderr (30-day retention)
- X-Ray: Trace requests end-to-end (Stripe calls, DB queries)
- VPC Flow Logs: Network traffic audit (14-day retention)
- RDS Slow Query Log: Queries > 2 seconds

---

## Disaster Recovery Plan

### RTO/RPO Targets
- **RTO (Recovery Time Objective):** < 30 minutes
- **RPO (Recovery Point Objective):** < 1 hour

### Backup Strategy

**RDS:**
- Automated snapshots every 6 hours
- 35-day retention period
- Cross-region copy to ap-southeast-1 daily

**S3:**
- Versioning enabled (track changes)
- Lifecycle: Archive to Glacier after 90 days

**Application:**
- Stateless (no local files)
- State stored in RDS/Redis/S3

### Failover Procedures

**AZ Failure (EC2/ElastiCache):**
- Auto Scaling Group launches replacement instances (automatic, < 2 min)
- ElastiCache automatic failover to standby (automatic, < 1 min)

**RDS Primary Failure:**
- Aurora automatic failover to read replica (automatic, < 30 sec)

**Region Failure (ap-southeast-7 → ap-southeast-1):**
- Manual: Promote RDS read replica in ap-southeast-1
- Manual: Update Route 53 DNS to ap-southeast-1 ALB
- Estimated: < 15 min recovery

---

## Post-Launch Optimization (Months 2-6)

**Month 2: Cost Optimization**
- Reserved Instances for baseline capacity (1-year: -30%)
- CloudFront caching tuning (-$1K/month)
- Database index optimization (-$500/month)

**Month 3: Performance Tuning**
- A/B test caching strategies
- Code profiling (CPU hotspots)
- Query optimization

**Month 4: Scaling Preparation**
- Load test 10K concurrent users (3x current)
- Design multi-region failover (active-passive)

**Month 5: Security Hardening**
- SOC 2 Type II formal audit
- Annual PCI DSS assessment
- Security group audit

**Month 6: Team & Ops**
- Hire 2nd DevOps engineer (24/7 coverage)
- Establish incident review process
- Quarterly disaster recovery drills

---

## Appendix: Terraform Module Structure

```
terraform/
├── main.tf                 # VPC, subnets, route tables
├── variables.tf            # Input variables (region, budget, team)
├── outputs.tf              # Output ALB DNS, RDS endpoint, etc.
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds/
│   │   ├── main.tf
│   │   └── ...
│   ├── ec2/
│   │   ├── main.tf
│   │   └── ...
│   ├── cache/
│   │   ├── main.tf
│   │   └── ...
│   ├── alb/
│   │   ├── main.tf
│   │   └── ...
│   ├── s3/
│   │   ├── main.tf
│   │   └── ...
│   └── kms/
│       ├── main.tf
│       └── ...
├── environments/
│   ├── staging.tfvars
│   ├── production.tfvars
│   └── dr-region.tfvars
└── terraform.tfstate       # State file (S3 backend with locking)
```

---

**Document End**
