$LOAD_PATH.unshift("#{__dir__}/../lib")
require 'mruby-ruby'

filter = ENV["FILTER"]

ret = 0
Dir.chdir("#{__dir__}/cases") do
  Dir["*.rb"].each do |rb_path|
    next if filter && !rb_path.include?(filter)

    system "mrbc #{rb_path}"
    mrb_path = rb_path.sub(/\.rb$/, '.mrb')
    expected = `mruby #{mrb_path}`
    begin
      given_out, given_err = *MrubyRuby.run_file_and_capture(mrb_path)
      if !given_err.empty?
        puts "[#{mrb_path}] stderr: #{given_err}"
        ret = 1
      end
      if given_out == expected
        puts "[#{mrb_path}] ok"
      else
        puts "[#{mrb_path}] given_out: #{given_out}, expected: #{expected}"
        ret = 1
      end
    rescue => e
      puts "[#{mrb_path}] #{e}"
      raise e
    end
  end
end
exit ret
