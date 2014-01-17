# Create a new middleman app with options to
# * create a github repo
# * create an s3 bucket
#
# want:
#   mman init -gh -s3 <project_name> # init a middleman project with github and s3
#
# want:
#   mman init [-gh=project_other_name] [-s3=project_bucket_name] <project_dir>
#
# inside middleman project:
#   mm deploy [production|staging|whatever]
#
# require 'middleman'

require 'thor'
require 'git'
require 'fileutils'
require 'middleman'

class MiddleManager < Thor

  option :gh, :type => :boolean, :desc => "include git and github initialization",
              :aliases => ["--with-github"]
  option :s3, :type => :boolean, :desc => "include s3 bucket creation",
              :aliases => ["--with-s3"]
  option :t,  :type => :string,  :desc => "the middleman template to use, default 'mbot-haml'",
              :aliases => ["--with-template"]
  desc "init <project_dir>", "Set up a middleman project in the specified directory"
  def init(working_dir = "ASK")
    working_dir = ask_for_project_name if working_dir == "ASK"
    crash("directory exists and isn't empty!") unless available?(working_dir)
    middleman_init(working_dir, options)

    # extras?
    options[:gh] ? github_init(working_dir, options) : ask_about_github
    options[:s3] ? s3_init(working_dir, options)     : ask_about_s3
    
    message("middleman site created at ./#{working_dir}")
  end

  private


    ### user queries

    def ask_for_project_name
      response = ask "What directory do you want to create your project in?"
      crash("needed a real answer here, chief. [] won't cut it.") if response.empty?
      response
    end

    def ask_about_github
      if ask("would you like to set up a github project?").match(/^[Yy]/)
        message("setting up a github project.")
      end
    end

    def ask_about_s3
      if ask("would you like to set up an s3 bucket?").match(/^[Yy]/)
        message("setting up an s3 bucket.")
      end
    end

    ### tasks

    def middleman_init(dir, options)
      message("creating a middleman site at ./#{dir}")
      init_string = "doing: middleman init #{dir}"
      init_string << " --template=#{options[:t] ? options[:t] : 'mbot-haml'}"
      message init_string # build middleman

      key = (options[:t] || "mmgr-default").to_sym
      unless ::Middleman::Templates.registered.has_key?(key)
        crash("unknown project template '#{key}'")
      end

      template_group = ::Middleman::Templates.registered[key]
      template_group.new([dir], options).invoke_all

      message("middleman: DONE!")
    end

    def s3_init(bucket_name, options)
      message("initializing s3 bucket: #{bucket_name}")
      # retrieve credentials
      # connect to s3
      # check if bucket exists
      # create bucket
      # configure bucket
      # spit out bucket information
    end

    def github_init(dir, options)
      message("initializing git at #{dir}")
      g = Git::init(dir)
      File.open(File.join(dir, ".gitignore"), "w") do |f|
        f.write(".sass_cache\n.DS_Store\nbuild\n")
      end

      g.add(all: true)
      g.commit("middle-manager commits everything")

      # message("creating github project for #{dir}")
      # client = Octokit::Client.new(credentials)
      # client.create_repository(thing)
      # create github project
      # add remote to working_dir
      # push working_dir to github
      # say some stuff
      github_url = "git@github.com/user/project"
      message("pushed to #{github_url}.")
    end

    ### utilities

    def ask(question, default = "")
      $stdout.print "!! " +  question + " [#{default}] : "
      $stdout.flush
      response = $stdin.gets.chomp
      return response.empty? ? default : response
    end

    def message(message, mtype="INFO", stream = $stdout)
      stream.puts("-- mmgr[#{mtype}] - #{message}")
    end

    def crash(message)
      message(message, "ERR", $stderr)
      raise Thor::Error.new("you have upset your manager!")
    end

    def available?(working_dir)
      !File.exists?(working_dir) || directory_empty?(working_dir)
    end

    def directory_empty?(working_dir)
      File.directory?(working_dir) && Dir.glob("#{working_dir}/*").empty?
    end

end
