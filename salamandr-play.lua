-- salamandr-play
-- a sample slicer for norns
-- by @fardles

-- slice_modes = {'segments', 'beats', 'transient','manual'}

fileselect = require('fileselect')
textentry = require('textentry')
tabutil = require('tabutil')

-- reset variables

  file_name = ""
  sliced_name = ""

-- global variables

  samples = {}
  slices = {}
  waveform_samples = {}
  interval = 0
  waveform_loaded = false
  sample_len = 1
  position = 1
  level = 1.0
  number_slices = 16
  selected_slice = 1
  playing = false
  
  seq = {
    pos = 1,
    start = 1,
    length = number_slices --TODO
  }
  
  latch = 0
  step_latch = {}
  
-- WAVEFORMS
  local interval = 0
  waveform_samples = {}
  scale = 20
  
function init()

  -- softcut setup
  softcut.buffer_clear()
  audio.level_cut(1)
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  softcut.level(1,1)
  softcut.level_slew_time(1,0.1)
  softcut.level_input_cut(1, 1, 1.0)
  softcut.level_input_cut(2, 1, 1.0)
  softcut.pan(1, 0.5)
  softcut.play(1, 0)
  softcut.rate(1, 1)
  softcut.rate_slew_time(1,0.1)
  softcut.loop_start(1, 0)
  softcut.loop_end(1, 350)
  softcut.loop(1, 1)
  softcut.fade_time(1, 0.1)
  softcut.rec(1, 0)
  softcut.rec_level(1, 1)
  softcut.pre_level(1, 1)
  softcut.position(1, 0)
  softcut.buffer(1,1)
  softcut.enable(1, 1)
  softcut.filter_dry(1, 1)

  softcut.phase_quant(1,0.01)
  softcut.poll_start_phase()
  softcut.event_render(on_render)

  -- load a sample

  params:add_trigger('load_s', 'Load sample')
  params:set_action('load_s', function() fileselect.enter(_path.audio,load_file) end)

  -- name of sliced sample

  params:add_trigger('set_sliced_n', 'Sliced sample name')
  params:set_action('set_sliced_n', function() textentry.enter(get_sliced_name,file_name, "") end)

  -- number of slices for segment slicing

  params:add_separator()
  params:add{type = 'number', id = 'set_number_slices',name = 'Number of slices',min = 1,max = 64,default = 16, action = function(x) number_slices = x seq.length = x initialize_samples() slice_segments() end}

redraw()
end

function on_render(ch, start, i, s)
  waveform_samples = s
  interval = i
  print('render')
  redraw()
end

function update_content(buffer,winstart,winend,samples)
  softcut.render_buffer(buffer, winstart, winend - winstart, 256)
end

function load_file(file)
  if file ~= 'cancel' then
    -- get names of folder and file
    local split_at = string.match(file, "^.*()/")
      local folder_name = string.sub(file, 1, split_at)
      sample_name = string.sub(file, split_at + 1)
      print(sample_name)
      
      --set default name for sliced files
      sliced_name = sample_name:gsub(".wav","")
      
      -- load file in softcut
      softcut.buffer_clear_region(1,-1)
      local ch, samples, rate = audio.file_info(file)
      sample_len = samples / rate
      softcut.buffer_clear(1)
      softcut.buffer_read_mono(file, 0, 0, -1, 1, 1)
      softcut.loop_start(1,0)
      softcut.loop_end(1,sample_len)
      waveform_loaded = true
      update_content(1,1,sample_len,128)
      print('loaded')
  end
initialize_samples()
slice_segments()
redraw()
end

function get_sliced_name(name)
  if name ~= nil then
    sliced_name = name
    print(sliced_name)
    initialize_samples()
    slice_segments()
  end
end

function initialize_samples()
  for i=1,number_slices do
    samples[i]={}
    samples[i].start=0
    samples[i].length=0
    local slice_number = i
    if string.len(slice_number) == 1 then slice_number = '0'..i end
    samples[i].name=sliced_name..slice_number
  end
redraw()
end

function slice_segments()
  print(sample_len)
  length_per_segment = sample_len / number_slices
  for i=1,number_slices do
    samples[i].start= 0 + (length_per_segment * (i-1))
    samples[i].length = length_per_segment
    print(samples[i].start)
    print(samples[i].length)
  end
redraw()
end

function write_buffer()

  sliced_folder_path = _path.audio..'salamandr/'..sliced_name

  -- Sanitise folder and file names
  
    local sliced_folder_path_s = sliced_folder_path:gsub(" ","\\ ")

    -- create folder for sliced sample files

  local cmd_create_folder = 'mkdir -p '..sliced_folder_path
  print(cmd_create_folder)
  os.execute(cmd_create_folder)

  -- save buffer as mono file

  for i=1,number_slices do
    local sliced_file_path = sliced_folder_path..'/'..samples[i].name..'.wav'
    local loop_start = samples[i].start
    print(loop_start)
    local loop_length = samples[i].length
    print(loop_length)

    softcut.buffer_write_mono(sliced_file_path, loop_start, loop_length+0.12, 1)
    print('Slice '..i..' saved as '..sliced_file_path)
  end
end

function step()
  while true do
    clock.sync(1)
    print('Playing '..seq.pos)
    softcut.loop(1,0)
    softcut.loop_start(1,samples[seq.pos].start)
    softcut.loop_end(1,samples[seq.pos].start+samples[seq.pos].length)
    softcut.position(1,samples[seq.pos].start)
    softcut.play(1,1)
    seq.pos = seq.pos + 1
    if seq.pos > seq.length then
      seq.pos = seq.start
    elseif seq.pos < seq.start then
      seq.pos = seq.start
    end
  redraw()
  end
end

function key(n,z)
  if n == 1 then
    alt = z==1 
  elseif n == 2 and z == 1 then
    if alt ~= true then
      slice_segments()
    elseif alt == true then
      if playing == false then
        softcut.loop(1,1)
        softcut.loop_start(1,samples[selected_slice].start)
        softcut.loop_end(1,samples[selected_slice].start+samples[selected_slice].length)
        softcut.position(1,samples[selected_slice].start)
        softcut.play(1,1)
        playing = true
      elseif playing == true then
        softcut.play(1,0)
        playing = false
      end
    end
  elseif n ==3 and z == 1 then
      if alt ~= true then
        write_buffer()
      elseif alt == true then
        latch = 1 - latch
          if latch == 1 then
            table.insert(step_latch, clock.run(step))
          elseif latch == 0 then
            for i,v in ipairs(step_latch) do
              clock.cancel(v)
            end
            step_latch = {}
          end
      
      end
  end
end

function enc(n,d)
  if n == 1 then
    selected_slice = util.clamp(selected_slice+d,1,16)
    print(selected_slice)
  elseif n == 2 then
    if alt ~= true then
      -- coarse
      samples[selected_slice].start = util.clamp(samples[selected_slice].start+d/1,0,sample_len)
    elseif alt == true then
      -- fine
      samples[selected_slice].start = util.clamp(samples[selected_slice].start+d/10,0,sample_len)
    end
  elseif n == 3 then
    if alt ~= true then
      -- coarse
      samples[selected_slice].length = util.clamp(samples[selected_slice].length+d/1,0,sample_len-samples[selected_slice].start)
    elseif alt == true then
      -- fine
      samples[selected_slice].length = util.clamp(samples[selected_slice].length+d/10,0,sample_len-samples[selected_slice].start)
    end
  end
softcut.loop_start(1,samples[selected_slice].start)
softcut.loop_end(1,samples[selected_slice].start + samples[selected_slice].length)
redraw()
end

function redraw()
  screen.clear()
  if not waveform_loaded then
    screen.level(15)
    screen.move(62,50)
    screen.text_center("load sample in params")
  else
    local x_pos = 0
    for i,s in ipairs(waveform_samples) do
      screen.level(4)
      local height = util.round(math.abs(s) * (scale*level))
      screen.move(util.linlin(0,128,10,120,x_pos), 35 - height)
      screen.line_rel(0, 2 * height)
      screen.stroke()
      x_pos = x_pos + 1
    end
    for i = 1,number_slices do
      if i == selected_slice then screen.level(15) 
      elseif i == seq.pos and latch == 1 then screen.level(15) 
      else screen.level(2) end
      
      screen.move(util.linlin(0,sample_len,10,120,samples[i].start), 13)
      screen.line_rel(0,40)
      screen.stroke()
      screen.move(util.linlin(0,sample_len,10,120,samples[i].start+samples[i].length),13)
      screen.line_rel(0,40)
      screen.stroke()
    end
    -- for i=1,number_slices+1 do
    --   if i == selected_slice or i == selected_slice + 1 then
    --     screen.level(15)
    --   else screen.level(8) end
    --   screen.move(util.linlin(1,number_slices+1,10,120,i),13)
    --   screen.line_rel(0, 40)
    --   screen.stroke()
    -- end
    screen.level(15)
    screen.move(120,55)
    screen.text(seq.pos)
    screen.move(110,55)
    screen.text(selected_slice)
  end
  screen.update()
end