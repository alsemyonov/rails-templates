GIT_KEEP = '{lib/tasks,log,vendor/plugins}/.gitkeep tmp/{cache,pids,sessions,sockets}/.gitkeep'

module Rails
  class TemplateRunner
    def app_name
      @app_name ||= Pathname.new(root).basename.to_s
    end

    def human_app_name
      @human_app_name ||= app_name.humanize
    end

    def configure_git
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

      run "touch #{GIT_KEEP}"

      git :init
      git :add => GIT_KEEP
      git :add => '.'

      git :commit => '-am "Generic rails application"'
    end

    def generic_plugins(options = {})
      options.reverse_merge!(
        :i18n => true,
        :active_record => true,
        :action_controller => true,
        :action_view => true,
        :haml => true,
        :mongo_mapper => false
      )
      gems = []

      if options[:i18n]
        gems << 'russian'
      end

      if options[:active_record]
        gems << 'will_paginate'
        gems << 'searchlogic'
      end

      if options[:mongo_mapper]
        gems << 'mongo_mapper'
        initializer 'mongo_mapper.rb', <<-FILE
MongoMapper.database = "#{app_name}-\#{Rails.env}"
FILE
      end

      if options[:action_controller]
        gems << 'inherited_resources'
      end

      if options[:action_view]
        gems << 'formtastic'
        gems << 'sugar'
      end

      if options[:haml]
        gems << 'haml'
        gems << 'compass'

        run 'compass --rails . --sass-dir=app/stylesheets --css-dir=public/stylesheets'
        file 'app/views/layouts/application.html.haml', <<-FILE
<!DOCTYPE html>
%html#nojs{html_attrs('ru-RU')}
  %head
    %meta(http-equiv="Content-type" content="text/html; charset=UTF-8")
    %title= [page_title, t('application.meta.title', :default => '#{human_app_name}')].compact * '. '
  %body
    %header.b_header
      %h1.b_logo= t('application.meta.title', :default => '#{human_app_name}')
    %nav.b_nav
      %ul
        %li= link_to('Home', '/')
    %section.b_content
      = yield
    %footer.b_footer
      %p.b_copyrights &copy;&nbsp;\#{t('application.meta.copyrights', :default => 'Alexander Semyonov')}, 2010
FILE
      end

      if gems.any?
        gems.each do |gem_name|
          gem(gem_name)
        end

        git :commit => %(-am "#{gems.to_sentence} support added")
      end
    end

    def deploy_on_atservers
      capify!
      file 'config/deploy.rb', <<-FILE
set :application, '#{app_name}'
set :user, 'rotuka'
set :domain, 'eu107.activeby.net'

set :scm, :git
set :repository,  "\#{user}@\#{domain}:repos/\#{application}.git"
set :deploy_to, "/home/\#{user}/apps/\#{application}"
set :deploy_via, :remote_cache
set :use_sudo, false
set :checkout, 'export'

server domain, :app, :web, :db, :primary => true
FILE

      git :add => '.'
      git :commit => '-am "Plugins for db and deploying"'

      # FastCGI Dispatchers and Apache Magic
      run 'rake rails:update:generate_dispatchers'
      file 'public/.htaccess', <<-FILE
AddHandler fcgid-script .fcgi
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
      git :commit => '-am "FastCGI Dispatchers and Apache Magic for Atservers.com hosting"'
    end
  end
end
