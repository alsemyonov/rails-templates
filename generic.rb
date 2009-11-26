run 'echo TODO > README'

# Configuring git
file '.gitignore', <<-FILE
*.log
*.sqlite3
*.sw[opn]
.DS_store
coverage
doc/api
doc/app
doc/plugins
public/cache/**/*
public/uploads
tmp/**/*
tmp/test
vendor/gems
FILE

run 'touch {tmp,log,vendor}/.gitignore tmp/{cache,pids,sessions,sockets}/.gitignore'
run 'rm public/index.html'

git :init
git :add => '.'
git :commit => '-am "Generic rails application"'

# Adding some basic functionality
gem 'formtastic'
gem 'inherited_resources'
gem 'searchlogic'
gem 'will_paginate'
gem 'russian'
git :add => '.'
git :commit => '-am "WillPaginate, Searchlogic, InheritedResources and Russian support built in"'

# Adding Compass
gem 'compass'
gem 'haml'
run 'compass --rails . --sass-dir=app/stylesheets --css-dir=public/stylesheets'
file 'app/views/layouts/application.html.haml', <<-FILE
!!! HTML5
%html#nojs{html_attrs('ru-RU')}
  %head
    %meta(http-equiv="Content-type" content="text/html; charset=UTF-8")
    %title= [page_title, t('application.meta.title')].compact * '. '
  %body
    %header.b_header
      %h1.b_logo= t('application.meta.title')
    %nav.b_nav
      %ul
        %li= link_to('Home', '/')
    %section.b_content
      = yield
    %footer.b_footer
      %p.b_copyrights= t('application.meta.copyrights')
FILE
git :add => '.'
git :commit => '-am "HAML, SASS and Blueprint through Compass"'

run 'capify .'
file 'config/deploy.rb', %q{
set :application, 'application_name_here'
set :user, 'rotuka'
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
plugin 'irs_process_scripts', :git => 'git://github.com/rails/irs_process_scripts.git'

git :add => '.'
git :commit => '-am "FastCGI Dispatchers and Apache Magic"'

load_template "http://github.com/rotuka/rails-templates/raw/master/authlogic.rb" if yes?("Add AuthLogic authentication? (y/n)")
