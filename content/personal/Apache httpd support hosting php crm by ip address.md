
2024-07-19 17:57

Status:

Tags: [[httpd]] [[php]]

# Apache httpd support hosting php crm by ip address


## background

I am required to make zibo crm2 website accessed by ip only, previouly it is accessed via zscrm.yunqishuke.com.

It took me over 3 hours to finish it. 

The solution is simple. Because I don't know that apache httpd supports to listen on multiple ports, I tried 
```mermaid
flowchart LR
request --> nginx
nginx --> httpd
```
```mermaid
flowchart LR
request --> nginx
```

Both solution failed. I think it is doable to host php website using nginx, but I am not quite familiare with nginx, and I don't want to make things complicated. Every service/webiste is hosed by apache httpd and its configuration is simple and I already hosted php crm in it.

The httpd listens 80, as we need to use IP address to access our website, we need to make apache httpd listens on a different port, e.g. 8088.

So I added `listen 8088` under `listen 80` in `/etc/httpd/conf/http.conf`.
And add below to `/etc/httpd/conf.d/vhosts.conf`
```
   <VirtualHost *:8088>
    DocumentRoot "/var/www/html/zs_crm"
    ServerName 112.92.78.113

    ErrorLog "logs/zhibo2-crm.com-error_log"
    CustomLog "logs/zhibo2-crm.com-access_log" common

   <Directory "/var/www/html/zs_crm">
      Options Indexes FollowSymLinks
      AllowOverride All
      Require all granted
   </Directory>
   </VirtualHost>

```

**Last but not the least, enable 8088 to be accessed by 0.0.0.0/0 on huawei cloud.**

# References