module GoBuilder
  class GoDocker
    def self.get_docker_ip_address
    	if !ENV['DOCKER_HOST']
    		return "127.0.0.1"
    	else
    		# dockerhost set
    		host = ENV['DOCKER_HOST'].dup
    		host.gsub!(/tcp:\/\//, '')
    		host.gsub!(/:\d+/,'')

    		return host
    	end
    end

    def self.find_image image_name
    	found = nil
    	Docker::Image.all.each do | image |
    		found = image if image.info["RepoTags"].include? image_name
    	end

    	return found
    end

    def self.pull_image image_name
    	puts "Pulling Image: #{image_name}"
    	puts `docker pull #{image_name}`
    end

    def self.get_container args
    	container = self.find_running_container
    	if container != nil
    		return container
    	else
    		return self.create_and_start_container(args)
    	end
    end

    def self.find_running_container
    	containers = Docker::Container.all(:all => true)
    	found = nil

    	containers.each do | container |
    		if container.info["Image"] == "golang" && container.info["Status"].start_with?("Up")
    			return container
    		end
    	end

    	return nil
    end

    def self.create_and_start_container args
    	# update the timeout for the Excon Http Client
    	# set the chunk size to enable streaming of log files
    	Docker.options = {:chunk_size => 1, :read_timeout => 3600}

    	container = Docker::Container.create(
    		'Image' => args['build_args']['image'],
    		'Cmd' => ['/bin/bash'],
    		'Tty' => true,
    		"Binds" => ["#{ENV['GOPATH']}/src:/go/src"],
    		"Env" => args['build_args']['env'],
    		'WorkingDir' => args['build_args']['working_directory'])
    	container.start

    	return container
    end

    def self.tag_and_push args
      image =  self.find_image "#{args['go']['application_name']}:latest"
    	image.tag('repo' => "#{args['docker_registry']['namespace']}/#{args['go']['application_name']}", 'force' => true) unless image.info["RepoTags"].include? "#{args['docker_registry']['namespace']}/#{args['go']['application_name']}:latest"

    	system("docker login -u #{args['docker_registry']['user']} -p #{args['docker_registry']['password']} -e #{args['docker_registry']['email']} #{args['docker_registry']['url']}")
      abort "Unable to login" unless $?.exitstatus ==  0

    	system("docker push #{args['docker_registry']['namespace']}/#{args['go']['application_name']}:latest")
      abort "Unable to push to registry" unless $?.exitstatus ==  0
    end
  end
end
