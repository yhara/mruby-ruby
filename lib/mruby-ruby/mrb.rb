require 'mruby-ruby/mrb/parser'

module MrubyRuby
  class Mrb
    def self.load_file(path)
      Parser.new(File.read path).parse
    end

    attr_accessor :major
    attr_accessor :minor
    attr_accessor :reps

    class Rep
      attr_accessor :nlocals # Number of local variables
      attr_accessor :nregs  # Number of register variables
      attr_accessor :clen    # Number of catch handlers

      attr_accessor :iseqs
      attr_accessor :pool
      attr_accessor :syms
      attr_accessor :children
    end
  end
end
