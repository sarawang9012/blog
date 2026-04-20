1. 源ecs和目标ecs所在地域必须一致
2. 源ecs生成镜像，并且分享给目标ecs的账户id，注意，源ecs必须设置 支持NVMe驱动，否则再目标ecs更换操作系统时会选不到
3. 目标ecs 停止示例，点击操作的更换操作系统。选择共享镜像，进行更换。
4. 参考文档：
5. https://help.aliyun.com/zh/ecs/user-guide/create-a-custom-image-from-a-snapshot-1?spm=a2c4g.11186623.0.i2