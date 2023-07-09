# AMI = Pre-configured template that contains the necessary operating system, 
#software, and configurations required to launch an instance (virtual server) in AWS.
# The AMI datasource in Terraform allows you to query the AWS account to get information
# about available AMIs based on specific criteria. ( latest version etc ....)
# found in EC2 documentation


# We need to provide an AMI from which we will deploy our EC2 instance.
# We need an AMI ID based on some filters we will provide.

data "aws_ami" "server_ami" {
    most_recent = true
    owners = ["099720109477"]
 

    filter {
        name = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"] # Do not leave a space at the beg or end of string 

    }
}







