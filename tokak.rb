run 'touch tmp/.gitignore log/.gitignore vendor/.gitignore'
run 'rm public/index.html'

git :init
git :add => '.'
git :commit => '-am "Rails application generated"'

gem 'tokak_engine'
gem 'espresso'
gem 'sugar'
gem 'searchlogic'
gem 'inherited_resources'
gem 'formtastic'
gem 'will_paginate'
gem 'haml'
gem 'russian'

git :add => '.'
git :commit => '-am "Gem dependencies declared"'

file 'app/views/layouts/application.html.haml', <<-FILE
!!! HTML5
%html#nojs{html_attrs('ru-RU')}
  %head
    %meta(http-equiv="Content-type" content="text/html; charset=UTF-8")
    %title= [page_title, t('application.title')].compact * '. '
  %body
    %header.b_header
      %h1.b_logo= t('application.title')
    %nav.b_nav
      - #%ul= main_navigation
    %content.b_content
      = yield
    %footer.b_footer
      %p.b_copyrights= t('application.copyrights')
FILE
git :add => '.'
git :commit => '-am "HAML, SASS and Blueprint through Compass"'


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
git :commit => '-am "Plugins for deploying"'

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
