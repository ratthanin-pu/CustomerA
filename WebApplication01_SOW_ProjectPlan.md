# Statement of Work & Project Plan
## WebApplication01 — Customer Support Platform

**Version:** 1.0 | **Date:** 2026-05-25 | **Region:** ap-southeast-7

---

## Part A: Statement of Work (SOW)

### A1. Project Information

| Field | Value |
|---|---|
| Project Name | WebApplication01 — Customer Support Platform |
| Client | CustomerA |
| Start Date | 2026-06-01 |
| End Date | 2026-08-23 |
| Duration | 12 weeks |
| Team Size | 2 engineers |
| Monthly Budget | $20,000 USD |

### A2. Objective

Deploy a production-grade, highly available (99.95% SLA) Customer Support Web Platform on AWS ap-southeast-7 (Thailand) using a traditional multi-tier EC2 architecture. The platform will support 500 concurrent users, a product catalog of 50 items, asynchronous real-time inventory management, and Stripe-integrated payment processing.

### A3. Deliverables

| ID | Deliverable | Description | Due Date |
|---|---|---|---|
| D1 | Architecture Design Document | Full AWS architecture design with cost breakdown | 2026-06-07 |
| D2 | Terraform IaC Modules | Production-grade Terraform for all infrastructure | 2026-06-28 |
| D3 | CI/CD Pipeline | CodePipeline or equivalent for app deployment | 2026-07-12 |
| D4 | Application Deployment | Customer support app running on EC2 | 2026-07-26 |
| D5 | Monitoring & Alerting Setup | CloudWatch dashboards + PagerDuty/SNS alerts | 2026-08-02 |
| D6 | Load Test Report | 500+ concurrent user test results | 2026-08-09 |
| D7 | Security Hardening Report | WAF tuning, pen test results, compliance evidence | 2026-08-16 |
| D8 | Operations Runbook | Incident response, failover procedures, backup/restore | 2026-08-23 |

### A4. Scope

**In Scope:**
- AWS infrastructure provisioning (VPC, EC2, RDS, ElastiCache, SQS, ALB, CloudFront, WAF)
- Terraform IaC for all infrastructure components
- EC2-based application deployment and configuration
- Stripe payment integration (webhook endpoints)
- SQS-based async inventory pipeline
- CloudWatch monitoring, alarms, and dashboards
- Security group configuration, WAF rules, KMS encryption
- SOC 2 Type II and CIS AWS Foundations compliance documentation

**Out of Scope:**
- Application code development (assumed pre-existing)
- Stripe account setup and KYC
- Third-party inventory system integration (SQS producer assumed)
- Data migration from existing systems
- Mobile application development

### A5. Budget Summary

| Category | Monthly | 12-Week Total |
|---|---|---|
| AWS Infrastructure | $1,125 | ~$3,375 |
| Engineering (2 × senior) | $18,000 | ~$54,000 |
| Tools & Licensing | $200 | ~$600 |
| Contingency (10%) | $1,933 | ~$5,798 |
| **Total** | **~$21,258** | **~$63,773** |

*Note: Monthly budget of $20,000 covers infrastructure + team. Contingency applied to infrastructure + tools only.*

### A6. Acceptance Criteria

- Architecture approved by security team prior to build
- All D-deliverables reviewed and signed off
- Load test confirms 500 concurrent users with < 2s P95 response time
- RDS Multi-AZ failover tested; RTO confirmed < 30 minutes
- All SOC 2 / CIS controls documented with evidence
- Zero critical findings in security hardening report
- Monitoring alerts proven to fire within 5 minutes of incident simulation
- Cost estimate within ±15% of actual first-month infrastructure spend

### A7. Assumptions & Dependencies

- AWS account exists and ap-southeast-7 region is enabled
- Application code is deployable on Ubuntu 22.04 LTS EC2 instances
- Stripe account and API keys are available before Week 7
- External inventory system will publish events to SQS by Week 7
- DNS domain is registered and transferable to Route 53

---

## Part B: Project Implementation Plan

### B1. Timeline Overview (12 Weeks)

```
gantt
    title WebApplication01 Deployment Timeline
    dateFormat YYYY-MM-DD
    axisFormat %d-%b

    section Phase 1 — Foundation
        Architecture Review & Sign-off        :crit, p1a, 2026-06-01, 7d
        VPC & Networking (Terraform)          :p1b, after p1a, 7d
        IAM, KMS, Secrets Manager             :p1c, 2026-06-08, 5d
        S3, CloudTrail, Flow Logs             :p1d, 2026-06-10, 4d

    section Phase 2 — Compute & Data
        RDS Multi-AZ Provisioning             :crit, p2a, 2026-06-15, 7d
        ElastiCache Redis Cluster             :p2b, 2026-06-15, 5d
        SQS FIFO Queue + DLQ                  :p2c, 2026-06-18, 3d
        EC2 Launch Template + ASG             :p2d, after p2a, 7d
        ALB + Target Groups + Health Checks   :p2e, 2026-06-22, 5d
        Bastion Host Setup                    :p2f, 2026-06-22, 2d

    section Phase 3 — Application & Integration
        CloudFront + WAF (Count Mode)         :p3a, 2026-07-06, 5d
        Route 53 DNS Configuration            :p3b, 2026-07-06, 2d
        Application Deployment to EC2         :crit, p3c, 2026-07-08, 10d
        Stripe Webhook Integration & Test     :p3d, 2026-07-13, 5d
        Inventory SQS Pipeline Integration    :p3e, 2026-07-13, 7d
        CI/CD Pipeline Setup                  :p3f, 2026-07-06, 7d

    section Phase 4 — Hardening & Go-Live
        Load Testing (k6 / JMeter)            :crit, p4a, 2026-08-03, 5d
        WAF Switch to Block Mode + Tuning     :p4b, 2026-08-03, 3d
        Security Pen Test & Remediation       :p4c, 2026-08-06, 5d
        Failover Testing (RDS + ASG)          :p4d, 2026-08-06, 3d
        Monitoring Dashboards & Runbooks      :p4e, 2026-08-10, 5d
        Production Cutover                    :crit, milestone, p4f, 2026-08-21, 2d
```

### B2. Weekly Task Breakdown

#### Weeks 1–2 (2026-06-01 to 2026-06-14): Design & Foundation
- [ ] Architecture review with stakeholders; sign-off on design document (D1)
- [ ] SOC 2 / CIS AWS compliance checklist review
- [ ] Terraform project structure setup (modules: vpc, ec2, rds, elasticache, alb, security)
- [ ] VPC creation: 6 subnets, route tables, IGW
- [ ] NAT Gateways × 2 (one per AZ)
- [ ] IAM roles and policies (EC2 instance profiles, least-privilege)
- [ ] KMS customer-managed keys (RDS, S3, SQS, ElastiCache)
- [ ] Secrets Manager secrets: Stripe API key, DB credentials
- [ ] S3 buckets: static assets, backups, logs (block public access, SSE-KMS)
- [ ] CloudTrail + VPC Flow Logs enabled

#### Weeks 3–4 (2026-06-15 to 2026-06-28): Compute & Data Layer
- [ ] RDS PostgreSQL 15 Multi-AZ deployment (db.r6g.large, 100GB gp3)
- [ ] ElastiCache Redis 7.x cluster (cache.r6g.medium, 2 nodes, encryption enabled)
- [ ] SQS FIFO queue + Dead Letter Queue configuration
- [ ] EC2 Launch Template (Ubuntu 22.04, t3.large, user data for app dependencies)
- [ ] Auto Scaling Group (min: 2, max: 6, target tracking: 60% CPU)
- [ ] Application Load Balancer (listener rules, target group, health check: /health)
- [ ] Bastion Host (t3.small) with strict Security Group
- [ ] Terraform state in S3 with DynamoDB locking (D2 — partial)

#### Weeks 5–6 (2026-06-29 to 2026-07-12): Completion of IaC & Pipeline
- [ ] Terraform modules for all services completed and peer-reviewed (D2 — final)
- [ ] CI/CD pipeline: GitHub → CodeBuild → S3 artifact → CodeDeploy to EC2 (D3)
- [ ] CloudFront distribution (S3 origin for static, ALB origin for dynamic)
- [ ] WAF Web ACL attached to ALB and CloudFront (Count mode initially)
- [ ] Route 53 hosted zone configuration; SSL certificate via ACM

#### Weeks 7–9 (2026-07-13 to 2026-08-02): Application & Integration
- [ ] Application deployment and smoke testing (D4)
- [ ] Stripe webhook endpoint: /api/payments/webhook (HTTPS, signature validation)
- [ ] Stripe payment flow end-to-end testing (test mode → live mode)
- [ ] SQS inventory consumer on EC2: poll, process, update RDS
- [ ] ElastiCache session configuration in application
- [ ] CloudWatch metrics: custom metrics for support tickets/min, inventory lag
- [ ] CloudWatch alarms: CPU > 75%, RDS connections > 80%, SQS DLQ depth > 0 (D5)
- [ ] SNS topics for alerting (email + Slack webhook)

#### Weeks 10–11 (2026-08-03 to 2026-08-16): Hardening
- [ ] Load test: 500 concurrent users sustained 30 min (k6 or Apache JMeter) (D6)
- [ ] Performance tuning: RDS parameter group, ElastiCache TTLs, ASG scale-in cooldown
- [ ] WAF switch to Block mode; false-positive review
- [ ] Security penetration test (external scanner or manual OWASP)
- [ ] Remediate any findings; re-test (D7)
- [ ] RDS Multi-AZ failover drill; document actual failover time
- [ ] ASG instance termination test; verify replacement < 5 minutes

#### Week 12 (2026-08-17 to 2026-08-23): Go-Live
- [ ] Operations runbook finalized (D8)
- [ ] DNS cutover to Route 53
- [ ] Production Stripe keys rotated into Secrets Manager
- [ ] 24-hour production monitoring watch
- [ ] Formal handover and sign-off

### B3. Resource Allocation

| Phase | Duration | Tasks (Engineer 1) | Tasks (Engineer 2) |
|---|---|---|---|
| Design & Foundation | 2 weeks | Architecture, Terraform VPC/IAM | CloudTrail, S3, Security groups, KMS |
| Compute & Data | 2 weeks | RDS, ElastiCache, ASG | ALB, SQS, Bastion, Launch Template |
| IaC & Pipeline | 2 weeks | Terraform finalization, CI/CD | CloudFront, WAF, Route 53 |
| App & Integration | 3 weeks | App deployment, Stripe | SQS consumer, CloudWatch, SNS |
| Hardening | 2 weeks | Load testing, performance tuning | WAF tuning, pen test, failover drill |
| Go-Live | 1 week | DNS cutover, production monitoring | Runbooks, handover documentation |

### B4. Communication Plan

| Meeting | Frequency | Participants | Purpose |
|---|---|---|---|
| Daily Standup | Daily (15 min) | Both engineers | Blockers, progress |
| Architecture Review | Week 1 end | Engineers + stakeholder | Design sign-off |
| Sprint Demo | Every 2 weeks | Engineers + stakeholder | Deliverable review |
| Go/No-Go Review | Week 11 end | All | Production cutover approval |

---

## Part C: SOW JSON Reference

```json
{
  "sow": {
    "project_name": "WebApplication01 — Customer Support Platform",
    "objective": "Deploy highly available customer support platform on AWS ap-southeast-7 with 99.95% SLA, 500 concurrent users, Stripe payments, async inventory, no serverless",
    "deliverables": [
      {"id": "D1", "name": "Architecture Design Document", "due_date": "2026-06-07"},
      {"id": "D2", "name": "Terraform IaC Modules", "due_date": "2026-06-28"},
      {"id": "D3", "name": "CI/CD Pipeline", "due_date": "2026-07-12"},
      {"id": "D4", "name": "Application Deployment", "due_date": "2026-07-26"},
      {"id": "D5", "name": "Monitoring & Alerting", "due_date": "2026-08-02"},
      {"id": "D6", "name": "Load Test Report", "due_date": "2026-08-09"},
      {"id": "D7", "name": "Security Hardening Report", "due_date": "2026-08-16"},
      {"id": "D8", "name": "Operations Runbook", "due_date": "2026-08-23"}
    ],
    "timeline": {
      "start_date": "2026-06-01",
      "end_date": "2026-08-23",
      "phases": [
        {"name": "Phase 1: Foundation", "start": "2026-06-01", "end": "2026-06-14", "deliverables": ["D1"], "resources": 2},
        {"name": "Phase 2: Compute & Data", "start": "2026-06-15", "end": "2026-06-28", "deliverables": ["D2"], "resources": 2},
        {"name": "Phase 3: Application & Integration", "start": "2026-06-29", "end": "2026-08-02", "deliverables": ["D3","D4","D5"], "resources": 2},
        {"name": "Phase 4: Hardening & Go-Live", "start": "2026-08-03", "end": "2026-08-23", "deliverables": ["D6","D7","D8"], "resources": 2}
      ]
    },
    "budget": {
      "infrastructure_monthly_usd": 1125,
      "team_cost_monthly_usd": 18000,
      "tools_monthly_usd": 200,
      "contingency_pct": 10,
      "total_monthly_usd": 20000
    },
    "acceptance_criteria": [
      "Architecture approved by security team before build",
      "500 concurrent users with P95 < 2 seconds confirmed by load test",
      "RDS Multi-AZ failover RTO < 30 minutes",
      "Zero critical security findings in hardening report",
      "All SOC 2 Type II and CIS AWS Foundations controls documented",
      "CloudWatch alarms fire within 5 minutes of incident simulation",
      "Infrastructure cost within ±15% of $1,125/month estimate"
    ]
  }
}
```
