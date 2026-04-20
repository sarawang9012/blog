
2024-07-22 14:50

Status:

Tags: [[linux]]

# Linux command

## change server hostname permanently
1. update the hostname using hostnamectl
```
hostnamectl status
sudo hostnamectl set-hostname newhostname
```
2. edit `/etc/hosts` and mapping `127.0.0.1` to  new hostname
3. reboot system: 
```
sudo reboot
```



# References