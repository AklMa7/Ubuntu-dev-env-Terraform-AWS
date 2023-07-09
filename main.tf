#aws_vpc 


resource "aws_vpc" "akl_vpc" {
    cidr_block           = "10.123.0.0/16"
    enable_dns_hostnames = true 
    enable_dns_support   = true

    tags = {
        Name = "dev"
    }
}   

#aws_subnet -> Deploy a subnet to which we can deploy  our future EC2 instance .

resource "aws_subnet" "akl_public_subnet" {
    vpc_id                  = aws_vpc.akl_vpc.id #Name of the service shows by -> terraform state show + .id (it's id shown by -> terraform state show <name of service>)
    cidr_block              = "10.123.1.0/24"    #subnet of VPC's CIDR block
    map_public_ip_on_launch = true 
    availability_zone       = "us-east-1a"
    
    tags = {
        Name = "dev-public" #names public bcs its a public subnet so i don't put sensitive info here 
    }
}

# Gateway : Give our resources a way to the internet by creatin an internet gateway 

resource "aws_internet_gateway" "akl_internet_gateway" {
    vpc_id = aws_vpc.akl_vpc.id

    tags = {
        Name = "dev-igw"
    }
}

# Route table to route traffic from our subnet to our internet gateway

resource "aws_route_table" "akl_public_rt"{
    vpc_id   = aws_vpc.akl_vpc.id

    tags = {
        Name = "dev-public-rt"
    }
}

resource "aws_route" "default_route"{
    route_table_id          = aws_route_table.akl_public_rt.id
    destination_cidr_block  = "0.0.0.0/0"  #All ip adresses will head to our internet gateway
    gateway_id              = aws_internet_gateway.akl_internet_gateway.id #Links route table to internet gateway 


}

# Now we need to bridge the gap between out route table and our subnet 

resource "aws_route_table_association" "akl_public_assoc" {
    subnet_id        = aws_subnet.akl_public_subnet.id
    route_table_id   = aws_route_table.akl_public_rt.id

}


#security groups   TLS=Transport Layer Security.
    # TCP port 443 is usualy associated with TLS


resource "aws_security_group" "akl_sg" {
  name        = "dev-sg"
  description = "dev security group"
  vpc_id      = aws_vpc.akl_vpc.id

  ingress {     #From Subnet to me ( or outside )
    description      = ""
    from_port        = 0  #Any port needed 
    to_port          = 0
    protocol         = "-1" # Any protocol needed
    cidr_blocks      = ["0.0.0.0/0"] #  Brackets allow a list to be input / Needs to be changed to your own ip !!!!!  
    
  }

  egress {  # me to subnet 
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"] #Whatever can go into subnet can access anythin ( any IP has access to subnet)
    ipv6_cidr_blocks = ["::/0"]
  }

}


#Key pair : Key pairs are used in SSH protocol for secure remote login and file transfer.
# We will create a key pair then an AWS resource that utilizes this key pair. This will be used by the EC2 instance resource we create 
# so we can SSH into it later 

# Keys are generated using the command " ssh-keygen -t ed25519 "

# After we do ... the keys are in the directory  " ~/.ssh " / name the directory when creatin the key pair : aklkey 


resource "aws_key_pair" "akl_auth" {
    key_name   = "aklkey"
    public_key = file ("~/.ssh/aklkey.pub") # instead of whole key as in input we use "file" function .. look up on the terraform doc.

}


# Now we launch the EC2 instance.

resource "aws_instance" "dev_node" {
    instance_type          = "t2.micro"
    ami                    = data.aws_ami.server_ami.id

    key_name               = aws_key_pair.akl_auth.id
    #key_name is present in the "aws_key_pair" resource state ... but id will work too .
    # terraform state show aws_key_pair.akl_auth 
    
    vpc_security_group_ids = [aws_security_group.akl_sg.id] # if instance is created in VPC ( our case ) if not : security_groups
    subnet_id              = aws_subnet.akl_public_subnet.id
    
    user_data              = file("userdata.tpl")
    #update apt / install it / install some dependencies / download docker gpg key / Add docker repo / update it / 
    # install docker / adds ubuntu to docker group ( allowin to run docker commands as ubuntu user) 

    root_block_device {    #size for the root block device ( in GB ).
        volume_size        = 10
    }


    tags ={
        Name               = "dev-node"
        
    }

}

#Connecting to  the instance via SSH. Requires public IP of the instance.
#ssh -i ~/.ssh/aklkey ubuntu@18.206.223.29 ( Instance's public ip adress )














