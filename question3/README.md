**Overview**
- **Project**: High-Availability architecture with an Internet-facing ALB, private EC2 instances in an ASG, and NAT for outbound access.
- **Location**: `question3` folder in this repository.

**Architecture & Traffic Flow**
- **Design summary**: I placed all application EC2 instances inside private subnets across two Availability Zones and exposed the application only through an Internet-facing Application Load Balancer (ALB) deployed in public subnets. An Auto Scaling Group (ASG) launches EC2 instances (no public IPs) across the two private subnets for high availability.
- **Traffic flow**: User -> Internet -> ALB (public subnets) -> Target Group -> EC2 instances (private subnets). Instance outbound traffic (e.g., package updates) goes through the NAT Gateway in a public subnet.
- **Resiliency**: ALB spans two AZs; ASG distributes instances across both private subnets to tolerate AZ failure and automatically replaces unhealthy instances.

**Exact CIDRs & variables used**
- **VPC**: `10.0.0.0/16`
- **Public Subnet A**: `10.0.1.0/24`
- **Public Subnet B**: `10.0.2.0/24`
- **Private Subnet A**: `10.0.11.0/24`
- **Private Subnet B**: `10.0.12.0/24`
- **Key pair name** (from `terraform.tfvars`): `divyansh_saxena_Key`
- **Admin SSH CIDR** (from `terraform.tfvars`): `103.46.203.21/32` (used to restrict SSH to the admin IP)
- **ASG sizes** (from `main.tf` variables): `desired = 2`, `min = 2`, `max = 4`

**Resources created (high-level)**
- `aws_lb.alb` : Internet-facing ALB in the two public subnets.
- `aws_lb_target_group.tg` : HTTP target group (port 80) with health checks.
- `aws_launch_template.lt` : Launch template with Amazon Linux 2 + Nginx user-data.
- `aws_autoscaling_group.asg` : ASG spanning the two private subnets and attached to the target group.
- Security groups:
  - `alb_sg`: allows HTTP (80) from Internet.
  - `ec2_sg`: allows HTTP (80) from the ALB security group and SSH (22) only from `103.46.203.21/32`.

**How to deploy**
1. From the `question3` folder run:
```powershell
terraform init
terraform plan -out plan.out
terraform apply "plan.out"
```
2. After `apply` completes, get the ALB DNS name:
```powershell
terraform output alb_dns
```
3. Open `http://<alb_dns>` in a browser to reach the application.

**How to verify (quick)**
- Check ALB configuration in AWS Console: `EC2 > Load Balancers` and open `divyansh-saxena-alb`.
- Check target group health: `EC2 > Target Groups` and view `divyansh-saxena-tg` — healthy targets should show the instances created by the ASG.
- Confirm ASG: `EC2 > Auto Scaling Groups` and open `divyansh-saxena-asg` to see instances and lifecycle events.
- EC2 instances (launched by ASG) appear in private subnets — they will have no public IPs.

**Screenshots (in `photos/`)**
- `photos/Screenshot 2025-12-04 235410.png` — ALB or Target Group (pick the ALB console view)
- `photos/Screenshot 2025-12-04 235426.png` — Auto Scaling Group / EC2 instances view

If the images need different mapping, open the `photos/` folder and use the appropriate screenshots for:
- ALB configuration
- Target group
- Auto Scaling Group
- EC2 instances created via ASG

**GitHub link to Terraform code**
- `https://github.com/divyanshsaxena21/Flentus/tree/main/question3`

**Security & best-practices notes**
- SSH access is restricted to the single admin IP specified in `terraform.tfvars` (`103.46.203.21/32`) — this reduces attack surface.
- Application instances are placed in private subnets with no public IPs; public access is only through the ALB.
- Use IAM instance profiles for tasks that need AWS API access instead of embedding credentials.
- Consider adding HTTPS listener with a certificate (ACM) and redirecting HTTP to HTTPS for production.
- Monitor target health and set appropriate scaling policies based on CPU, request rate or custom metrics.

**Next steps / suggestions**
- Add an `aws_acm_certificate` and HTTPS listener to secure traffic.
- Add lifecycle/rolling update settings or health/termination policies for graceful instance replacement.
- Add CloudWatch alarms and ASG scaling policies.
- Optional: Use blue/green or canary deployments via target group switching or CodeDeploy.

---
Generated README summarizing the high-availability design and deployment steps.
