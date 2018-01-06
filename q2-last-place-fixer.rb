#!/usr/bin/env ruby
#
# Patch *.t files for unset last place where there's more records
#
# Back-up your *.t files first just in case!
#
# 10 Apr 2015 -- Written; (maq)
#
# Released into the Public Domain with no warranty of any kind.
#

STDOUT.binmode
PROGNAME = File.basename($0)
USAGE_STR = "Usage: #{PROGNAME} [--stdout] jumpdir_path"

class MapSingleFile
  def initialize(jumpdir)
    @jumpdir = jumpdir
    #change directory to jumpdir
    Dir.chdir(jumpdir)
    #get all files with t extension
    all_maps = Dir.glob("*.t")
    for @map in all_maps
      #check all except users.t
      if @map != 'users.t'
        @map_file_path = File.join(@jumpdir, @map)
        load if test(?f,@map_file_path)
      end
    end
  end

  def load(path=@map_file_path)
    dat = File.read(path)
    #strange file structure
    @jump_ver, @some_number, @map_name, @top_times_text, top_times, @all_times_text , @file_all_times = dat.split(/\n/,7)
    #get top map times
    @top_times =      top_times.scan(/\d{2}[\/]{1}\d{2}[\/]{1}\d{2}\s[0-9]+[\.]{1}[0-9]{6}\s\d+/)
    #get all map times
    @all_times =  @file_all_times.scan(/\d{2}[\/]{1}\d{2}[\/]{1}\d{2}\s[0-9]+[\.]{1}[0-9]{6}\s\d+/)
    #sor all map times
    @all_times_sorted = @all_times.map {|rec| rec.split(/\s/)}.sort_by{|k| k[1].to_f}
    @top_times_mapped = @top_times.map {|rec| rec.split(/\s/)}
    #check if it's less than 15 top times and if there's more in all times
    #duplicates
    @top_times = @top_times.uniq
    #puts @top_times
    #puts " --- "
    #puts @map
    #puts @all_times
    if @top_times.count < 15 && @top_times.count <= @all_times.count && @top_times_mapped != @all_times_sorted[0..14]
      #get top 15 from all times already sorted
      for i in @top_times.count-1..14
        if @top_times[i] == nil && @all_times_sorted[i] != nil
          @top_times[i] = @all_times_sorted[i].join(" ")
        end
      end
      @top_times_sorted = @top_times[0..14].join(" ")
      #puts @top_times[0..14]
      #create file structure
      @file_content = @jump_ver + "\n" + @some_number + "\n" + @map_name + "\n" + @top_times_text + "\n " + @top_times_sorted + "\n" + @all_times_text + "\n" + @file_all_times
      #save file
      File.open(path, "wb") {|filex| filex.write @file_content}
      #output which files has been afected
      puts @map + " has been patched"
    end
  end

end

use_stdout = ARGV.delete("--stdout")
jumpdir = ARGV.shift
(jumpdir.to_s.strip.empty?) and abort(USAGE_STR)
test(?d, jumpdir) or abort("#{PROGNAME}: jumpdir path not found at: #{jumpdir.inspect}")

@maps = MapSingleFile.new(jumpdir)