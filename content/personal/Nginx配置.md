
2024-08-30 15:55

Status:

Tags:

# Nginx配置
1. 配置nginx 通过ip+端口访问zsax.zxiaowei.com
```nginx
server {
    listen 8080;
    listen 1.92.78.113:8080;

    location / {
        proxy_pass https://zsax.zxiaowei.com;

        proxy_set_header Host zsax.zxiaowei.com;  # Set the Host header to the proxied server
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;  # Corrected to match the scheme of the proxied server
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_http_version 1.1;

        # Add additional headers if necessary
        proxy_set_header Referer "https://zsax.zxiaowei.com";
        proxy_set_header Accept-Encoding "";
   }                                                                                                                                                                               
}            
```





# References