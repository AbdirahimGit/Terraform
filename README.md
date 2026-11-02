# Assignment 1 – Deploy WordPress Using Terraform

## Objective

Use Terraform to deploy a full WordPress stack on AWS, including:

- An EC2 instance running WordPress
- Security groups
- User data to install dependencies
- A working public endpoint
- All resources provisioned via Terraform

This project shows how Terraform manages real infrastructure end to end. Instead of clicking through the AWS console, the whole environment is described in code, so it can be built, reviewed and destroyed with a few commands.

![WordPress homepage running on AWS](screenshots/23-wordpress-homepage.png)

## Architecture

```mermaid
flowchart TB
    U[Internet / Website Visitors]
    SSH[Administrator - SSH]
    subgraph AWS["AWS Cloud - eu-west-2"]
        subgraph VPC["Default VPC"]
            SG["Security Group<br/>HTTP: 80 - anyone<br/>SSH: 22 - my IP only"]
            EC2["Amazon EC2<br/>Amazon Linux 2023"]
            subgraph APP["Installed by user data"]
                AP["Apache"]
                PHP["PHP"]
                WP["WordPress"]
                DB["MariaDB"]
            end
            EC2 --> AP --> PHP --> WP --> DB
        end
    end
    U -->|HTTP port 80| SG
    SSH -->|SSH port 22| SG
    SG --> EC2
```

- Visitors reach the site on the EC2 instance's public IP address over HTTP (port 80).
- A security group acts as the firewall: web traffic is open to everyone, SSH is open to my IP address only.
- The EC2 instance sits in a subnet of the default VPC and gets a public IP.
- The server installs and configures Apache, PHP, MariaDB and WordPress by itself on first boot, with no manual SSH session needed.

## Project structure

```text
Assignment-1-Wordpress/
├── main.tf                  # AWS provider, and the calls to the three modules
├── variables.tf             # Root values (my IP, database password, instance settings)
├── output.tf                # Public IP, DNS name and instance ID
├── terraform.tfvars         # My real values (not committed to Git)
├── .terraform.lock.hcl      # Locks provider versions
├── .gitignore
├── screenshots/
└── modules/
    ├── network/
    │   ├── main.tf          # Default VPC and subnet lookups, security group and rules
    │   ├── variables.tf
    │   └── outputs.tf       # VPC ID, subnet ID, security group ID
    ├── ec2/
    │   ├── main.tf          # AMI lookup and the EC2 instance
    │   ├── variables.tf
    │   └── outputs.tf       # Instance ID, public IP, DNS name
    └── wordpress/
        ├── main.tf          # Fills the database details into the script
        ├── variables.tf
        ├── outputs.tf       # The finished user data script
        └── user_data.sh     # The install script
```

## Modules

### Network module

Sets up what the server needs to be reachable:

- **Default VPC:** looked up with a data source (nothing is created)
- **Subnets:** looked up with a data source, and the first one is used
- **Security group** with three rules:
  - HTTP (port 80) from anywhere
  - SSH (port 22) from my IP address only
  - All outbound traffic, so the server can download software at startup

### EC2 module

Everything that creates the server:

- **AMI data source:** finds the latest x86_64 Amazon Linux 2023 image, so no image ID is hardcoded
- **EC2 instance** with the chosen subnet, the security group and a public IP address
- Runs the user data script it is given
- `user_data_replace_on_change = true`: user data only runs on first boot, so this makes Terraform recreate the server whenever the script changes, and the new version actually runs

### WordPress module

Prepares the application install:

- Uses Terraform's `templatefile()` function to fill the database name, user and password into the script
- Outputs the finished script so the EC2 module can attach it
- The password is a `sensitive` variable, so Terraform hides it in plan output

### How the modules connect

Modules can't reference each other directly, so values pass through the root `main.tf`:

```text
network outputs.tf → root main.tf → ec2 variables.tf
wordpress outputs.tf → root main.tf → ec2 variables.tf
```

For example, the subnet ID and security group ID come out of the network module and go into the EC2 module, and the finished script comes out of the WordPress module and goes into the EC2 module.

```mermaid
flowchart TD
    A["Root module (main.tf)"] --> B["network"]
    A --> C["wordpress"]
    A --> D["ec2"]
    B -->|"subnet_id, security_group_id"| D
    C -->|"user_data"| D
    D --> E["Running WordPress server"]
```

## What the user data script does

- Updates the operating system
- Installs Apache, PHP (with the extensions WordPress needs) and MariaDB
- Starts the services and enables them to start on reboot
- Creates the WordPress database and a dedicated database user
- Downloads WordPress and copies it into the web folder
- Writes the WordPress configuration with the database details and fresh security keys
- Sets file ownership and permissions for Apache
- Restarts the web server

## How to deploy

Create `terraform.tfvars` with your own values (this file is ignored by Git):

```hcl
ip_address  = "YOUR_PUBLIC_IP/32"
db_password = "YOUR_STRONG_PASSWORD"
```

Then run:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Wait 3–5 minutes for the user data script to finish, then get the address and open it in a browser:

```bash
terraform output ec2_public_ip
```

```text
http://YOUR_EC2_PUBLIC_IP
```

To remove everything and avoid charges:

```bash
terraform destroy
```

## Completing the WordPress setup

1. Open `http://<public-ip>` and choose a language
2. Enter a site title, an admin username, a strong password and an email address
3. Click **Install WordPress**, then log in at `http://<public-ip>/wp-admin`

## Deployment walkthrough

### 1. Terraform initialised

![Terraform initialised](screenshots/01-terraform-initialised.png)

### 2. Default VPC and subnet looked up

![Plan for the default VPC lookup](screenshots/07-terraform-plan-default-vpc.png)

![VPC and subnet IDs returned](screenshots/12-vpc-subnet-id-output-successfull.png)

### 3. Security group

The rules in code:

![Security group rules](screenshots/14-sg-rules.png)

The plan before anything is built:

![Security group plan](screenshots/15-sg-terraform-plan.png)

Created by Terraform, and visible in the AWS console:

![Security group created](screenshots/16-sg-created.png)

![Security group in the AWS console](screenshots/17-sg-AWS-console.png)

### 4. AMI lookup

![AMI ID found by the data source](screenshots/18-ami-id.png)

### 5. EC2 instance running

![EC2 instance created](screenshots/19-ec2-instance-running.png)

![EC2 instance in the AWS console](screenshots/20-ec2-running-on-console.png)

### 6. Terraform outputs

![Terraform outputs](screenshots/21-ec2-ouputs.png)

### 7. WordPress is live

The installer appears at the server's public address:

![WordPress installer](screenshots/22-wordpress-installer-page.png)

The finished site:

![WordPress homepage](screenshots/23-wordpress-homepage.png)

A published post, proving the web server, PHP, WordPress and database all work together:

![Published post](screenshots/24-wordpress-published-post.png)

## Troubleshooting walkthrough

The trickiest bug was an output that looked right but held the wrong value.

**Step 1: The subnet output showed a region, not a subnet ID**

`terraform apply` finished without any error, but the `subnet_id` output printed `eu-west-2`, which is a region, not a subnet ID (those start with `subnet-`).

![Output showing the region](screenshots/08-error-subnet-finds-regionID-not-subnetID.png)

![Region outputted instead of the subnet](screenshots/09-error-subent-region-is-outputted.png)

**Step 2: Finding the cause**

I checked the docs for the `aws_subnets` data source. Its `id` attribute holds the AWS **region**, while its `ids` attribute holds the **list of subnet IDs**. I was reading the wrong one.

**Step 3: The fix**

Read the list and pick the first entry with `.ids[0]`:

![The fix finds the subnet ID](screenshots/10-error-fix-finds-subnetID.png)

![Region corrected to subnet ID](screenshots/11-error-fix-regionID-to-subnetID.png)

I then compared the IDs with `aws ec2 describe-vpcs` and `describe-subnets` to confirm they were real.

## Issues encountered and fixes

### 1. Reference pointed at the wrong data block

**Error:** `Reference to undeclared resource: A data resource "aws_vpc" "default_subnets" has not been declared in the root module.`
**Cause:** A Terraform reference is `data.TYPE.LABEL.ATTRIBUTE`, and the type and label must match a block that exists. My filter used the VPC type with the subnets label.
**Fix:** Pointed the filter at the VPC block (`data.aws_vpc.default.id`) and the subnet output at the subnets block.

![Error calling the VPC block](screenshots/02-error-calling-vpcblock-.png)

![Output read from the wrong block](screenshots/03-error-ouput-read-from-wrong-block.png)

![Fixed: reading the subnet ID](screenshots/04-error-fixed-reading-subnetID.png)

![Fixed: calling the subnet ID](screenshots/05-error-fixed-calling-subnetID.png)

![Validation succeeds](screenshots/06-error-validated-succesfully.png)

### 2. Subnet output returned the region

**Symptom:** The `subnet_id` output printed `eu-west-2`.
**Cause:** `.id` on the `aws_subnets` data source is the region. `.ids` is the list of subnet IDs.
**Fix:** Used `.ids[0]` (see the troubleshooting walkthrough above).

### 3. Filter value was not a list

**Symptom:** The filter was written as `values = data.aws_vpc.default.id[0]`.
**Cause:** `values` expects a list, and `[0]` picks an item *out of* a list. I had used the square brackets for the wrong job.
**Fix:** Wrapped the single value in a list: `values = [data.aws_vpc.default.id]`. The `[0]` belongs in the output, on `.ids`.

### 4. IAM user had no EC2 permissions

**Error:** `UnauthorizedOperation ... User: arn:aws:iam::...:user/terraform-wordpress is not authorized to perform: ec2:DescribeVpcs because no identity-based policy allows the ec2:DescribeVpcs action`
**Cause:** The IAM group had no policy attached, so the user could log in but not do anything with EC2.
**Fix:** Attached the `AmazonEC2FullAccess` policy to the group and confirmed the user was a member of it.

### 5. Invented argument name in a resource

**Error:** `Unsupported argument: An argument named "ami_import" is not expected here.`
**Cause:** The names on the left of `=` inside a resource are fixed by the AWS provider. Only the value on the right is mine.
**Fix:** Used `ami` on the left, and gave each instance its own variable for the value on the right.

### 6. Security group reference didn't match its label

**Error:** `aws_security_group ... is not defined`
**Cause:** The group was labelled `allow_http`, but the rules referenced `aws_security_group.wordpress`.
**Fix:** Renamed the label to `wordpress` and made the name, label and tag consistent.

### 7. SSH rule used the IPv6 argument

**Symptom:** The SSH rule used `cidr_ipv6` with an IPv4 address.
**Cause:** Wrong argument for the address type.
**Fix:** Switched to `cidr_ipv4`.

### 8. Tried to set a read-only attribute

**Symptom:** `public_ip = true` was rejected on the instance.
**Cause:** `public_ip` is filled in by AWS after the instance exists. It can't be set.
**Fix:** Used `associate_public_ip_address = true` to request a public IP, and kept `public_ip` for the output.

### 9. Module was missing required arguments

**Error:** `Missing required argument: The argument "test_ami" is required, but no definition was found.`
**Cause:** A variable with no default is required, and nothing was passed in the `module` block. A module only receives values from the block that calls it, not from `terraform.tfvars`.
**Fix:** Passed the values through the module call.

### 10. Variable names didn't match between module and caller

**Cause:** The network module declared `ssh_allowed_cidr`, but its code used `var.ip_address`.
**Fix:** Picked one name (`ip_address`) and used it in the module, the module call, the root variable and `terraform.tfvars`.

### 11. Arrow keys printed `^[[D` at a Terraform prompt

**Cause:** Terraform's input prompt has no line editing.
**Fix:** Used Backspace to correct mistakes, and moved the value into `terraform.tfvars` so it never prompts.

## Lessons learned

- A **data source** reads something that already exists, and a **resource** creates and manages it. Variables don't change that.
- References are `data.TYPE.LABEL.ATTRIBUTE`, and `TYPE.LABEL.ATTRIBUTE` for resources. Type and label must match a block that exists.
- `[ ]` builds a list when giving a value, and picks an item when reading a list.
- A successful `apply` doesn't mean the value is right. Check outputs against what the AWS console shows.
- Argument names inside a resource are fixed by the provider. Only the values are mine.
- A module is a sealed box. Values go in through variables and come out through outputs, and `terraform.tfvars` only fills the root's variables.
- SSH is an application that runs over TCP, so the firewall rule is "TCP, port 22", locked to one IP.
- Terraform reads every `.tf` file in the folder, so file names are for organisation, not behaviour.
- Read `terraform plan` before every apply, especially for anything marked "must be replaced".
- Add a `.gitignore` before the first commit, and never commit state files, keys or `terraform.tfvars`.

## Future improvements

- Custom VPC with public and private subnets, instead of the default VPC
- Application Load Balancer, with the server in a private subnet
- HTTPS with a domain name and an AWS Certificate Manager certificate
- Elastic IP, so the address survives a stop and start
- Move the database to Amazon RDS, so data survives if the server is replaced
- AWS Secrets Manager for the database password, instead of passing it through user data
- AWS Systems Manager Session Manager instead of SSH
- Remote Terraform state in S3 with locking
- GitHub Actions pipeline running `fmt`, `validate` and `plan` on every pull request