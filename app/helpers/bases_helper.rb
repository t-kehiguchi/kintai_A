module BasesHelper

  def getNextBaseNo(bases)
    unless bases.empty?
      return bases.maximum(:baseNo) + 1
    else
      return 1
    end
  end

end