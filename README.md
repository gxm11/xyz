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

## table - user

| id | name | passwd | level |
|:-:|:----:|:------:|:----:|
| 0 | admin | admin | 10 |

- login
- start tasks
- create / edit task code

## table - code

|id | name | kind | author | version | input | output | entrance | state |
|:-:|:----:|:----:|:------:|:-------:|:-----:|:------:|:--------:|:-----:|
| 0 | initialize | process | admin | 0.1 | [] | [] | initiailze | enable |

- input / output: json array
- entrance is the file path of ENTRANCE, /home/xyz/{author}/{entrance}
- kind: calculation / process
- state: enable / disable, disable code will be ignored in auto searching

## table - calculation

id | state | job_id | start_time | finish_time
:-:|:-----:|:--------:|:----------:|:-----------:
0  | finish | 0 | 1970-1-1 00:00 | 1970-1-1 00:00

- state: waiting / running / finish / abort
- job_id is PBS job id, set to 0 if not controled by PBS

## table - material

id | name | state | property-1 | property-2 
:-:|:----:|:-----:|:----------:|:----------:
0 | null | freeze | 0 | 0

- task-1 may be spg / refine_cell / band / openmx_dat ...
- the value of task-1 is the task id for the property

# webpage