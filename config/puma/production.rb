require 'dotenv'
Dotenv.load

environment ENV.fetch('RAILS_ENV', 'production')

workers Integer(ENV.fetch('WEB_CONCURRENCY') { 2 })
min_threads_count = Integer(ENV.fetch('RAILS_MIN_THREADS') { 1 })
max_threads_count = Integer(ENV.fetch('RAILS_MAX_THREADS') { 64 })
threads min_threads_count, max_threads_count

app_dir = '/var/www/apps/MakeRetailService'
directory "#{app_dir}/current"
bind "unix://#{app_dir}/sockets/.puma.sock"
stdout_file = "#{app_dir}/log/puma.stdout.log"
stderr_file = "#{app_dir}/log/puma.stderr.log"
stdout_redirect stdout_file, stderr_file, true
pidfile "#{app_dir}/run/puma.pid"
state_path "#{app_dir}/run/puma.state"
activate_control_app

preload_app!

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end