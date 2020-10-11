# This terraform template will deploy udeploy in HA configuration
# It will provision the following resource

data "aws_availability_zones" "available" {
}

resource "aws_vpc" "vcs_vpc" {
  cidr_block           = var.option_4_aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name          = var.option_3_aws_vpc_name
    Product       = var.product
    Team          = var.team
    Owner         = var.owner
    Environment   = var.environment
    Organization  = var.organization
    "Cost Center" = var.costcenter
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vcs_vpc.id
  cidr_block = cidrsubnet(aws_vpc.vcs_vpc.cidr_block, 8, 2)
  tags = {
    Name          = "subnet-${var.option_3_aws_vpc_name}"
    Product       = var.product
    Team          = var.team
    Owner         = var.owner
    Environment   = var.environment
    Organization  = var.organization
    "Cost Center" = var.costcenter
  }
}

resource "aws_subnet" "rds_subnet_1" {
  count             = var.option_9_use_rds_database
  vpc_id            = aws_vpc.vcs_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vcs_vpc.cidr_block, 8, 3)
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name          = "subnet-rds-1-${var.option_3_aws_vpc_name}"
    Product       = var.product
    Team          = var.team
    Owner         = var.owner
    Environment   = var.environment
    Organization  = var.organization
    "Cost Center" = var.costcenter
  }
}

resource "aws_subnet" "rds_subnet_2" {
  count             = var.option_9_use_rds_database
  vpc_id            = aws_vpc.vcs_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vcs_vpc.cidr_block, 8, 4)
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name          = "subnet-rds-2-${var.option_3_aws_vpc_name}"
    Product       = var.product
    Team          = var.team
    Owner         = var.owner
    Environment   = var.environment
    Organization  = var.organization
    "Cost Center" = var.costcenter
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  count      = var.option_9_use_rds_database
  name       = "rds-mysql"
  subnet_ids = [aws_subnet.rds_subnet_1[0].id, aws_subnet.rds_subnet_2[0].id]

  tags = {
    Name          = "subnet_group-rds-${var.option_3_aws_vpc_name}"
    Product       = var.product
    Team          = var.team
    Owner         = var.owner
    Environment   = var.environment
    Organization  = var.organization
    "Cost Center" = var.costcenter
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vcs_vpc.id
  tags = {
    Name          = "IG-${var.option_3_aws_vpc_name}"
    Product       = var.product
    Team          = var.team
    Owner         = var.owner
    Environment   = var.environment
    Organization  = var.organization
    "Cost Center" = var.costcenter
  }
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vcs_vpc.id
  tags = {
    Name          = "RTB-${var.option_3_aws_vpc_name}"
    Product       = var.product
    Team          = var.team
    Owner         = var.owner
    Environment   = var.environment
    Organization  = var.organization
    "Cost Center" = var.costcenter
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rtb.id
}

resource "aws_key_pair" "admin_ssh_key" {
  key_name   = var.option_5_aws_admin_ssh_key_name
  public_key = var.option_6_aws_admin_public_ssh_key
}

resource "aws_key_pair" "dev_ssh_key" {
  key_name   = var.option_7_aws_dev_ssh_key_name
  public_key = var.option_8_aws_dev_public_ssh_key
}

resource "aws_security_group" "mast_sg" {
  name   = "web_${var.option_3_aws_vpc_name}"
  vpc_id = aws_vpc.vcs_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.option_4_aws_vpc_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "agent_sg" {
  name   = "app_${var.option_3_aws_vpc_name}"
  vpc_id = aws_vpc.vcs_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.option_4_aws_vpc_cidr]
  }

  ingress {
    from_port   = 7919
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.option_4_aws_vpc_cidr]
  }
  ingress {
    from_port   = 7918
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.option_4_aws_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_instance" "master" {
  ami                    = var.images["app"]
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.mast_sg.id]
  key_name               = aws_key_pair.dev_ssh_key.id
  tags = {
    App           = var.option_3_aws_vpc_name
    Name          = "mast-${var.option_3_aws_vpc_name}"
    Tier          = "APP"
    Product       = var.product
    Team          = var.team
    Owner         = var.owner
    Environment   = var.environment
    Organization  = var.organization
    "Cost Center" = var.costcenter
  }
}

resource "aws_instance" "agent1" {
  ami                    = var.images["app"]
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.agent_sg.id]
  key_name               = aws_key_pair.dev_ssh_key.id
  tags = {
    App           = var.option_3_aws_vpc_name
    Name          = "agent-${var.option_3_aws_vpc_name}"
    Tier          = "APP"
    Product       = var.product
    Team          = var.team
    Owner         = var.owner
    Environment   = var.environment
    Organization  = var.organization
    "Cost Center" = var.costcenter
  }
}
output "vpc_id" {
  value = aws_vpc.vcs_vpc.id
}

output "mgmt_public_ip" {
  value = aws_instance.mgmt.public_ip
}

output "web1_public_ip" {
  value = aws_instance.web1.public_ip
}

output "web2_public_ip" {
  value = aws_instance.web2.public_ip
}

