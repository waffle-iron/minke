module Minke
  module Tasks
    class Cucumber < Task

      def run args = nil
      	puts "## Running cucumber with tags #{args}"

        compose_file = @config.compose_file_for(@task_name)
        compose_file = File.expand_path(compose_file)
        compose = @docker_compose_factory.create compose_file unless compose_file == nil

        run_with_block do
          status = false
          begin
            compose.up
            server_address = @service_discovery.build_address(@task_settings.health_check) 
            @health_check.wait_for_HTTPOK(server_address) unless @task_settings.health_check == nil
            
            status = @shell_helper.execute "cucumber --color -f pretty #{get_features args}"
          ensure
            compose.down
            @error_helper.fatal_error("Cucumber steps failed") unless status == true
          end
      	end
      end

      def get_features args
        if args != nil && args[:feature] != nil
      		feature = "--tags #{args[:feature]}"
      	else
      		feature = ""
      	end
      end

    end
  end
end
