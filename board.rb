require 'colorize'

class Board
  def initialize
    @grid = Array.new(8) { Array.new(8) }
  end

  def place_pieces
    red_init_pos = (0..2).to_a.product((0..7).to_a).select do |row, col| 
      (row + col).odd?
    end
    black_init_pos = (5..7).to_a.product((0..7).to_a).select do |row, col| 
      (row + col).odd?
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

  def validate_start_pos(moves, turn)
    if !has_piece?(moves.first)
      raise InvalidMoveError.new("No piece in start position!")
    elsif self[moves.first].color != turn
      raise InvalidMoveError.new("Cannot move opponent's piece!")
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