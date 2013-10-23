module Gistore
  class Runner
    desc "checkout [--rev <rev>]",
         "Checkout entries to <path>"
    option :rev, :aliases => [:r], :desc => "Revision to checkout", :banner => "<rev>"
    option :to, :required => true, :banner => "<path>", :desc => "a empty directory to save checkout items"
    def checkout(*args)
      gistore = Repo.new(options[:repo] || ".")
      work_tree = options[:to]
      if File.exist? work_tree
        if not File.directory? work_tree
          abort "\"#{work_tree}\" is not a valid directory."
        elsif File.file? File.join(work_tree, ".git")
          gitfile = File.open(File.join(work_tree, ".git")) {|io| io.read}.strip
          if gitfile != "gitdir: #{gistore.repo_path}"
            abort "\"#{work_tree}\" not a checkout from #{gistore.repo_path}"
          end
        elsif Dir.entries(work_tree).size != 2
          abort "\"#{work_tree}\" is not a blank directory."
        end
      else
        require 'fileutils'
        FileUtils.mkdir_p work_tree
        File.open(File.join(work_tree, '.git'), 'w') do |io|
          io.puts "gitdir: #{gistore.repo_path}"
        end
      end
      if git_version_compare('1.7.7.1') >= 0
        args = args.empty? ? ["."]: args.dup
        args << {:work_tree => work_tree, :without_gitdir => true}
        args.shift if args.first == '--'
        cmds = [git_cmd,
                "checkout",
                options[:rev] || 'HEAD',
                "--",
                *args]
        gistore.system(*cmds)
      else
        gistore.setup_environment
        Dir.chdir(work_tree) do
          `#{git_cmd} archive --format=tar #{options[:rev] || 'HEAD'} #{args.map{|e| e.inspect}.join(' ')} | tar xf -`
        end
      end 

    rescue SystemExit => e
      exit 1
    rescue Exception => e
      $stderr.puts "Error: #{e.inspect}"
      exit 2
    end
  end
end
