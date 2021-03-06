require 'benchmark'
original_intcodes = File.read(File.join(__dir__, 'input.txt')).split(",").map(&:to_i)
original_intcodes[0] = 2
class IntcodeProcessor
  attr_accessor :intcodes, :parameter_mode, :inputs, :outputs, :relative_base
  def initialize(intcodes, inputs, outputs)
    @intcodes = intcodes
    @parameter_mode = 0
    @inputs = inputs
    @outputs = outputs
    @relative_base = 0
  end

  def finished?
    @finished
  end

  def parse_optcode(optcode)
     bits = optcode.to_s.rjust(5, "0").split('')
     [bits[0], bits[1], bits[2], [bits[3], bits[4]].join].map(&:to_i)
  end

  def index_for(parameter, mode)
    return parameter if mode.zero?
    @relative_base + parameter
  end

  def write_parameter(parameter, index, value)
    mode = @parameter_mode[3 - index]
    return @intcodes[parameter + @relative_base] = value if mode == 2
    return @intcodes[parameter] = value if mode == 1
    return @intcodes[parameter] = value if mode == 0
  end

  def read_parameter(parameter, index, position = 0)
    mode = @parameter_mode[3 - index]
    return @intcodes[parameter + @relative_base] || 0 if mode == 2
    return parameter if mode == 1
    return @intcodes[parameter] || 0 if mode == 0
  end

  def operate
    current_opt_index = 0
    i = 0
    while i <= @intcodes.length
      index = i.dup
      i += 1
      next if index < current_opt_index
      parsed_optcode = parse_optcode(intcodes[index])
      @parameter_mode = parsed_optcode.first(3)
      case parsed_optcode.last
      when 99
        puts 'finished'
        break intcodes
      when 1
        current_opt_index += 4
        section = intcodes[index..(index + 3)]
        write_parameter(section.last, 3, read_parameter(section[1], 1) + read_parameter(section[2], 2))
      when 2
        current_opt_index += 4
        section = @intcodes[index..(index + 3)]
        write_parameter(section.last, 3, read_parameter(section[1], 1) * read_parameter(section[2], 2))
      when 3
        current_opt_index += 2
        section = @intcodes[index..(index + 1)]
        write_parameter(section.last, 1, inputs.shift)
      when 4
        current_opt_index += 2
        section = @intcodes[index..(index + 1)]
        @outputs.push(read_parameter(section[1], 1))
      when 5
        current_opt_index += 3
        section = @intcodes[index..(index + 2)]
        if read_parameter(section[1], 1) != 0
          i = read_parameter(section[2], 2)
          current_opt_index = read_parameter(section[2], 2)
        end
      when 6
        current_opt_index += 3
        section = @intcodes[index..(index + 2)]
        if read_parameter(section[1], 1) == 0
          i = read_parameter(section[2], 2)
          current_opt_index = read_parameter(section[2], 2)
        end
      when 7
        current_opt_index += 4
        section = @intcodes[index..(index + 3)]
        if read_parameter(section[1], 1) < read_parameter(section[2], 2)
          write_parameter(section.last, 3, 1)
        else
          write_parameter(section.last, 3, 0)
        end
      when 8
        current_opt_index += 4
        section = @intcodes[index..(index + 3)]
        if read_parameter(section[1], 1) == read_parameter(section[2], 2)
          write_parameter(section.last, 3, 1)
        else
          write_parameter(section.last, 3, 0)
        end
      when 9
        current_opt_index += 2
        section = @intcodes[index..(index + 1)]
        @relative_base += read_parameter(section.last, 1)
      else
        puts "unknown optcode #{parsed_optcode.last}"
        break "error"
      end
    end
  end
end

@input = Queue.new
@output = Queue.new
thread = Thread.new {
  IntcodeProcessor.new(
    original_intcodes.dup,
    @input,
    @output
  ).tap(&:operate)
}

size = [50, 50]
sleep 0.5
@acc = []
@output.size.times { @acc.push @output.pop }
@width = @acc.map(&:chr).find_index("\n")
@acc = @acc.map(&:chr).each_slice(@width + 1).to_a

def calculate_alignment_parameter(x, y)
  x * y
end

sum = @acc.map.with_index do |row, y|
  row.map.with_index do |cell, x|
    next unless x >= 1 && x <= @width - 1 && y >= 1 && y <= @acc.length
    if cell == '#' && @acc[y][x + 1] == '#' && @acc[y][x - 1] == '#' && @acc[y + 1][x] == '#' && @acc[y - 1][x] == '#'
      calculate_alignment_parameter(x, y)
    end
  end
end.flatten.compact.sum

def send_ascii(str)
  str.chars.map(&:ord).map { |e| @input.push e  }
end

# L,4,L,6,L,8,L,12,L,8,R,12,L,12,L,8,R,12,L,12,
# L,4,L,6,L,8,L,12,L,8,R,12,L,12,R,12,L,6,L,6,L,8,
# L,4,L,6,L,8,L,12,R,12,L,6,L,6,L,8,L,8,R,12,L,12,R,12,L,6,L,6,L,8
send_ascii("A,B,B,A,B,C,A,C,B,C\n")
send_ascii("L,4,L,6,L,8,L,12\n")
send_ascii("L,8,R,12,L,12\n")
send_ascii("R,12,L,6,L,6,L,8\n")
send_ascii("n\n")
sleep 0.5

output = []
loop do
  @output.size.times do
    chr = @output.pop
    if chr < 255
      output.push chr.chr
    else
      output.push chr
    end
  end
  puts output.join
  exit
end

# pp send_ascii('A,B,C,B,A,C')
