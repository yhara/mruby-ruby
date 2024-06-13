require 'mruby-ruby/mrb'
require 'mruby-ruby/vm'
require 'stringio'

module MrubyRuby
  def self.run_file(path)
    MrubyRuby::Vm.new(MrubyRuby::Mrb.load_file(path)).run
  end

  def self.run_file_and_capture(path)
    stdout = StringIO.new
    stderr = StringIO.new
    MrubyRuby::Vm.new(MrubyRuby::Mrb.load_file(path), stdout:, stderr:).run
    [stdout.string, stderr.string]
  end
end
