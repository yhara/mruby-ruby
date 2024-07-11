require 'mruby-ruby/mrb'
require 'mruby-ruby/vm'
require 'stringio'

module MrubyRuby
  def self.run_file(path)
    MrubyRuby::Vm.new(MrubyRuby::Mrb.load_file(path)).run
  end

  def self.run_file_and_capture(path)
    orig_out = $stdout
    orig_err = $stderr
    stdout = StringIO.new
    stderr = StringIO.new
    $stdout = stdout
    $stderr = stderr
    MrubyRuby::Vm.new(MrubyRuby::Mrb.load_file(path), stdout:, stderr:).run
    [stdout.string, stderr.string]
  ensure
    $stdout = orig_out
    $stderr = orig_err
  end
end
