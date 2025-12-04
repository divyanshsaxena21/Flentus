**Overview**
- **Project**: Deploy a static resume website on an EC2 instance using Nginx.
- **Location**: `question2` directory of this repository.

**What this does**
- Launches a `t3.micro` EC2 instance (Free Tier eligible) in an existing VPC/subnet (IDs are set in `main.tf`).
- Uses a key pair from `ec2key.pub` and a private key `divyansh_saxena_.pem` for SSH and provisioner actions.
- Uses `userdata.sh` to update packages, install Nginx, create a webroot and redirect `index.html` to the uploaded resume PDF.
- A Terraform `file` provisioner uploads `divyansh_saxena_resume.pdf` and a `remote-exec` provisioner ensures the resume ends up in the Nginx webroot.

**Files of interest**
- `main.tf` : Terraform code to create the EC2 instance, security group and key pair and provision the resume.
- `userdata.sh` : Bootstrapping script that runs on first boot to install and start Nginx and create the redirecting `index.html`.
- `divyansh_saxena_resume.pdf` : The resume uploaded to the instance and served.
- `photos/` : Contains screenshots for EC2, Security Group and the website in a browser.

**How the instance and site are configured (summary)**
- AMI: `ami-0d176f79571d18a8f` (set in `main.tf`). Confirm this AMI is appropriate and up-to-date for your region and use-case.
- Instance type: `t3.micro` (Free Tier eligible alternative: `t2.micro` depending on account eligibility).
- Subnet: `subnet-018deda5f044b6779` (public subnet with `associate_public_ip_address = true`).
- Security Group: `divyansh_saxena_sg` allows SSH (22) and HTTP (80) from `0.0.0.0/0` (see hardening notes below).
- User data: `userdata.sh` runs `yum update -y`, installs `nginx`, enables and starts it, and creates `index.html` that redirects to `divyansh_saxena_resume.pdf`.

**Nginx installation & resume placement**
- `userdata.sh`:
  - Updates packages and installs `nginx`.
  - Enables and starts `nginx`.
  - Creates `/usr/share/nginx/html/index.html` which redirects to the resume PDF.
- Terraform provisioner uploads `divyansh_saxena_resume.pdf` to `/home/ec2-user/` and a `remote-exec` block moves it into `/usr/share/nginx/html/` with appropriate ownership and permissions, restarts nginx.

**Hardening & best-practice recommendations applied or advised**
- Applied / present:
  - SSH uses key-based authentication (no password set by Terraform provisioning). The instance uses the provided key-pair files.
- Recommended improvements (actionable):
  - Restrict SSH access: change the security group rule to allow SSH only from your IP (e.g., `203.0.113.4/32`) instead of `0.0.0.0/0`.
  - Remove wide open ICMP/other ports: keep only required ports (80, 443 as needed).
  - Use the latest, minimal AMI and enable automatic security updates (or a configuration management tool) to reduce attack surface.
  - Disable unused services and remove default credentials.
  - Use IAM roles (instance profile) rather than embedded credentials if the instance needs AWS API access.
  - Configure the OS firewall (firewalld/ufw) to limit traffic and use SELinux in enforcing mode if available.
  - Regularly rotate and protect private keys; do not commit private keys to a public repo. (`divyansh_saxena_.pem` is present in this folder—ensure it is stored securely and removed from public repos.)

**How to reproduce / redeploy**
1. From `question2` directory:
```powershell
terraform init
terraform plan -out plan.out
terraform apply "plan.out"
```
2. After apply finishes, Terraform outputs the EC2 `public_ip` (see `terraform output public_ip`).
3. Open a browser to `http://<public_ip>/` to see the redirect to the resume PDF.

**How to SSH (if needed)**
```powershell
# from PowerShell on your machine (example)
ssh -i .\divyansh_saxena_.pem ec2-user@<public_ip>
```
Note: Replace `ec2-user` with the correct user for the AMI if different (e.g., `ubuntu`).

**Screenshots (in this folder)**
- `photos/Screenshot 2025-12-04 221433.png` — EC2 instance list / details (showing instance created)
- `photos/Screenshot 2025-12-04 221614.png` — Security Group rules (SSH & HTTP)
- `photos/Screenshot 2025-12-04 221859.png` — Website accessible in browser (shows resume page)

If any of these screenshots correspond differently, open the `photos/` folder and pick the images that show those pages.

**Security note (important)**
- This repository currently contains private key file `divyansh_saxena_.pem`. If this repository is public, remove the private key immediately and replace the key pair by creating a new key pair. Committing private keys is insecure.

**GitHub link to code**
- `https://github.com/divyanshsaxena21/Flentus/tree/main/question2`

**Next steps I can help with**
- Restrict the security group to a CIDR for your IP and update `main.tf` accordingly.
- Move SSH key usage to a safer workflow (SSM Session Manager or limiting to specific IPs) and remove the private key from the repo.
- Replace the `file` and `remote-exec` provisioners with a more robust artifact deployment (e.g., bake the resume into an AMI, use S3 + CloudFront, or use a configuration management tool).

---
Generated: automated README for `question2` to summarize the EC2 static site setup and best-practices.
