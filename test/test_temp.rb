$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require "fileutils"
require "test/unit"
require "galaxy/temp"

class TestTemp < Test::Unit::TestCase
  
  def test_simple
    begin
      file = Galaxy::Temp.mk_file
      dir = Galaxy::Temp.mk_dir
      assert File.exists?(file)
      assert File.exists?(dir)
      ObjectSpace.garbage_collect
      assert File.exists?(file)
      assert File.exists?(dir)
    ensure
      FileUtils.rm file if File.exists? file
      FileUtils.rmdir dir if File.exists? dir
    end
  end
  
  def test_repeated
    used_files = []
    used_dirs = []
    begin
      100.times do
        file = Galaxy::Temp.mk_file
        assert !used_files.include?(file)
        assert !used_dirs.include?(file)
        used_files.push file
        dir = Galaxy::Temp.mk_dir
        assert !used_files.include?(dir)
        assert !used_dirs.include?(dir)
        used_dirs.push dir
        assert File.exists?(file)
        assert File.exists?(dir)
        ObjectSpace.garbage_collect
        assert File.exists?(file)
        assert File.exists?(dir)
      end
    ensure
      used_files.each { |file| FileUtils.rm file if File.exists? file }
    end
  end
  
  def test_auto
    rd, wr = IO.pipe
    if fork
      wr.close
      file, dir = rd.read.split "\t"
      rd.close
      Process.wait
      begin
        assert !File.exists?(file)
        assert !File.exists?(dir)
      ensure
        FileUtils.rm file if File.exists? file
        FileUtils.rmdir dir if File.exists? dir
      end
    else
      rd.close
      file = Galaxy::Temp.mk_auto_file
      dir = Galaxy::Temp.mk_auto_dir
      assert File.exists?(file)
      assert File.exists?(dir)
      ObjectSpace.garbage_collect
      assert File.exists?(file)
      assert File.exists?(dir)
      wr.write "#{file}\t#{dir}"
      wr.close
      exit 0
    end
  end

end
