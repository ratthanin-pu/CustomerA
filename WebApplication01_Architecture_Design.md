# Architecture Design Document
## WebApplication01 — Customer Support Platform

**Version:** 1.0  
**Date:** 2026-05-25  
**Region:** ap-southeast-7 (Thailand/Bangkok)  
**Prepared by:** AWS Business Architect Analyzer

---

## 1. Executive Summary

| Field | Value |
|---|---|
| Project Name | WebApplication01 — Customer Support Platform |
| Objective | Deploy a highly available, production-grade customer support web platform in AWS Thailand region |
| Target Availability | 99.95% uptime (≤ 4.38 hrs downtime/year) |
| Concurrent Users | 500 |
| AWS Region | ap-southeast-7 (Bangkok, Thailand) |
| Budget | $20,000/month (infrastructure + team) |
| Timeline | 12 weeks |
| Team | 2 engineers |
| Architecture Style | Traditional multi-tier EC2 (no serverless) |

**Key Business Drivers:**
- Reliable customer support portal with real-time inventory visibility
- Secure payment processing via Stripe
- Product catalog supporting 50 services/products
- Async inventory synchronization for decoupled, resilient operations
- Full compliance with SOC 2 Type II & CIS AWS Foundations Benchmark

**Estimated Monthly Infrastructure Cost: $1,050 – $1,350/month** (well within budget, leaving ~$18,650 for team and operational costs)

---

## 2. Use Case Analysis

### 2.1 Functional Requirements

| ID | Requirement | Priority |
|---|---|---|
| FR-01 | Customer support ticket creation and management | Critical |
| FR-02 | Product catalog browsing (50 services/products) | Critical |
| FR-03 | Real-time inventory status display (async sync) | High |
| FR-04 | Payment processing via Stripe API | Critical |
| FR-05 | User authentication and session management | Critical |
| FR-06 | Agent/admin dashboard | High |
| FR-07 | Notification system (email/in-app) | Medium |
| FR-08 | Reporting and analytics dashboard | Medium |

### 2.2 Non-Functional Requirements

| Category | Requirement | Target |
|---|---|---|
| Availability | Uptime SLA | 99.95% (Multi-AZ) |
| Performance | Page load time | < 2 seconds (P95) |
| Performance | API response time | < 500ms (P99) |
| Scalability | Concurrent users | 500 baseline, 1,500 burst |
| Scalability | Future growth | 3-5x within 24 months |
| Security | Data encryption | TLS 1.3 in transit, AES-256 at rest |
| Compliance | Standards | SOC 2 Type II, CIS AWS Foundations v1.4 |
| RPO | Recovery Point Objective | ≤ 1 hour |
| RTO | Recovery Time Objective | ≤ 30 minutes |

### 2.3 Constraints & Assumptions

- **No Serverless**: Lambda, API Gateway (serverless), Aurora Serverless are excluded
- **Region**: All primary resources deployed in ap-southeast-7; CloudFront uses global edge
- **Team Capacity**: 2 engineers manage both infrastructure and application; Terraform for IaC
- **Stripe Integration**: Outbound HTTPS from app tier to Stripe API endpoints
- **Async Inventory**: Inventory updates via SQS queue; EC2 workers consume and update DB
- **Budget Breakdown**: ~$1,200 infrastructure + ~$18,800 team/ops within $20,000/month

---

## 3. Proposed Architecture

### 3.1 Architecture Pattern

**Pattern:** Multi-Tier EC2 Web Application with Multi-AZ High Availability

```
                    ┌─────────────────────────────────┐
                    │         Internet / Users         │
                    └────────────────┬────────────────┘
                                     │
                    ┌────────────────▼────────────────┐
                    │    Route 53 (DNS + Health Check) │
                    └────────────────┬────────────────┘
                                     │
                    ┌────────────────▼────────────────┐
                    │  CloudFront CDN + WAF + ACM SSL  │
                    └────────────────┬────────────────┘
                                     │
  ╔══════════════ VPC 10.0.0.0/16 (ap-southeast-7) ══════════════╗
  ║                                  │                            ║
  ║  ┌───────────────────────────────▼──────────────────────┐    ║
  ║  │            Application Load Balancer (Multi-AZ)       │    ║
  ║  └──────────────┬────────────────────────────┬──────────┘    ║
  ║                 │                            │               ║
  ║      ┌──────────▼──────────┐    ┌────────────▼──────────┐    ║
  ║      │  AZ-a (10.0.11.0)  │    │  AZ-b (10.0.12.0)    │    ║
  ║      │  EC2 App Server     │    │  EC2 App Server       │    ║
  ║      │  (t3.large)         │    │  (t3.large)           │    ║
  ║      │  Auto Scaling Group │    │  Auto Scaling Group   │    ║
  ║      └──────────┬──────────┘    └────────────┬──────────┘    ║
  ║                 │                            │               ║
  ║      ┌──────────▼────────────────────────────▼──────────┐    ║
  ║      │              Data Tier (Private Subnets)          │    ║
  ║      │  ┌─────────────────┐  ┌──────────────────────┐  │    ║
  ║      │  │ RDS PostgreSQL  │  │ ElastiCache Redis     │  │    ║
  ║      │  │ Multi-AZ        │  │ Primary + Replica     │  │    ║
  ║      │  │ db.r6g.large    │  │ cache.r6g.medium      │  │    ║
  ║      │  └─────────────────┘  └──────────────────────┘  │    ║
  ║      │  ┌─────────────────┐                             │    ║
  ║      │  │ SQS Queue       │  (Inventory async updates)  │    ║
  ║      │  │ (FIFO)          │                             │    ║
  ║      │  └─────────────────┘                             │    ║
  ║      └──────────────────────────────────────────────────┘    ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝
                    │
          ┌─────────▼──────────┐
          │   External Services │
          │  Stripe API (HTTPS) │
          └────────────────────┘
```

### 3.2 Service Selection Rationale

| AWS Service | Tier | Justification |
|---|---|---|
| **Route 53** | Edge | DNS with health checks; enables failover routing |
| **CloudFront** | Edge | CDN for static assets; reduces latency for Thai users; SSL offloading |
| **AWS WAF** | Edge | OWASP Top 10 protection; rate limiting; bot mitigation |
| **ACM** | Edge | Free managed TLS certificates; auto-renewal |
| **Application Load Balancer** | Public | Layer 7 load balancing; path-based routing; session stickiness |
| **EC2 t3.large** | App | 2 vCPU, 8GB RAM; good cost/performance for web workloads; no serverless |
| **Auto Scaling Group** | App | Maintains HA; scales on CPU/request count metrics |
| **RDS PostgreSQL Multi-AZ** | Data | ACID compliance; automatic failover; managed backups; suitable for support tickets |
| **ElastiCache Redis** | Data | Session storage; API response caching; pub/sub for real-time inventory status |
| **SQS FIFO Queue** | Async | Decoupled inventory updates; exactly-once processing; durable |
| **S3** | Storage | Static assets, user uploads, DB backups, CloudTrail logs |
| **NAT Gateway** | Network | Outbound internet (Stripe API) from private subnets; HA across 2 AZs |
| **Secrets Manager** | Security | Stripe API keys; DB credentials; auto-rotation |
| **KMS** | Security | Customer-managed keys for RDS, S3, SQS, ElastiCache encryption |
| **CloudWatch** | Operations | Metrics, alarms, dashboards, log aggregation |
| **CloudTrail** | Operations | API audit trail; compliance evidence |
| **Bastion Host** | Operations | Secure SSH access to private instances; replaced by SSM Session Manager optionally |

### 3.3 Network Architecture

| Subnet | CIDR | AZ | Resources |
|---|---|---|---|
| Public AZ-a | 10.0.1.0/24 | ap-southeast-7a | ALB, NAT GW, Bastion |
| Public AZ-b | 10.0.2.0/24 | ap-southeast-7b | ALB, NAT GW |
| Private App AZ-a | 10.0.11.0/24 | ap-southeast-7a | EC2 App Servers |
| Private App AZ-b | 10.0.12.0/24 | ap-southeast-7b | EC2 App Servers |
| Private Data AZ-a | 10.0.21.0/24 | ap-southeast-7a | RDS Primary, ElastiCache Primary |
| Private Data AZ-b | 10.0.22.0/24 | ap-southeast-7b | RDS Standby, ElastiCache Replica |

### 3.4 High Availability Design (99.95% Target)

The 99.95% uptime target allows ≤ **4 hours 22 minutes** downtime per year. Achieved via:

- **ALB**: Spans both AZs; health-checks every 30 seconds; routes only to healthy targets
- **EC2 ASG**: Min 2 instances (1 per AZ); replaces unhealthy instances automatically
- **RDS Multi-AZ**: Synchronous replication; automatic failover in ~60-120 seconds
- **ElastiCache**: Primary + Replica; automatic promotion on failure
- **NAT Gateway**: One per AZ; avoids single-AZ dependency
- **Route 53 Health Checks**: Monitors ALB endpoint; DNS-based failover if needed
- **CloudFront**: Serves cached content during brief backend disruptions

---

## 4. Security & Compliance

### 4.1 Encryption Strategy

| Layer | Method |
|---|---|
| Data in transit (public) | TLS 1.3 — CloudFront to user, ALB termination |
| Data in transit (internal) | TLS 1.2+ — App to RDS, App to Redis, App to SQS |
| Data at rest — RDS | AWS KMS CMK (AES-256) |
| Data at rest — S3 | SSE-KMS with CMK |
| Data at rest — SQS | Server-side encryption with CMK |
| Data at rest — ElastiCache | Encryption at rest enabled with CMK |
| Secrets | AWS Secrets Manager with KMS encryption; auto-rotation every 30 days |

### 4.2 IAM & Access Control

- **Least-privilege IAM roles** for all EC2 instances (instance profiles)
- **No long-lived AWS credentials** on EC2; use IAM roles exclusively
- **MFA required** for all human IAM users with console access
- **SCPs (Service Control Policies)** to restrict regions to ap-southeast-7 only
- **Resource-based policies** on S3 buckets to deny public access
- **Stripe API keys** stored in Secrets Manager; retrieved at runtime

### 4.3 Network Security

- **Security Groups**: Stateful; minimal inbound rules
  - ALB SG: 443/80 from 0.0.0.0/0
  - App SG: 8080 from ALB SG only
  - RDS SG: 5432 from App SG only
  - ElastiCache SG: 6379 from App SG only
- **NACLs**: Stateless layer; block known malicious CIDR ranges
- **VPC Flow Logs**: All traffic logged to S3/CloudWatch
- **WAF Rules**: OWASP Top 10, rate limiting (500 req/5min/IP), geo-blocking

### 4.4 Audit & Logging

| Service | Purpose | Retention |
|---|---|---|
| CloudTrail | All AWS API calls | 1 year (S3 + CloudWatch) |
| VPC Flow Logs | Network traffic | 90 days (CloudWatch) |
| ALB Access Logs | HTTP request logs | 90 days (S3) |
| Application Logs | App-level events | 30 days (CloudWatch) |
| RDS Slow Query Logs | DB performance | 14 days |

---

## 5. Cost Estimation

### 5.1 Monthly Infrastructure Cost (ap-southeast-7)

| Service | Spec | Qty | Unit Cost | Monthly |
|---|---|---|---|---|
| EC2 t3.large (App) | 2 vCPU, 8GB | 2 (min) | $67/mo | $134 |
| EC2 t3.large (Scale buffer) | On-demand burst | ~1 avg | $67/mo | $67 |
| EC2 t3.small (Bastion) | 2 vCPU, 2GB | 1 | $15/mo | $15 |
| RDS PostgreSQL Multi-AZ | db.r6g.large | 1 | $350/mo | $350 |
| ElastiCache Redis | cache.r6g.medium × 2 | 2 | $112/mo | $224 |
| Application Load Balancer | - | 1 | $20 + LCU | $50 |
| NAT Gateway | Per AZ | 2 | $35/mo + data | $100 |
| CloudFront | 100GB/mo data | - | - | $40 |
| S3 | 500GB storage | - | - | $25 |
| SQS FIFO | 1M requests/mo | - | - | $5 |
| WAF | Web ACL + rules | 1 | - | $30 |
| CloudWatch | Metrics + logs | - | - | $50 |
| CloudTrail | Management events | - | - | $10 |
| Secrets Manager | 5 secrets | - | - | $5 |
| KMS | CMKs + API calls | - | - | $10 |
| Route 53 | Hosted zone + queries | - | - | $10 |
| ACM | SSL certificates | - | Free | $0 |
| **TOTAL** | | | | **~$1,125/mo** |

### 5.2 Total Budget Allocation

| Category | Monthly Cost |
|---|---|
| AWS Infrastructure | $1,125 |
| 2 × Engineers (senior) | ~$16,000–18,000 |
| Tools & licensing | ~$200 |
| **Total (estimated)** | **~$17,325–$19,325** |
| **Budget remaining** | **~$675–$2,675** |

### 5.3 Cost Optimization Recommendations

- Use **Reserved Instances (1-year)** for RDS and steady-state EC2 to save ~35%
- Enable **CloudFront caching** aggressively for static assets (catalog images, CSS, JS)
- Set **CloudWatch alarms** on estimated charges; alert at 80% of $1,500 infrastructure cap
- Use **S3 Intelligent-Tiering** for backup files older than 30 days
- Review ASG **scheduled scaling** for predictable low-traffic hours (nighttime Thailand)

### 5.4 Scale Impact on Cost

| Scale Factor | Est. Additional Monthly Cost |
|---|---|
| 2x users (1,000 concurrent) | +$135 (ASG scales to 4 instances) |
| 5x users (2,500 concurrent) | +$540 (ASG scales to 8 instances) |
| RDS upgrade to db.r6g.xlarge | +$350/mo |

---

## 6. Implementation Roadmap

### Phase 1: Foundation (Weeks 1–3)
- VPC, subnets, route tables, Internet Gateway, NAT Gateways
- IAM roles, KMS keys, Secrets Manager secrets
- Security Groups and NACLs
- S3 buckets with policies
- CloudTrail and VPC Flow Logs

### Phase 2: Compute & Data (Weeks 4–6)
- RDS PostgreSQL Multi-AZ provisioning and baseline tuning
- ElastiCache Redis cluster setup
- SQS FIFO queue and DLQ
- EC2 launch template, Auto Scaling Group
- ALB with target groups and health checks
- Bastion host with key-pair management

### Phase 3: Application & Integration (Weeks 7–9)
- Application deployment to EC2 (CI/CD pipeline via CodePipeline or manual deploy)
- CloudFront distribution with WAF association
- Route 53 DNS configuration
- Stripe webhook endpoint configuration and testing
- Inventory async pipeline (SQS producer + consumer) integration testing

### Phase 4: Hardening & Go-Live (Weeks 10–12)
- Load testing (500+ concurrent users via Apache JMeter or k6)
- Security penetration testing (WAF rule validation)
- Failover testing: RDS Multi-AZ promotion test, ASG replacement test
- Monitoring dashboards and alerting runbooks
- Documentation handover; production cutover

---

## 7. Risks & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| ap-southeast-7 service availability gaps | Medium | High | Verify all required services in new region before commit; have fallback to ap-southeast-1 |
| Stripe webhook latency from Thailand | Low | Medium | Test Stripe → EC2 round-trip; add retry logic with exponential backoff |
| RDS failover exceeds RTO (>30 min) | Low | High | Test Multi-AZ promotion; implement circuit breaker in app |
| 2-engineer team overload (12-week timeline) | High | High | Prioritize IaC (Terraform); automate testing; defer non-critical features to Phase 2 |
| Inventory sync desync under high load | Medium | Medium | SQS FIFO + DLQ; add idempotency keys; alert on DLQ depth |
| Budget overrun from unexpected data transfer | Low | Medium | CloudWatch billing alarms; NAT Gateway data transfer monitoring |
| WAF blocking legitimate users | Low | Medium | Start in Count mode; review logs before Switch to Block; tune rules |
