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
  def acc(i, n, result)
    if i == -1
      result
    else
      acc(i - 1, n + result, n)
    end
  end

  def fib(i)
    acc(i, 1, 0)
  end
end  

class RescueFib < Fib
  RunAgain = Class.new(Exception)
  
  def acc(i, n, result)
    if i == -1
      result
    else
      raise RunAgain
    end
  rescue RunAgain
    i, n, result = i - 1, n + result, n
    retry
  end
end
  
class CatchFib < Fib 
  tailcall_optimize :acc
end

class RedoFib < Fib
  define_method(:acc) do |i, n, result|
    if i == -1
      result
    else
      i, n, result = i - 1, n + result, n
      redo
    end
  end
end

class IterativeFib < Fib
  def acc(i, n, result)
    until i == -1
      i, n, result = i - 1, n + result, n
    end
    result
  end
end

if defined?(RubyVM::InstructionSequence)
  RubyVM::InstructionSequence.compile_option = {
    :tailcall_optimization => true,
    :trace_instruction => false
  }
  
  RubyVM::InstructionSequence.new(<<-EOF).eval
    def acc(i, n, result)
      if i == -1
        result
      else
        acc(i - 1, n + result, n)
      end
    end

    def fib(i)
      acc(i, 1, 0)
    end
  EOF
end
