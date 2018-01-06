#!/usr/bin/env ruby
#
# Patch num_maps_completed fields in users.t to match the actual
# count of maps in the corresponding uid.u files.
#
# Back-up your users.t file first just in case!
#
# 10 Jul 2014 -- Written; (quadz)
#
# Released into the Public Domain with no warranty of any kind.
#
#encoding=utf-8
STDOUT.binmode
PROGNAME = File.basename($0)
USAGE_STR = "Usage: #{PROGNAME} [--stdout] jumpdir_path"

class JumpSingleUserFile
  def initialize(jumpdir, uid)
    @jumpdir = jumpdir
    @uid = uid
    @user_file_path = File.join(@jumpdir, "#{@uid}.u")
    @rec = nil
    load if test(?f, @user_file_path)
  end

  def load(path=@user_file_path)
    @rec = File.read(path).strip.split(/\s+/)
  end

  def have_rec?
    !! @rec
  end

  def num_maps_completed
    @rec.length
  end
end

class JumpUsersFile
  include Enumerable

  def initialize(jumpdir)
    @jumpdir = jumpdir
    @users_file_path = File.join(@jumpdir, "users.t")
    @jump_ver = nil
    @recs = []
    load if test(?f, @users_file_path)
  end

  def load(path=@users_file_path)
    dat = File.read(path)
    puts path
    @jump_ver, user_dat = dat.split(/\s/, 2)
    @recs = user_dat.scan(/(?:\d+\s){9}\S+/).map {|rec| rec.split(/\s/)}
  end

  def save(path=@users_file_path)
    File.open(path, "wb") {|io| io.print gen_users_dat}
  end

  def gen_users_dat
    ([@jump_ver] + @recs.map {|rec| rec.join(" ")}).join(" ")
  end

  def fix_maps_completed(rec)
    user_id = rec[0]
    user = JumpSingleUserFile.new(@jumpdir, user_id)
    if user.have_rec?
      maps_completed = rec[1].to_i
      if maps_completed != user.num_maps_completed
        warn "patching user_id #{user_id} maps_completed from #{maps_completed} to #{user.num_maps_completed}"
        rec[1] = user.num_maps_completed.to_s
      end
    else
      warn "no user file for user_id #{user_id}"
    end
  end

  def each(&block)
    @recs.each(&block)
  end
end

use_stdout = ARGV.delete("--stdout")
jumpdir = ARGV.shift
(jumpdir.to_s.strip.empty?) and abort(USAGE_STR)
test(?d, jumpdir) or abort("#{PROGNAME}: jumpdir path not found at: #{jumpdir.inspect}")

users = JumpUsersFile.new(jumpdir)
users.each {|rec| users.fix_maps_completed(rec)}
if use_stdout
  print users.gen_users_dat
else
  users.save
end
