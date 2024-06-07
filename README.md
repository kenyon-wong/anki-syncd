# README

用自编译 Rust 二进制可执行程序作为服务组件来封装的Anki 自托管同步服务器项目

## 编译镜像

修改配置文件中的版本号之后，执行编译

```bash
docker build -t anki/syncd:v24.06.2 .
```



## 参考资料

- [3 分钟为英语学习神器 Anki 部署一个专属同步服务器](https://www.cnblogs.com/ryanyangcs/p/17508044.html)
- [搭建 Anki 自托管同步服务器](https://blog.gazer.win/essay/build-anki-self-hosted-sync-server.html)
