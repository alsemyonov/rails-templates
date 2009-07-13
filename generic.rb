run "echo TODO > README"

file '.gitignore', <<-FILE
*.sqlite3
.DS_store
doc/api
doc/app
doc/plugins
log/*.log
public/cache/**/*
tmp/**/*
vendor/gems
FILE

run 'touch tmp/.gitignore log/.gitignore vendor/.gitignore'
run "cp config/database.yml config/example_database.yml"
run 'rm public/index.html'

git :init
git :add => '.'
git :commit => '-am "Generic rails application"'

# Adding items searching and pagination
gem 'searchlogic'
gem 'mislav-will_paginate', :lib => 'will_paginate', :source => 'http://gems.github.com/'
git :add => '.'
git :commit => '-am "WillPaginate and Searchlogic support built in"'

# Adding HAML and SASS
gem 'haml'
file 'vendor/plugins/haml/init.rb', <<-FILE
begin
  require File.join(File.dirname(__FILE__), 'lib', 'haml') # From here
rescue LoadError
  require 'haml' # From gem
end

# Load Haml and Sass
Haml.init_rails(binding)
FILE

# Adding Compass
gem 'chriseppstein-compass', :lib => 'compass', :source => 'http://gems.github.com/'
run 'compass --rails -f blueprint . --sass-dir=app/stylesheets --css-dir=public/stylesheets/compiled'

file 'app/views/layouts/application.html.haml', <<-FILE
!!! HTML5
%html#nojs{html_attrs('ru-RU')}
  %head
    %meta(http-equiv="Content-type" content="text/html; charset=UTF-8")
    %title= [page_title, t('title')].compact * '. '
  %body
    %header.b_header
      %h1.b_logo= t('logo')
    %nav.b_nav
      %ul= main_navigation
    %content.b_content
      = yield
    %footer.b_footer
      %p.b_copyrights= t('copyrights')
FILE
git :add => '.'
git :commit => '-am "HAML, SASS and Blueprint through Compass"'

plugin 'annotate_models', :git => 'git://github.com/rotuka/annotate_models.git'
plugin 'irs_process_scripts', :git => 'git://github.com/rails/irs_process_scripts.git'
run 'capify .'
file 'config/deploy.rb', %q{
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
}

git :add => '.'
git :commit => '-am "Plugins for db and deploying"'

# FastCGI Dispatchers and Apache Magic
run 'rake rails:update:generate_dispatchers'
file 'public/.htaccess', <<-FILE
AddHandler fastcgi-script .fcgi
AddHandler cgi-script .cgi
Options +FollowSymLinks +ExecCGI

RewriteEngine On

RewriteRule ^$ index.html [QSA]
RewriteRule ^([^.]+)$ $1.html [QSA]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^(.*)$ dispatch.fcgi [QSA,L]

ErrorDocument 500 "<h2>Application error</h2>Rails application failed to start properly"
FILE

git :add => '.'
git :commit => '-am "FastCGI Dispatchers and Apache Magic"'

load_template "http://github.com/rotuka/rails-templates/raw/master/authlogic.rb" if yes?("Add AuthLogic authentication?")

# Installing gems
rake 'gems:install', :sudo => true
