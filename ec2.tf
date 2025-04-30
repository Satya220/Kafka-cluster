resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Kafka-1"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "Kafka-2"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "eu-west-1c"

  tags = {
    Name = "Kafka-3"
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  tags = {
    Name = "Kafka_testing"
  }
}

resource "aws_nat_gateway" "NAT-1" {
  allocation_id = aws_eip.lb.id
  subnet_id  = aws_subnet.private.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_eip" "lb" {
  domain   = "vpc"
}

resource "aws_route_table" "igw_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Route_table"
  }
}

resource "aws_route_table" "nat_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0"
    gateway_id = aws_nat_gateway.NAT-1.id
  }

  tags = {
    Name = "Route_table"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "IGW_VPC"
  }
}

resource "aws_iam_role" "test_role" {
  name = "test_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.test_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.nat_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.nat_rt.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.nat_rt.id
}