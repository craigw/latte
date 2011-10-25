class HexPresenter
  initialize_with :object

  def to_s
    object.to_s.unpack('H*')[0].scan(/../).join ' '
  end
end
