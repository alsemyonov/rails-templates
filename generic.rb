run "echo TODO > README"

file '.gitignore', %q{
.DS_store
*.sqlite3
log/*.log
tmp/**/*
public/cache/**/*
doc/api
doc/app
doc/plugins
}

run 'touch tmp/.gitignore log/.gitignore vendor/.gitignore'
run "cp config/database.yml config/example_database.yml"

git :init
git :add => '.'
git :commit => '-am "Generic rails application"'

gem 'RedCloth', 
    :lib => 'redcloth'
gem 'mislav-will_paginate', 
    :lib => 'will_paginate', 
    :source => 'http://gems.github.com'
git :add => '.'
git :commit => '-am "RedCloth and WillPaginate support built in"'

gem 'haml'
gem 'chriseppstein-compass',
    :lib => 'compass'
run 'haml --rails .'
run 'compass --rails -f blueprint'
git :add => '.'
git :commit => '-am "HAML, SASS and Blueprint through Compass"'
