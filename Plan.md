# Plan
- [x] write login system
- [x] write first process task: top
- [x] write task: initialize
- [x] write insert material task
- [ ] write material collection / material list / material page

## Login System
登录界面有3个选项需要填写：
1. username, 用户名
2. password, 密码
3. activation key, 激活码

如果激活码是可用的，用户名不在数据库里，则创建新用户
如果激活码是不可用的
 - 用户名、密码正确，成功登录，记录用户名、密码、IP 到 cookie 里。
 - 否则需要重新登录

## Material System
材料界面，包括：
1. 全体材料列表
2. 单个材料数据展示
3. 筛选材料创建材料集合

## Code System
计算用的程序管理，包括：
1. 提交程序代码
2. 创建任务
3. 查看任务完成情况

在完成第 2 步的时候，还需要完成以下几个子任务：
1. 尝试联合qsub执行单次任务：创建文件夹，cd && qsub
2. 根据最终目标筛选合适的任务

在完成第 3 步的时候，还需要完成：
1. 监控任务完成情况
2. 及时启动更多的任务

## Code-Input
目前的做法是 code 的 input 的每一行以字符串的形式传入，而不是之前设想的数组：
```ruby
input = ["OUTCAR;openmx.scf;BANDDAT1"]
```