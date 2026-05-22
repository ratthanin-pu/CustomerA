# Statement of Work (SOW)
## E-commerce-3 Platform - AWS Thailand Deployment

**Project ID:** ECOM3-TH-2025  
**Client:** E-commerce Platform Owner  
**Vendor:** AWS Solutions Architecture Team  
**Document Date:** February 1, 2025  
**Duration:** 12 weeks (Feb 1 - May 9, 2025)  
**Total Project Cost:** $180,350 USD  

---

## Executive Summary

This Statement of Work outlines the comprehensive design, deployment, and validation of a production-grade e-commerce platform on AWS. The platform will support 5,000 concurrent users, a 1-million-product catalog, real-time inventory management, and Stripe payment processing with 99.95% uptime SLA.

### Scope
- Infrastructure design & deployment (VPC, RDS, EC2, ElastiCache, SQS, SNS, S3)
- Application containerization & CI/CD pipeline
- Database schema design & 1M product seeding
- Stripe payment integration (PCI compliance)
- Async inventory processing (SQS consumer)
- Load testing (5K concurrent users validation)
- Security hardening & penetration testing
- Disaster recovery validation
- Team training & knowledge transfer
- Production cutover (blue-green deployment)

### Budget & Timeline
- **Total Cost:** $180,350 USD (12 weeks)
- **Infrastructure:** $60,000 (3 months × $20K/month)
- **Team:** $105,000 (3 engineers × $35K/month average)
- **3rd-Party Services:** $8,500 (penetration test, PCI audit, certificates)
- **Contingency:** $6,850 (10% buffer)

---

## Deliverables

### D1: Architecture Design Document
**Due:** February 7, 2025  
**Format:** Markdown (15-20 pages) + DrawIO file  
**Owner:** Solutions Architect  

Comprehensive AWS architecture including:
- Executive summary & business drivers
- Use case analysis (functional & non-functional requirements)
- Proposed architecture (network, compute, database, cache, messaging, storage, security)
- Security & compliance mapping (SOC 2 Type II, CIS AWS Foundations, PCI DSS)
- Cost estimation (monthly breakdown, optimization path)
- Implementation roadmap (4 phases, 12 weeks)
- Risk assessment & mitigation
- Monitoring & observability strategy
- Disaster recovery plan

**Acceptance Criteria:**
- [ ] Security team approval on encryption & access control
- [ ] Cost estimate within ±15% of quoted $20K/month
- [ ] All SOC 2 & CIS controls explicitly mapped
- [ ] Multi-AZ failover strategy documented
- [ ] Availability SLA (99.95%) achievable with architecture

**Effort:** 40 hours  
**Cost:** Included in team allocation  

---

### D2: Architecture Diagram (DrawIO + Mermaid)
**Due:** February 7, 2025  
**Format:** DrawIO (.drawio), Mermaid (.mmd), PNG (4K resolution)  
**Owner:** Solutions Architect  

Visual representation of AWS infrastructure:
- All AWS services (EC2, RDS, ElastiCache, SQS, SNS, S3, CloudFront, ALB, KMS)
- Data flows labeled (HTTP, SQL, SQS messages, SNS notifications)
- Multi-AZ redundancy clearly shown
- Security boundaries (public, private, database subnets)
- Color-coded by layer (network, compute, data, security, external)

**Acceptance Criteria:**
- [ ] All AWS services correctly represented
- [ ] Data flows clearly labeled with protocol/payload types
- [ ] Multi-AZ redundancy visible
- [ ] DrawIO file editable (can be imported into AWS Architecture Icons)
- [ ] PNG export high resolution (4K, suitable for presentations)

**Effort:** 16 hours  
**Cost:** Included in team allocation  

---

### D3: Terraform IaC Modules
**Due:** March 7, 2025  
**Format:** Terraform HCL (main.tf, variables.tf, outputs.tf, modules/)  
**Owner:** DevOps Engineer  

Production-grade Terraform code:
- VPC & networking (subnets, route tables, NAT, security groups)
- RDS Aurora MySQL (Multi-AZ, automated backups, cross-region replica)
- ElastiCache Redis (Multi-AZ, encryption, replication)
- EC2 Auto Scaling Group (launch template, health checks, scaling policies)
- Application Load Balancer (target groups, listeners, access logs)
- S3 buckets (versioning, encryption, lifecycle policies)
- KMS keys (encryption, rotation policies)
- AWS Secrets Manager (API keys, passwords)
- CloudWatch (logs, metrics, alarms, dashboards)
- CloudTrail (audit logging to S3)

**Acceptance Criteria:**
- [ ] Single `terraform apply` deploys entire infrastructure
- [ ] All security groups, IAM roles, KMS keys defined
- [ ] Multi-AZ architecture fully codified
- [ ] State stored in S3 with encryption & DynamoDB locking
- [ ] Consistent tagging strategy (Environment, Project, Cost, Owner)
- [ ] Documentation for all variables & outputs
- [ ] Tested against destroy/recreate cycle

**Effort:** 80 hours  
**Cost:** Included in team allocation  

---

### D4: Dockerized Web Application
**Due:** March 28, 2025  
**Format:** Docker image + docker-compose.yml + GitHub Actions workflows  
**Owner:** Full-Stack Engineer  

Containerized e-commerce application:
- Dockerfile (multi-stage build, minimal footprint)
- docker-compose.yml for local development
- GitHub Actions CI/CD pipeline (build → test → ECR → deploy)
- Application code (product API, cart, checkout, inventory sync)
- Health check endpoint (/health, < 100ms response)
- Graceful shutdown handling (SIGTERM → drain connections)
- Structured logging (CloudWatch integration)
- Configuration via environment variables (no hardcoded secrets)

**Acceptance Criteria:**
- [ ] Docker image builds without errors (< 5 min)
- [ ] Docker image runs on EC2, connects to RDS/Redis/S3/SQS
- [ ] Handles 5K concurrent users (load tested)
- [ ] Stripe webhook handling with idempotency
- [ ] Graceful shutdown (no dropped connections)
- [ ] Health check endpoint responds in < 100ms
- [ ] All logs flow to CloudWatch Logs
- [ ] CI/CD pipeline deploys to staging automatically

**Effort:** 80 hours  
**Cost:** Included in team allocation  

---

### D5: Database Schema & Indexes
**Due:** March 14, 2025  
**Format:** SQL files + migration scripts + performance report  
**Owner:** Full-Stack Engineer  

Optimized MySQL schema for 1M products:
- Tables: products, categories, carts, cart_items, orders, order_items, inventory_queue, users, audit_logs
- Indexes optimized for common queries (product search, order lookup)
- Foreign key constraints & data integrity
- Migration scripts (Flyway-compatible)
- 1M product seed data (synthetic, realistic)
- Performance baseline report

**Acceptance Criteria:**
- [ ] 1M products loaded successfully
- [ ] Product search query (category + price) < 200ms p95 latency
- [ ] Cart lookup < 50ms latency
- [ ] Inventory updates < 500ms latency
- [ ] Backup/restore tested (RTO < 30 min)
- [ ] No N+1 query problems
- [ ] Proper indexing on hot queries
- [ ] Audit logs functional for GDPR compliance

**Effort:** 60 hours  
**Cost:** Included in team allocation  

---

### D6: Monitoring & Observability Setup
**Due:** April 11, 2025  
**Format:** Terraform + CloudWatch Dashboards + Runbooks  
**Owner:** DevOps Engineer  

Complete monitoring stack:
- CloudWatch dashboards (real-time health, performance, cost)
- CloudWatch alarms (error rate, latency, CPU, RDS, cache)
- CloudWatch Logs (application, VPC Flow Logs, RDS slow query)
- X-Ray tracing (request-level visibility, Stripe calls)
- CloudTrail audit logging (compliance, security)
- On-call escalation procedures (PagerDuty integration)

**Acceptance Criteria:**
- [ ] Dashboard shows real-time health (ALB targets, RDS CPU, cache hits)
- [ ] Alarms for all critical thresholds (error rate, latency, CPU)
- [ ] Logs centralized in CloudWatch Logs (30-day retention)
- [ ] X-Ray tracing enabled for payment flow
- [ ] CloudTrail logging all API calls to S3
- [ ] On-call rotation documented
- [ ] Runbooks for common incidents (RDS failover, scaling, payment issues)

**Effort:** 40 hours  
**Cost:** Included in team allocation  

---

### D7: Security Hardening & Compliance Report
**Due:** April 25, 2025  
**Format:** PDF report + remediation checklist  
**Owner:** Security Engineer (with 3rd-party penetration tester)  

Security assessment outcomes:
- 3rd-party penetration test report (OWASP Top 10 coverage)
- Vulnerability findings (CVSS scores, remediation status)
- OWASP remediation (SQLi, XSS, CSRF, RCE prevention)
- PCI DSS Level 1 checklist (payment data security)
- SOC 2 Type II control evidence
- Security hardening steps applied
- SSL/TLS certificate validation
- No hardcoded secrets audit (Secrets Manager)

**Acceptance Criteria:**
- [ ] Penetration test by 3rd party (PCI-approved)
- [ ] No CVSS 4.0+ vulnerabilities on launch
- [ ] PCI DSS Level 1 checklist signed off
- [ ] All OWASP Top 10 controls documented
- [ ] SSL/TLS certificate valid, non-expired
- [ ] No secrets committed to git (pre-commit hooks)
- [ ] Remediation plan for any findings

**Effort:** 20 hours (internal) + 40 hours (external)  
**Cost:** $5,000 (penetration testing, external)  

---

### D8: Load Testing & Performance Validation
**Due:** April 18, 2025  
**Format:** JMeter test files + HTML report with graphs  
**Owner:** QA Engineer  

Load test execution & analysis:
- JMeter test plan (product search, add to cart, checkout)
- Ramp-up: 0 → 5K concurrent users over 10 minutes
- Sustained: 5K users for 30 minutes
- Measurements: latency (p50/p95/p99), error rate, throughput
- CloudWatch metrics collection
- Auto-scaling behavior validation
- Bottleneck identification & optimization recommendations

**Acceptance Criteria:**
- [ ] 5K concurrent users sustained for 30 min without errors
- [ ] P95 latency < 500ms achieved
- [ ] P99 latency < 1000ms achieved
- [ ] Cache hit rate > 80%
- [ ] Error rate < 0.1%
- [ ] ASG scaling works correctly (responds to CPU)
- [ ] Database connection pool not saturated
- [ ] All metrics captured in report

**Effort:** 40 hours  
**Cost:** Included in team allocation  

---

### D9: Disaster Recovery Runbook
**Due:** April 25, 2025  
**Format:** Markdown wiki + video tutorials  
**Owner:** DevOps Engineer + Solutions Architect  

Step-by-step recovery procedures:
- RDS Multi-AZ failover (automatic, RTO < 30 sec)
- EC2 AZ failure recovery (automatic ASG replacement, RTO < 2 min)
- RDS backup/restore from snapshot (manual, RTO < 30 min)
- Cross-region failover to ap-southeast-1 (manual, RTO < 15 min)
- Payment processing incident response
- Data corruption detection & recovery
- DDoS attack response (AWS Shield)
- Team roles & responsibilities
- Video walkthroughs for each procedure

**Acceptance Criteria:**
- [ ] RDS Multi-AZ failover < 30 sec (tested, timed)
- [ ] Cross-region failover < 15 min (manual, tested)
- [ ] Backup restore from 1-week snapshot successful
- [ ] All procedures tested in staging environment
- [ ] Team trained and certified
- [ ] Video tutorials for complex procedures
- [ ] Escalation contacts documented

**Effort:** 30 hours  
**Cost:** Included in team allocation  

---

### D10: Project Handoff & Knowledge Transfer
**Due:** May 9, 2025  
**Format:** Confluence wiki + Training materials + Runbooks + Slack automation  
**Owner:** Solutions Architect  

Complete documentation & team training:
- Architecture overview document (non-technical friendly)
- Runbooks wiki (RDS, EC2, incident response)
- Troubleshooting FAQ (common issues & solutions)
- On-call playbook (escalation, notification, resolution)
- Cost tracking dashboard (budget alerts active)
- 3-month optimization roadmap (Reserved Instances, performance tuning)
- Security baseline documentation (compliance, access control)
- Team training sessions (hands-on labs, scenario walkthroughs)

**Acceptance Criteria:**
- [ ] Team can independently manage RDS, EC2, ASG failover
- [ ] Cost tracking dashboard active (alerts at $15K)
- [ ] 3-month optimization plan documented
- [ ] Security baseline maintained (monthly audits scheduled)
- [ ] SLA monitoring 24/7 via PagerDuty
- [ ] All team members certified on runbooks
- [ ] On-call rotation active (primary, secondary, tertiary)

**Effort:** 40 hours  
**Cost:** Included in team allocation  

---

## Timeline & Phases

### Phase 1: Infrastructure Foundation (Weeks 1-4)
**Duration:** February 1 - February 28, 2025  
**Team:** Solutions Architect (50%), DevOps Engineer (100%)  
**Deliverables:** D1, D2, D3 (partial)  

Activities:
- Week 1-2: Architecture design review, security assessment, team training
- Week 3: VPC, networking, RDS Aurora setup
- Week 4: EC2 ASG, ALB, ElastiCache, failover testing

**Success Criteria:**
- VPC fully operational
- RDS Multi-AZ active, automated backups running
- EC2 ASG launching instances correctly
- All failover tests passed
- Architecture approved by security team

---

### Phase 2: Application Development & Deployment (Weeks 5-8)
**Duration:** March 1 - March 28, 2025  
**Team:** Full-Stack Engineer (80%), DevOps Engineer (50%)  
**Deliverables:** D3 (complete), D4, D5  

Activities:
- Week 5: Containerization, CI/CD pipeline setup
- Week 6: Database schema, 1M product seeding, query optimization
- Week 7: Stripe payment integration, error handling
- Week 8: Inventory async processing (SQS/SNS)

**Success Criteria:**
- Docker image running on EC2, connected to all services
- 1M products loaded, search < 200ms latency
- Stripe payment flow end-to-end
- Inventory worker processing 100+ msg/sec
- SNS notifications publishing

---

### Phase 3: Testing & Hardening (Weeks 9-10)
**Duration:** April 1 - April 18, 2025  
**Team:** QA Engineer (100%), Security Engineer (50%), DevOps (50%), Solutions Architect (50%)  
**Deliverables:** D6, D7, D8, D9  

Activities:
- Week 9: Load testing (5K concurrent users), performance analysis
- Week 10: Security penetration test, PCI compliance, DR testing

**Success Criteria:**
- Load test passed (P95 < 500ms, error rate < 0.1%)
- Penetration test findings remediated (no CVSS 4+)
- PCI DSS compliance verified
- Disaster recovery procedures tested & documented
- Team trained on runbooks

---

### Phase 4: Production Cutover & Handoff (Weeks 11-12)
**Duration:** April 19 - May 9, 2025  
**Team:** DevOps Engineer (100%), Solutions Architect (50%), Full-Stack Engineer (50%)  
**Deliverables:** D10  

Activities:
- Week 11: Blue-green deployment, traffic shift (10% → 50% → 100%)
- Week 12: Stabilization, team knowledge transfer, project closure

**Success Criteria:**
- 100% traffic on production, no critical incidents
- 24-hour no-incidents rule satisfied
- Team trained & on-call rotation active
- All documentation complete

---

## Budget

### Infrastructure Costs (Monthly)

| Service | Configuration | Monthly Cost |
|---------|---|------|
| EC2 | 4x c6i.2xlarge | $1,987 |
| RDS Aurora | 1 primary + read replica | $3,504 |
| ElastiCache | cache.r6g.2xlarge Multi-AZ | $2,001 |
| ALB | 1 load balancer + LCU | $543 |
| S3 + CloudFront | Storage + CDN | $4,267 |
| NAT Gateway | 2x NAT + data transfer | $115 |
| KMS | 1 key | $1 |
| CloudWatch | Logs + metrics | $28 |
| RDS Backups | 100GB retention | $10 |
| Miscellaneous | VPC endpoints, Systems Manager | $150 |
| **Subtotal** | | **$12,606** |
| **Buffer (15%)** | | **$1,891** |
| **Monthly Total** | | **$14,497** |

**Within $20,000/month budget with $5,503/month contingency**

### Project Costs (12-Week Breakdown)

| Category | Amount | Notes |
|----------|--------|-------|
| **Infrastructure (3 months)** | $60,000 | 3 × $20K/month |
| **Team (3 engineers × $35K/month)** | $105,000 | 12 weeks = 3 months |
| **3rd-Party Services** | $8,500 | Penetration test ($5K), PCI audit ($3K), SSL cert ($500) |
| **Contingency (10%)** | $6,850 | Buffer for unexpected costs |
| **TOTAL** | **$180,350** | Complete project cost |

**Note:** Infrastructure costs are operational costs (monthly recurring). After project completion, platform costs $14.5K-20K/month ongoing.

---

## Acceptance Criteria & Sign-Off

### Deliverable Acceptance

All deliverables must meet stated acceptance criteria before project closure.

| Deliverable | Responsible | Due Date | Criteria |
|---|---|---|---|
| D1 | Solutions Architect | Feb 7 | Security approval, cost ±15%, SLA achievable |
| D2 | Solutions Architect | Feb 7 | Visually complete, DrawIO editable |
| D3 | DevOps Engineer | Mar 7 | One-command deployment, tested |
| D4 | Full-Stack Engineer | Mar 28 | Runs on EC2, handles 5K concurrent, all services connected |
| D5 | Full-Stack Engineer | Mar 14 | 1M products, < 200ms queries, backup tested |
| D6 | DevOps Engineer | Apr 11 | Dashboards live, alarms working, logs flowing |
| D7 | Security Engineer | Apr 25 | No CVSS 4+ vulnerabilities, PCI checklist signed |
| D8 | QA Engineer | Apr 18 | P95 < 500ms, error rate < 0.1%, ASG scaling proven |
| D9 | DevOps Engineer | Apr 25 | Procedures tested, team trained, documented |
| D10 | Solutions Architect | May 9 | Team certified, on-call active, documentation complete |

### Final Sign-Off

**Client Acceptance:**
- Client representative sign-off on all deliverables
- Production infrastructure approval
- Team training completion verification

**Vendor Accountability:**
- All deliverables completed on-time and within scope
- No outstanding blockers to production launch
- 24-hour production stability validated

**Date Signed:** __________ (May 9, 2025)  
**Client:** __________ (Name, Title)  
**Vendor:** __________ (Solutions Architect, Name)  

---

## Terms & Conditions

### Scope Boundaries

**In Scope:**
- AWS infrastructure design & deployment (VPC, RDS, EC2, etc.)
- Application containerization & CI/CD
- Database schema & initial data load
- Stripe payment integration
- Load testing & optimization
- Security hardening & compliance
- Team training & knowledge transfer
- 12-week project delivery

**Out of Scope:**
- Ongoing 24/7 managed services (support contract separate)
- Custom application feature development (beyond scope)
- License purchases (software, third-party tools)
- Multi-region active-active setup (Phase 2+)
- Advanced analytics/reporting system (Phase 2+)

### Change Control

Any changes to scope, timeline, or budget require:
1. Change Request document (description, impact, cost, timeline)
2. Client approval (email confirmation)
3. Impact analysis (schedule, resources, cost)
4. Revised SOW signature (both parties)

### Assumptions

- Client provides AWS account(s) in ap-southeast-7 region
- Client provides Stripe account (or assist with setup)
- Team of 3 engineers available full-time for 12 weeks
- No external dependencies (data integration, legacy systems)
- Internet connectivity & development tool access available
- Decision-makers available for weekly status reviews

### Risks & Mitigation

See Detailed Implementation Plan (Document 02) for comprehensive risk assessment.

### Timeline & Delivery

- Project starts: February 1, 2025
- Project ends: May 9, 2025
- Weekly status meetings (Thursdays, 10 AM)
- Bi-weekly steering committee reviews
- Go/No-Go decision: Friday, April 18, 2025 (end of Week 10)

### Payment Terms

- **Milestone 1 (Feb 28):** 25% ($45,088) - Phase 1 completion
- **Milestone 2 (Mar 28):** 25% ($45,088) - Phase 2 completion
- **Milestone 3 (Apr 18):** 25% ($45,088) - Phase 3 completion
- **Milestone 4 (May 9):** 25% ($45,087) - Final delivery & sign-off

**Total:** $180,350 USD

---

## Appendix: Glossary

| Term | Definition |
|------|-----------|
| **RTO** | Recovery Time Objective - max acceptable downtime (< 30 min target) |
| **RPO** | Recovery Point Objective - max acceptable data loss (< 1 hour target) |
| **SLA** | Service Level Agreement - 99.95% uptime commitment |
| **Multi-AZ** | Multiple Availability Zones for redundancy |
| **IaC** | Infrastructure as Code (Terraform) |
| **CI/CD** | Continuous Integration / Continuous Deployment (GitHub Actions) |
| **PCI DSS** | Payment Card Industry Data Security Standard (Level 1 compliance) |
| **SOC 2** | System and Organization Controls audit (Type II for 12-month period) |
| **KMS** | AWS Key Management Service (encryption keys) |
| **VPC** | Virtual Private Cloud (isolated network) |

---

**Document End**
