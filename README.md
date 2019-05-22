# xyz-repl
The xyz-project running on repl.it, framework is sinatra.

# workflow
Everything runing is a task.

Start tasks in web server, results show in web page.

Process is managed by ruby process; Calculation is managed by PBS + database

# database
Use Sqlite3, table:
 - user
 - code
 - process
 - calculation
 - material

# deploy
1. Clone project `git clone https://github.com/gxm11/xyz.git`
2. Change Sinatra_Port in `./model/xyz.rb`
3. Init test database: `/home/guoxm/local/bin/ruby2.6.3/bin/ruby reset.rb --reset --test`
4. Run `/home/guoxm/local/ruby2.6.3/bin/ruby main.rb`
