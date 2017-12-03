class Ga
  MAX_GENOM_NUM = 800 #個体数
  SELECT_GENOM = 20 #優秀個体を選択する数
  INDIVIDUAL_MUTATION_PROB = 10 #個体が突然変異を起こす確率(%)
  GENE_MUTATION_PROB = 10 #遺伝子が突然変異を起こす確率(%)
  MAX_GENERATION = 50 #世代数の最大
  MAX_WEIGHT = 6404180 #最大重量
  Genom = Struct.new(:val, :weight, :arr, :tmp_val, :tmp_arr) #遺伝子に関する構造体
  Item = Struct.new(:weight, :profit, :index) #荷物に関する構造体

  def initialize(is_heuristics_calculatable, is_type_C)
    # 理論上の最適解は以下
    # MAX_VAL = 13549094

    weights = [382745,799601,909247,729069,467902,
        44328, 34610,698150,823460,903959,853665,551830,
        610856,670702,488960,951111,323046,446298,931161,
        31385,496951,264724,224916,169684]

    profits = [825594,1677009,1676628,1523970,943972,
      97426, 69666,1296457,1679693,1902996,1844992,1049289,
      1252836,1319836,953277,2067538,675367,853655,1826027,
      65731,901489,577243,466257,369261]

    genom_arr = []
    @items = []
    @genomes = []

    weights.each_with_index do |wight, i|
      @items.push(Item.new(wight, profits[i], i))
    end

    MAX_GENOM_NUM.times { genom_arr.push( Array.new(weights.size, 0).map{ rand(2) } ) }
    genom_arr.each_with_index do |arr, i|
      @genomes.push( Genom.new(0, 0, arr, 0, arr) )
      evaluate(i)
      calc_heuristics(i, is_type_C) if is_heuristics_calculatable
    end
  end

  def evaluate(idx)
    # ある個体における価値の総量、総重量を計算する
    value =  @genomes[idx].arr.map.with_index { |ele, i|
      ele * @items[i].profit
    }.inject(:+)

    weight = @genomes[idx].arr.map.with_index {|ele, i|
      ele * @items[i].weight
    }.inject(:+)

    #もし重量の制限を守っていない場合は劣等個体(価値を１)とする。
    @genomes[idx].weight = weight
    @genomes[idx].val = weight > MAX_WEIGHT ? 1 : value
  end

  def calc_heuristics(idx, is_type_C)
    # 欲張り法を用い、できるだけ費用(重量)対効果が良いものを優先につめていったときの
    # profit(tmp_val)を計算する。
    # なお、ラマルク進化型GAの場合(is_type_C = true)は局所探索で改良された個体によって子孫を作るため
    # 局所解をtmp_arrに保存しておく
    additional_weight = 0
    tmp_val = Marshal.load(Marshal.dump(@genomes[idx].val))
    @items.sort_by { |item| - ((item.profit).to_f / item.weight) }.each do |item|
      if @genomes[idx].arr[item.index] == 0 && @genomes[idx].weight + item.weight + additional_weight <= MAX_WEIGHT
        @genomes[idx].tmp_arr[item.index] = 1 if is_type_C
        additional_weight += item.weight
        tmp_val += item.profit
      end
    end
    @genomes[idx].tmp_val = tmp_val
  end

  def select_elite(is_normal)
    # 現行の遺伝子のうち、profitの合計が高いものをエリートとし
    # 指定の個数(SELECT_GENOM)だけ取り出す。
    if is_normal
      @genomes.sort_by { |genom| -genom.val }[0..(SELECT_GENOM - 1)]
    else
      @genomes.sort_by { |genom| -genom.tmp_val }[0..(SELECT_GENOM - 1)]
    end
  end

  def cross_over(elite, is_type_C)
    # elite同士を2点交叉させ新しい個体を作る。
    # ラマルク進化型の場合(is_type_C = true)は局所解(tmp_arr)を用いて交叉をする。
    res = []
    elite.each_slice(2) do |aa, bb|
      start_index = rand(aa.arr.size)
      len = rand(aa.arr.size - start_index)
      range = start_index..(start_index + len)
      if is_type_C
        aa.tmp_arr[range], bb.tmp_arr[range] = bb.tmp_arr[range], aa.tmp_arr[range]
        aa.arr = Marshal.load(Marshal.dump(aa.tmp_arr))
        bb.arr = Marshal.load(Marshal.dump(bb.tmp_arr))
      else
        aa.arr[range], bb.arr[range] = bb.arr[range], aa.arr[range]
      end
      res.push(aa)
      res.push(bb)
    end
    res
  end

  def mutating(genomes)
    genomes = genomes.each_with_index do |genom, i|
      if rand(100) < INDIVIDUAL_MUTATION_PROB
        genom.arr.each_with_index do |element, j|
          if rand(100) < GENE_MUTATION_PROB
            case element
            when 0
              genomes[i].arr[j] = 1
            when 1
              genomes[i].arr[j] = 0
            end
          end
        end
      end
    end
    genomes
  end

  def create_nexts(elite, progeny_genomes, is_normal)
    # エリート戦略をとるため、優秀個体、優秀個体の交叉からできた個体はすべて残し
    # 現行の遺伝子はその数だけスコアが低いものを淘汰する。
    if is_normal
      @genomes.sort_by { |genom| -genom.val }[0..-(2* SELECT_GENOM + 1)] + elite + progeny_genomes
    else
      @genomes.sort_by { |genom| -genom.tmp_val }[0..-(2* SELECT_GENOM + 1)] + elite + progeny_genomes
    end
  end

  def calc(is_normal, is_type_C)
    start_time = Time.now
    MAX_GENERATION.times do |i|
      elite = select_elite(is_normal)
      progeny_genomes = cross_over(elite, is_type_C)
      next_generation = create_nexts(elite, progeny_genomes, is_normal)
      mutated_generation = mutating(next_generation)
      #世代交代
      @genomes = Marshal.load(Marshal.dump(mutated_generation))
      #計算し直す
      @genomes.size.times do |i|
        evaluate(i)
        calc_heuristics(i, is_type_C) unless is_normal
      end
      max = @genomes.sort_by { |genom| -genom.val }.first.val
      min = @genomes.sort_by { |genom| genom.val }.first.val
      p "======第#{i+1}世代====="
      p "max: #{max}"
      p "min: #{min}"
    end
    max = @genomes.sort_by {|genom| -genom.val }.first.val
    array = @genomes.sort_by {|genom| -genom.val }.first.arr
    interval = Time.now - start_time
    p "====================="
    p "max: #{max}"
    p "arr: #{array}"
    p "time: #{interval}"
  end
end

# normal GA
ga = Ga.new(false, false)
ga.calc(true, false)

# ボールドウィン進化型GA
ga = Ga.new(true, false)
ga.calc(false, false)

# ラマルク進化型GA
ga = Ga.new(true, true)
ga.calc(false, true)
