require '../templates/common.rb'

configure_git
generic_plugins
deploy_on_atservers

load_template "http://github.com/rotuka/rails-templates/raw/master/authlogic.rb" if yes?("Add AuthLogic authentication? (y/n)")
