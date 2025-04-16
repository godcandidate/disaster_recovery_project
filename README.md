# Disaster Recovery Project - Pilot Light Strategy

This project implements a disaster recovery (DR) solution using the Pilot Light strategy with Terraform. The infrastructure is organized in a modular and manageable way to ensure easy maintenance and scalability.

## Project Structure

```
disaster_recovery_project/
├── modules/                    # Reusable Terraform modules
│   ├── vpc/                    # VPC, subnets, route tables, Internet Gateway
│   ├── iam/                    # IAM roles and policies
│   ├── security_groups/        # Security groups for different resources
│   └── ... (future modules)
├── environments/               # Environment-specific configurations
│   ├── primary/                # Primary region (eu-west-1)
│   └── dr/                     # DR region (eu-west-2)
└── README.md                   # Project documentation
```

## Regions

- Primary Region: eu-west-1 (Ireland)
- DR Region: eu-west-2 (London)

## Implementation Plan

### Unit 1: Networking and Security Setup
- VPC with public and private subnets in two Availability Zones
- Internet Gateway for public subnet access
- IAM roles and policies for cross-region operations
- Security groups for EC2, RDS, and Lambda resources

### Future Units (Planned)
- Unit 2: Compute and Database Setup
- Unit 3: Storage and Replication
- Unit 4: Serverless Components
- Unit 5: Monitoring and Alerting
- Unit 6: DR Testing and Validation

## Usage

Instructions for deploying the infrastructure will be provided as the project progresses.
