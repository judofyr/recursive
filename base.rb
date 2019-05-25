class Class
  # Found in [ruby-talk:145593]
  def tailcall_optimize(*methods)
    methods.each do |meth|
      org = instance_method(meth)
      define_method(meth) do |*args|
        if Thread.current[meth]
          throw(:recurse, args)
        else
          Thread.current[meth] = org.bind(self)
          result = catch(:done) do
            loop do
              args = catch(:recurse) do
                throw(:done, Thread.current[meth].call(*args))
              end
            end
          end
          Thread.current[meth] = nil
          result
        end
      end
    end
  end
end

class Fib
  def acc(i, a, b)
    return b if i == 0

    acc(i - 1, b, a + b)
  end

  def fib(i)
    acc(i, 0, 1)
  end
end

class RescueFib < Fib
  RunAgain = Class.new(Exception)
  
  def acc(i, a, b)
    return b if i == 0
    
    raise RunAgain
  rescue RunAgain
    i, a, b = i - 1, b, a + b
    retry
  end
end
  
class CatchFib < Fib 
  tailcall_optimize :acc
end

class RedoFib < Fib
  define_method(:acc) do |i, a, b|
    return b if i == 0

    i, a, b = i - 1, b, a + b
    redo
  end
end

class IterativeFib < Fib
  def acc(i, a, b)
    until i == 0
      i, a, b = i - 1, b, a + b
    end

    b
  end
end

if defined?(RubyVM::InstructionSequence)
  RubyVM::InstructionSequence.compile_option = {
    :tailcall_optimization => true,
    :trace_instruction => false
  }
  
  RubyVM::InstructionSequence.new(<<-EOF).eval
    def acc(i, a, b)
      return b if i == 0

      acc(i - 1, b, a + b)
    end

    def fib(i)
      acc(i, 0, 1)
    end
  EOF
end
