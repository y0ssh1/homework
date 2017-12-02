class Ga
  MAX_GENOM_NUM = 500 #個体数
  SELECT_GENOM = 20 #優秀個体を選択する数
  INDIVIDUAL_MUTATION_PROB = 10 #個体が突然変異を起こす確率(%)
  GENE_MUTATION_PROB = 10 #遺伝子が突然変異を起こす確率(%)
  MAX_GENERATION = 100 #世代数の最大
  MAX_WEIGHT = 6404180 #最大重量
  Genom = Struct.new(:val, :arr) #遺伝子に関する構造体
  Item = Struct.new(:weight, :profit) #荷物に関する構造体

  def initialize
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
      @items.push(Item.new(wight, profits[i]))
    end

    MAX_GENOM_NUM.times { genom_arr.push( Array.new(weights.size, 0).map{ rand(2) } ) }
    genom_arr.each_with_index do |arr, i|
      @genomes.push( Genom.new(0, arr) )
      evaluate(i)
    end
  end

  def evaluate(index)
    value =  @genomes[index].arr.map.with_index { |ele, i|
      ele * @items[i].profit
    }.inject(:+)

    weight = @genomes[index].arr.map.with_index {|ele, i|
      ele * @items[i].weight
    }.inject(:+)

    #もし重量の制限を守っていない場合は劣等個体(価値を１)とする。
    @genomes[index].val = weight > MAX_WEIGHT ? 1 : value
  end

  def select_elite
    # 現行の遺伝子のうち、profitの合計が高いものをエリートとし
    # 指定の個数(SELECT_GENOM)だけ取り出す。
    @genomes.sort_by { |genom| -genom.val }[0..(SELECT_GENOM - 1)]
  end

  def cross_over(elite)
    # elite同士を2点交叉させ新しい個体を作る。
    res = []
    elite.each_slice(2) do |aa, bb|
      start_index = rand(aa.arr.size)
      len = rand(aa.arr.size - start_index)
      range = start_index..(start_index + len)
      aa.arr[range], bb.arr[range] = bb.arr[range], aa.arr[range]
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

  def create_nexts(elite, progeny_genomes)
    # エリート戦略をとるため、優秀個体、優秀個体の交叉からできた個体はすべて残し
    # 現行の遺伝子はその数だけスコアが低いものを淘汰する。
    @genomes.sort_by { |genom| -genom.val }[0..-(2* SELECT_GENOM + 1)] + elite + progeny_genomes
  end

  def calc
    MAX_GENERATION.times do |i|
      elite = select_elite
      progeny_genomes = cross_over(elite)
      next_generation = create_nexts(elite, progeny_genomes)
      mutated_generation = mutating(next_generation)
      #世代交代
      @genomes = Marshal.load(Marshal.dump(mutated_generation))
      #計算し直す
      @genomes.size.times { |i| evaluate(i) }
      max = @genomes.sort_by { |genom| -genom.val }.first.val
      min = @genomes.sort_by { |genom| genom.val }.first.val
      p "======第#{i+1}世代====="
      p "max: #{max}"
      p "min: #{min}"
    end
  end
end

ga = Ga.new()
ga.calc
