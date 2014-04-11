require 'colorize'

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

    enemy_pos = avg_pos(@pos, target_pos)

    if jump_moves.include?(target_pos) && 
      @board[target_pos].nil? &&
      !@board[enemy_pos].nil? && 
      @board[enemy_pos].color != @color
      true
    else
      false
    end
  end

  def perform_moves(move_seq)
    if valid_move_seq?(move_seq)
      perform_moves!(move_seq)
    else
      raise InvalidMoveError.new("Invalid move!")
    end
  end

  def perform_moves!(move_seq)
    if move_seq.count <= 2 #slide or jump
      start_piece = @board[move_seq.first]
      end_pos = move_seq.last

      if start_piece.slide_valid?(end_pos)
        start_piece.perform_slide(end_pos)
      elsif start_piece.jump_valid?(end_pos)
        start_piece.perform_jump(end_pos)
      else
        raise InvalidMoveError.new("Invalid move!")
      end
    else
      duped_seq = move_seq.dup

      until duped_seq.count <= 1
        jumping_piece = @board[duped_seq.shift]
        next_pos = duped_seq.first

        unless jumping_piece.jump_valid?(next_pos)
          raise InvalidMoveError.new("Illegal move sequence!")
        end

        jumping_piece.perform_jump(next_pos)
      end
    end

  end

  def valid_move_seq?(move_seq)
    duped_board = @board.dup

    begin
      duped_board[@pos].perform_moves!(move_seq)
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