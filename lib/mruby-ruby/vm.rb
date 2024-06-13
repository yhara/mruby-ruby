module MrubyRuby
  class Vm
    def initialize(mrb, stdout: $stdout, stderr: $stderr)
      @mrb = mrb
      @stdout = stdout
      @stderr = stderr
    end

    def run
      @mrb.run
    end
  end
end
