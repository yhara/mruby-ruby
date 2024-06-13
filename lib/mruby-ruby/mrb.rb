require 'mruby-ruby/mrb/parser'

module MrubyRuby
  class Mrb
    def self.load_file(path)
      new(path)
    end

    def initialize(path)
      Parser.new(File.read path).parse
    end
  end
end
