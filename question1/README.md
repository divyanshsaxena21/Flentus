**Overview**
- **Project**: Basic AWS VPC with public and private subnets, IGW and NAT Gateway.
- **Location**: `question1` directory of this repository.

**Design**
- **VPC**: A single VPC to contain all subnets and routing.
- **Public Subnets (2)**: Placed in two AZs so internet-facing resources can be multi-AZ.
- **Private Subnets (2)**: Placed in the same AZs for high-availability of private resources.
- **Internet Gateway (IGW)**: Attached to the VPC for inbound/outbound internet access from public subnets.
- **NAT Gateway**: Placed in one public subnet (with an Elastic IP) to allow private subnets outbound internet access while keeping instances private.

**CIDR Ranges (exact)**
- **VPC**: `10.0.0.0/16`
- **Public Subnet A**: `10.0.1.0/24` (availability zone `ap-south-1a`)
- **Public Subnet B**: `10.0.2.0/24` (availability zone `ap-south-1b`)
- **Private Subnet A**: `10.0.11.0/24` (availability zone `ap-south-1a`)
- **Private Subnet B**: `10.0.12.0/24` (availability zone `ap-south-1b`)

Rationale: I used a `10.0.0.0/16` VPC to give plenty of usable addresses while keeping the addressing simple and private. Each subnet is a `/24` giving up to 256 addresses per subnet which is enough for most small deployments and keeps IP planning straightforward. Public and private subnets are numbered to avoid overlap and to make it obvious which ranges are public vs private.

**Screenshots**
The screenshots you uploaded are in the `photos/` folder in this directory. They show the AWS Console views for the required resources.
- **VPC**: `photos/Screenshot 2025-12-04 182342.png`
- **Subnets**: `photos/Screenshot 2025-12-04 182420.png`
- **Route Tables**: `photos/Screenshot 2025-12-04 182455.png`
- **NAT Gateway + IGW**: `photos/Screenshot 2025-12-04 182605.png`

If your screenshots correspond differently, open the `photos/` folder and pick the images that show those console pages.

**Terraform files / GitHub link**
- The Terraform code used to create this setup is in this repository under `question1/main.tf`.
- GitHub link to this folder: `https://github.com/divyanshsaxena21/Flentus/tree/main/question1`

**How to deploy (quick)**
1. From the `question1` directory run:
```
terraform init
terraform plan -out plan.out
terraform apply "plan.out"
```
2. Terraform outputs include IDs for the VPC, subnets, NAT gateway and IGW.
3. To destroy the resources when done:
```
terraform destroy -auto-approve
```

**Notes & tips**
- The Terraform `provider` in `main.tf` sets AWS region to `ap-south-1`.
- The NAT gateway is created in `Public Subnet A` and has an Elastic IP for outbound traffic.
- The public route table has a `0.0.0.0/0` route to the IGW; the private route table has a `0.0.0.0/0` route to the NAT gateway.

**Files in this folder**
- `main.tf` : Terraform definitions used to create the VPC, subnets, IGW, NAT and route tables.
- `terraform.tfstate` : Current Terraform state (do not commit sensitive state in public repos).
- `photos/` : Contains the requested screenshots.

If you want, I can:
- Add a short `variables.tf` and `outputs.tf` split to make the module cleaner.
- Create a small diagram (PNG) of the network layout and add it to `photos/`.

---
Generated: automated README created by helper script.
