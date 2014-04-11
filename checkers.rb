require 'colorize'
require './board'
require './piece'
require './errors'

class Game
  def initialize
    @board = Board.new
    @turn = :black
  end

  def change_turn
    @turn == :black ? (@turn = :red) : (@turn = :black)
  end

  def prompt_input
    puts "#{@turn.to_s.capitalize}'s turn."
    puts "Enter start/end coordinate delimited by space and coordinates delimited by commas."
    puts "(e.g. 5,2 4,3): "

    gets.chomp
  end

  def process_to_moves(input)
    moves = input.split(" ")
    
    moves.map! do |move|
      move.split(",").map { |coord| Integer(coord) }
    end
  end

  def run
    @board.place_pieces

    until @board.over?
      begin
        puts @board
        puts

        input = prompt_input

        unless input =~ /^([0-7],[0-7]\s)*[0-7],[0-7]$/
          raise "Invalid board position and/or format!"
        end

        moves = process_to_moves(input)

        if !@board.has_piece?(moves.first)
          raise InvalidMoveError.new("No piece in start position!")
        elsif @board[moves.first].color != @turn
          raise InvalidMoveError.new("Cannot move opponent's piece!")
        end
        
        @board[moves.first].perform_moves(moves, @turn)

      rescue InvalidMoveError => e
        print "Invalid input: "
        puts e.message
        puts
        retry
      rescue InvalidInputError => e
        puts e.message
        puts
        retry
      rescue => e
        print "Other error: "
        puts e.message
        puts
      else
        change_turn
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