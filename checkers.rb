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

  def []=(pos, piece)
    row, col = pos
    @grid[row][col] = piece
  end

  def [](pos)
    row, col = pos
    @grid[row][col]
  end

  def place_piece(piece, pos)
    self[pos] = piece
  end

  def valid_pos?(pos)
    pos.all? { |coord| coord.between?(0, 7) }
  end


  def to_s
    str = ""
    
    str << "  #{(0..7).to_a.join(" ")}\n"

    8.times do |row|
      str << "#{row}"

      8.times do |col|
        if @grid[row][col].nil?
          bgcolor = ((row + col).odd? ? :light_black : :light_white)
          
          str << "  ".colorize({ :background => bgcolor })
        else
          str << "#{@grid[row][col].to_s} ".colorize({
            :background => :light_black
          })
        end
      end

      str << "\n"
    end

    str
  end

  def has_piece?(pos)
    !self[pos].nil?
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
    validate_slide(target_pos)

    @board[@pos] = nil
    @pos = target_pos
    @board.place_piece(self, target_pos)

    maybe_promote
  end

  def validate_slide(target_pos)
    slide_moves = move_diffs.map { |move_diff| add_pos(@pos, move_diff) }

    if !slide_moves.include?(target_pos)
      raise InvalidInputError.new("Cannot slide to target location")
    elsif !@board[target_pos].nil?
      raise InvalidInputError.new("Piece already exists on target position")
    end
  end

  def perform_jump(target_pos)
    validate_jump(target_pos)

    @board[avg_pos(@pos, target_pos)] = nil
    @board[@pos] = nil
    @pos = target_pos
    @board.place_piece(self, target_pos)

    maybe_promote
  end

  def validate_jump(target_pos)
    jump_moves = move_diffs.map do |move_diff|
      add_pos(@pos, move_diff, move_diff)
    end

    if !jump_moves.include?(target_pos)
      raise InvalidInputError.new("Cannot jump to target location")
    elsif !@board[target_pos].nil?
      raise InvalidInputError.new("Piece already exists on target position")
    elsif @board[avg_pos(@pos, target_pos)].nil?
      raise InvalidInputError.new("No piece to jump over")
    elsif @board[avg_pos(@pos, target_pos)].color == @color
      raise InvalidInputError.new("Cannot jump over own piece")
    end
  end

  def perform_moves!(move_sequence)

  end

  def maybe_promote
    promote if on_last_row?
  end

  def on_last_row?
    (@color == :black && @pos.first == 0) || 
    (@color == :red && @pos.first == 7)
  end

  def move_diffs
    moves = [[1, -1], [1, 1]]

    moves << [-1, -1] << [-1, 1] if @king

    if @color == :black
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
        puts @board
        input = gets.chomp
        
        unless input =~ /^.\s[0-7],[0-7]\s[0-7],[0-7]$/
          raise "Invalid board position and/or format."
        end

        type, start_pos, end_pos = input.split(" ")
        start_pos = start_pos.split(",").map { |coord| Integer(coord) }
        end_pos = end_pos.split(",").map { |coord| Integer(coord) }

        unless @board.has_piece?(start_pos)
          raise InvalidInputError.new("No piece in start position")
        end
        
        if type == 's'
          @board[start_pos].perform_slide(end_pos)
        elsif type == 'j'    
          @board[start_pos].perform_jump(end_pos)
        end

      rescue InvalidInputError => e
        puts "Invalid input!"
        puts e.message
        puts
        retry
      rescue => e
        puts "Unknown error"
        puts e.message
        puts e.backtrace
        puts
      end

      puts
    end
  end
end

class InvalidInputError < StandardError

end

class InvalidMoveError < StandardError

end

game = Game.new

game.run