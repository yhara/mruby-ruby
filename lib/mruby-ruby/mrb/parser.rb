module MrubyRuby
  class Mrb
    class Parser
      # Taken from mrubyc/src/opcodes.h
      OPCODES = [
        {name: :OP_NOP        , code: 0x00, operand_type: :Z    }, # no operation
        {name: :OP_MOVE       , code: 0x01, operand_type: :BB   }, # R[a] = R[b]
        {name: :OP_LOADL      , code: 0x02, operand_type: :BB   }, # R[a] = Pool[b]
        {name: :OP_LOADI      , code: 0x03, operand_type: :BB   }, # R[a] = mrb_int(b)
        {name: :OP_LOADINEG   , code: 0x04, operand_type: :BB   }, # R[a] = mrb_int(-b)
        {name: :OP_LOADI__1   , code: 0x05, operand_type: :B    }, # R[a] = mrb_int(-1)
        {name: :OP_LOADI_0    , code: 0x06, operand_type: :B    }, # R[a] = mrb_int(0)
        {name: :OP_LOADI_1    , code: 0x07, operand_type: :B    }, # R[a] = mrb_int(1)
        {name: :OP_LOADI_2    , code: 0x08, operand_type: :B    }, # R[a] = mrb_int(2)
        {name: :OP_LOADI_3    , code: 0x09, operand_type: :B    }, # R[a] = mrb_int(3)
        {name: :OP_LOADI_4    , code: 0x0A, operand_type: :B    }, # R[a] = mrb_int(4)
        {name: :OP_LOADI_5    , code: 0x0B, operand_type: :B    }, # R[a] = mrb_int(5)
        {name: :OP_LOADI_6    , code: 0x0C, operand_type: :B    }, # R[a] = mrb_int(6)
        {name: :OP_LOADI_7    , code: 0x0D, operand_type: :B    }, # R[a] = mrb_int(7)
        {name: :OP_LOADI16    , code: 0x0E, operand_type: :BS   }, # R[a] = mrb_int(b)
        {name: :OP_LOADI32    , code: 0x0F, operand_type: :BSS  }, # R[a] = mrb_int((b<<16)+c)
        {name: :OP_LOADSYM    , code: 0x10, operand_type: :BB   }, # R[a] = Syms[b]
        {name: :OP_LOADNIL    , code: 0x11, operand_type: :B    }, # R[a] = nil
        {name: :OP_LOADSELF   , code: 0x12, operand_type: :B    }, # R[a] = self
        {name: :OP_LOADT      , code: 0x13, operand_type: :B    }, # R[a] = true
        {name: :OP_LOADF      , code: 0x14, operand_type: :B    }, # R[a] = false
        {name: :OP_GETGV      , code: 0x15, operand_type: :BB   }, # R[a] = getglobal(Syms[b])
        {name: :OP_SETGV      , code: 0x16, operand_type: :BB   }, # setglobal(Syms[b], R[a])
        {name: :OP_GETSV      , code: 0x17, operand_type: :BB   }, # R[a] = Special[Syms[b]]
        {name: :OP_SETSV      , code: 0x18, operand_type: :BB   }, # Special[Syms[b]] = R[a]
        {name: :OP_GETIV      , code: 0x19, operand_type: :BB   }, # R[a] = ivget(Syms[b])
        {name: :OP_SETIV      , code: 0x1A, operand_type: :BB   }, # ivset(Syms[b],R[a])
        {name: :OP_GETCV      , code: 0x1B, operand_type: :BB   }, # R[a] = cvget(Syms[b])
        {name: :OP_SETCV      , code: 0x1C, operand_type: :BB   }, # cvset(Syms[b],R[a])
        {name: :OP_GETCONST   , code: 0x1D, operand_type: :BB   }, # R[a] = constget(Syms[b])
        {name: :OP_SETCONST   , code: 0x1E, operand_type: :BB   }, # constset(Syms[b],R[a])
        {name: :OP_GETMCNST   , code: 0x1F, operand_type: :BB   }, # R[a] = R[a]::Syms[b]
        {name: :OP_SETMCNST   , code: 0x20, operand_type: :BB   }, # R[a+1]::Syms[b] = R[a]
        {name: :OP_GETUPVAR   , code: 0x21, operand_type: :BBB  }, # R[a] = uvget(b,c)
        {name: :OP_SETUPVAR   , code: 0x22, operand_type: :BBB  }, # uvset(b,c,R[a])
        {name: :OP_GETIDX     , code: 0x23, operand_type: :B    }, # R[a] = R[a][R[a+1]]
        {name: :OP_SETIDX     , code: 0x24, operand_type: :B    }, # R[a][R[a+1]] = R[a+2]
        {name: :OP_JMP        , code: 0x25, operand_type: :S    }, # pc+=a
        {name: :OP_JMPIF      , code: 0x26, operand_type: :BS   }, # if R[a] pc+=b
        {name: :OP_JMPNOT     , code: 0x27, operand_type: :BS   }, # if !R[a] pc+=b
        {name: :OP_JMPNIL     , code: 0x28, operand_type: :BS   }, # if R[a]==nil pc+=b
        {name: :OP_JMPUW      , code: 0x29, operand_type: :S    }, # unwind_and_jump_to(a)
        {name: :OP_EXCEPT     , code: 0x2A, operand_type: :B    }, # R[a] = exc
        {name: :OP_RESCUE     , code: 0x2B, operand_type: :BB   }, # R[b] = R[a].isa?(R[b])
        {name: :OP_RAISEIF    , code: 0x2C, operand_type: :B    }, # raise(R[a]) if R[a]
        {name: :OP_SSEND      , code: 0x2D, operand_type: :BBB  }, # R[a] = self.send(Syms[b],R[a+1]..,R[a+n+1]:R[a+n+2]..) (c=n|k<<4)
        {name: :OP_SSENDB     , code: 0x2E, operand_type: :BBB  }, # R[a] = self.send(Syms[b],R[a+1]..,R[a+n+1]:R[a+n+2]..,&R[a+n+2k+1])
        {name: :OP_SEND       , code: 0x2F, operand_type: :BBB  }, # R[a] = R[a].send(Syms[b],R[a+1]..,R[a+n+1]:R[a+n+2]..) (c=n|k<<4)
        {name: :OP_SENDB      , code: 0x30, operand_type: :BBB  }, # R[a] = R[a].send(Syms[b],R[a+1]..,R[a+n+1]:R[a+n+2]..,&R[a+n+2k+1])
        {name: :OP_CALL       , code: 0x31, operand_type: :Z    }, # R[0] = self.call(frame.argc, frame.argv)
        {name: :OP_SUPER      , code: 0x32, operand_type: :BB   }, # R[a] = super(R[a+1],... ,R[a+b+1])
        {name: :OP_ARGARY     , code: 0x33, operand_type: :BS   }, # R[a] = argument array (16=m5:r1:m5:d1:lv4)
        {name: :OP_ENTER      , code: 0x34, operand_type: :W    }, # arg setup according to flags (23=m5:o5:r1:m5:k5:d1:b1)
        {name: :OP_KEY_P      , code: 0x35, operand_type: :BB   }, # R[a] = kdict.key?(Syms[b])
        {name: :OP_KEYEND     , code: 0x36, operand_type: :Z    }, # raise unless kdict.empty?
        {name: :OP_KARG       , code: 0x37, operand_type: :BB   }, # R[a] = kdict[Syms[b]]; kdict.delete(Syms[b])
        {name: :OP_RETURN     , code: 0x38, operand_type: :B    }, # return R[a] (normal)
        {name: :OP_RETURN_BLK , code: 0x39, operand_type: :B    }, # return R[a] (in-block return)
        {name: :OP_BREAK      , code: 0x3A, operand_type: :B    }, # break R[a]
        {name: :OP_BLKPUSH    , code: 0x3B, operand_type: :BS   }, # R[a] = block (16=m5:r1:m5:d1:lv4)
        {name: :OP_ADD        , code: 0x3C, operand_type: :B    }, # R[a] = R[a]+R[a+1]
        {name: :OP_ADDI       , code: 0x3D, operand_type: :BB   }, # R[a] = R[a]+mrb_int(b)
        {name: :OP_SUB        , code: 0x3E, operand_type: :B    }, # R[a] = R[a]-R[a+1]
        {name: :OP_SUBI       , code: 0x3F, operand_type: :BB   }, # R[a] = R[a]-mrb_int(b)
        {name: :OP_MUL        , code: 0x40, operand_type: :B    }, # R[a] = R[a]*R[a+1]
        {name: :OP_DIV        , code: 0x41, operand_type: :B    }, # R[a] = R[a]/R[a+1]
        {name: :OP_EQ         , code: 0x42, operand_type: :B    }, # R[a] = R[a]==R[a+1]
        {name: :OP_LT         , code: 0x43, operand_type: :B    }, # R[a] = R[a]<R[a+1]
        {name: :OP_LE         , code: 0x44, operand_type: :B    }, # R[a] = R[a]<=R[a+1]
        {name: :OP_GT         , code: 0x45, operand_type: :B    }, # R[a] = R[a]>R[a+1]
        {name: :OP_GE         , code: 0x46, operand_type: :B    }, # R[a] = R[a]>=R[a+1]
        {name: :OP_ARRAY      , code: 0x47, operand_type: :BB   }, # R[a] = ary_new(R[a],R[a+1]..R[a+b])
        {name: :OP_ARRAY2     , code: 0x48, operand_type: :BBB  }, # R[a] = ary_new(R[b],R[b+1]..R[b+c])
        {name: :OP_ARYCAT     , code: 0x49, operand_type: :B    }, # ary_cat(R[a],R[a+1])
        {name: :OP_ARYPUSH    , code: 0x4A, operand_type: :BB   }, # ary_push(R[a],R[a+1]..R[a+b])
        {name: :OP_ARYDUP     , code: 0x4B, operand_type: :B    }, # R[a] = ary_dup(R[a])
        {name: :OP_AREF       , code: 0x4C, operand_type: :BBB  }, # R[a] = R[b][c]
        {name: :OP_ASET       , code: 0x4D, operand_type: :BBB  }, # R[b][c] = R[a]
        {name: :OP_APOST      , code: 0x4E, operand_type: :BBB  }, # *R[a],R[a+1]..R[a+c] = R[a][b..]
        {name: :OP_INTERN     , code: 0x4F, operand_type: :B    }, # R[a] = intern(R[a])
        {name: :OP_SYMBOL     , code: 0x50, operand_type: :BB   }, # R[a] = intern(Pool[b])
        {name: :OP_STRING     , code: 0x51, operand_type: :BB   }, # R[a] = str_dup(Pool[b])
        {name: :OP_STRCAT     , code: 0x52, operand_type: :B    }, # str_cat(R[a],R[a+1])
        {name: :OP_HASH       , code: 0x53, operand_type: :BB   }, # R[a] = hash_new(R[a],R[a+1]..R[a+b*2-1])
        {name: :OP_HASHADD    , code: 0x54, operand_type: :BB   }, # hash_push(R[a],R[a+1]..R[a+b*2])
        {name: :OP_HASHCAT    , code: 0x55, operand_type: :B    }, # R[a] = hash_cat(R[a],R[a+1])
        {name: :OP_LAMBDA     , code: 0x56, operand_type: :BB   }, # R[a] = lambda(Irep[b],L_LAMBDA)
        {name: :OP_BLOCK      , code: 0x57, operand_type: :BB   }, # R[a] = lambda(Irep[b],L_BLOCK)
        {name: :OP_METHOD     , code: 0x58, operand_type: :BB   }, # R[a] = lambda(Irep[b],L_METHOD)
        {name: :OP_RANGE_INC  , code: 0x59, operand_type: :B    }, # R[a] = range_new(R[a],R[a+1],FALSE)
        {name: :OP_RANGE_EXC  , code: 0x5A, operand_type: :B    }, # R[a] = range_new(R[a],R[a+1],TRUE)
        {name: :OP_OCLASS     , code: 0x5B, operand_type: :B    }, # R[a] = ::Object
        {name: :OP_CLASS      , code: 0x5C, operand_type: :BB   }, # R[a] = newclass(R[a],Syms[b],R[a+1])
        {name: :OP_MODULE     , code: 0x5D, operand_type: :BB   }, # R[a] = newmodule(R[a],Syms[b])
        {name: :OP_EXEC       , code: 0x5E, operand_type: :BB   }, # R[a] = blockexec(R[a],Irep[b])
        {name: :OP_DEF        , code: 0x5F, operand_type: :BB   }, # R[a].newmethod(Syms[b],R[a+1]); R[a] = Syms[b]
        {name: :OP_ALIAS      , code: 0x60, operand_type: :BB   }, # alias_method(target_class,Syms[a],Syms[b])
        {name: :OP_UNDEF      , code: 0x61, operand_type: :B    }, # undef_method(target_class,Syms[a])
        {name: :OP_SCLASS     , code: 0x62, operand_type: :B    }, # R[a] = R[a].singleton_class
        {name: :OP_TCLASS     , code: 0x63, operand_type: :B    }, # R[a] = target_class
        {name: :OP_DEBUG      , code: 0x64, operand_type: :BBB  }, # print a,b,c
        {name: :OP_ERR        , code: 0x65, operand_type: :B    }, # raise(LocalJumpError, Pool[a])
        {name: :OP_EXT1       , code: 0x66, operand_type: :Z    }, # make 1st operand (a) 16bit
        {name: :OP_EXT2       , code: 0x67, operand_type: :Z    }, # make 2nd operand (b) 16bit
        {name: :OP_EXT3       , code: 0x68, operand_type: :Z    }, # make 1st and 2nd operands 16bit
        {name: :OP_STOP       , code: 0x69, operand_type: :Z    }, # stop VM
      ]
      OP_TABLE = OPCODES.map { |op| [op[:code], op] }.to_h

      def initialize(bin)
        @bin = bin
        @cur = 0
      end

      def parse
        p bytesize: @bin.bytesize
        ident, major, minor, size, compiler, ver = read(20,"Z4 Z2 Z2 I> Z4 Z4")
        if ident != "RITE"
          raise "not a mruby binary"
        end
        p ident:, major:, minor:, size:, compiler:, ver:;

        until all_read?
          type, size = read(8, "a4 I>")
          p type:, size:;
          case type
          when "IREP"
            irep_ver, = read(4, "a4")
            p irep_ver:;
            parse_irep(size)
          when "LVAR"
            read(size, "C#{size}")
          when "DBG\0"
            raise "[TODO] section type #{type}"
          when "END\0"
            break
          else
            raise "unknown section type #{type}"
          end
        end
      end

      def parse_irep(size)
        start = @cur
        # rlen = number of child ireps
        # clen = number of catch handlers
        # ilen = opecode length
        record_size, nlocals, nregs, rlen, clen, ilen = read(16, "I> S> S> S> S> I>")
        p record_size:, nlocals:, nregs:, rlen:, clen:, ilen:;
        parse_iseqs(ilen)

        parse_pool_block

        parse_syms_block

        p read: @cur - start, size: size
        rlen.times do |i|
          p child: [i]
          parse_irep(size)
        end
      end

      def parse_iseqs(ilen)
        start = @cur
        while @cur - start < ilen
          code, = read(1, "C")
          op = OP_TABLE[code] or raise("unknown opcode 0x%x" % code)
          case op[:operand_type]
          when :B
            a, = read(1, "C")
            p op: op, a: a
          when :BB
            a, b = read(2, "CC")
            p op: op, a: a, b: b
          when :BBB
            a, b, c = read(3, "CCC")
            p op: op, a: a, b: b, c: c
          when :BS
            a, b = read(3, "CS>")
            p op: op, a: a, b: b
          when :BSS
            a, b, c = read(5, "CSS>")
            p op: op, a: a, b: b, c: c
          when :W
            a, = read(2, "S>")
            p op: op, a: a
          when :Z
            p op: op
          else
            raise "[TODO] operand type #{op[:operand_type]}"
          end
        end
      end

      def parse_pool_block
        n_literals, = read(2, "S>")
        p n_literals:;
        n_literals.times do
          lit_type, lit_len = read(3, "C S>")
          p lit_type:, lit_len:;
          # mruby/include/mruby/irep.h:
          # IREP_TT_STR   = 0,          /* string (need free) */
          # IREP_TT_SSTR  = 2,          /* string (static) */
          # IREP_TT_INT32 = 1,          /* 32bit integer */
          # IREP_TT_INT64 = 3,          /* 64bit integer */
          # IREP_TT_BIGINT = 7,         /* big integer (not yet supported) */
          # IREP_TT_FLOAT = 5,          /* float (double/float) */
          case lit_type
          when 0
            lit_body, = read(lit_len, "Z#{lit_len}")
            p lit_body:;
            read(1, "C") # null terminator
          else
            raise "[TODO] literal type #{lit_type}"
          end
        end
      end

      def parse_syms_block
        n_syms, = read(2, "S>")
        p n_syms:;
        n_syms.times do
          sym_len, = read(2, "S>")
          sym_body, = read(sym_len, "Z#{sym_len}")
          p sym_body:;
          read(1, "C") # null terminator
        end
      end

      def peek(n, fmt)
        @bin[@cur, n].unpack(fmt)
      end

      def read(n, fmt)
        peek(n, fmt).tap { @cur += n }
      end

      def all_read?
        @cur >= @bin.bytesize
      end
    end
  end
end
