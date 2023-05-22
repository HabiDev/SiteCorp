# Load environment variables to correctly set RAILS_ENV
# and fetch deploy settings
require 'dotenv'
env_name = ".deploy.#{fetch(:stage)}.env"
Dotenv.load(env_name)

# config valid for current version and patch releases of Capistrano
lock "~> 3.17.1"

set :rvm_type, :user
set :rvm_ruby_version, '3.1.1'
set :rvm_ruby_string, fetch(:rvm_ruby_version)

set :application, "MakeRetailService"
set :repo_url, "https://github.com/HabiDev/SiteCorp.git"
set :deploy_to, "/var/www/apps/#{fetch(:application)}"

# Tell to Capistrano about a 'foreman' gem.
# The 'foreman' command will be executed with a 'bundle exec' prefix.
ruby_version_manager = :rvm
map_bins_key = "#{ruby_version_manager}_map_bins".to_sym
unless fetch(map_bins_key).nil?
  set map_bins_key, fetch(map_bins_key) + ['foreman']
end

# Tell to Capistrano to create symlinks to this files.
# They are ignored by git and must be uploaded to the remote server separately
# to the 'deploy_to + shared_dir' directory.
# For example: /var/www/apps/Application/shared/.
append :linked_files,
       'config/database.yml',
       'Procfile.dev',
       '.env',
       'config/master.key'

# Tell to Capistrano to create symlinks to this directories.
# They must be created on the remote server separately
# in the 'deploy_to + shared_dir' directory
# For example: /var/www/apps/Application/shared/.
append :linked_dirs,
       'tmp/pids',
       'tmp/cache',
       'tmp/sockets'

# Files with permission to deny access to other users
set :protected_linked_files, [
  '.env',
  'config/master.key'
]

# Tasks inside this namespace can be executed by command:
# 'cap stage deploy:task'
# where 'stage' is a name of the deploying environment and
# 'task' is a name of the task to execute.
namespace :deploy do
  desc 'Create service directories required for the application to work'
  task :prepare_service_dirs do
    on roles(:all) do
      [
        '/var/www/log',
        fetch(:deploy_to),
        "#{fetch(:deploy_to)}/run",
        "#{fetch(:deploy_to)}/log",
        "#{fetch(:deploy_to)}/sockets",
        shared_path,
        *shared_dirs.map { |dirname| "#{shared_path}/#{dirname}" }
      ].each { |dir| execute "mkdir -p #{dir}" }
    end
  end

  desc 'Upload linked files'
  task :upload_linked_files do
    on roles(:all) do |_host|
      shared_linked_files.each do |file|
        # Shared linked files are stored in the local 'shared' directory
        # and must be uploaded to the remote 'shared' directory
        upload!("shared/#{fetch(:branch)}/#{file}", "#{shared_path}/#{file}")
      end

      project_linked_files.each do |file|
        remote_file = "#{shared_path}/#{file}"

        # Credentials keys must be uploaded once
        next if credentials_key?(file) && test("[ -f #{remote_file} ]")

        # Shared project files are stored in the project structure
        # and must be uploaded to the remote 'shared' directory
        upload!(file, remote_file)
      end
    end
  end

  desc 'Set permission to linked files'
  task :set_linked_files_permissions do
    on roles(:all) do |_host|
      # Set -rw-r----- in order to deny any access to other users
      fetch(:protected_linked_files).each do |file|
        execute "chmod 640 #{shared_path}/#{file}"
      end
    end
  end

  desc 'Setup'
  task :setup do
    on roles(:all) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'db:create:all'
        end
      end
    end
  end

  desc "reload the database with seed data"
  task :seed do
    on roles(:all) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'db:seed'
        end
      end
    end
  end


  desc 'Foreman init'
  task :foreman_init do
    on roles(:all) do
      foreman_temp = '/var/www/tmp/foreman'
      execute "mkdir -p #{foreman_temp}"
      within current_path do
        execute "cd #{current_path}"
        execute 'foreman',
                :export,
                :systemd,
                foreman_temp.to_s,
                "-a #{fetch(:application)}",
                "-u #{fetch(:deployer_user)}",
                "-f #{current_path}/Procfile.dev"
      end
      execute "chmod 640 #{foreman_temp}/#{fetch(:application)}*"
      sudo "rm -rf /etc/systemd/system/#{fetch(:application)}*"
      sudo "mv #{foreman_temp}/* /etc/systemd/system"
      sudo "rm -r #{foreman_temp}"
      sudo 'systemctl daemon-reload'
      sudo "systemctl enable #{fetch(:application)}.target"
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:all) do |_host|
      sudo :systemctl, :restart, "#{fetch(:application)}.target"
    end
  end

  after :finishing, 'deploy:foreman_init'
  after :finishing, 'deploy:cleanup'
  after :finishing, 'deploy:restart'

  before 'deploy:setup', 'deploy:prepare_service_dirs'
  after 'deploy:prepare_service_dirs', 'deploy:upload_linked_files'

  before :setup, 'deploy:starting'
  before :setup, 'deploy:updating'
  before :setup, 'bundler:install'
  after :setup, 'deploy:foreman_init'

  before :deploy, 'deploy:upload_linked_files'
  after 'deploy:upload_linked_files', 'deploy:set_linked_files_permissions'

  # Regexp to separate linked files to shared and project files.
  set :project_linked_files_regexp, %r{\Aconfig\/.*.key\z}

  # Shared files are stored in a special local 'shared' directory, has
  # different versions per environment and usually has a development
  # version inside a project structure.
  # For example .env file has a development version inside the root folder
  # and one version per each environment in a local 'shared' folder.
  def shared_linked_files
    fetch(:linked_files, []).reject do |file|
      file.match?(fetch(:project_linked_files_regexp))
    end
  end

  # Project files are stored inside a project and usually doesn't depends on
  # the environment or has the environment in the name.
  # Examples:
  # - config/credentials/staging.key
  # - config/credentials/production.key
  def project_linked_files
    fetch(:linked_files, []).select do |file|
      file.match?(fetch(:project_linked_files_regexp))
    end
  end

  # Shared directories are linked_dirs plus all directories of linked_files
  def shared_dirs
    (fetch(:linked_files) + fetch(:linked_dirs))
      .map { |path| File.dirname(path) }
      .reject { |dirname| dirname == '.' }
      .uniq
  end

  # Returns true if the file is a credentials key
  def credentials_key?(file)
    file.end_with?('.key')
  end
end