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
      @target_class = nil
      @global_vars = {}
    end

    def run
      eval_rep(@mrb.reps.first)
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

    def eval_iseq(rep, op, *args)
      @logger.debug(op.inspect)
      case op[0]
      when :OP_NOP
        # do nothing
      when :OP_MOVE
        @regs[op[1]] = @regs[op[2]]
      when :OP_LOADL
        @regs[op[1]] = rep.pool[op[2]]
      when :OP_LOADI
        @regs[op[1]] = Runtime.m_int(op[2])
      when :OP_LOADINEG
        @regs[op[1]] = Runtime.m_int(-op[2])
      when :OP_LOADI__1
        @regs[op[1]] = Runtime.m_int(-1)
      when :OP_LOADI_0
        @regs[op[1]] = Runtime.m_int(0)
      when :OP_LOADI_1
        @regs[op[1]] = Runtime.m_int(1)
      when :OP_LOADI16
        @regs[op[1]] = Runtime.m_int(op[2])
      when :OP_LOADI32
        todo
      when :OP_LOADSYM
        @regs[op[1]] = Runtime.m_sym(rep.syms[op[2]])
      when :OP_LOADNIL
        @regs[op[1]] = Runtime.m_nil
      when :OP_LOADSELF
        @regs[op[1]] = @self
      when :OP_LOADT
        @regs[op[1]] = Runtime.m_bool(true)
      when :OP_LOADF
        @regs[op[1]] = Runtime.m_bool(false)

      #
      # Variables
      #
      when :OP_GETGV
        @regs[op[1]] = @runtime.gvar_get(rep.syms[op[2]])
      when :OP_SETGV
        @runtime.gvar_set(rep.syms[op[2]], @regs[op[1]])
      when :OP_GETIV
        @regs[op[1]] = Runtime.ivar_get(@self, rep.syms[op[2]])
      when :OP_SETIV
        Runtime.ivar_set(@self, rep.syms[op[2]], @regs[op[1]])
      when :OP_GETCV
        todo
      when :OP_SETCV
        todo
      when :OP_GETCONST
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
        args = @regs[op[1]+1, op[3]]
        sym = rep.syms[op[2]]
        @regs[op[1]] = @runtime.invoke_mruby_method(@self, sym, *args)
      when :OP_SSENDB
        todo
      when :OP_SEND
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
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :+, @regs[op[3]])
      when :OP_ADDI
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :+, Runtime.m_int(op[3]))
      when :OP_SUB
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :-, @regs[op[3]])
      when :OP_SUBI
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :-, Runtime.m_int(op[3]))
      when :OP_MUL
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :*, @regs[op[3]])
      when :OP_DIV
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :/, @regs[op[3]])
      when :OP_EQ
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :==, @regs[op[3]])
      when :OP_LT
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :<, @regs[op[3]])
      when :OP_LE
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :<=, @regs[op[3]])
      when :OP_GT
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :>, @regs[op[3]])
      when :OP_GE
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[2]], :>=, @regs[op[3]])
        
      #
      # Array
      #
      when :OP_ARRAY
        @regs[op[1]] = @regs[op[2], op[3]]
      when :OP_ARYCAT
        @regs[op[1]] += @regs[op[2]]
      when :OP_ARYPUSH
        todo
      when :OP_ARYDUP
        @regs[op[1]] = @regs[op[1]].dup
      when :OP_AREF
        @regs[op[1]] = @regs[op[2]][@regs[op[3]]]
      when :OP_ASET
        @regs[op[1]][@regs[op[2]]] = @regs[op[3]]
      when :OP_APOST
        todo
        
      #
      # String/Symbol
      #
      when :OP_INTERN
        @regs[op[1]] = Runtime.m_str(@regs[op[1]].to_sym)
      when :OP_SYMBOL
        @regs[op[1]] = Runtime.m_sym(rep.pool[op[2]].to_sym)
      when :OP_STRING
        @regs[op[1]] = Runtime.m_str(rep.pool[op[2]])
      when :OP_STRCAT
        @regs[op[1]] = Runtime.invoke_mruby_method(@regs[op[1]], :+, @regs[op[2]])

      #
      # Hash
      #
      when :OP_HASH
        @regs[op[1]] = Hash[*@regs[op[2], op[3]]]
      when :OP_HASHADD
        todo
      when :OP_HASHCAT
        todo

      #
      # Proc
      #
      when :OP_LAMBDA
        todo
      when :OP_BLOCK
        todo
      when :OP_METHOD
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
        @regs[op[1]] = @regs[op[2]..@regs[op[3]]]
      when :OP_RANGE_EXC
        @regs[op[1]] = @regs[op[2]...@regs[op[3]]]

      #
      # Class
      #
      when :OP_OCLASS
        @regs[op[1]] = Object
      when :OP_CLASS
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
        todo

      when :OP_EXEC
        @regs[op[1]] = blockexec(@regs[op[1]], rep.children[op[2]])
      when :OP_DEF
        block = @regs[op[1]+1]
        Runtime.define_mruby_method(@regs[op[1]], rep.syms[op[2]], block)
        @regs[op[1]] = rep.syms[op[2]]
      when :OP_ALIAS
        todo
      when :OP_UNDEF
        todo

      when :OP_SCLASS
        @regs[op[1]] = Runtime.get_singleton_class(@regs[op[1]])
      when :OP_TCLASS
        @regs[op[1]] = @target_class

      # 
      # Misc.
      #
      when :OP_DEBUG
        todo
      when :OP_ERR
        todo
      when :OP_EXT1
        todo
      when :OP_EXT2
        todo
      when :OP_EXT3
        todo
      when :OP_STOP
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
