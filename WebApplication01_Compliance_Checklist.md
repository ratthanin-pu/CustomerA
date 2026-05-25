# SOC 2 Type II & CIS AWS Foundations Compliance Checklist
## WebApplication01 — Customer Support Platform

**Assessment Date:** 2026-05-25  
**Region:** ap-southeast-7 (Thailand)  
**Framework Versions:** SOC 2 Type II (AICPA 2017 TSC), CIS AWS Foundations Benchmark v1.4  

---

## Summary Dashboard

| Framework | Total Controls | Implemented | In Progress | Not Applicable |
|---|---|---|---|---|
| SOC 2 Type II | 17 | 12 | 5 | 0 |
| CIS AWS Foundations v1.4 | 28 | 20 | 8 | 0 |
| **Total** | **45** | **32** | **13** | **0** |

---

## Part 1: SOC 2 Type II Controls

### CC1 — Control Environment

| Control ID | Control Name | Requirement | AWS Implementation | Status | Priority |
|---|---|---|---|---|---|
| CC1.1 | COSO Principle 1: Demonstrates Commitment to Integrity | Establish policies for security and ethical behavior | IAM password policy enforced; MFA required for all console users; documented acceptable use policy | REQUIRED | CRITICAL |
| CC1.2 | COSO Principle 2: Exercises Oversight Responsibility | Board/management oversight of security | Security review gate before each phase; architecture sign-off required | REQUIRED | HIGH |

### CC2 — Communication and Information

| Control ID | Control Name | Requirement | AWS Implementation | Status | Priority |
|---|---|---|---|---|---|
| CC2.1 | COSO Principle 13: Uses Relevant Information | Identify and use information to support controls | CloudWatch Logs + CloudTrail for all events; VPC Flow Logs enabled | REQUIRED | CRITICAL |
| CC2.2 | COSO Principle 14: Internal Communication | Communicate control information internally | SNS alerting to engineering team; runbook documentation | REQUIRED | HIGH |

### CC3 — Risk Assessment

| Control ID | Control Name | Requirement | AWS Implementation | Status | Priority |
|---|---|---|---|---|---|
| CC3.1 | COSO Principle 6: Specifies Objectives | Define and communicate security objectives | Architecture design document with SLA targets; Terraform enforces configurations | REQUIRED | HIGH |
| CC3.2 | COSO Principle 7: Identifies and Analyzes Risk | Identify risks to achieving objectives | Risk register in design doc; AWS Trusted Advisor + Security Hub | REQUIRED | HIGH |

### CC6 — Logical and Physical Access Controls

| Control ID | Control Name | Requirement | AWS Implementation | Status | Priority |
|---|---|---|---|---|---|
| CC6.1 | Logical Access Controls | Restrict logical access to authorized users | IAM least-privilege roles; no shared credentials; Secrets Manager for app secrets; MFA required | REQUIRED | CRITICAL |
| CC6.2 | Authentication Mechanisms | Authenticate users before granting access | EC2 key pairs + IAM roles; ALB HTTPS only; application-level auth (assumed) | REQUIRED | CRITICAL |
| CC6.3 | Authorization | Restrict access based on roles | IAM policies by role; RDS SG restricts to App SG only; S3 bucket policies block public | REQUIRED | CRITICAL |
| CC6.6 | Security Boundaries | Implement logical network boundaries | VPC with public/private subnet separation; NACLs; Security Groups; WAF | REQUIRED | CRITICAL |
| CC6.7 | Transmission Integrity and Confidentiality | Protect data in transit | TLS 1.3 on CloudFront; TLS 1.2+ on ALB; encrypted RDS/Redis connections | REQUIRED | CRITICAL |
| CC6.8 | Malware Protection | Protect against malware | AWS WAF OWASP rules; EC2 Amazon Inspector; OS patching via SSM Patch Manager | REQUIRED | HIGH |

### CC7 — System Operations

| Control ID | Control Name | Requirement | AWS Implementation | Status | Priority |
|---|---|---|---|---|---|
| CC7.1 | System Monitoring | Monitor system components | CloudWatch alarms: CPU, RDS connections, SQS DLQ depth, ALB 5xx rate | REQUIRED | CRITICAL |
| CC7.2 | Anomaly Detection | Detect anomalies and events | AWS GuardDuty enabled; CloudWatch anomaly detection on key metrics; WAF rate limiting | IN PROGRESS | HIGH |
| CC7.3 | Incident Response | Respond to identified security events | Incident response runbook (D8); SNS alerts with escalation path; RDS failover playbook | IN PROGRESS | HIGH |

### CC8 — Change Management

| Control ID | Control Name | Requirement | AWS Implementation | Status | Priority |
|---|---|---|---|---|---|
| CC8.1 | Change Control Process | Manage changes to systems | Terraform IaC: all changes via PR + plan + apply workflow; no manual console changes in prod | REQUIRED | CRITICAL |

### CC9 — Risk Mitigation

| Control ID | Control Name | Requirement | AWS Implementation | Status | Priority |
|---|---|---|---|---|---|
| CC9.2 | Third-Party Risk | Manage risks from vendors and partners | Stripe PCI-DSS compliance verified; API keys in Secrets Manager; webhook signature validation | IN PROGRESS | HIGH |

### A1 — Availability

| Control ID | Control Name | Requirement | AWS Implementation | Status | Priority |
|---|---|---|---|---|---|
| A1.1 | Capacity Management | Maintain sufficient capacity | EC2 Auto Scaling (min 2, max 6); RDS Multi-AZ; CloudWatch capacity alarms | REQUIRED | CRITICAL |
| A1.2 | Environmental Protections | Protect against environmental threats | AWS Multi-AZ spans physically separate data centers in ap-southeast-7 | REQUIRED | CRITICAL |

---

## Part 2: CIS AWS Foundations Benchmark v1.4

### Section 1 — Identity and Access Management

| CIS ID | Title | Recommendation | AWS Service | Status | Priority |
|---|---|---|---|---|---|
| 1.1 | Maintain current contact details | Ensure account contact email is monitored | AWS Account Settings | REQUIRED | HIGH |
| 1.2 | Ensure security contact is registered | Register security contact in account | AWS Account Settings | REQUIRED | HIGH |
| 1.3 | No root account usage for daily tasks | Root account not used for operations | IAM: root MFA enabled; CloudTrail alert on root login | REQUIRED | CRITICAL |
| 1.4 | Enable MFA for root account | Root account has MFA enabled | IAM root MFA (hardware token recommended) | REQUIRED | CRITICAL |
| 1.5 | No root account access keys | No active access keys for root | IAM: verify no root access keys exist | REQUIRED | CRITICAL |
| 1.6 | Enable MFA for IAM users with console access | All console users have MFA | IAM password policy + MFA requirement SCP | REQUIRED | CRITICAL |
| 1.7 | Password policy: minimum length 14 | IAM password policy configured | IAM Account Password Policy: 14+ chars, complexity, 90-day rotation | REQUIRED | HIGH |
| 1.8 | No inline IAM policies | Use managed policies | All EC2 roles use AWS managed or customer managed policies; no inline | IN PROGRESS | HIGH |
| 1.9 | Permissions via groups/roles | No direct user policy attachments | IAM groups for humans; IAM roles for EC2 | IN PROGRESS | HIGH |
| 1.10 | Decommission unused credentials | Disable credentials unused > 90 days | IAM Access Analyzer; quarterly credential audit | REQUIRED | HIGH |
| 1.11 | Rotate access keys every 90 days | Rotate IAM access keys regularly | Secrets Manager auto-rotation; no long-lived access keys on EC2 | REQUIRED | HIGH |

### Section 2 — Storage (S3)

| CIS ID | Title | Recommendation | AWS Service | Status | Priority |
|---|---|---|---|---|---|
| 2.1 | S3 Block Public Access | Enable at account level | S3 Account Public Access Block: all 4 settings enabled | REQUIRED | CRITICAL |
| 2.2 | S3 MFA Delete on CloudTrail bucket | Enable MFA delete on log buckets | S3 MFA Delete on CloudTrail S3 bucket | IN PROGRESS | HIGH |
| 2.3 | CloudTrail log file validation | Enable log file integrity validation | CloudTrail: Enable log file validation = true | REQUIRED | HIGH |

### Section 3 — Logging

| CIS ID | Title | Recommendation | AWS Service | Status | Priority |
|---|---|---|---|---|---|
| 3.1 | Enable CloudTrail in all regions | Multi-region CloudTrail trail | CloudTrail: Multi-region trail with management events | REQUIRED | CRITICAL |
| 3.2 | CloudTrail log file validation | Enable integrity validation | CloudTrail log file validation enabled | REQUIRED | HIGH |
| 3.3 | CloudTrail integrated with CloudWatch Logs | Ship to CloudWatch for alerting | CloudTrail → CloudWatch Logs group | REQUIRED | HIGH |
| 3.4 | VPC Flow Logs enabled | Enable for all VPCs | VPC Flow Logs → CloudWatch / S3 | REQUIRED | HIGH |
| 3.5 | AWS Config enabled | Enable Config recording | AWS Config enabled in ap-southeast-7; all resource types | IN PROGRESS | HIGH |
| 3.6 | CloudWatch alarms for unauthorized API calls | Alert on failed API calls | CloudWatch metric filter + alarm on CloudTrail | IN PROGRESS | HIGH |
| 3.7 | CloudWatch alarm for root login | Alert on root account usage | CloudWatch metric filter + SNS on root login | REQUIRED | CRITICAL |
| 3.8 | CloudWatch alarm for MFA console login without MFA | Alert on MFA bypass attempts | CloudWatch metric filter + SNS | IN PROGRESS | MEDIUM |

### Section 4 — Networking

| CIS ID | Title | Recommendation | AWS Service | Status | Priority |
|---|---|---|---|---|---|
| 4.1 | No unrestricted SSH (port 22) inbound | Restrict SSH to bastion SG | Bastion SG: SSH from office IP only; App/Data SGs: no port 22 | REQUIRED | CRITICAL |
| 4.2 | No unrestricted RDP (port 3389) | Restrict RDP access | No Windows instances; N/A for Linux; SG rule confirmed | REQUIRED | HIGH |
| 4.3 | No unrestricted port 3306 (MySQL) | Restrict DB port access | RDS SG: port 5432 from App SG only; no public access | REQUIRED | CRITICAL |
| 4.4 | No unrestricted port 5432 (PostgreSQL) | Restrict PostgreSQL port | RDS SG allows 5432 from App SG only | REQUIRED | CRITICAL |
| 4.5 | Default VPC removed | Delete default VPC | Delete default VPC in ap-southeast-7; use custom VPC only | REQUIRED | HIGH |
| 4.6 | Restrict ingress on all ports to default SG | Default SG has no rules | Default SG: remove all inbound/outbound rules | REQUIRED | HIGH |

---

## Part 3: Encryption Standards

| Category | Standard | Implementation |
|---|---|---|
| Data in transit (public) | TLS 1.3 | CloudFront enforces TLS 1.3; ACM certificate |
| Data in transit (internal) | TLS 1.2+ | RDS SSL required; Redis TLS enabled; SQS HTTPS |
| Data at rest — RDS | AES-256 (KMS CMK) | RDS encrypted with `rds-cmk` (KMS) |
| Data at rest — S3 | AES-256 (KMS CMK) | S3 SSE-KMS with `s3-cmk` |
| Data at rest — SQS | AES-256 (KMS CMK) | SQS SSE with `sqs-cmk` |
| Data at rest — ElastiCache | AES-256 (KMS CMK) | ElastiCache encryption at rest |
| Secrets | AES-256 (Secrets Manager + KMS) | Stripe keys, DB passwords via Secrets Manager |
| Key rotation | Annual (CMK), 30-day (Secrets) | KMS auto-rotation enabled; Secrets Manager rotation Lambda |

---

## Part 4: Logging & Monitoring Baseline

| Control | Configuration | Alert Condition |
|---|---|---|
| CloudTrail | Multi-region, all management events, log validation | Root login, unauthorized API calls |
| VPC Flow Logs | All traffic, 90-day retention in CloudWatch | Rejected connections spike > 1,000/min |
| ALB Access Logs | S3 bucket, 90-day retention | 5xx error rate > 1% in 5 minutes |
| CloudWatch — CPU | EC2 CPU > 75% for 5 minutes | SNS → Engineering Slack channel |
| CloudWatch — RDS | Connections > 80% max, FreeStorageSpace < 10GB | SNS → Engineering Slack channel |
| CloudWatch — SQS | DLQ message depth > 0 | SNS → Engineering Slack channel (inventory failure) |
| CloudWatch — ALB | UnhealthyHostCount > 0 | SNS → PagerDuty (critical) |
| GuardDuty | Enabled for ap-southeast-7 | HIGH severity findings → SNS → PagerDuty |

---

## Part 5: Compliance Evidence Collection

| Evidence Item | Collection Method | Frequency | Owner |
|---|---|---|---|
| IAM credential report | AWS CLI / Console download | Monthly | Engineer 1 |
| CloudTrail log integrity | SHA-256 digest validation | Weekly (automated) | CloudTrail |
| Security Group audit | AWS Config rule: restricted-ssh | Continuous | AWS Config |
| MFA compliance report | IAM Access Analyzer | Monthly | Engineer 2 |
| Patch compliance report | SSM Patch Manager report | Weekly | Engineer 1 |
| RDS backup verification | RDS console — verify automated snapshot | Weekly | Engineer 2 |
| WAF rule review | WAF CloudWatch metrics review | Monthly | Engineer 1 |
| Secrets rotation verification | Secrets Manager rotation audit | Monthly | Engineer 2 |
