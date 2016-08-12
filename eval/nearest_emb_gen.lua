require 'dp'
log = require 'log'

cmd = torch.CmdLine()
cmd:text()
cmd:text('Train a LSTM langauge model on definition dataset.')
cmd:text('Options:')
-- Data --
cmd:option('--dataDir', 'data/commondefs', 'dataset directory')
cmd:option('--cuda', false, 'use CUDA')
cmd:option('--embFilepath', 'data/commondefs/auxiliary/emb.t7',
           'path to word embedding torch binary file. See preprocess/prep_w2v.lua')
cmd:option('--outputFile', 'models/nearest/test_nearest.txt', 'file to save output')
cmd:option('--exampleFile', 'train.txt', 'data to copy definitions from')
cmd:option('--wordListFile', 'shortlist_test.txt', 'words to generate definitions')
-- Reporting --
cmd:option('--logFilepath', '', 'Log file path (std by default)')

cmd:text()
opt = cmd:parse(arg or {})

w2i = torch.load(path.join(opt.dataDir, 'word2index.t7'))
i2w = torch.load(path.join(opt.dataDir, 'index2word.t7'))
emb = torch.load(opt.embFilepath)
if opt.cuda then
  require 'cutorch'
  emb = emb:cuda()
end
examples = {}
definitions = {}

for line in io.lines(path.join(opt.dataDir, opt.exampleFile)) do
  local parts = stringx.split(line, '\t')
  local word = parts[1]
  local definition = parts[4]
  if not definitions[word] then definitions[word] = {} end
  table.insert(definitions[word], definition)
  examples[w2i[word]] = true
end
ofp = io.open(path.join(opt.dataDir, opt.outputFile), 'w')
for word in io.lines(path.join(opt.dataDir, opt.wordListFile)) do
  local widx = w2i[word]
  local wemb = emb[widx]
  local dist = emb * wemb
  local v, idx = torch.sort(dist, true)
  local max_example_idx
  for i = 1,idx:size(1) do
    if examples[idx[i]] then
      max_example_idx = idx[i]
      break
    end
  end
  local nearest_defs = definitions[i2w[max_example_idx]]
  for i = 1, #nearest_defs do
    ofp:write(word)
    ofp:write('\t')
    ofp:write(nearest_defs[i])
    ofp:write('\n')
  end
end
ofp:close()