# E-Commerce Platform - Architecture Diagram

```mermaid
graph TB
    subgraph "Client Layer"
        web[Web Browser]
        mobile[Mobile App]
    end
    
    subgraph "CloudFront CDN"
        cf[CloudFront<br/>Static Content]
    end
    
    subgraph "Edge Security"
        waf[AWS WAF<br/>DDoS Protection]
    end
    
    subgraph "Load Balancing"
        alb[Application Load Balancer<br/>Multi-AZ]
    end
    
    subgraph "VPC - EU-WEST-1 Ireland"
        subgraph "Web Tier - Multi-AZ"
            ec2_1[EC2 Instance<br/>AZ-1a]
            ec2_2[EC2 Instance<br/>AZ-1b]
            ec2_3[EC2 Instance<br/>AZ-1c]
        end
        
        subgraph "Application Services"
            asg[Auto Scaling Group<br/>Min:2 Max:8]
            session[ElastiCache Redis<br/>Session Store]
        end
        
        subgraph "Data Layer"
            rds["Amazon Aurora PostgreSQL<br/>Multi-AZ Read Replicas"]
            rds_replica["Read Replica<br/>Analytics"]
        end
        
        subgraph "Cache Layer"
            cache["ElastiCache Redis<br/>Product Catalog<br/>Inventory Cache"]
        end
        
        subgraph "Search & Inventory"
            opensearch[OpenSearch Domain<br/>Product Search]
            sqs["SQS Queue<br/>Inventory Sync"]
        end
    end
    
    subgraph "Event-Driven Services"
        sns["SNS Topic<br/>Inventory Events"]
        lambda["Lambda Functions<br/>Event Processors"]
    end
    
    subgraph "Storage & Media"
        s3["Amazon S3<br/>Product Images<br/>Catalog Data"]
        s3_backup["S3 Backup Vault<br/>Cross-Region"]
    end
    
    subgraph "Payment & External"
        stripe[Stripe API<br/>Payment Gateway]
    end
    
    subgraph "Monitoring & Security"
        cloudwatch["CloudWatch<br/>Metrics & Logs"]
        cloudtrail["CloudTrail<br/>Audit Logs"]
        kms["AWS KMS<br/>Encryption Keys"]
    end
    
    subgraph "Backup & Disaster Recovery"
        backup["AWS Backup<br/>RDS Snapshots"]
        dr["Cross-Region<br/>DR Replica"]
    end
    
    web -->|HTTPS| cf
    mobile -->|HTTPS| cf
    cf -->|HTTPS| waf
    waf --> alb
    
    alb --> ec2_1
    alb --> ec2_2
    alb --> ec2_3
    
    ec2_1 --> session
    ec2_2 --> session
    ec2_3 --> session
    
    ec2_1 --> cache
    ec2_2 --> cache
    ec2_3 --> cache
    
    ec2_1 --> opensearch
    ec2_2 --> opensearch
    
    ec2_1 --> rds
    ec2_2 --> rds
    ec2_3 --> rds
    
    rds -->|Read Only| rds_replica
    
    ec2_1 --> stripe
    ec2_2 --> stripe
    
    ec2_1 --> sqs
    ec2_2 --> sqs
    
    sqs --> sns
    sns --> lambda
    lambda --> cache
    lambda --> rds
    
    ec2_1 --> s3
    ec2_2 --> s3
    
    ec2_1 --> cloudwatch
    ec2_2 --> cloudwatch
    ec2_3 --> cloudwatch
    rds --> cloudwatch
    
    ec2_1 -.->|Audit| cloudtrail
    rds -.->|Audit| cloudtrail
    
    rds -->|Encrypt| kms
    s3 -->|Encrypt| kms
    session -->|Encrypt| kms
    
    rds -->|Backup| backup
    backup --> dr
    s3 -->|Replicate| s3_backup
    
    style waf fill:#ff6b6b
    style kms fill:#4dabf7
    style cloudtrail fill:#51cf66
    style backup fill:#ffd43b
```

## Architecture Components

### Compute Layer
- **ALB (Application Load Balancer)**: Distributes 10K concurrent users across multiple AZs
- **EC2 Auto Scaling Group**: Horizontally scales application servers (min 2, max 8 instances)
- **ElastiCache Redis**: Session management and real-time cache for product data

### Data Layer
- **Aurora PostgreSQL Multi-AZ**: Ensures 99.95% uptime with automatic failover
- **Read Replicas**: Handle analytics queries without impacting production
- **OpenSearch**: Full-text search for 1M product catalog

### Real-Time Inventory Sync
- **SQS**: Decouples inventory updates from web tier
- **SNS**: Publishes inventory events
- **Lambda**: Processes events and updates caches
- **Redis Cache**: Stores inventory state for microsecond lookups

### Storage & CDN
- **S3**: Product images, static content
- **CloudFront**: Global content delivery with EU edge locations
- **Cross-Region S3**: Disaster recovery backup

### Security & Compliance
- **WAF**: Protects against common web exploits
- **KMS**: Encryption for data at rest
- **CloudTrail**: GDPR-compliant audit logging
- **VPC**: Isolated network with security groups

### Disaster Recovery
- **AWS Backup**: Automated RDS snapshots every 4 hours
- **Cross-Region Replica**: Failover capability in seconds
- **S3 Cross-Region Replication**: Data durability
