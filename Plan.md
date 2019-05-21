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

## 素材的修改
部分素材是无法删除的：
1. 材料，可以新增，无法删除，允许上传文件，但不允许删除文件；私有材料其他人不可见
2. 材料组合，可以新增、复制、删除和修改
3. 计算代码，可以新增和修改，无法删除，可以设置 enable 禁用，这样就无法被查找到
4. 任务树，可以新增、复制、删除和修改
5. 共享文件，可以新增、删除

这是因为**材料**和**计算代码**是保存在数据库里，不是很方便删除行？

## 计划任务
指定**材料集合**和**任务树**就可以创建计划任务，创建时必须要通过初步检测：
1. 初步检测是否所有的输入文件都预备了
2. 任务树由系统统一管理
3. 创建后，当前的材料集合和任务树会被保存下来，如果修改了任务树和材料集合，对当前的任务不会生效。
4. 允许删除材料，或者取消全部任务

数据库里的 calculation 表会统计全部的计算结果，并供查找
state：SLEEP/WAIT/RUN/ERROR/DONE/ABORT

SLEEP：本次计算已经就绪等待程序调度
WAIT：本次计算已经进入Qlist
CANCEL：本次计算被主动取消，只能在SLEEP和WAIT阶段转入CANCEL

RUN：本次计算正在运行

DONE：本次计算正常结束
ERROR：本次计算正常结束，但是报错了
ABORT：本次计算被意外中止，没有任何报错信息
