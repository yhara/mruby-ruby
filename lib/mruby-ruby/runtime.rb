module MrubyRuby
  # Design note: Basically BUILTIN_CLASSES or BASIC_OBJECTS should be instance variables of Runtime
  # rather than constants so that you can create multiple Runtime objects to, say, run multiple
  # mruby programs in parallel. However, I chose constants because this project is for educational
  # purposes and I want to keep it simple.
  class Runtime
    class MObj
      def initialize(klass_obj, ivars={}, singleton_class: nil)
        @klass_obj = klass_obj
        @ivars = ivars
        @singleton_klass = singleton_class
      end
      attr_reader :klass_obj

      def mruby_singleton_class
        # Lazily create singleton class (otherwise infinite loop happens on MObj.new)
        of = if @klass_obj == BUILTIN_CLASSES[:Class]
               " of #{ivar_get(:name)}"
             else
               ""
             end
        @singleton_klass ||= MObj.new(BUILTIN_CLASSES[:Class], {
          name: "(singleton#{of})",
          superclass: BUILTIN_CLASSES[:Class],
          instance_methods: {},
        })
      end

      def ivar_get(name)
        @ivars[name]
      end

      def ivar_set(name, value)
        @ivars[name] = value
      end

      # Only used for bootstraping.
      def unsafe_set_class(klass_obj)
        @klass_obj = klass_obj
      end

      def inspect
        klass_name = @klass_obj.ivar_get(:name)
        "#<MObj(#{klass_name}):#{@ivars.inspect}>"
      end
      alias to_s inspect
    end

    BUILTIN_CLASSES = {}
    BUILTIN_CLASSES[:Object] = MObj.new(nil, {
      name: "Object",
      superclass: nil,
      instance_methods: {
        inspect: ->(r, slf) { Runtime.m_str("#<something>") },
        puts: ->(r, _slf, *args) { 
          r.stdout.puts(*args.map{ _1.ivar_get(:content) })
          nil
        },
        p: ->(r, _slf, *args) {
          r.stdout.puts(*args.map{ 
            mstr = r.invoke_mruby_method(_1, "inspect")
            mstr.ivar_get(:content)
          })
          args.length == 1 ? args[0] : args
        },
      }
    })
    BUILTIN_CLASSES[:Class] = MObj.new(nil, {
      name: "Class",
      superclass: BUILTIN_CLASSES[:Object],
      instance_methods: {}
    })
    BUILTIN_CLASSES[:Object].unsafe_set_class(BUILTIN_CLASSES[:Class])
    BUILTIN_CLASSES[:Class].unsafe_set_class(BUILTIN_CLASSES[:Class])
    BUILTIN_CLASSES[:Integer] = MObj.new(BUILTIN_CLASSES[:Class], {
      name: "Integer",
      superclass: BUILTIN_CLASSES[:Object],
      instance_methods: {
        inspect: ->(r, slf) { Runtime.m_str(slf.ivar_get(:content).to_s) },
        "+":  ->(r, slf, other) { Runtime.m_int(slf.ivar_get_get(:content) + other.ivar_get(:content)) },
        "-":  ->(r, slf, other) { Runtime.m_int(slf.ivar_get(:content) - other.ivar_get(:content)) },
        "*":  ->(r, slf, other) { Runtime.m_int(slf.ivar_get(:content) * other.ivar_get(:content)) },
        "/":  ->(r, slf, other) { Runtime.m_int(slf.ivar_get(:content) / other.ivar_get(:content)) },
        ">":  ->(r, slf, other) { Runtime.m_int(slf.ivar_get(:content) > other.ivar_get(:content)) },
        ">=": ->(r, slf, other) { Runtime.m_int(slf.ivar_get(:content) >= other.ivar_get(:content)) },
        "<":  ->(r, slf, other) { Runtime.m_int(slf.ivar_get(:content) < other.ivar_get(:content)) },
        "<=": ->(r, slf, other) { Runtime.m_int(slf.ivar_get(:content) <= other.ivar_get(:content)) },
      }
    })
    BUILTIN_CLASSES[:String] = MObj.new(BUILTIN_CLASSES[:Class], {
      name: "String",
      instance_methods: {
        "+":  ->(r, slf, other) { Runtime.m_str(slf.ivar_get(:content) + other.ivar_get(:content)) },
        "-":  ->(r, slf, other) { Runtime.m_str(slf.ivar_get(:content) - other.ivar_get(:content)) },
        "*":  ->(r, slf, other) { Runtime.m_str(slf.ivar_get(:content) * other.ivar_get(:content)) },
        "/":  ->(r, slf, other) { Runtime.m_str(slf.ivar_get(:content) / other.ivar_get(:content)) },
        ">":  ->(r, slf, other) { Runtime.m_str(slf.ivar_get(:content) > other.ivar_get(:content)) },
        ">=": ->(r, slf, other) { Runtime.m_str(slf.ivar_get(:content) >= other.ivar_get(:content)) },
        "<":  ->(r, slf, other) { Runtime.m_str(slf.ivar_get(:content) < other.ivar_get(:content)) },
        "<=": ->(r, slf, other) { Runtime.m_str(slf.ivar_get(:content) <= other.ivar_get(:content)) },
      }
    })

    BASIC_OBJECTS = {
      true: MObj.new(BUILTIN_CLASSES[:TrueClass]),
      false: MObj.new(BUILTIN_CLASSES[:FalseClass]),
      nil: MObj.new(BUILTIN_CLASSES[:NilClass]),
    }

    BUILTIN_CONSTANTS = BUILTIN_CLASSES.transform_keys(&:to_s)

    def initialize(stdout: $stdout, stderr: $stderr, logger: Logger.new(nil))
      @stdout = stdout
      @stderr = stderr
      @logger = logger
      @global_variables = {}
      @constants = BUILTIN_CONSTANTS.dup
      @main = MObj.new(
        BUILTIN_CLASSES[:Object],
        {},
        singleton_class: MObj.new(BUILTIN_CLASSES[:Class], {
          name: "(singleton of main)",
          superclass: BUILTIN_CLASSES[:Class],
          instance_methods: {
            inspect: ->(_slf) { Runtime.m_str("main") },
          }
        })
      )
    end
    attr_reader :stdout, :stderr
    attr_reader :main

    def gvar_get(name)
      @global_variables[name]
    end

    def gvar_set(name, value)
      @global_variables[name] = value
    end

    # TODO: const namespace
    def const_get(name)
      @constants[name.to_s]
    end
    def const_set(name, value)
      @constants[name.to_s] = value
    end

    # TODO: keyword arguments, etc.
    def invoke_mruby_method(receiver, name, *positional_args)
      method = lookup_mruby_method(receiver, name)
      return method.call(self, receiver, *positional_args)
    end

    private def lookup_mruby_method(mobj, name)
      sing = Runtime.get_singleton_class(mobj)
      if sing
        method = sing.ivar_get(:instance_methods)[name.to_sym]
        return method if method
      end
      cls = mobj.klass_obj
      while cls
        #@logger.debug("lookup_mruby_method(#{name}): cls=#{cls.inspect}")
        method = cls.ivar_get(:instance_methods)[name.to_sym]
        if method
          return method
        else
          cls = cls.ivar_get(:superclass)
        end
      end
      # TODO: raise mruby exception, not Ruby exception
      raise "MRuby method not found: #{name}"
    end

    def self.create_mruby_class(name, sup, &block)
      MObj.new(BUILTIN_CLASSES[:Class], {
        name: name,
        superclass: sup || BUILTIN_CLASSES[:Object],
        instance_methods: {},
      })
    end

    def self.get_singleton_class(mobj)
      mobj.mruby_singleton_class
    end

    def self.define_mruby_method(klass, name, block)
      klass.ivar_get(:instance_methods)[name.to_sym] = block
    end

    def self.ivar_get(mobj, name)
      mobj[:ivars][name]
    end

    def self.ivar_set(mobj, name, value)
      mobj[:ivars][name] = value
    end

    # Get mruby nil
    def self.m_nil
      BASIC_OBJECTS[:nil]
    end

    # Get mruby true/false
    def self.m_bool(b)
      if b
        BASIC_OBJECTS[:true]
      else
        BASIC_OBJECTS[:false]
      end
    end

    # Create mruby int from Ruby int
    def self.m_int(n)
      MObj.new(BUILTIN_CLASSES[:Integer], {content: n})
    end

    # Create mruby string from Ruby string
    def self.m_str(s)
      MObj.new(BUILTIN_CLASSES[:String], {content: s})
    end

    # Create mruby symbol from Ruby string
    def self.m_sym(s)
      MObj.new(BUILTIN_CLASSES[:Symbol], {content: s})
    end
  end
end
