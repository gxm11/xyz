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
