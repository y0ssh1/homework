class Chess
  def initialize
    #Set Knight at both ends as a default
    @board = []
    8.times do |i|
      if i == 0
        @board.push([1,0,1,0,1,0,1,0])
      else
        @board.push([0,0,0,0,0,0,0,0])
      end
    end
  end

  def is_settable(i, j)
    # if already setting, return false ( can't settable )
    # or if there are 4 knight in one line, return false
    return false if @board[i][j] == 1 || @board.select{ |num| num == 0 }.size == 4
    check = false
    target_arr = []
    target_arr.push([[i + 1, i - 1], [j + 2, j - 2]])
    target_arr.push([[i + 2, i - 2], [j + 1, j - 1]])
    target_arr.each do |arr|
      arr[0].each do |k|
        arr[1].each do |m|
          if k < 0 || k >= 8 || m < 0 || m >= 8
            check ||= false
          else
            check ||= (@board[k][m] == 1)
          end
        end
      end
    end
    !check
  end

  def setKnight
    7.times do |i|
      8.times do |j|
        if is_settable(i + 1, j)
          @board[i + 1][j] = 1
        end
      end
    end
  end

  def board
    @board
  end

end

chess = Chess.new()
chess.setKnight
chess.board.each do |line|
  p line.map{ |num| num == 1 ? "♘" : "☓" }
end
