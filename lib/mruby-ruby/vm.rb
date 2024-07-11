module MrubyRuby
  class Vm
    def initialize(mrb, stdout: $stdout, stderr: $stderr)
      @mrb = mrb
      @stdout = stdout
      @stderr = stderr
      @regs = []
      @self = Object.new
    end

    def run
      @mrb.reps.each do |rep|
        eval_rep(rep)
      end
    end

    private

    def eval_rep(rep)
      @rep = rep
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
        @regs[op[1]] = @rep.pool[op[2]]
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
        args = @regs[op[1]+1, op[3]]
        sym = @rep.syms[op[2]]
        @regs[op[1]] = @self.__send__(sym, *args)

      when :OP_RETURN
        # todo
        
      when :OP_INTERN
        @regs[op[1]] = @regs[op[1]].intern
      when :OP_SYMBOL
        @regs[op[1]] = @rep.pool[op[2]].intern
      when :OP_STRING
        @regs[op[1]] = @rep.pool[op[2]].dup

      when :OP_STOP
        throw :OP_STOP
      else
        raise "Unknown opcode: #{op[0]}"
      end
    end
  end
end
