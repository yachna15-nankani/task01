provider "aws" {
 region = "ap-south-1"
 profile = "nankani"
}
resource "aws_security_group" "my_security13" {
 name = "my_security13"
 
 ingress {
  description = "SSH"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }
  ingress {
  description = "HTTP"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }
  egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }
 tags = {
  Name = "my_security13"
 }
}
resource "aws_instance" "firstos13" {
 ami = "ami-005956c5f0f757d37"
 instance_type = "t2.micro"
 key_name = "my1key"
 security_groups = ["my_security13"] 
 connection {
  type = "ssh"
  user = "ec2-user"
  private_key = file("C:/Users/hp/Downloads/my1key.pem")
  host = aws_instance.firstos13.public_ip
 }
  provisioner "remote-exec" {
  inline = [
    "sudo yum install httpd git -y",
    "sudo systemctl restart httpd",
    "sudo systemctl enable httpd",
           ]
 }
 tags = {
  Name = "lwos13"
 }
 depends_on = [
  aws_security_group.my_security13,
 ]
}
resource "null_resource" "mynull" {
  depends_on = [
   aws_volume_attachment.muhdattach,
  ]
}
resource "aws_ebs_volume" "myhd13" {
 availability_zone = aws_instance.firstos13.availability_zone
 size = 1
 tags = {
  Name = "myhd13"
 }
}
resource "aws_volume_attachment" "muhdattach" {
 device_name = "/dev/sdm"
 volume_id = aws_ebs_volume.myhd13.id
 instance_id = aws_instance.firstos13.id
 force_detach = true
 
 depends_on = [
  aws_ebs_volume.myhd13,
 ]
 provisioner "remote-exec" {
  inline = [
   "sudo mkfs.ext4 /dev/xvdm",
   "sudo mount /dev/xvdm /var/www/html/*",
   "sudo rm -rf /var/www/html/*",
   "sudo git clone https://github.com/yachna15-nankani/task01.git /var/www/html/"
  ]
 }
 connection {
  type = "ssh"
  user = "ec2-user"
  private_key = file("C:/Users/hp/Downloads/my1key.pem")
  host = aws_instance.firstos13.public_ip
 }
}
resource "aws_s3_bucket" "mybuckt13" {
 bucket = "mybucketmadebypooja212"
 force_destroy = true
 acl = "public-read"
 provisioner "local-exec" {
  command = "https://github.com/yachna15-nankani/task01.git C:/Users/hp/Downloads/yachna/nankani/images"
 }
 provisioner "local-exec" {
  when = destroy
  command = "echo Y | rmdir /S images"
 }
}
output "buck1" {
 value=aws_s3_bucket.mybuckt13
}
resource "aws_s3_bucket_object" "mybucobj13" {
 depends_on = [
  aws_s3_bucket.mybuckt13,
 ]
 bucket = aws_s3_bucket.mybuckt13.bucket
 key = "images.png"
 source = "C:/Users/hp/Downloads/yachna/nankani/images/images.png"
 acl = "public-read"
 content_type = "image/png"
}
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
 comment = "Some comment"
}
resource "aws_cloudfront_distribution" "s3_distribution" {
 origin {
    domain_name = aws_s3_bucket.mybuckt13.bucket_domain_name
    origin_id   = "mybucobj13"
    s3_origin_config {
     origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
          }
       }
 enabled = true
 is_ipv6_enabled = true
 default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "mybucobj13"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
   viewer_protocol_policy = "allow-all"
     min_ttl = 0
     default_ttl = 3600
     max_ttl = 86400
  }
   restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

}