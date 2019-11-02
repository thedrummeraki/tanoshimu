#!/usr/bin/ruby

require 'streamio-ffmpeg'

def help
    puts "./create_thumbnails [-d|--directory <videos directory>] [-h|--help]"
    puts "\t-d or --directory: Indicates where the video files are. Default: current directory. You can pass in several directories at once"
    puts "\t-h or --help: Shows this message."
    puts "\t-f or --force: If passed, the image will be generated even if it already exists."
    puts "\t-v or --verbose: Shows everything that is happening."
    puts "\t-dr or --dry-run: Runs the script normally without creating any files. Useful for \"What if\" scenarios."
    puts "\t-drv or -vdr: Combines --dry-run and --verbose (-dr and -v) flags."
    exit 1
end

class ThumbnailManager

    def initialize paths, verbose: false, dry_run: false
        #if File.file? path
        #    throw Exception.new "Please specify a directory path instead of a file."
        #end
        
        if paths.nil?
            @testing = true
            return self
        end

        @files = []
        @verbose = verbose
        @dr = dry_run == true
        info("Verbose mode is ON!") if @verbose
        info("Running the script for a dry run...") if @dr
        
        if paths.instance_of? FFMPEG::Movie
            @video = paths
            return self
        end

        paths.each do |path|
            get_files path
        end
        self
    end

    def generate(force_generation: true)
        if @testing
            p "Skipping image generation..."
            return
        end
        if @video
            return generate_for @video, force_generation: force_generation
        end

        log("Analyzing #{@files.size} video file(s)...")
        total = @files.size; current = 0
        @files.each do |file|
            generate_for file, force_generation: force_generation
            current += 1
            show_progress current, total
        end
        warn "Done."
    end

    def has_image?(video, ext: 'jpg')
        path = video.path
        image_path = to_image_path path, ext: ext
        File.exists? image_path
    end

    def generate_for(video, image_extention: 'jpg', force_generation: true)
        if @testing
            p "Skipping image generation..."
            return
        end

        has_image = has_image?(video, ext: image_extention)

        if !force_generation && has_image
            p "Skipping image generation (already exists...)"
            return
        elsif has_image
            p "Overwritting current video thumbnail..."
        end

        log("Generating video thumbnail for #{video.path}...")

        duration = video.duration
        seek_point = (duration/2).floor
        log("Video is #{duration} sec. long")
        log("Seeking thumbnail at #{seek_point} sec.")

        new_image_path = to_image_path(video.path, ext: image_extention)
        log("Thumbnail will be saved at: #{new_image_path}")
        info("The existing thumbnail will be replaced!") if File.exists? new_image_path

        video.screenshot(new_image_path,  seek_time: seek_point) unless @dr

        warn "\n" if @verbose
    end

    def videos
        @files
    end

    private

    def log(message)
        info(message) if @verbose
    end

    def info(message)
        puts "[INFO] #{message}"
    end

    def show_progress current, total
        progress = (current.to_f / total.to_f) * 100
        progress = progress.to_i
        info("#{progress}\% complete...")
    end

    def get_files path
        path = File.expand_path('.', path)
        log("Analyzing video files in the directory #{path}...")
        unless path.end_with? "/"
            path = path + "/"
        end
        files = Dir[path + "*"].select{|file| File.file?(file)}.sort
        files = files.map{|file| FFMPEG::Movie.new(file)}.select{|video| video.valid? && !video.video_stream.nil? && !video.audio_stream.nil?}
        @files += files
    end

    def to_image_path video_path, ext: 'jpg'
        parts = video_path.split('/')
        filename = parts[parts.size-1]
        fs = filename.split '.'
        fs[1] = ext.to_s
        filename = fs.join '.'
        parts[parts.size-1] = filename
        parts.join '/'
    end
end

def has_arg? arg, alt=nil
    pos = ARGV.index(arg)
    if pos.nil? && !alt.nil?
        pos = ARGV.index(alt)
        arg = alt
    end
    {present: !pos.nil?, pos: pos, flag: arg}
end

def check_invalid_flags
    authorized_flags = ["-v", "--verbose", "-d", "--directory", "-h", "--help", "-dr", "--dry-run", "-vdr", "-drv"]
    other_flags = ARGV.select{|arg| arg.start_with?("-")}.reject{|arg| authorized_flags.include?(arg)}
    unless other_flags.empty?
        warn "Invalid parameters: #{other_flags}"
        help
    end
end

if __FILE__ != $0
    exit(0)
end

verbose = has_arg?("-v", "--verbose")[:present]
dry_run = has_arg?("-dr", "--dry-run")[:present]
unless verbose || dry_run
    verbose = dry_run = has_arg?("-drv", "-vdr")[:present]
end

check_invalid_flags

if has_arg?("-h", "--help")[:present]
    help
end

path = nil

specified_dir = has_arg?("-d", "--directory")
force = has_arg?("-f", "--force")[:present]

if ARGV.empty? || !specified_dir[:present]
    warn "No file specified - looking for videos in the current directory..." if verbose
    paths = ['.']
elsif specified_dir[:present]
    path_pos = ARGV.index(specified_dir[:flag]) + 1
    paths = []
    found_path = false
    path = ARGV[path_pos]
    while !path.nil?
        path = nil if path.start_with? '-'
        unless path.nil?
            paths << path
            found_path = true
        end
        path_pos += 1
        path = ARGV[path_pos]
    end
    unless found_path
        warn "Oops, seems you forgot to specify the directory name with the argument \"#{specified_dir[:flag]}\"!"
        help
    end
end

begin
    manager = ThumbnailManager.new paths, verbose: verbose, dry_run: dry_run
rescue Exception => e
    warn "Error: #{e}"
    exit 1
end
if manager.videos.empty?
    warn "No videos were found in this directory (#{paths.map{|path| File.expand_path(".", path)}.join(' ').strip})!"
    exit 0
end

manager.generate(force_generation: force)