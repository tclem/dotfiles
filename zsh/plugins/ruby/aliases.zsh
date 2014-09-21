alias sc='script/console'
alias ss='script/server'
alias st='script/test'
alias t='bin/testrb'

alias migrate='rake db:migrate db:test:clone'

alias s="ps aux | grep \"[r]uby\" | grep script/server || echo \"You're not running any, dawg.\""

alias killnginx="ps aux | grep nginx | awk '{print $2}' | xargs sudo kill -9"

