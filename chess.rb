class Chess
  BOARD_SIZE = 6

  def initialize
    #initialize board array
    @board = Array.new(Chess::BOARD_SIZE).map{ Array.new(Chess::BOARD_SIZE, 0) }
    @max_count = 0
    @temp_max = 0
    @ans_board = []
  end

  def is_knight_settable(i, j)
    #define knight move
    target_arr = []
    target_arr.push([[i + 1, i - 1], [j + 2, j - 2]])
    target_arr.push([[i + 2, i - 2], [j + 1, j - 1]])
    is_settable(i, j, target_arr)
  end

  def is_king_settable(i, j)
    #define knight move
    target_arr = []
    target_arr.push([[i + 1, i - 1], [j, j + 1, j - 1]])
    target_arr.push([[i], [j + 1, j - 1]])
    is_settable(i, j, target_arr)
  end

  def is_bishop_settable(i, j)
    target_arr = []
    bottom_margin = (Chess::BOARD_SIZE - 1) - i
    right_margin = (Chess::BOARD_SIZE - 1) - j
    [
      [i, right_margin].min,
      [bottom_margin, right_margin].min,
      [bottom_margin, j].min,
      [i, j].min
    ].each_with_index do |v, index|
      v.times do |count|
        case index
        when 0
          target_arr.push([[i - (count + 1)], [j + count + 1]])
        when 1
          target_arr.push([[i + (count + 1)], [j + count + 1]])
        when 2
          target_arr.push([[i + (count + 1)], [j - (count + 1)]])
        when 3
          target_arr.push([[i - (count + 1)], [j - (count + 1)]])
        end
      end
    end
    is_settable(i, j, target_arr)
  end

  def is_settable(i, j, target_arr)
    check = false
    target_arr.each do |arr|
      arr[0].each do |k|
        arr[1].each do |m|
          # when out of board, return false
          if k < 0 || k >= Chess::BOARD_SIZE || m < 0 || m >= Chess::BOARD_SIZE
            check ||= false
          else
            check ||= (@board[k][m] == 1)
          end
        end
      end
    end
    !check
  end

  def search(i, j, type)
    for k in i..Chess::BOARD_SIZE - 1
      # if j has already defined, start m-roop at that point in first k-roop
      n = k == i ? j : 0
      for m in n..Chess::BOARD_SIZE - 1
        # call function according to type string, where k,m are arguments
        if send "is_#{type}_settable", k, m
          @board[k][m] = 1
          m == 5 ? search(k + 1, 0, type) : search(k, m + 1, type)
          @board[k][m] = 0
        end
      end
    end
    score = @board.map{ |line| line.select{|n| n == 1}.size}.inject(:+)
    if @max_count <= score
      if @max_count < score
        @ans_board.clear
      end
      # deep copy
      @max_count = Marshal.load(Marshal.dump(score))
      @ans_board << Marshal.load(Marshal.dump(@board))
    end
  end

  def ans_board
    @ans_board
  end
end

{"king": "♔", "knight": "♘", "bishop": "♗"}.each do |key, val|
  chess = Chess.new()
  chess.search(0, 0, key.to_s)
  p "Count: #{chess.ans_board.size}"
  chess.ans_board.first.each do |line|
    p line.map{ |num| num == 1 ? val : "☓" }
  end
end
