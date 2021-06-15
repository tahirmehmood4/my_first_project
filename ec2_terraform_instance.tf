# 1. create vpc
# 2. create internet gateway
# 3. create custom route table
# 4. create a subnet
# 5. associate subnet with route table
# 6. create security group to allow port 22,80,443
# 7. create network interface with an ip in the subnet that was created in step 4
# 8. assign an elastic ip to the network interface created in step 7
# 9. create ubuntu server and install/enable apache2
# IMP Link: https://serverfault.com/questions/716564/why-is-my-aws-instances-private-ip-outside-of-the-subnets-range
# IMP Link: https://www.bogotobogo.com/DevOps/Terraform/Terraform-VPC-Subnet-ELB-RouteTable-SecurityGroup-Apache-Server-1.php
# IMP Link: https://stackoverflow.com/questions/63441544/how-to-fix-no-default-vpc-for-this-user-status-code-400-in-terraform
# IMP Link: https://stackoverflow.com/questions/51496944/terraform-forces-new-resource-on-security-group

#ALB
# IMP Link: https://medium.com/cognitoiq/terraform-and-aws-application-load-balancers-62a6f8592bcf
# https://codeburst.io/provisioning-an-application-load-balancer-with-terraform-166ba6ccf2b8
# https://hiveit.co.uk/techshop/terraform-aws-vpc-example/04-create-the-application-load-balancer/
# https://learn.hashicorp.com/tutorials/terraform/blue-green-canary-tests-deployments?in=terraform/use-case
# https://www.bogotobogo.com/DevOps/Terraform/Terraform-Introduction-AWS-ASG-Modules.php

# https://registry.terraform.io/modules/terraform-aws-modules/autoscaling/aws/latest




#IMPPPPP
#https://medium.com/@ratulbasak93/aws-elb-and-autoscaling-using-terraform-9999e6266734

# terraform fmt //Format your configuration. Terraform will print out the names of the files it modified, if any. In this case, your configuration file was already formatted correctly, so Terraform won't return any file names.
# terraform validate //validate your configuration either it is syntactically correct
# terraform show // Inspect the current state
# terraform state list //Terraform has a built-in command called terraform state for advanced state management. Use the list subcommand to list of the resources in your project's state. 

resource "aws_vpc" "test_vpc" {
  cidr_block       = "${var.main_vpc_cidr}"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "testing"
  }
}

/*
 resource "aws_subnet" "subnet1" {
   vpc_id     = "${aws_vpc.main.id}"
   cidr_block = "10.0.1.0/24"
   availability_zone = "${var.availability_zone1}"


  tags  =  {
    Name = "app-subnet-1"
    }
 }
 resource "aws_subnet" "subnet2" {
   vpc_id     = "${aws_vpc.main.id}"
   cidr_block = "10.0.2.0/24"
   availability_zone = "${var.availability_zone2}"


     tags  =  {
      Name = "app-subnet-2"
     }
   }
  
*/

resource "aws_internet_gateway" "test_gw" {
  vpc_id = aws_vpc.test_vpc.id

 tags = {
    Name = "testing"
  }
}

resource "aws_route_table" "test_rt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_gw.id
  }

  tags = {
    Name = "testing"
  }
}

/*data "aws_availability_zones" "available" {}

resource "aws_subnet" "test_sn1" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "172.20.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "testing"
  }
}

resource "aws_subnet" "test_sn2" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = "172.20.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "testing"
  }
}
*/

resource "aws_subnet" "test_sn" {
  count = "${length(var.subnet_cidrs_public)}"

  vpc_id = "${aws_vpc.test_vpc.id}"
  cidr_block = "${var.subnet_cidrs_public[count.index]}"
  availability_zone = "${var.availability_zones[count.index]}"
  map_public_ip_on_launch = "true"

// The key differentiator between a private and public subnet is the map_public_ip_on_launch flag, 
// if this is True, instances launched in this subnet will have a public IP address and be accessible via the internet gateway.
}

/*
resource "aws_route_table_association" "private-assoc-1" {
  subnet_id      = "${aws_subnet.subnet1.id}"
  route_table_id = "${aws_route_table.main-private-rt.id}"
}
resource "aws_route_table_association" "private-assoc-2" {
  subnet_id      = "${aws_subnet.subnet2.id}"
  route_table_id = "${aws_route_table.main-private-rt.id}"
}
*/

resource "aws_route_table_association" "test_rta" {
  count = "${length(var.subnet_cidrs_public)}"

  subnet_id      = "${element(aws_subnet.test_sn.*.id, count.index)}"
  route_table_id = "${aws_route_table.test_rt.id}"
}

/*
resource "aws_security_group" "bastion-sg" {
  name   = "bastion-security-group"
##  vpc_id = "${aws_default_vpc.default.id}"
   vpc_id = "${aws_vpc.main.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0 
    to_port     = 0 
    cidr_blocks = ["0.0.0.0/0"]
  }
}
*/
resource "aws_security_group" "test_sg" {
  name        = "allow_ssh"
  description = "Allow SSH and HTTP inbound traffic"
  vpc_id      = aws_vpc.test_vpc.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    //cidr_blocks      = [aws_vpc.test_vpc.cidr_block]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    //cidr_blocks      = [aws_vpc.test_vpc.cidr_block]
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    //cidr_blocks      = [aws_vpc.test_vpc.cidr_block]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "testing"
  }
}

//resource "aws_eip" "test_eip" {
//  vpc      = true
//  network_interface = aws_network_interface.test_ni.id
//  associate_with_private_ip = "10.0.1.50"
//  depends_on = aws_internet_gateway.test_gw
//  instance = aws_instance.test_instance.id 
//}

data "aws_ami" "test_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
//  values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


/*

resource "aws_instance" "test_instance" {

  count = "${length(var.subnet_cidrs_public)}"
  subnet_id = "${element(aws_subnet.test_sn.*.id,count.index)}"
  //private_ip     = ["10.0.10.50", "10.0.20.50"]
  private_ip       = "${lookup(var.mgmt_jump_private_ips,count.index)}"
  //ami           = "${lookup(var.amis, var.region)}"  
  ami           = data.aws_ami.test_ami.id
  instance_type = "t2.micro"
  //availability_zone = "us-east-1a"
  key_name = "test-key"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.test_sg.id]
  user_data = <<-EOF
	      #!/bin/bash
        sudo yum update -y
        sudo yum -y install httpd
        sudo service httpd start
        sudo chkconfig httpd on
        sudo usermod -a -G apache ec2-user
        sudo chown -R ec2-user:apache /var/www
        sudo bash -c 'echo your very first project > /var/www/html/index.html'
        EOF

  tags = {
    Name = "Testing"
  }
}

*/


/*
output "ec2_public_ip" {
  value = "${aws_instance.test_instance.public_ip}"
}

resource "aws_eip" "nat" {
}

resource "aws_nat_gateway" "main-natgw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.subnet4.id}"

  tags = {
    Name = "main-nat"
  }
}
*/






resource "aws_alb" "alb" {
  name            = "terraform-example-alb"
  security_groups = [aws_security_group.test_sg.id]
  load_balancer_type = "application"
  subnets         = aws_subnet.test_sn.*.id
  enable_cross_zone_load_balancing = true

  //enable_deletion_protection = true
  
  }

resource "aws_alb_target_group" "test_targetgroup" {
  name     = "terraform-example-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.test_vpc.id
  load_balancing_algorithm_type = "least_outstanding_requests"
  stickiness {
    enabled = true
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page.
  health_check {
    
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }

  depends_on = [
    aws_alb.alb
  ]

  lifecycle {
    create_before_destroy = true
  }
  
} 

# create new application load balancer listeners. The first listener is configured to accept HTTP 
# client connections.

resource "aws_alb_listener" "listener_http" {

  count = "${length(var.subnet_cidrs_public)}"
  //load_balancer_arn = "${element(aws_alb.alb.*.arn,count.index)}"
  load_balancer_arn = "${aws_alb.alb.arn}"
  //load_balancer_arn = ["aws_alb.alb.*.arn"]
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.test_targetgroup.arn
  }
}

# Instance Attachement
/*
resource "aws_lb_target_group_attachment" "test_tga" {
  target_group_arn = aws_alb_target_group.test_targetgroup.arn
  
  count = "${length(var.subnet_cidrs_public)}"
  target_id = "${element(aws_instance.test_instance.*.id,count.index)}"

  //target_id        = aws_instance.test_instance.id
  port             = 80
}
*/

###Note: You must specify either launch_configuration, launch_template, or mixed_instances_policy

data "template_file" "test_tf" {
  template = <<-EOF
	      #!/bin/bash
        sudo yum update -y
        sudo yum -y install httpd
        sudo service httpd start
        sudo chkconfig httpd on
        sudo usermod -a -G apache ec2-user
        sudo chown -R ec2-user:apache /var/www
        sudo bash -c 'echo your very first project > /var/www/html/index.html'
        EOF
}


resource "aws_launch_configuration" "test_lc" {
  name          = "web_config"
  
  image_id      = data.aws_ami.test_ami.id
  instance_type = "t2.micro"
  user_data = "${base64encode(data.template_file.test_tf.rendered)}"
  key_name = "test-key"

  
  associate_public_ip_address = true
  
  security_groups = [aws_security_group.test_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

/*
resource "aws_launch_template" "test_lt" {

  # Launch template
  description            = "Launch template example"
  update_default_version = true
  
  //private_ip       = "${lookup(var.mgmt_jump_private_ips,count.index)}"

  //ebs_optimized     = true
  //enable_monitoring = true
  
  image_id      = data.aws_ami.test_ami.id
  instance_type = "t2.micro"

  #user_data = filebase64("${path.module}/example.sh")
  user_data = "${base64encode(data.template_file.test_tf.rendered)}"
  key_name = "test-key"
  
  //network_interfaces {
  //  associate_public_ip_address = true
  //}

  vpc_security_group_ids = [aws_security_group.test_sg.id]

lifecycle {
    create_before_destroy = true
  }
}

*/

resource "aws_autoscaling_group" "test_asg" {
  name                 = "terraform-asg-example"
  //launch_configuration = aws_launch_configuration.test_lc.id
  //count = "${length(var.subnet_cidrs_public)}"
  //subnet_id = "${element(aws_subnet.test_sn.*.id,count.index)}"
  availability_zones = ["us-east-1a", "us-east-1b"]
  min_size             = 2
  max_size             = 2
  desired_capacity     = 2
  wait_for_capacity_timeout = 0
  launch_configuration = aws_launch_configuration.test_lc.id
  lifecycle {
    create_before_destroy = true
    ignore_changes = [load_balancers, target_group_arns]
  }
  
  //vpc_zone_identifier       = ["subnet-1235678", "subnet-87654321"]
  
  //load_balancers = aws_alb.alb.id


  /*launch_template {
    id      = aws_launch_template.test_lt.id
    version = "$Latest"
  }*/

  tag {
    key                 = "Name"
    value               = "${var.aws_region}-asg"
    propagate_at_launch = true
  }
}

//$ aws ec2 describe-security-groups --region us-east-1 |grep webservers
//$ aws elb describe-load-balancers --region us-east-1 |grep webservers

# Autoscaling Attachement

resource "aws_autoscaling_attachment" "test_asa" {
  autoscaling_group_name = aws_autoscaling_group.test_asg.id
  alb_target_group_arn   = aws_alb_target_group.test_targetgroup.arn
}


/*

//Notes URL1: https://hiveit.co.uk/techshop/terraform-aws-vpc-example/04-create-the-application-load-balancer/
//Notes URL2: https://codeburst.io/provisioning-an-application-load-balancer-with-terraform-166ba6ccf2b8


// Classic Load Balancer Type

//resource "aws_elb" "prod_web" {
//  name = "prod-web"
//  instances = aws_instance.prod_web.*.id
//  subnets = [aws_subnet.test_sn1.id]
//  security_groups = [aws_security_group.test_sg.id]

//  listener {
//    instance_port = 80
//    instance_protocol = "http"
//    lb_port = "80"
//    lb_protocol = "http"
// }
//}

// launch template exmaple , for this to use you need to remove aws_instance, aws_eip_association 
// resource if present from your code 
//resource "aws_launch_template" "foobar" {
//  name_prefix   = "foobar"
//  image_id      = "ami-1a2b3c"
//  instance_type = "t2.micro"
//}

//resource "aws_autoscaling_group" "bar" {
//  availability_zones = ["us-east-1a"]
//  vpc_zone_identifier = [aws_subnet.test_sn1.id]
//  desired_capacity   = 1
//  max_size           = 1
//  min_size           = 1

//  launch_template {
//    id      = aws_launch_template.foobar.id
//    version = "$Latest"
//  }
//}


//This example creates an encrypted image from the latest ubuntu 16.04 base image.

//resource "aws_ami_copy" "ubuntu-xenial-encrypted-ami" {
//  name              = "ubuntu-xenial-encrypted-ami"
 // description       = "An encrypted root ami based off ${data.aws_ami.ubuntu-xenial.id}"
 // source_ami_id     = "${data.aws_ami.ubuntu-xenial.id}"
 // source_ami_region = "eu-west-2"
 // encrypted         = "true"

//  tags {
//    Name = "ubuntu-xenial-encrypted-ami"
//  }
//}

//data "aws_ami" "encrypted-ami" {
//  most_recent = true

//  filter {
//    name   = "name"
//    values = ["ubuntu-xenial-encrypted"]
//  }

//  owners = ["self"]
//}

//data "aws_ami" "ubuntu-xenial" {
//  most_recent = true

//  filter {
//    name   = "name"
//    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
//  }

//  owners      = ["099720109477"]
//}
*/
