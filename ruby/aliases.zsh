alias r='rvm use 1.8.7'

alias sc='script/console'
alias ss='script/server -p `available_rails_port`'
alias sg='script/generate'
alias sd='script/destroy'
alias st='script/test_server'
alias str='script/test_runner'

alias migrate='rake db:migrate db:test:clone'

alias s="ps aux | grep \"[r]uby\" | grep script/server || echo \"You're not running any, dawg.\""

alias killnginx="ps aux | grep nginx | awk '{print $2}' | xargs sudo kill -9"

