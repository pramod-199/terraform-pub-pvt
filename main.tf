# ✅ VPC
resource "aws_vpc" "myvpc" {
  cidr_block = var.aws_vpc_cidr_block

  tags = {
    Name = "my-vpc"
  }
}

# ✅ Public Subnet
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.aws_subnet1_cidr_block
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# ✅ Private Subnet
resource "aws_subnet" "sub2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = var.aws_subnet2_cidr_block
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet"
  }
}

# ✅ Internet Gateway for Public Subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "internet-gateway"
  }
}

# ✅ Public Route Table
resource "aws_route_table" "myrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# ✅ Associate Public Route Table with Public Subnet
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.myrt.id
}

# ✅ Elastic IP for NAT Gateway
resource "aws_eip" "myeip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
}

# ✅ NAT Gateway for Private Subnet
resource "aws_nat_gateway" "mynat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.sub1.id

  tags = {
    Name = "nat-gateway"
  }
}

# ✅ Private Route Table (Using NAT Gateway for Internet)
resource "aws_route_table" "myrt1" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.mynat.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# ✅ Associate Private Route Table with Private Subnet
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.myrt1.id
}

# ✅ Security Group for EC2 Instances
resource "aws_security_group" "mysg" {
  vpc_id = aws_vpc.myvpc.id

  dynamic "ingress" {
    for_each = var.allowed_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-security-group"
  }
}

# ✅ S3 Bucket (Public Access)
resource "aws_s3_bucket" "mybucket" {
  bucket = "pramodaarna2026"
}

# ✅ Allow Public Access to S3 Bucket
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.mybucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ✅ Set Bucket Ownership Controls
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.mybucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# ✅ Set Public Read ACL for Bucket
resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.mybucket.id
  acl    = "public-read"
}

# ✅ Public EC2 Instance
resource "aws_instance" "public" {
  ami                         = var.aws_instance_ami
  instance_type               = var.aws_instance_type
  subnet_id                   = aws_subnet.sub1.id
  vpc_security_group_ids      = [aws_security_group.mysg.id]
  key_name                    = "ptest"
  associate_public_ip_address = true
  user_data                   = base64encode(file("userdata.sh"))
  iam_instance_profile = aws_iam_instance_profile.s3_instance_profile.name

  tags = {
    Name = "public-instance"
  }
}

# ✅ Private EC2 Instance
resource "aws_instance" "private" {
  ami                    = var.aws_instance_ami
  instance_type          = var.aws_instance_type
  subnet_id              = aws_subnet.sub2.id
  vpc_security_group_ids = [aws_security_group.mysg.id]
  key_name               = "ptest"
  user_data              = base64encode(file("userdata1.sh"))
  iam_instance_profile = aws_iam_instance_profile.s3_instance_profile.name

  tags = {
    Name = "private-instance"
  }
}

# ✅ create application loadbalancer

resource "aws_lb" "mylb" {
  name               = "mylb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]

  enable_deletion_protection = false

  tags = {
    Name = "mylb"
  }
}

# ✅ create target group

resource "aws_lb_target_group" "mytg" {
  name     = "mytg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    
  }

  tags = {
    Name = "mytg"
  }
}

# target group attachment

resource "aws_lb_target_group_attachment" "mytg_attachment" {
  target_group_arn = aws_lb_target_group.mytg.arn
  target_id        = aws_instance.public.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "mytg_attachment1" {
  target_group_arn = aws_lb_target_group.mytg.arn
  target_id        = aws_instance.private.id
  port             = 80
}

# ✅ create listener

resource "aws_lb_listener" "mylistener" {
  load_balancer_arn = aws_lb.mylb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mytg.arn
  }
}

resource "aws_iam_role" "s3_role" {
  name = "EC2S3FullAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "EC2 S3 Full Access Role"
  }
}
resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_instance_profile" "s3_instance_profile" {
  name = "EC2S3FullAccessProfile"
  role = aws_iam_role.s3_role.name
}