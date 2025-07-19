require "find"
require "optparse"
require "thread"
require "open3"
require "fileutils"

module Mafido

  def verbose=(obj)
    @verbose = obj
  end

  def verbose
    @verbose || false
  end

  def log(*args, prefix: "mafido> ")
    return false unless Mafido.verbose
    args.each do |lline|
      puts "%s %s" % [prefix, lline]
    end
  end

  class Collection < Array
    def files
      self
    end
  end
  
  class Files
    def initialize(**kwargs)
      target_dir = kwargs[:path]
      @target_dir = File.expand_path(target_dir)
      raise "not existing: `#{@target_dir}'" unless File.exist?(@target_dir)
    end

    def collect(**kwargs)
      log "Files: collecting in `#{@target_dir}'"
      fileslist = Find.find(@target_dir).to_a

      extension = kwargs[:extension]

      @collection = Collection.new
      if extension
        @collection.push(*fileslist.grep(/\.#{extension}/))
      end
      @collection
    end

  end


  class Processor
    class ProcessQueue < Array
    end

    class Substitues < Hash
    end

    class Subroutine
      attr_reader :processor
      def initialize(processor, ifile, ofile)
        @processor = processor
        @input_file = ifile
        @output_file = ofile
        @substitues = Substitues.new
        @substitues.merge!(input: @input_file, output: @output_file)
      end

      def inspect
        io = [File.basename(@input_file), File.basename(@output_file)]
        "<Subroutine(%s/{'%s','%s'})>" % [File.dirname(@input_file), *File.basename(@input_file), io.join(",")]
      end

      def shell_command
        unless @shell_command
          cmd_to_run = processor.command.dup
          @substitues.each_pair do |k, v|
            cmd_to_run.gsub!(/\%#{k}\%/, "'%s'"%v)
          end
          @shell_command = cmd_to_run
        end
        @shell_command
      end

      def run(**kwargs)
        mock = kwargs[:mock]
        log "$ #{mock ? "(mock)" : ""}running #{shell_command}"

        if mock
          if kwargs[:remove]
            log "removing input due to --remove `#{@input_file}'"
          end
          return true 
        end

        stdout, stderr, status = Open3.capture3(shell_command)
        unless status.success?
          puts "-"*60
          puts $stderr
        else
          log "removing input due to --remove `#{@input_file}'"
          FileUtils.rm_rf(@input_file, verbose: false)
        end
      end
    end


    attr_accessor :collection, :command, :queue

    def initialize(collection, command)
      @collection = collection
      @command = command
      @queue = Queue.new
    end

    def process!(**kwargs)
      @collection.each do |centry|
        a=Subroutine.new(self, *make_filenames(centry))
        @queue << a
      end

      process_queue(**kwargs)
    end

    def make_filenames(input_filename)
      ext = File.extname(input_filename)
      basename = input_filename.sub(/#{Regexp.escape(ext)}$/, '')

      m = @command.match(/%output%(\.[a-z0-9]+)\b/i)
      template_ext = m ? m[1] : nil

      output_file = template_ext ? basename : input_filename

      [input_filename, output_file]
    end

    def process_queue(**kwargs, &block)
      threads = []
      jobs = kwargs[:jobs]
      log "processing queue with jobs=#{jobs} mock=#{!!kwargs[:mock]}"

      jobs.times do
        threads << Thread.new do
          while (job = queue.pop(true) rescue nil)
            begin
              done_job = job.run(**kwargs)
              yield done_job if block_given?
            rescue => e
              log "Processor\#process_queue: #{e}"
            end
          end
        end
      end

      threads.each(&:join)
    end
  end

end
