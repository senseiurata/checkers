require 'debugger'
require 'colorize'

class Board
  def initialize
    @grid = Array.new(8) { Array.new(8) }
  end

  def place_pieces
    red_init_pos = (0..2).to_a.product((0..7).to_a).select do |pos| 
      (pos.first + pos.last).odd?
    end
    black_init_pos = (5..7).to_a.product((0..7).to_a).select do |pos| 
      (pos.first + pos.last).odd?
    end

    red_init_pos.each do |pos|
      self[pos] = Piece.new(self, pos, :red)
    end
    black_init_pos.each do |pos|
      self[pos] = Piece.new(self, pos, :black)
    end
  end

  def []= (pos, piece)
    row, col = pos
    @grid[row][col] = piece
  end

  def [] (pos)
    row, col = pos
    @grid[row][col]
  end

  def place_piece(piece, pos)
    self[pos] = piece
  end

  def valid_pos?(pos)
    pos.all? { |coord| coord.between?(0, 7) }
  end


  def render
    puts "  #{(0..7).to_a.join(" ")}"
    8.times do |row|
      print "#{row}"
      8.times do |col|
        if @grid[row][col].nil?
          bgcolor = ((row + col).odd? ? :light_black : :light_white)
          print "  ".colorize({ :background => bgcolor })
        else
          print "#{@grid[row][col].to_s} ".colorize({
            :background => :light_black
          })
        end
      end
      puts
    end
  end

  def has_piece?(pos)
    !self[pos].nil? && self[pos].is_a?(Piece)
  end

end

class Piece
  attr_reader :king, :color

  def initialize(board, pos, color)
    @board = board
    @pos = pos
    @color = color
    @king = false

    board.place_piece(self, pos)
  end

  def promote
    @king = true
  end

  def add_pos(*pos)
    pos.inject([0,0]) do |sum, one_pos|
      [sum.first + one_pos.first, sum.last + one_pos.last]
    end
  end

  def avg_pos(pos1, pos2)
    [(pos1.first + pos2.first) / 2, (pos1.last + pos2.last) / 2]
  end

  def perform_slide(target_pos)
    return false unless slide_valid?(target_pos)

    @board[@pos] = nil
    @pos = target_pos
    @board.place_piece(self, target_pos)
  end

  def slide_valid?(target_pos)
    slide_moves = move_diffs.map { |move_diff| add_pos(@pos, move_diff) }

    if !slide_moves.include?(target_pos)
      puts "Cannot slide there"
      false
    elsif !@board[target_pos].nil?
      puts "Piece already exists on target position"
      false
    else
      true
    end
  end

  def perform_jump(target_pos)
    return false unless jump_valid?(target_pos)

    @board[avg_pos(@pos, target_pos)] = nil
    @board[@pos] = nil
    @pos = target_pos
    @board.place_piece(self, target_pos)

    true
  end

  def jump_valid?(target_pos)
    jump_moves = move_diffs.map do |move_diff|
      add_pos(@pos, move_diff, move_diff)
    end

    if !jump_moves.include?(target_pos)
      puts "Cannot jump there"
      false
    elsif !@board[target_pos].nil?
      puts "Piece already exists on target position"
    elsif @board[avg_pos(@pos, target_pos)].nil?
      puts "No piece to jump over"
      false
    elsif @board[avg_pos(@pos, target_pos)].color == @color
      puts "Cannot jump over own piece"
      false
    else
      true
    end
  end

  def move_diffs
    moves = [[1, -1], [1, 1]]

    moves << [-1, -1] << [1, -1] if @king

    if color == :black
      moves.map { |move| [-move.first, move.last] } 
    else
      moves
    end
  end

  def to_s
    if @king
      @color == :black ? "\u26C3".colorize(:black) : "\u26C3".colorize(:red)
    else
      @color == :black ? "\u26C2".colorize(:black) : "\u26C2".colorize(:red)
    end
  end
end

class Game
  def initialize
    @board = Board.new
  end

  def run
    @board.place_pieces

    while true
      begin
      @board.render
      input = gets.chomp
      
      unless input =~ /^.\s[0-7],[0-7]\s[0-7],[0-7]$/
        raise "Invalid board position and/or format."
      end

      type, start_pos, end_pos = input.split(" ")
      start_pos = start_pos.split(",").map { |coord| Integer(coord) }
      end_pos = end_pos.split(",").map { |coord| Integer(coord) }

      raise "No piece in start position" unless @board.has_piece?(start_pos)
      
      if type == 's'
        @board[start_pos].perform_slide(end_pos)
      elsif type == 'j'    
        @board[start_pos].perform_jump(end_pos)
      end

      rescue => e
        puts e.message
        puts e.backtrace
        retry
      end

      puts
    end
  end
end

game = Game.new

game.run
# b.place_pieces

# pos = [5,6]

# b[[4,3]] = Piece.new(b, [4,3], :red)
# b[[4,5]] = Piece.new(b, [4,7], :red)

# b[[5,0]].perform_slide([4, -1])
# b[[5,0]].perform_slide([4, 1])
# b[[4,1]].perform_slide([5, 0])
# b[[2,3]].perform_slide([3, 2])
# b[[3,2]].perform_slide([4, 3])
# b[[3,2]].perform_slide([4, 1])
# b.render