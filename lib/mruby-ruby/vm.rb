require 'logger'
require 'mruby-ruby/runtime'

module MrubyRuby
  # The mruby-ruby virtual machine.
  #
  # Objects are represented as JSON-like structures. For example:
  #
  #    {class: :Integer, content: 1}
  #    {class: :String, content: "hello"}
  #    {class: :Array, content: [...]}
  class Vm
    def initialize(mrb, stdout: $stdout, stderr: $stderr)
      @mrb = mrb
      @stdout = stdout
      @stderr = stderr
      @logger = Logger.new(STDERR)

      @regs = []
      @runtime = Runtime.new(stdout: stdout, stderr: stderr, logger: @logger)
      @self = @runtime.main
      @target_class = Runtime.get_singleton_class(@self)
      @global_vars = {}
    end

    def run
      eval_rep(@mrb.reps.first)
      @logger.debug("mruby execution finished #{@regs.inspect}")
    end

    def inspect
      "#<#{self.class}:0x#{object_id.to_s(16)}>"
    end

    def eval_rep(rep, *args)
      @rep = rep
      ret = nil
      catch(:OP_STOP) do
        rep.iseqs.each do |iseq|
          ret = eval_iseq(rep, iseq, *args)
        end
      end
      ret
    end

    private

    def trace(msg)
      @logger.debug(msg)
    end

    def eval_iseq(rep, op, *args)
      case op[0]
      when :OP_NOP
        trace("#{op[0]}")
        # do nothing
      when :OP_MOVE
        trace("#{op[0]} @#{op[1]} <- #{op[2]}")
        @regs[op[1]] = @regs[op[2]]
      when :OP_LOADL
        trace("#{op[0]} @#{op[1]} <- #{rep.pool[op[2]]}")
        @regs[op[1]] = rep.pool[op[2]]
      when :OP_LOADI
        trace("#{op[0]} @#{op[1]} <- #{op[2]}")
        @regs[op[1]] = Runtime.m_int(op[2])
      when :OP_LOADINEG
        trace("#{op[0]} @#{op[1]} <- #{-op[2]}")
        @regs[op[1]] = Runtime.m_int(-op[2])
      when :OP_LOADI__1
        trace("#{op[0]} @#{op[1]} <- -1")
        @regs[op[1]] = Runtime.m_int(-1)
      when :OP_LOADI_0
        trace("#{op[0]} @#{op[1]} <- 0")
        @regs[op[1]] = Runtime.m_int(0)
      when :OP_LOADI_1
        trace("#{op[0]} @#{op[1]} <- 1")
        @regs[op[1]] = Runtime.m_int(1)
      when :OP_LOADI16
        trace("#{op[0]} @#{op[1]} <- #{op[2]}")
        @regs[op[1]] = Runtime.m_int(op[2])
      when :OP_LOADI32
        todo
      when :OP_LOADSYM
        trace("#{op[0]} @#{op[1]} <- #{op[2]}")
        @regs[op[1]] = Runtime.m_sym(rep.syms[op[2]])
      when :OP_LOADNIL
        trace("#{op[0]} @#{op[1]} <- nil")
        @regs[op[1]] = Runtime.m_nil
      when :OP_LOADSELF
        trace("#{op[0]} @#{op[1]} <- self")
        @regs[op[1]] = @self
      when :OP_LOADT
        trace("#{op[0]} @#{op[1]} <- true")
        @regs[op[1]] = Runtime.m_bool(true)
      when :OP_LOADF
        trace("#{op[0]} @#{op[1]} <- false")
        @regs[op[1]] = Runtime.m_bool(false)

      #
      # Variables
      #
      when :OP_GETGV
        trace("#{op[0]} @#{op[1]} <- gvar_get(:#{rep.syms[op[2]]})")
        @regs[op[1]] = @runtime.gvar_get(rep.syms[op[2]])
      when :OP_SETGV
        trace("#{op[0]} gvar_set(:#{rep.syms[op[2]]}}, @#{op[1]})")
        @runtime.gvar_set(rep.syms[op[2]], @regs[op[1]])
      when :OP_GETIV
        trace("#{op[0]} @#{op[1]} <- ivar_get(:#{rep.syms[op[2]]})")
        @regs[op[1]] = Runtime.ivar_get(@self, rep.syms[op[2]])
      when :OP_SETIV
        trace("#{op[0]} ivar_set(:#{rep.syms[op[2]]}}, @#{op[1]})")
        Runtime.ivar_set(@self, rep.syms[op[2]], @regs[op[1]])
      when :OP_GETCV
        todo
      when :OP_SETCV
        todo
      when :OP_GETCONST
        trace("#{op[0]} @#{op[1]} <- const_get(:#{rep.syms[op[2]]})")
        # TODO: const lookup
        @regs[op[1]] = @runtime.const_get(rep.syms[op[2]])
      when :OP_SETCONST
        todo
      when :OP_GETMCNST
        todo
      when :OP_SETMCNST
        todo
      when :OP_GETUPVAR
        todo
      when :OP_SETUPVAR
        todo

      when :OP_GETIDX
        todo
      when :OP_SETIDX
        todo
      when :OP_JMP
        todo
      when :OP_JMPIF
        todo
      when :OP_JMPNOT
        todo
      when :OP_JMPNIL
        todo
      when :OP_JMPUW
        todo
      when :OP_EXCEPT
        todo
      when :OP_RESCUE
        todo
      when :OP_RAISEIF
        todo

      #
      # Method invocation
      #
      when :OP_SSEND
        trace("#{op[0]} @#{op[1]} <- invoke_mruby_method(self, :#{rep.syms[op[2]]}#{(0...op[3]).map{|i| ", @#{op[1]+1+i}"}.join})")
        args = @regs[op[1]+1, op[3]]
        sym = rep.syms[op[2]]
        @regs[op[1]] = @runtime.invoke_mruby_method(@self, sym, *args)
      when :OP_SSENDB
        todo
      when :OP_SEND
        trace("#{op[0]} @#{op[1]} <- invoke_mruby_method(@#{op[1]}, :#{rep.syms[op[2]]}#{(0...op[3]).map{|i| ", @#{op[1]+1+i}"}.join})")
        args = @regs[op[1]+1, op[3]]
        sym = rep.syms[op[2]]
        @regs[op[1]] = @runtime.invoke_mruby_method(@regs[op[1]], sym, *args)
      when :OP_SENDB
        todo
      when :OP_CALL
        todo
      when :OP_SUPER
        todo
      when :OP_ARGARY
        todo
      when :OP_ENTER
        #todo
      when :OP_KEY_P
        todo
      when :OP_KEYEND
        todo
      when :OP_KARG
        todo
      when :OP_RETURN
        trace("#{op[0]} return @#{op[1]}")
        @regs[op[1]]
      when :OP_RETURN_BLK
        todo
      when :OP_BREAK
        todo
      when :OP_BLKPUSH
        todo

      #
      # Numeric
      #
      when :OP_ADD
        trace("#{op[0]} @#{op[1]} <- @#{op[2]} + @#{op[3]}")
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :+, @regs[op[3]])
      when :OP_ADDI
        trace("#{op[0]} @#{op[1]} <- @#{op[2]} + #{op[3]}")
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :+, Runtime.m_int(op[3]))
      when :OP_SUB
        trace("#{op[0]} @#{op[1]} <- @#{op[2]} - @#{op[3]}")
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :-, @regs[op[3]])
      when :OP_SUBI
        trace("#{op[0]} @#{op[1]} <- @#{op[2]} - #{op[3]}")
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :-, Runtime.m_int(op[3]))
      when :OP_MUL
        trace("#{op[0]} @#{op[1]} <- @#{op[2]} * @#{op[3]}")
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :*, @regs[op[3]])
      when :OP_DIV
        trace("#{op[0]} @#{op[1]} <- @#{op[2]} / @#{op[3]}")
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :/, @regs[op[3]])
      when :OP_EQ
        trace("#{op[0]} @#{op[1]} <- @#{op[2]} == @#{op[3]}")
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :==, @regs[op[3]])
      when :OP_LT
        trace("#{op[0]} @#{op[1]} <- @#{op[2]} < @#{op[3]}")
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :<, @regs[op[3]])
      when :OP_LE
        trace("#{op[0]} @#{op[1]} <- @#{op[2]} <= @#{op[3]}")
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :<=, @regs[op[3]])
      when :OP_GT
        trace("#{op[0]} @#{op[1]} <- @#{op[2]} > @#{op[3]}")
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :>, @regs[op[3]])
      when :OP_GE
        trace("#{op[0]} @#{op[1]} <- @#{op[2]} >= @#{op[3]}")
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :>=, @regs[op[3]])
        
      #
      # Array
      #
      when :OP_ARRAY
        trace("#{op[0]}")
        @regs[op[1]] = @regs[op[2], op[3]]
      when :OP_ARYCAT
        trace("#{op[0]}")
        @regs[op[1]] += @regs[op[2]]
      when :OP_ARYPUSH
        trace("#{op[0]}")
        todo
      when :OP_ARYDUP
        trace("#{op[0]}")
        @regs[op[1]] = @regs[op[1]].dup
      when :OP_AREF
        trace("#{op[0]}")
        @regs[op[1]] = @regs[op[2]][@regs[op[3]]]
      when :OP_ASET
        trace("#{op[0]}")
        @regs[op[1]][@regs[op[2]]] = @regs[op[3]]
      when :OP_APOST
        trace("#{op[0]}")
        todo
        
      #
      # String/Symbol
      #
      when :OP_INTERN
        trace("#{op[0]}")
        @regs[op[1]] = Runtime.m_str(@regs[op[1]].to_sym)
      when :OP_SYMBOL
        trace("#{op[0]}")
        @regs[op[1]] = Runtime.m_sym(rep.pool[op[2]].to_sym)
      when :OP_STRING
        trace("#{op[0]}")
        @regs[op[1]] = Runtime.m_str(rep.pool[op[2]])
      when :OP_STRCAT
        trace("#{op[0]}")
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[1]], :+, @regs[op[2]])

      #
      # Hash
      #
      when :OP_HASH
        trace("#{op[0]}")
        @regs[op[1]] = Hash[*@regs[op[2], op[3]]]
      when :OP_HASHADD
        trace("#{op[0]}")
        todo
      when :OP_HASHCAT
        trace("#{op[0]}")
        todo

      #
      # Proc
      #
      when :OP_LAMBDA
        trace("#{op[0]}")
        todo
      when :OP_BLOCK
        trace("#{op[0]}")
        todo
      when :OP_METHOD
        trace("#{op[0]}")
        child_rep = rep.children[op[2]]
        vm = self
        logger = @logger
        @regs[op[1]] = lambda{|*args| 
          #logger.debug("mruby method call: #{child_rep.inspect}")
          ret = vm.eval_rep(child_rep, *args)
          #logger.debug("mruby method return: #{ret.inspect}")
          ret
        }

      #
      # Range
      #
      when :OP_RANGE_INC
        trace("#{op[0]}")
        @regs[op[1]] = @regs[op[2]..@regs[op[3]]]
      when :OP_RANGE_EXC
        trace("#{op[0]}")
        @regs[op[1]] = @regs[op[2]...@regs[op[3]]]

      #
      # Class
      #
      when :OP_OCLASS
        trace("#{op[0]}")
        @regs[op[1]] = Object
      when :OP_CLASS
        trace("#{op[0]}")
        name = rep.syms[op[2]]
        sup = op[3]
        if sup.nil?
          cls = Class.new
        else
          cls = Class.new(sup)
        end
        cls = Runtime.create_mruby_class(name, cls)
        @self = cls
        @runtime.const_set(name, cls)
        @regs[op[1]] = cls
      when :OP_MODULE
        trace("#{op[0]}")
        todo

      when :OP_EXEC
        trace("#{op[0]}")
        @regs[op[1]] = blockexec(@regs[op[1]], rep.children[op[2]])
      when :OP_DEF
        trace("#{op[0]}")
        block = @regs[op[1]+1]
        Runtime.define_mruby_method(@regs[op[1]], rep.syms[op[2]], block)
        @regs[op[1]] = rep.syms[op[2]]
      when :OP_ALIAS
        trace("#{op[0]}")
        todo
      when :OP_UNDEF
        trace("#{op[0]}")
        todo

      when :OP_SCLASS
        trace("#{op[0]} @#{op[1]} <- get_singleton_class(@#{op[1]})")
        @regs[op[1]] = Runtime.get_singleton_class(@regs[op[1]])
      when :OP_TCLASS
        trace("#{op[0]} @#{op[1]} <- target_class")
        @regs[op[1]] = @target_class

      # 
      # Misc.
      #
      when :OP_DEBUG
        trace("#{op[0]}")
        todo
      when :OP_ERR
        trace("#{op[0]}")
        todo
      when :OP_EXT1
        trace("#{op[0]}")
        todo
      when :OP_EXT2
        trace("#{op[0]}")
        todo
      when :OP_EXT3
        trace("#{op[0]}")
        todo
      when :OP_STOP
        trace("#{op[0]}")
        throw :OP_STOP
      else
        raise "Unknown opcode: #{op[0]}"
      end
    end

    def blockexec(target_class, child_rep)
      orig_target_class = @target_class
      @target_class = target_class
      return eval_rep(child_rep)
    ensure
      @target_class = orig_target_class
    end

#    def exec_block(child_rep, *args)
#      eval_rep(child_rep, *args)
#    end
  end
end
