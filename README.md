# 🌐 AWS VPC Network Foundation (Reusable Terraform Module)

This project provides a **reusable AWS VPC network foundation** that can be used as the starting point for any cloud project.  
Instead of manually recreating VPC, subnets, route tables, NAT gateways, and security groups for every deployment, this setup allows you to **deploy a complete, production-ready network with one Terraform apply**.

---

## 🚀 Why I Built This

In real cloud environments, we often need the **same base networking setup** every time:
- A **VPC**
- Public and private subnets across multiple Availability Zones
- Internet Gateway + NAT Gateways
- Route tables and routing associations
- Security groups following **least-privilege** best practices

Creating these manually in AWS Console again and again is:
- Time-consuming
- Error-prone
- Hard to reproduce across environments (dev/staging/prod)

By building this as **Infrastructure-as-Code**:

✔️ I can deploy the same architecture consistently  
✔️ I avoid clicking around the console  
✔️ I can reuse it in any future project  
✔️ It is version-controlled and team-collaborative  
✔️ Any environment can be reproduced in **seconds**

This setup now acts as my **standard base network** for:
- EC2 deployments
- ECS / EKS clusters
- RDS databases
- Microservices architecture
- Web apps / APIs / internal tooling

---

## 🧱 What This Network Includes

| Component | Description |
|----------|-------------|
| **VPC (10.0.0.0/16)** | Private virtual network |
| **Public Subnets (x2)** | Spread across 2 AZs, allow internet access |
| **Private Subnets (x2)** | For app + database workloads |
| **Internet Gateway** | Enables inbound/outbound public traffic |
| **NAT Gateways (x2)** | Allow private subnets to access the internet securely |
| **Public & Private Route Tables** | Correct routing applied automatically |
| **Security Groups** | ALB SG, App SG, DB SG with least-privilege rules |

This is a **production-ready, multi-AZ architecture**, not just a demo.

---

## 📂 Directory Structure


### What Each File Does

| File | Purpose | Explanation |
|------|---------|-------------|
| **main.tf** | Core Infrastructure Logic | Contains all AWS resources (VPC, subnets, route tables, NAT gateways, security groups). This is the main network blueprint. |
| **variables.tf** | Input Variables | Allows customization of CIDR ranges, region, naming prefixes, etc. Makes the module reusable. |
| **outputs.tf** | Helpful Outputs | Prints resource IDs (subnets, SGs, VPC) after deployment so they can be referenced in other modules or services. |
| **versions.tf** | Provider & Terraform Requirements | Ensures AWS provider and Terraform version compatibility, keeping deployments consistent. |
| **.gitignore** | Protects State & Sensitive Files | Prevents accidental commits of terraform.tfstate, plan files, and cache dirs to GitHub. |

---

## 🔗 Next Components You Can Layer On Top

| Component | Description | Placement / Notes |
|----------|-------------|------------------|
| **EC2 Auto Scaling + ALB** | Scalable application servers | Instances in **private subnets**, ALB in **public subnets** routing traffic inward |
| **RDS PostgreSQL/MySQL** | Managed database layer | DB in **private subnets**, secured using `sg-db` (no public access) |
| **ECS (EC2 or Fargate)** | Containerized workloads | Runs in **private subnets**, pulls images via NAT |
| **EKS Cluster (Kubernetes)** | Workload orchestration | Worker nodes in **private subnets**, integrates with ALB ingress |

---

## 🎯 Key Benefits

| Benefit | Explanation |
|--------|-------------|
| **Reusable** | Use the same VPC foundation across all future projects |
| **Consistent** | Eliminates manual setup mistakes |
| **Secure** | Private workloads + least-privilege security groups |
| **Scalable** | Multi-AZ layout supports production workloads |
| **Automated** | Fully reproducible with one `terraform apply` |
| **Cloud Best Practices** | Matches AWS reference architecture standards |

---

## 🚀 Deploy

```bash
terraform init
terraform plan
terraform apply -auto-approve
