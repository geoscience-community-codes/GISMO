function ct = ChannelTag(scnl)
   %ChannelTag Converter from scnlobject to ChannelTag
  ct = reshape([scnl.tag],size(scnl));
end