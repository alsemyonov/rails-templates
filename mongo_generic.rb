require '../templates/common.rb'

configure_git
generic_plugins(:active_record => false, :mongo_mapper => true)
