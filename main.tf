# configured aws provider with proper credentials
provider "aws" {
  region = "us-east-2"
}
# create default vpc if one does not exit
resource "aws_default_vpc" "default_vpc" {

  tags = {
    Name = "default vpc"
  }
}
# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}

# create default subnet if one does not exit
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags = {
    Name = "default subnet"
  }
}

# create security group for the ec2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 80 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2_instance_sg"
  }
}


# use data source to get a registered amazon linux 2 ami
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Create IAM role for EC2
resource "aws_iam_role" "weather_dashboard_role" {
  name = "weather_dashboard_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Create IAM policy for S3 access
resource "aws_iam_role_policy" "weather_dashboard_policy" {
  name = "weather_dashboard_policy"
  role = aws_iam_role.weather_dashboard_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "${aws_s3_bucket.weather_dashboard_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Create instance profile
resource "aws_iam_instance_profile" "weather_dashboard_profile" {
  name = "weather_dashboard_profile"
  role = aws_iam_role.weather_dashboard_role.name
}

#launch s3 Bucket
resource "aws_s3_bucket" "weather_dashboard_bucket" {
  bucket        = "weather-dashboard700"
  force_destroy = true
}

# launch the ec2 instance
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  iam_instance_profile   = aws_iam_instance_profile.weather_dashboard_profile.name
  key_name               = "mynewkeypair"

  tags = {
    Name = "EC2 server"
  }
}
# an empty resource block
resource "null_resource" "name" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/Downloads/mynewkeypair.pem")
    host        = aws_instance.ec2_instance.public_ip
  }

  # copy files from your computer to the ec2 instance
  provisioner "file" {
    source      = "weather_dashboard.py"
    destination = "/home/ec2-user/weather_dashboard.py"
  }
  provisioner "file" {
    source      = ".env"
    destination = "/home/ec2-user/.env"
  }

  provisioner "file" {
    source      = "requirements.txt"
    destination = "/home/ec2-user/requirements.txt"
  }

  # set permissions and run the python script
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y python3",
      "sudo yum install -y python3-pip",

      # Set up PATH to include local bin directory
      "echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc",
      "source ~/.bashrc",

      # Upgrade pip to latest version
      "python3 -m pip install --user --upgrade pip",

      # Install packages with upgraded pip
      "echo 'Installing Python packages...'",
      "python3 -m pip install --user -r ~/requirements.txt",

      # Run the Python script with the updated PATH
      "echo 'Running Python script...'",
      "export PATH=$PATH:$HOME/.local/bin",
      "python3 ~/weather_dashboard.py"
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.ec2_instance, aws_s3_bucket.weather_dashboard_bucket]
}

