#!/bin/bash
yum update -y
yum install -y nginx

systemctl enable nginx
systemctl start nginx

mkdir -p /usr/share/nginx/html

cp /home/ec2-user/divyansh_saxena_resume.pdf /usr/share/nginx/html/divyansh_saxena_resume.pdf

cat <<EOF > /usr/share/nginx/html/index.html
<html>
<head>
  <meta http-equiv="refresh" content="0; url=divyansh_saxena_resume.pdf" />
</head>
<body>
  <p>If you're not redirected automatically, <a href="divyansh_saxena_resume.pdf">click here</a>.</p>
</body>
</html>
EOF

systemctl restart nginx