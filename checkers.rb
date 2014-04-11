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

  def over?
    pieces.none? { |piece| piece.color == :black } ||
    pieces.none? { |piece| piece.color == :red }
  end

  def winner
    return :red if pieces.none? { |piece| piece.color == :black }
    return :black if pieces.none? { |piece| piece.color == :red }

    nil
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

  def has_piece?(pos)
    !self[pos].nil?
  end

  def pieces
    @grid.flatten.compact
  end

  def dup
    new_board = Board.new

    pieces.each do |piece|
      new_piece = piece.dup(new_board)
      new_board.place_piece(new_piece, new_piece.pos)
    end

    new_board
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
end

class Piece
  attr_reader :king, :color, :pos

  def initialize(board, pos, color, king = false)
    @board = board
    @pos = pos
    @color = color
    @king = king

    board.place_piece(self, pos)
  end

  def promote
    @king = true
  end

  def dup(board)
    Piece.new(board, @pos.dup, @color, @king)
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
    @board[@pos] = nil
    @pos = target_pos
    @board.place_piece(self, target_pos)

    maybe_promote
  end

  def slide_valid?(target_pos)
    slide_moves = move_diffs.map { |move_diff| add_pos(@pos, move_diff) }

    if slide_moves.include?(target_pos) && @board[target_pos].nil?
      true
    else
      false
    end
  end

  def perform_jump(target_pos)
    @board[avg_pos(@pos, target_pos)] = nil
    @board[@pos] = nil
    @pos = target_pos
    @board.place_piece(self, target_pos)

    maybe_promote
  end

  def jump_valid?(target_pos)
    jump_moves = move_diffs.map do |move_diff|
      add_pos(@pos, move_diff, move_diff)
    end

    if jump_moves.include?(target_pos) && 
      @board[target_pos].nil? &&
      !@board[avg_pos(@pos, target_pos)].nil? &&
      @board[avg_pos(@pos, target_pos)].color != @color
      true
    else
      false
    end
  end

  def perform_moves(move_sequence)
    if valid_move_seq?(move_sequence)
      perform_moves!(move_sequence)
    else
      raise InvalidMoveError.new("Illegal move sequence!")
    end
  end

  def perform_moves!(move_sequence)
    if move_sequence.count <= 2 #slide or jump
    start_piece = @board[move_sequence.first]
    end_pos = move_sequence.last

      if start_piece.slide_valid?(end_pos)
        start_piece.perform_slide(end_pos)
      elsif start_piece.jump_valid?(end_pos)
        start_piece.perform_jump(end_pos)
      else
        raise InvalidMoveError.new("Illegal move!")
      end
    else
      duped_sequence = move_sequence.dup

      until duped_sequence.count <= 1
        jumping_piece = @board[duped_sequence.first]
        next_pos = duped_sequence[1]

        unless jumping_piece.jump_valid?(next_pos)
          raise InvalidMoveError.new("Illegal move sequence!")
        end

        jumping_piece.perform_jump(next_pos)

        duped_sequence = duped_sequence[1..-1]
      end
    end

  end

  def valid_move_seq?(move_sequence)
    duped_board = @board.dup

    begin
      duped_board[@pos].perform_moves!(move_sequence)
    rescue InvalidMoveError
      return false
    rescue StandardError
      raise "Error processing valid_move_seq?"
    else
      return true
    end
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

    until @board.over?
      begin
        puts @board
        input = gets.chomp
        
        unless input =~ /^([0-7],[0-7]\s)*[0-7],[0-7]$/
          raise "Invalid board position and/or format."
        end

        moves = input.split(" ")
        
        moves.map! do |move|
          move.split(",").map { |coord| Integer(coord) }
        end

        unless @board.has_piece?(moves.first)
          raise InvalidMoveError.new("No piece in start position!")
        end
        
        @board[moves.first].perform_moves(moves)

      rescue InvalidMoveError => e
        print "Invalid input: "
        puts e.message
        retry
      rescue InvalidInputError => e
        puts e.message
        retry
      rescue => e
        print "Other error: "
        puts e.message
      end

      puts "\n"
    end

    puts @board
    puts
    puts "#{@board.winner.to_s.capitalize} wins!"
  end
end

class InvalidInputError < StandardError

end

class InvalidMoveError < StandardError

end

game = Game.new

game.run