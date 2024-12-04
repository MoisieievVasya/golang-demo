provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu_20_04" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_vpc" "golang_vpc" {
  cidr_block = "10.0.0.0/16"
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "demo_subnet" {
  count                  = 2
  cidr_block             = cidrsubnet(aws_vpc.golang_vpc.cidr_block, 8, count.index)
  vpc_id                 = aws_vpc.golang_vpc.id
  availability_zone      = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "golang_igw" {
  vpc_id = aws_vpc.golang_vpc.id    
}

resource "aws_route_table" "golang_route_table" {
  vpc_id = aws_vpc.golang_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.golang_igw.id
  }
}

resource "aws_route_table_association" "golang_route_assoc" {
  count          = length(aws_subnet.demo_subnet)
  subnet_id      = aws_subnet.demo_subnet[count.index].id
  route_table_id = aws_route_table.golang_route_table.id
}


resource "aws_security_group" "golang_sg" {
  vpc_id = aws_vpc.golang_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 22
      to_port     = 22
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

resource "aws_instance" "silly_demo" {
  count = 2

  ami           = data.aws_ami.ubuntu_20_04.id
  instance_type = "t2.micro"

  user_data = base64encode(templatefile("ec2-setup.sh", {
    db_endpoint = var.db_endpoint,
    db_user     = var.db_username,
    db_password = var.db_password
    db_name = var.db_name
  }))
}

resource "aws_lb" "golang_lb" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.golang_sg.id]
  subnets            = aws_subnet.demo_subnet[*].id
}

resource "aws_lb_target_group" "golang_tg" {
  name        = "demo-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.golang_vpc.id
  target_type = "instance"
}

resource "aws_lb_listener" "golang_listener" {
  load_balancer_arn = aws_lb.golang_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.golang_tg.arn
  }
}
