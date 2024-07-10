module MrubyRuby
  class Vm
    def initialize(mrb, stdout: $stdout, stderr: $stderr)
      @mrb = mrb
      @stdout = stdout
      @stderr = stderr
      @regs = []
    end

    def run
      @mrb.reps.each do |rep|
        eval_rep(rep)
      end
    end

    private

    def eval_rep(rep)
      catch(:OP_STOP) do
        rep.iseqs.each do |iseq|
          eval_iseq(iseq)
        end
      end
    end

    def eval_iseq(op)
      case op[0]
      when :OP_NOP
        # do nothing
      when :OP_MOVE
        @regs[op[1]] = @regs[op[2]]
      when :OP_LOADL
        @regs[op[1]] = @pool[op[2]]
      when :OP_LOADI
        @regs[op[1]] = op[2]
      when :OP_LOADINEG
        @regs[op[1]] = -op[2]
      when :OP_LOADI__1
        @regs[op[1]] = -1
      when :OP_LOADI_0
        @regs[op[1]] = 0
      when :OP_LOADI_1
        @regs[op[1]] = 1

      when :OP_SSEND
        # todo

      when :OP_RETURN
        # todo

      when :OP_STOP
        throw :OP_STOP
      else
        raise "Unknown opcode: #{op[0]}"
      end
    end
  end
end
