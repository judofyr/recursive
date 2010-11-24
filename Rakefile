require 'grancher/task'
require 'rake/clean'
# Various files/directories:
DATA_DIR = "data"
HTML_DIR = "html"
CSV_FILE = "#{DATA_DIR}/rec.csv"
JSON_FILE = "#{DATA_DIR}/rec.json"
HTML_FILE = "#{DATA_DIR}/rec.html"
BUILT_HTML_FILE = "#{HTML_DIR}/index.html"
TEMPLATE = "misc/rec.template"
CLEAN << FileList[DATA_DIR, HTML_DIR]

# Benchmark settings:
MAX = 100_000
STEPS = 500

desc "Runs benchmark"
task :bench => CSV_FILE

desc "Re-runs the benchmark"
task :rebench => [:clean, :bench]

desc "Builds a JSON-file"
task :json => JSON_FILE

desc "Builds a HTML-file"
task :flot => HTML_FILE

desc "Builds a standalone HTML-directory"
task :build => BUILT_HTML_FILE

directory DATA_DIR
directory HTML_DIR

file CSV_FILE => DATA_DIR do
  require 'benchmark'
  require 'enumerator'
  require './base'

  @fake = []
  @bm = Benchmark.bmbm(20) do |x|
    @job = x
    regular = Fib.new
    rescuef = RescueFib.new
    catchf = CatchFib.new
    redof = RedoFib.new
    iterative = IterativeFib.new
    (STEPS..MAX).step(STEPS) do |n|
       x.report("#{n}|Regular") do
         begin
           regular.fib(n)
         rescue SystemStackError
           @fake << n
         end
       end
       x.report("#{n}|Rescue") { rescuef.fib(n) }
       x.report("#{n}|Catch") { catchf.fib(n) }
       x.report("#{n}|Redo") { redof.fib(n) }
       x.report("#{n}|Iterative") { iterative.fib(n) }
       x.report("#{n}|TCO") { fib(n) } if defined?(fib)
    end 
  end

  @res = Hash.new { |h, k| h[k] = {} }
  @bm.each_with_index do |e, i|
    label = @job.list[i][0]
    i, type = label.split("|")
    i, type = i.to_i, type.strip.downcase.to_sym
    real = e.real
    @res[i][type] = real unless type == :regular && @fake.include?(i)
  end

  File.open(CSV_FILE, "w") do |f|
    f << ["fib(x)", "Regular", "Rescue", "Catch", "Redo", "Iterative", "TCO"] * ',' + $/
    @res.sort_by { |k, v| k }.each do |k, v|
      f << [k, v[:regular], v[:rescue], v[:catch], v[:redo], v[:iterative], v[:tco]] * ',' + $/
    end
  end
end

file JSON_FILE => CSV_FILE do
  puts "** Building JSON"
  require 'json'
  require 'csv'

  table = {}
  header = nil

  File.open(CSV_FILE, "r") do |f|
    f.each_line do |line|
      row = line.chomp.split(",")
      i = row.shift
      if i == "fib(x)"
        header = row
        next
      end
      row.zip(header).each do |value, col|
        value = value.empty? ? nil : value.to_f
        data = table[col.downcase] ||= {
          :label => col,
          :data => []
        }
        data[:data] << [i.to_i, value] unless value.nil?
      end
    end
  end

  File.open(JSON_FILE, "w") do |f|
    f << table.to_json
  end
end

file HTML_FILE => JSON_FILE do
  puts "** Building HTML-file"
  temp = File.read(TEMPLATE)
  data = File.read(JSON_FILE)
  File.open(HTML_FILE, "w") do |f|
    f << temp.gsub("DATASET", data)
  end
end

file BUILT_HTML_FILE => [HTML_FILE, HTML_DIR] do |t|
  puts "** Building standalone HTML-directory"
  cp 'misc/jquery.js', 'html/jquery.js'
  cp 'misc/jquery.flot.js', 'html/jquery.flot.js'
  html = File.read(HTML_FILE).gsub('../misc/', '')
  File.open(BUILT_HTML_FILE, "w") do |f|
    f << html
  end
end

Grancher::Task.new do |g|
  g.branch = 'gh-pages'
  g.push_to = 'origin'
  
  g.directory 'html'
end
