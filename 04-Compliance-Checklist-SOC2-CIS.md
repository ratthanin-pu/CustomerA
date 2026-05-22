# SOC 2 Type II & CIS AWS Foundations Compliance Checklist
## E-commerce-3 Platform - AWS Thailand Deployment

**Project Name:** E-commerce-3 Platform  
**Assessment Date:** February 7, 2025  
**Assessment Scope:** Full infrastructure, application, and operations  
**Target Frameworks:** SOC 2 Type II + CIS AWS Foundations v1.5.0  
**Review Frequency:** Quarterly (Q1, Q2, Q3, Q4 2025)  

---

## Table of Contents
1. [SOC 2 Type II Controls](#soc-2-type-ii-controls)
2. [CIS AWS Foundations Benchmark](#cis-aws-foundations-benchmark)
3. [Encryption Strategy](#encryption-strategy)
4. [Logging & Monitoring](#logging--monitoring)
5. [Access Control & Authentication](#access-control--authentication)
6. [Incident Response](#incident-response)
7. [Audit Evidence Collection](#audit-evidence-collection)
8. [Compliance Sign-Off](#compliance-sign-off)

---

## SOC 2 Type II Controls

### Trust Service Criteria: CC (Common Criteria)

#### CC6.1 - Logical & Physical Access Controls
**Requirement:** The entity restricts access to information assets related to financial reporting and related metadata to authorized internal and external users, based on an appropriate authorization model.

**AWS Implementation:**
- AWS Identity & Access Management (IAM) with least-privilege policies
- VPC security groups (restrict by port, protocol, source IP)
- Network ACLs (defense in depth)
- Encryption key management (AWS KMS)
- Systems Manager Session Manager (no SSH keys)

**Evidence Artifacts:**
- [ ] IAM policy document (application-specific role, deny * by default)
- [ ] VPC security group rules (EC2 only from ALB, RDS only from EC2)
- [ ] CloudTrail logs (unauthorized access attempts audited)
- [ ] KMS key policy (principal restrictions on decrypt)
- [ ] Session Manager activity log (who accessed which instance)

**Status:** REQUIRED | **Priority:** CRITICAL  
**Implementation Target:** Week 1-4 (design & deployment), Week 9-10 (audit)  
**Owner:** DevOps Engineer + Security Engineer  
**Verification:** CloudTrail shows no unauthorized access attempts; all access logged

---

#### CC6.2 - Assignment of Responsibility
**Requirement:** The entity determines, documents, communicates, and assigns accountability and responsibility for IT-related general control activities.

**AWS Implementation:**
- IAM roles (EC2, RDS, Lambda, S3, SQS, SNS)
- Multi-Factor Authentication (MFA) for console access
- Password policy enforcement
- Systems Manager Session Manager (no hardcoded SSH keys)

**Evidence Artifacts:**
- [ ] AWS IAM role definitions (Principal, Action, Resource for each service)
- [ ] MFA configuration (root account, all admin users have virtual/hardware tokens)
- [ ] Console access logs (CloudTrail: GetConsoleLoginToken, AssumeRole)
- [ ] Session Manager activity log (audit of who accessed which instance)
- [ ] Password policy enforcement (14-char min, symbols, uppercase, lowercase, numbers)

**Status:** REQUIRED | **Priority:** CRITICAL  
**Implementation Target:** Week 1-2 (IAM design), Week 3-4 (MFA setup)  
**Owner:** DevOps Engineer  
**Verification:** CloudTrail shows all console logins; MFA required for all humans

---

#### CC6.3 - Network Access Restrictions
**Requirement:** The entity restricts access to protected information assets over network connections to authenticated internal and external users and processes, and to those explicitly authorized.

**AWS Implementation:**
- TLS 1.2+ for all APIs (ACM certificate on ALB)
- VPC endpoints for private access (S3 gateway, Secrets Manager interface)
- API Gateway authentication (if used)
- Encrypted database connections (SSL/TLS required)
- Redis TLS encryption enabled

**Evidence Artifacts:**
- [ ] SSL/TLS certificate metadata (valid, non-expired, strong cipher suite)
- [ ] VPC security group rules (no open 0.0.0.0/0 except 443, 80 on ALB)
- [ ] VPC Flow Logs sample (showing authorized connections only)
- [ ] API Gateway policies (authentication, rate limiting, IP restrictions)
- [ ] RDS parameter group (require_secure_transport = ON)
- [ ] ElastiCache parameter (transit_encryption_enabled = true)

**Status:** REQUIRED | **Priority:** HIGH  
**Implementation Target:** Week 3-4 (VPC setup), Week 9 (validation)  
**Owner:** DevOps Engineer + Security Engineer  
**Verification:** TLS 1.2+ enforced; no unencrypted traffic allowed

---

### Trust Service Criteria: C (Confidentiality)

#### C1.1 - Confidentiality of Information
**Requirement:** The entity obtains or generates, uses, and communicates relevant, quality information regarding objectives, including its responsibilities for confidentiality.

**AWS Implementation:**
- Encryption at rest (AWS KMS for all data)
- Encryption in transit (TLS 1.2+)
- Data classification (PII, payment data, logs)
- Access logs (who accessed what, when)

**Evidence Artifacts:**
- [ ] Data classification policy document (define PII, payment, audit data categories)
- [ ] KMS key policy (restrict decrypt to authorized roles only)
- [ ] RDS encryption configuration (KMS customer-managed key, not AWS-managed)
- [ ] S3 bucket encryption (SSE-KMS with customer-managed key)
- [ ] ElastiCache encryption (TLS + AWS KMS for at-rest)
- [ ] CloudTrail logs (all API calls documented)
- [ ] Access audit log (who accessed PII, when, why)

**Status:** REQUIRED | **Priority:** CRITICAL  
**Implementation Target:** Week 2-4 (KMS setup), Week 10 (audit)  
**Owner:** DevOps Engineer + Security Engineer  
**Verification:** All data encrypted at rest & in transit; access logs complete

---

### Trust Service Criteria: I (Integrity)

#### I1.1 - Data Integrity
**Requirement:** The entity implements and operates policies and procedures to ensure that authorized transactions are valid, authorized, and completely and accurately recorded and processed.

**AWS Implementation:**
- Database constraints (Foreign Keys, UNIQUE, NOT NULL, CHECK)
- Transaction logging (RDS audit, application logs)
- Checksums & versioning (S3 object tags, versioning enabled)
- Idempotency keys (Stripe payment deduplication)
- Application validation (input sanitization, business logic checks)

**Evidence Artifacts:**
- [ ] MySQL schema with constraints (FOREIGN KEY, UNIQUE, NOT NULL)
- [ ] RDS slow query log sample (any suspicious queries)
- [ ] RDS audit log sample (INSERT, UPDATE, DELETE events)
- [ ] Application error handling (duplicate transaction rejection with idempotency key)
- [ ] S3 object versioning enabled (can recover previous versions)
- [ ] CloudTrail logs (data modifications tracked)
- [ ] Application validation code review (input sanitization, business logic)

**Status:** REQUIRED | **Priority:** CRITICAL  
**Implementation Target:** Week 6 (database schema), Week 7 (payment idempotency)  
**Owner:** Full-Stack Engineer + Database Engineer  
**Verification:** Schema constraints enforced; transactions logged & traceable

---

### Trust Service Criteria: A (Availability)

#### A1.1 - System Availability
**Requirement:** The entity obtains or generates, uses, and communicates relevant information regarding the objectives, including responsibilities for availability.

**AWS Implementation:**
- Multi-AZ RDS with automatic failover (standby in different AZ)
- EC2 Auto Scaling Group (health checks, auto-replacement)
- ALB health checks (target deregistration on failure)
- Automated backups (6-hourly, 35-day retention)
- Disaster recovery procedures (documented & tested)

**Evidence Artifacts:**
- [ ] RDS Multi-AZ configuration (standby instance in different AZ confirmed)
- [ ] ASG health check settings (ELB type, grace period 300s)
- [ ] CloudWatch uptime metric (monthly uptime percentage ≥ 99.95%)
- [ ] RDS backup schedule (automated 6-hourly, cross-region copy daily)
- [ ] Disaster recovery test report (RTO < 30 min verified)
- [ ] Failover procedure documentation (tested & timed)
- [ ] ALB target health logs (deregistration on failure)

**Status:** REQUIRED | **Priority:** CRITICAL  
**Implementation Target:** Week 4 (deployment), Week 10 (validation)  
**Owner:** DevOps Engineer + Solutions Architect  
**Verification:** 99.95% uptime achieved; failover time < 30 sec confirmed

---

## CIS AWS Foundations Benchmark

### Section 1: Identity & Access Management (IAM)

#### 1.1 - Maintain Current Contact Details
**Recommendation:** Ensure account contact information (email, phone) is current and monitored for important notifications.

**Implementation:**
- [ ] AWS Account Settings: Primary contact email updated
- [ ] AWS Account Settings: Billing contact email provided
- [ ] AWS Account Settings: Security contact email provided
- [ ] Verified email addresses can receive AWS notifications

**Status:** REQUIRED | **Priority:** HIGH  
**Target Completion:** February 1, 2025 (Week 1)  
**Owner:** Solutions Architect  
**Verification:** Screenshot of AWS Console Account Settings

---

#### 1.2 - MFA for All IAM Users with Console Password
**Recommendation:** Enable Multi-Factor Authentication for all humans with AWS console access.

**Implementation:**
- [ ] Root account: MFA enabled (hardware token or virtual authenticator)
- [ ] All admin users: MFA enabled (no exceptions)
- [ ] MFA device type: Virtual (AWS Authenticator, Google Authenticator) or Hardware (U2F key)
- [ ] Backup codes: Generated and stored securely

**Status:** REQUIRED | **Priority:** CRITICAL  
**Target Completion:** February 5, 2025 (Week 1)  
**Owner:** DevOps Engineer  
**Verification:** IAM console shows all users with MFA ✓ status

---

#### 1.3 - Credentials Unused > 90 Days
**Recommendation:** Audit and disable IAM users with no API calls or console logins for 90+ days.

**Implementation:**
- [ ] AWS IAM Access Analyzer: Generate credential age report quarterly
- [ ] Identify unused credentials (no activity for 90+ days)
- [ ] Disable unused access keys (AWS IAM → Users → Access Keys → Deactivate)
- [ ] Document retention/deletion rationale
- [ ] Quarterly review scheduled (first audit May 1, 2025)

**Status:** REQUIRED | **Priority:** MEDIUM  
**Target Completion:** May 1, 2025 (post-launch review)  
**Owner:** DevOps Engineer  
**Verification:** IAM Access Analyzer report, disabled credentials log

---

#### 1.4 - Access Keys Rotated Every 90 Days
**Recommendation:** Rotate IAM user access keys every 90 days to limit exposure.

**Implementation:**
- [ ] AWS Secrets Manager: Store all access keys (with rotation Lambda)
- [ ] Rotation policy: Automatic key rotation every 90 days
- [ ] Application secrets: Never hardcoded (fetched from Secrets Manager at startup)
- [ ] CloudTrail: Log all CreateAccessKey/DeleteAccessKey events
- [ ] Policy enforcement: IAM policy denies use of keys > 90 days old (future state)

**Status:** REQUIRED | **Priority:** HIGH  
**Target Completion:** February 28, 2025 (Week 4)  
**Owner:** DevOps Engineer  
**Verification:** CloudTrail shows regular key rotations; no keys > 90 days

---

### Section 2: Logging

#### 2.1 - CloudTrail Enabled on AWS Account
**Recommendation:** Enable CloudTrail in all regions to log all API calls and console logins.

**Implementation:**
- [ ] AWS CloudTrail: Create trail "management-trail" (all regions, all events)
- [ ] CloudTrail S3 bucket: Encrypted, MFA delete enabled
- [ ] CloudTrail delivery: Logging is successful (green checkmark)
- [ ] CloudTrail events: Visible in CloudTrail console (within 15 minutes)
- [ ] Management events: Enabled (all API calls logged)
- [ ] Data events: Enabled (S3 object-level access logged for audit bucket)

**Status:** REQUIRED | **Priority:** CRITICAL  
**Target Completion:** February 1, 2025 (Week 1)  
**Owner:** DevOps Engineer  
**Verification:** CloudTrail console shows trail status = "Logging"; events visible

---

#### 2.2 - S3 Bucket for CloudTrail Logs Not Publicly Accessible
**Recommendation:** Block public access to CloudTrail S3 bucket; enable versioning & MFA delete.

**Implementation:**
- [ ] S3 bucket "Block public access": All 4 settings enabled (Block all public access)
- [ ] S3 bucket "Versioning": Enabled (can recover previous versions)
- [ ] S3 bucket "MFA Delete": Enabled (requires MFA to permanently delete objects)
- [ ] S3 bucket "Lifecycle Policy": Transition to Glacier after 30 days
- [ ] S3 bucket "Encryption": SSE-KMS with customer-managed key
- [ ] S3 bucket "Access Logging": Enabled (log who accessed the bucket)

**Status:** REQUIRED | **Priority:** CRITICAL  
**Target Completion:** February 7, 2025 (Week 2)  
**Owner:** DevOps Engineer  
**Verification:** S3 console shows public access blocked; versioning/MFA enabled

---

#### 2.3 - CloudTrail Log File Integrity Validation Enabled
**Recommendation:** Enable log file validation to detect tampering with CloudTrail logs.

**Implementation:**
- [ ] CloudTrail trail "Log file validation": Enabled
- [ ] Digest files: Generated hourly in S3 (separate folder)
- [ ] Validation procedure: Compare digest hash with S3 object hash to detect tampering
- [ ] AWS CloudTrail console: "Log file validation status" shows ✓

**Status:** REQUIRED | **Priority:** HIGH  
**Target Completion:** February 1, 2025 (Week 1)  
**Owner:** DevOps Engineer  
**Verification:** CloudTrail console shows "Log file validation = Enabled"

---

#### 2.4 - CloudWatch Log Group Encrypted with KMS
**Recommendation:** Encrypt CloudWatch Logs with customer-managed KMS key (not AWS-managed).

**Implementation:**
- [ ] CloudWatch Logs log group: Create or select existing
- [ ] Log group "Encryption": Edit → Select KMS customer-managed key
- [ ] KMS key policy: Allow CloudWatch Logs service to decrypt
- [ ] Verify encryption: Logs are encrypted in S3 backend (not visible in console, but enforced)

**Status:** REQUIRED | **Priority:** MEDIUM  
**Target Completion:** March 1, 2025 (Week 5)  
**Owner:** DevOps Engineer  
**Verification:** CloudWatch Logs console shows encryption = KMS (customer-managed)

---

### Section 3: Monitoring

#### 3.1 - Log Metric Filter & Alarm for Unauthorized API Calls
**Recommendation:** Alert on UnauthorizedOperation, AccessDenied, and other unauthorized API calls (potential breach).

**Implementation:**
- [ ] CloudWatch Logs Insights: Create query pattern
  ```
  ($.errorCode = "*UnauthorizedOperation") || 
  ($.errorCode = "AccessDenied") || 
  ($.errorCode = "*AuthFailure") || 
  ($.userIdentity.invokedBy = "CloudFront")
  ```
- [ ] CloudWatch Logs: Create metric filter on query pattern
- [ ] CloudWatch Logs: Create alarm (threshold ≥ 1 unauthorized call)
- [ ] Alarm action: SNS → on-call team (immediate notification)
- [ ] Test: Generate unauthorized API call, verify alarm triggers

**Status:** REQUIRED | **Priority:** HIGH  
**Target Completion:** April 1, 2025 (Week 9)  
**Owner:** DevOps Engineer  
**Verification:** CloudWatch alarms shows metric filter active; test trigger works

---

#### 3.2 - Log Metric Filter & Alarm for Root Account Usage
**Recommendation:** Alert whenever root account is used (should be reserved for emergency only).

**Implementation:**
- [ ] CloudWatch Logs Insights: Create query pattern
  ```
  ($.userIdentity.type = "Root") && 
  ($.userIdentity.invokedBy NOT EXISTS) && 
  ($.eventType != "AwsServiceEvent")
  ```
- [ ] CloudWatch Logs: Create metric filter on query pattern
- [ ] CloudWatch Logs: Create alarm (threshold ≥ 1 root account usage)
- [ ] Alarm action: SNS → on-call team (critical notification)
- [ ] Alert: Include details (service name, API call, timestamp)

**Status:** REQUIRED | **Priority:** CRITICAL  
**Target Completion:** March 15, 2025 (Week 6)  
**Owner:** DevOps Engineer  
**Verification:** Metric filter active; alarm threshold set to ≥ 1

---

### Section 4: Networking

#### 4.1 - VPC Flow Logs Enabled for All VPCs
**Recommendation:** Enable VPC Flow Logs to audit network traffic and security group rule effectiveness.

**Implementation:**
- [ ] VPC "Flow Logs": Create new
- [ ] Log destination: CloudWatch Logs (or S3 for long-term retention)
- [ ] Log group name: "vpc-flow-logs-{vpc-id}"
- [ ] Traffic type: ACCEPT and REJECT (capture both)
- [ ] Retention: 14 days in CloudWatch, archive to S3 after
- [ ] Verify: Flow log entries appear in CloudWatch Logs (within 10 minutes)

**Status:** REQUIRED | **Priority:** HIGH  
**Target Completion:** February 28, 2025 (Week 4)  
**Owner:** DevOps Engineer  
**Verification:** VPC console shows Flow Logs = enabled; entries visible in Logs

---

#### 4.2 - Security Groups Restrict Inbound Traffic
**Recommendation:** Restrict inbound traffic to only necessary ports; no open 0.0.0.0/0 except public ALB.

**Implementation:**
- [ ] **ALB Security Group:**
  - Inbound: 80, 443 from 0.0.0.0/0 (allow public web traffic)
  - Outbound: All (allow responses)
- [ ] **EC2 Security Group:**
  - Inbound: 80, 443 from ALB security group only (no 0.0.0.0/0)
  - Inbound: 22 from bastion/SSM only (no direct SSH)
  - Outbound: All (allow to DB, cache, internet)
- [ ] **RDS Security Group:**
  - Inbound: 3306 from EC2 security group only (no 0.0.0.0/0)
  - Outbound: None (database is inbound-only)
- [ ] **ElastiCache Security Group:**
  - Inbound: 6379 from EC2 security group only
  - Outbound: None

**Status:** REQUIRED | **Priority:** CRITICAL  
**Target Completion:** February 28, 2025 (Week 4)  
**Owner:** DevOps Engineer  
**Verification:** Security group rules reviewed; no 0.0.0.0/0 on ports > 1024

---

### Section 5: Identity

#### 5.1 - IAM Policies Attached Only to Groups or Roles
**Recommendation:** Never attach policies directly to IAM users; use groups/roles for easier management.

**Implementation:**
- [ ] IAM policy review: Search for users with direct policy attachments
- [ ] Remediation: Create groups, attach policies to groups, add users to groups
- [ ] Enforcement: IAM permission boundary policy prevents direct user attachments
- [ ] Cleanup: Remove any existing direct user policy attachments

**Status:** REQUIRED | **Priority:** MEDIUM  
**Target Completion:** February 28, 2025 (Week 4)  
**Owner:** DevOps Engineer  
**Verification:** IAM console shows no policies attached directly to users

---

#### 5.2 - Users Have Console Password OR Access Keys (Not Both)
**Recommendation:** Separate human users (console) from service accounts (API keys). Rotate keys.

**Implementation:**
- [ ] **Human Users (console login only):**
  - Console password: Yes
  - Access keys: None (use temporary STS credentials if API needed)
- [ ] **Service Accounts (API access only):**
  - Access keys: Yes (rotated every 90 days)
  - Console password: None (cannot login to console)
- [ ] **EC2/Lambda (IAM roles only):**
  - No hardcoded credentials
  - Temporary credentials via STS (auto-rotated)

**Status:** REQUIRED | **Priority:** HIGH  
**Target Completion:** February 28, 2025 (Week 4)  
**Owner:** DevOps Engineer  
**Verification:** IAM console shows separation of console users from API users

---

## Encryption Strategy

### Encryption at Rest (KMS)

**Customer-Managed Key Configuration:**
- [ ] KMS key created (not AWS-managed)
- [ ] Key policy: Restrict decrypt to specific IAM roles only
- [ ] Key rotation: Enabled (automatic annual)
- [ ] Key usage: RDS, ElastiCache, S3, EBS, Secrets Manager

**Per Service:**

**RDS Aurora:**
- [ ] Encryption at Rest: Enabled (KMS customer-managed key)
- [ ] Key ID: Documented in Terraform
- [ ] Read Replica: Uses same key (encryption inherited)
- [ ] Snapshots: Encrypted with same key
- [ ] Backups: Cross-region copy encrypted with same key

**ElastiCache:**
- [ ] Encryption at Rest: Enabled (KMS customer-managed key)
- [ ] Encryption in Transit: TLS 1.2 enabled
- [ ] Key ID: Documented in Terraform

**S3:**
- [ ] Encryption at Rest: SSE-KMS (customer-managed key)
- [ ] Default encryption: Applied to all new objects
- [ ] Bucket policy: Deny unencrypted PutObject

**EBS (EC2 Root Volume):**
- [ ] Encryption: Enabled (KMS customer-managed key)
- [ ] Volume type: gp3 (latest generation)
- [ ] Volume size: 100GB (sufficient for OS + application)

**Secrets Manager:**
- [ ] Encryption: Enabled (KMS customer-managed key)
- [ ] Secrets stored: Stripe API key, RDS password, API tokens

---

### Encryption in Transit (TLS 1.2+)

**ALB (Client → Server):**
- [ ] SSL/TLS certificate: AWS ACM (auto-renewing)
- [ ] Certificate valid until: [Cert expiry date]
- [ ] Protocol: HTTPS only
- [ ] HTTP → HTTPS redirect: Enabled
- [ ] TLS version: 1.2+ minimum
- [ ] Cipher suite: Modern ciphers only (no MD5, RC4, DES)

**Database Connections (Application → RDS):**
- [ ] Connection string parameter: `ssl=true`
- [ ] RDS parameter group: `require_secure_transport = ON`
- [ ] IAM database authentication: Token-based (15-min expiry)
- [ ] Verified: Application cannot connect without SSL

**Cache Connections (Application → ElastiCache):**
- [ ] ElastiCache: Transit encryption enabled
- [ ] TLS version: 1.2+ minimum
- [ ] Connection: Encrypted tunnel

**S3 Transfers (Application → S3):**
- [ ] Bucket policy: Deny unencrypted (HTTP) uploads
- [ ] All transfers: HTTPS only
- [ ] SDK configuration: Enforce SSL

**Stripe API (Application → Stripe):**
- [ ] API calls: HTTPS only (Stripe enforces)
- [ ] Certificate: Stripe's public certificate
- [ ] Verified: Application cannot send unencrypted payment data

---

## Logging & Monitoring

### CloudTrail (Audit Logging)

**Configuration:**
- [ ] Trail name: "management-trail"
- [ ] All regions: Enabled
- [ ] All events: Management + Data events
- [ ] S3 bucket: Encrypted, MFA delete enabled
- [ ] Log retention: 90 days (S3) + Archive to Glacier

**Monitoring:**
- [ ] CloudTrail status: "Logging" (green)
- [ ] Delivery status: Successful (S3 delivery confirmed)
- [ ] Events visible: Within 15 minutes of API call

**Querying:**
- [ ] CloudTrail console: Query events by service, user, event name
- [ ] Sample queries:
  - All IAM changes (search: "iam.amazonaws.com")
  - All RDS modifications (search: "rds.amazonaws.com")
  - All failed API calls (search: "errorCode")

---

### CloudWatch Logs (Application & System Logging)

**Log Sources:**
- [ ] Application logs: Docker container stdout/stderr
- [ ] RDS slow query log: Queries > 2 seconds
- [ ] VPC Flow Logs: Network traffic (ACCEPT + REJECT)
- [ ] ALB access logs: HTTP/HTTPS traffic

**Log Groups:**
- [ ] `/application/ecommerce-3`: Application logs (30-day retention)
- [ ] `/aws/rds/slow-query`: RDS slow queries (7-day retention)
- [ ] `/aws/vpc/flow-logs`: VPC Flow Logs (14-day retention)
- [ ] `/aws/alb/access-logs`: ALB access logs (90-day retention in S3)

**Encryption:**
- [ ] All log groups: Encrypted with KMS customer-managed key
- [ ] KMS key policy: Allow CloudWatch Logs service to decrypt

**Querying:**
- [ ] CloudWatch Logs Insights: SQL-like queries for log analysis
- [ ] Sample queries:
  - Error count per minute: `fields @timestamp, @message | filter @message like /ERROR/ | stats count() by bin(5m)`
  - Latency percentiles: `fields @duration | stats pct(@duration, 50), pct(@duration, 95), pct(@duration, 99)`
  - Payment processing latency: `fields @duration | filter @message like /payment/ | stats pct(@duration, 95)`

---

### CloudWatch Metrics & Alarms

**Metrics Collected:**
- [ ] ALB: TargetResponseTime, RequestCount, HTTPCode_Target_5XX_Count
- [ ] EC2: CPUUtilization, NetworkIn, NetworkOut
- [ ] RDS: CPUUtilization, DatabaseConnections, QueryLatency, DiskQueueDepth
- [ ] ElastiCache: CacheHits, CacheMisses, Evictions, CPUUtilization
- [ ] SQS: ApproximateNumberOfMessagesVisible, ApproximateAgeOfOldestMessage
- [ ] S3: BucketSizeBytes, NumberOfObjects

**Alarms (Critical):**
- [ ] ALB: TargetResponseTime > 1000ms for 5 min → SNS (page on-call)
- [ ] ALB: HTTPCode_Target_5XX_Count > 10 for 1 min → SNS (critical alert)
- [ ] EC2: CPUUtilization > 80% for 5 min → SNS (track)
- [ ] RDS: CPUUtilization > 80% for 5 min → SNS (page DBA)
- [ ] RDS: DatabaseConnections > 900 → SNS (connection pool saturation warning)
- [ ] ElastiCache: Evictions > 1000/min → SNS (cache too small)
- [ ] SQS: ApproximateAgeOfOldestMessage > 300s (5 min) → SNS (worker lag)

---

### X-Ray Tracing

**Configuration:**
- [ ] X-Ray sampling: 10% of requests (configurable by service)
- [ ] Traced services:
  - Application requests (ALB → EC2 → RDS)
  - Stripe payment processing (EC2 → Stripe API)
  - S3 operations (EC2 → S3)
  - SQS processing (EC2 → SQS → worker → RDS)

**Visualization:**
- [ ] X-Ray service map: Shows dependencies between services
- [ ] Trace analysis: Identify slow requests, errors
- [ ] Insights: Detect anomalies in response time, error rate

---

## Access Control & Authentication

### Root Account Security

- [ ] Console access: **DISABLED** (alternate admin user for emergency)
- [ ] Access keys: **NONE** (delete any existing)
- [ ] MFA: **ENABLED** (hardware token preferred)
- [ ] Billing email: Monitored
- [ ] No production API calls from root

---

### IAM Roles (Least-Privilege)

**EC2 Instance Role:**
- [ ] Service: EC2 (for application)
- [ ] Permissions:
  - `s3:GetObject` (product-images bucket only)
  - `sqs:ReceiveMessage, sqs:DeleteMessage` (inventory-queue only)
  - `sns:Publish` (order topics only)
  - `secretsmanager:GetSecretValue` (Stripe API key secret)
  - `rds-db:connect` (RDS IAM authentication, 15-min tokens)
  - `logs:CreateLogStream, logs:PutLogEvents` (CloudWatch)
  - `xray:PutTraceSegments` (X-Ray tracing)
- [ ] Trust policy: EC2 service only (no cross-account)
- [ ] Deny explicit: ec2:TerminateInstances, iam:*, kms:Decrypt (other keys)

**RDS IAM Authentication:**
- [ ] Enabled: `enable_iam_auth = true`
- [ ] Database user: `iamdb_user` (for IAM auth)
- [ ] Token generation: AWS SDK generates temporary token (15-min expiry)
- [ ] Application code: `generate_db_auth_token(endpoint, port, dbuser)` → token → connect

**Lambda Execution Role (if used):**
- [ ] Permissions: Only what Lambda needs
- [ ] Example: If Lambda invokes SQS, only `sqs:SendMessage` allowed

---

### Secrets Management

**AWS Secrets Manager:**

**Secret: Stripe API Key**
- [ ] Value: `sk_live_****` (secret part masked)
- [ ] Rotation: Enabled (every 90 days)
- [ ] Rotation function: Lambda that updates Stripe key in vault
- [ ] Access: EC2 role only (`secretsmanager:GetSecretValue`)
- [ ] Encryption: KMS customer-managed key

**Secret: RDS Master Password**
- [ ] Value: Random 32-char string (auto-generated)
- [ ] Rotation: Enabled (every 90 days)
- [ ] Rotation function: AWS auto-rotates
- [ ] Access: EC2 role + RDS service
- [ ] Encryption: KMS customer-managed key

**Secret: API Tokens**
- [ ] Value: 3rd-party API tokens (SendGrid, Twilio, etc.)
- [ ] Rotation: Manual (store contact for 3rd-party key update reminder)
- [ ] Access: EC2 role only
- [ ] Encryption: KMS customer-managed key

**Application Code (Never hardcode):**
```
# CORRECT: Fetch from Secrets Manager at startup
secret = secretsmanager.get_secret_value(SecretId="stripe-api-key")
STRIPE_API_KEY = secret["SecretString"]

# WRONG: Hardcoding in code (SECURITY VIOLATION)
STRIPE_API_KEY = "sk_live_1234567890"  # ❌ NEVER DO THIS
```

---

### Console Access Security

**Password Policy:**
- [ ] Minimum length: 14 characters
- [ ] Require uppercase: Yes
- [ ] Require lowercase: Yes
- [ ] Require numbers: Yes
- [ ] Require symbols: Yes (!, @, #, $, %, ^, &, *)
- [ ] Max password age: 90 days (force reset every 90 days)
- [ ] Password history: 24 (prevent reuse of last 24 passwords)

**MFA Requirement:**
- [ ] Root account: Hardware token (U2F key preferred)
- [ ] Admin users: Virtual authenticator (Google Authenticator, Authy) or hardware token
- [ ] Regular users: Virtual authenticator (optional, strongly recommended)
- [ ] Enforcement: IAM policy denies all actions unless MFA is provided

**Session Management:**
- [ ] Max session duration: 4 hours (maximum time logged in)
- [ ] Idle timeout: 15 minutes (auto-logout if inactive)
- [ ] Session logging: CloudTrail logs all login/logout events

---

### API Access (Systems Manager Session Manager)

**Why Not SSH?**
- No SSH keys to manage/rotate
- All access logged in CloudTrail
- Automatic session termination
- Keyboard input/output captured

**How It Works:**
1. Engineer runs: `aws ssm start-session --target i-1234567890abcdef0`
2. AWS Systems Manager: Checks IAM permissions
3. Session Manager: Opens interactive shell (pty) on EC2
4. CloudTrail: Logs session start/stop
5. Session logs: Can be archived to S3 (optional)

**IAM Permission:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ssm:StartSession",
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringLike": {
          "aws:username": "devops-engineer"
        }
      }
    }
  ]
}
```

---

### Application Access (OAuth 2.0 + JWT)

**User Authentication:**
- [ ] Method: OAuth 2.0 (3rd-party: Google, Facebook) OR Email + Password
- [ ] Password hashing: bcrypt (salted, 12 rounds minimum)
- [ ] Session management: JWT tokens in secure cookies
- [ ] Cookie security: HttpOnly (no JavaScript access), Secure (HTTPS only), SameSite=Strict

**Password Reset Flow:**
- [ ] User clicks "Forgot Password"
- [ ] App sends email with reset link (token, 24-hour expiry)
- [ ] User clicks link, sets new password
- [ ] Token invalidated (can't be reused)
- [ ] Email logging: Store in application logs (no password stored)

**JWT Token:**
```
Header:   {alg: "HS256", typ: "JWT"}
Payload:  {user_id: 12345, email: "user@example.com", exp: 1709251200}
Signature: HMAC-SHA256(header.payload, secret)

// Cookie header
Set-Cookie: jwt_token=eyJhbGc...N3JjQ; HttpOnly; Secure; SameSite=Strict; Max-Age=3600
```

**API Rate Limiting:**
- [ ] Rate limit: 10,000 requests/hour per IP
- [ ] Enforcement: ALB or application-level
- [ ] Exceeded: Return 429 Too Many Requests
- [ ] Logging: Track rate limit violations (potential abuse)

---

## Incident Response

### Incident Detection

**Automated Alerts:**
- [ ] Error rate > 1%: Page on-call engineer (PagerDuty)
- [ ] Latency p95 > 1000ms: Page on-call engineer
- [ ] CPU > 80% for 5 min: Notify on-call (track)
- [ ] Unauthorized API calls: Page on-call (potential breach)
- [ ] Root account usage: Page on-call (critical)
- [ ] SQS queue age > 5 min: Notify on-call (worker lag)

**Manual Detection:**
- [ ] Customer reports: "Site is slow"
- [ ] Monitoring dashboard: Engineer observes anomaly
- [ ] CloudWatch alarm: Engineer reviews and escalates

---

### Incident Response Procedure

**Severity Levels:**

**P1 - Critical (0% availability):**
- [ ] Impact: Production is down (no traffic)
- [ ] Response time: < 15 minutes to page someone
- [ ] Escalation: On-call → Lead → CTO immediately
- [ ] Incident commander: Solutions Architect or Lead

**P2 - High (Degraded service):**
- [ ] Impact: Latency > 1s, error rate > 5%
- [ ] Response time: < 30 minutes for initial response
- [ ] Escalation: On-call engineer → Lead (if unresolved > 1 hour)
- [ ] Incident commander: On-call engineer or Lead

**P3 - Medium (Minor issue):**
- [ ] Impact: Latency 500-1000ms, error rate 1-5%
- [ ] Response time: < 2 hours
- [ ] Escalation: On-call engineer only (no escalation initially)
- [ ] Incident commander: On-call engineer

---

### Playbook Procedures

**Playbook 1: RDS Failover**
1. Detect: CloudWatch alarm (RDS unavailable) OR CloudTrail shows failover event
2. Verify: Check RDS console (Multi-AZ status)
3. Application: Should auto-reconnect (transparent failover, < 30 sec)
4. Monitoring: Check CloudWatch for latency spike, log the event
5. Root cause: Check RDS logs for what triggered failover
6. Documentation: Log incident in wiki

**Playbook 2: High Application Latency**
1. Detect: CloudWatch alarm (p95 > 1000ms)
2. Investigate:
   - [ ] RDS: Check CPU, query latency, slow query log
   - [ ] ElastiCache: Check hit rate, evictions, CPU
   - [ ] EC2: Check CPU, memory, network
   - [ ] Network: Check ALB latency
3. Root cause: Narrow down to one service
4. Mitigation:
   - [ ] If DB: Kill long-running queries, add index, scale up
   - [ ] If cache: Increase instance size, warm cache
   - [ ] If EC2: Increase ASG desired count, check code
5. Recovery: Monitor latency until P95 < 500ms
6. Post-incident: RCA (root cause analysis) within 24 hours

**Playbook 3: Payment Processing Failure**
1. Detect: Stripe webhook failures OR customer complaints
2. Investigate:
   - [ ] Check Stripe dashboard (API status)
   - [ ] Check application logs (payment service errors)
   - [ ] Check CloudWatch alarms (webhook delivery failures)
3. Root cause:
   - [ ] Stripe API down (wait for recovery)
   - [ ] Application error (webhook handler code bug)
   - [ ] Network connectivity (check ALB security group)
4. Mitigation:
   - [ ] If application bug: Deploy hotfix, re-process failed payments
   - [ ] If Stripe down: Update status page, monitor for recovery
5. Recovery: Verify payments processed, notify affected customers
6. Post-incident: RCA, add test for payment failures

---

### Post-Incident Review

**Timing:** 24-48 hours after resolution  
**Participants:** Full engineering team + management  
**Output:** Wiki post-mortem (public document)

**Post-Mortem Template:**
```markdown
# Incident Post-Mortem: [Incident Title]

## Timeline
- 14:30: User reports site slow
- 14:32: On-call engineer paged
- 14:35: Incident commander declared
- 14:45: Root cause identified (RDS CPU maxed)
- 15:15: Mitigation applied (scaled RDS)
- 15:30: Site recovered (latency < 500ms)

## Root Cause
RDS running out of connections due to application connection leak (not closing connections properly).

## Impact
- Duration: 1 hour
- Users affected: All (during incident)
- Transactions lost: 0 (no data loss)
- Revenue impact: ~$5,000 (estimated)

## Contributing Factors
- Application code didn't implement connection pooling correctly
- No monitoring alert for connection count (added post-incident)
- No pressure test for connection limits in staging

## Remediation
1. Fix application code: Implement proper connection pooling (deadline: 1 week)
2. Add monitoring: CloudWatch alarm for RDS connections > 900 (done immediately)
3. Add test: Staging environment connection stress test (deadline: 1 week)
4. Scale RDS: Increase max_connections to 1500 (done immediately)

## Action Items
- [ ] Code fix: Engineer #1 (deadline Wed)
- [ ] Test case: Engineer #2 (deadline Wed)
- [ ] Documentation: Engineer #3 (deadline Thu)
- [ ] Follow-up: Verify fix in staging before deploying to prod (Fri)
```

---

## Audit Evidence Collection

### Quarterly Audit (Every 3 Months)

**Q1 Audit (May 1, 2025 - post-launch):**
- [ ] IAM policy review (unused roles, overprivileged users)
- [ ] Security group rules audit (unnecessary open ports)
- [ ] Encryption status (KMS key rotation, SSL certificates)
- [ ] Access logs review (CloudTrail sample, application logs)
- [ ] Incident summary (MTTR, root causes, improvements)
- [ ] **Deliverable:** Quarterly audit report

**Q2, Q3, Q4 Audits:** Same format, repeat quarterly

---

### Annual Audit (End of Year)

**SOC 2 Type II Formal Assessment (by external auditor):**
- [ ] Review all controls (CC6.1-6.3, C1.1, I1.1, A1.1)
- [ ] Verify evidence artifacts (CloudTrail logs, IAM policies, access logs)
- [ ] Test controls (manually verify security group rules, encryption status)
- [ ] Interview team (understand incident response procedures)
- [ ] **Deliverable:** SOC 2 Type II audit report (can be shared with customers)

**PCI DSS Compliance Assessment:**
- [ ] Level 1 checklist validation (payment data security)
- [ ] 3rd-party penetration testing (annual, already done quarterly post-launch)
- [ ] Security scan (Qualys or similar)
- [ ] **Deliverable:** PCI DSS compliance certificate

**GDPR Compliance Check (if serving EU customers):**
- [ ] Data residency: Confirm data stays in ap-southeast-7 (or approved region)
- [ ] Data subject rights: Can users export/delete their data?
- [ ] Consent management: Are cookies/consent properly tracked?
- [ ] Data processing agreement: With any 3rd parties (Stripe)?
- [ ] **Deliverable:** GDPR compliance assessment

---

### Evidence Storage

**Location:** S3 bucket `audit-evidence-{account-id}`  
**Retention:** 7 years (financial record requirement)  
**Encryption:** KMS customer-managed key  
**Access:** Restricted to audit team (IAM role)  

**Evidence Types:**
- [ ] CloudTrail logs (exported CSV, 90-day rolling)
- [ ] RDS audit logs (if enabled, monthly exports)
- [ ] Application logs (archived monthly)
- [ ] Compliance assessment reports (annual)
- [ ] Incident post-mortems (quarterly summaries)

---

## Compliance Sign-Off

### Project Lead

**Name:** ___________________  
**Title:** AWS Solutions Architect  
**Date:** February 7, 2025  
**Signature:** ___________________  

**Attestation:**
```
I certify that the E-commerce-3 Platform architecture complies with 
SOC 2 Type II trust service criteria and CIS AWS Foundations 
Benchmark requirements as outlined in this document.
```

---

### Security Lead

**Name:** ___________________  
**Title:** Security Engineer  
**Date:** April 25, 2025 (post-penetration testing)  
**Signature:** ___________________  

**Attestation:**
```
I certify that the platform has been hardened against common security 
vulnerabilities (OWASP Top 10), and all findings from third-party 
penetration testing have been remediated. No CVSS 4.0+ vulnerabilities 
remain.
```

---

### Compliance Officer

**Name:** ___________________  
**Title:** Chief Compliance Officer  
**Date:** May 9, 2025 (post-launch)  
**Signature:** ___________________  

**Attestation:**
```
I certify that the E-commerce-3 Platform meets organizational 
compliance standards for financial data handling, PCI DSS Level 1 
requirements, and security baseline expectations. The platform is 
approved for production use.
```

---

**Document End**
