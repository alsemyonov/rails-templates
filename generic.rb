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
run 'rm public/index.html'

git :init
git :add => '.'
git :commit => '-am "Generic rails application"'

gem 'RedCloth', :lib => 'redcloth'
gem 'searchlogic'
gem 'mislav-will_paginate', :lib => 'will_paginate', :source => 'http://gems.github.com/'
git :add => '.'
git :commit => '-am "RedCloth and Searchlogic support built in"'

gem 'haml'
gem 'chriseppstein-compass',
    :lib => 'compass'
run 'haml --rails .'
run 'compass --rails -f blueprint . --sass-dir=app/stylesheets --css-dir=public/stylesheets/compiled'
git :add => '.'
git :commit => '-am "HAML, SASS and Blueprint through Compass"'

plugin 'annotate_models', :git => 'git://github.com/rotuka/annotate_models.git'
plugin 'irs_process_scripts', :git => 'git://github.com/rails/irs_process_scripts.git'
run 'capify .'
file 'config/deploy.rb', %q(
set :application, 'application_name_here'
set :user, 'desmix'
set :domain, 'eu107.activeby.net'

set :scm, :git
set :repository,  "#{user}@#{domain}:repos/#{application}.git"
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false
set :checkout, 'export'

server domain, :app, :web, :db, :primary => true
)

git :add => '.'
git :commit => '-am "Plugins for db and deploying"'

# FastCGI Dispatchers and Apache Magic
run 'rake rails:update:generate_dispatchers'
file 'public/.htaccess', %q{
AddHandler fastcgi-script .fcgi
AddHandler cgi-script .cgi
Options +FollowSymLinks +ExecCGI

RewriteEngine On

RewriteRule ^$ index.html [QSA]
RewriteRule ^([^.]+)$ $1.html [QSA]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^(.*)$ dispatch.fcgi [QSA,L]

ErrorDocument 500 "<h2>Application error</h2>Rails application failed to start properly"
}

git :add => '.'
git :commit => '-am "FastCGI Dispatchers and Apache Magic"'
