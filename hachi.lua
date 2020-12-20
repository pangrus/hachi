-- hachi
-- 808 drum machine for norns
-- V2.2 @pangrus
-- https://llllllll.co/t/hachi-euclidean-drum-machine/35947
--
-- k1 shift
-- k1+k3 clear all (if stopped)
-- k1+k3 randomize (if started)
-- k2 start/stop
-- k3 insert step (if started)
-- k3 randomize all (if stopped)
-- e1 drum select
-- e2 drum parameter 1
-- e3 drum parameter 2
-- e1+k1 rotate pattern
-- e2+k1 number of pulses
-- e3+k1 number of steps

-- hachi means 8
engine.name = "Hachi"

-- euclidean rhythms
er = require "er"

-- variables
local drum = {}
local drum_number = 7
local name = {"BD", "CH", "OH",  "SD", "CP", "CW", "CL"}
local reset = false
local is_running = false
local selected = 1
local shift = false

-- midi clock management
local MIDI_Clock = require "beatclock"
local clk = MIDI_Clock.new()
local clk_midi = midi.connect()

function init()
    -- font and size
    screen.font_face(0)
    screen.font_size(8)
    screen.aa(0)
    screen.line_width(1)

    -- reduce encoders sensitivity
    norns.enc.sens(1, 3)
    norns.enc.sens(2, 3)
    norns.enc.sens(3, 3)

    -- clock management
    clk_midi.event = function(data)
        clk:process_midi(data)
    end
    clk.on_step = execute_step
    clk.on_select_internal = function()
        clk:start()
    end
    clk.on_select_external = reset_sequence
    clk.on_start = reset_sequence
  
    -- parameters
   params:set('reverb', 1)
   params:add_separator("clock parameters")
    clk:add_clock_params()

    params:add_separator("pattern parameters")
    for i = 1, drum_number do
        params:add {
            type = "number",
            id = name[i] .. " rotation",
            name = name[i] .. " rotation",
            min = 0,
            max = 32,
            default = 0,
            action = function()
                selected = i
                generate_patterns()
            end
        }
        params:add {
            type = "number",
            id = name[i] .. " pulses",
            name = name[i] .. " pulses",
            min = 0,
            max = 32,
            default = 0,
            action = function()
                selected = i
                generate_patterns()
            end
        }
        params:add {
            type = "number",
            id = name[i] .. " steps",
            name = name[i] .. " steps",
            min = 1,
            max = 32,
            default = 16,
            action = function()
                selected = i
                generate_patterns()
            end
        }
    end
    params:add_separator("sound parameters")
    params:add {
        type = "number",
        id = "BD tone",
        name = "BD tone",
        min = 45,
        max = 300,
        default = 60,
        action = function(x)
            selected = 1
            engine.kick_tone(x)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "BD decay",
        name = "BD decay",
        min = 1,
        max = 35,
        default = 25,
        action = function(x)
            selected = 1
            engine.kick_decay(x)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "BD level",
        name = "BD level",
        min = 0,
        max = 100,
        default = 100,
        action = function(x)
            engine.kick_level(x/100)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "CH tone",
        name = "CH tone",
        min = 50,
        max = 1000,
        default = 500,
        action = function(x)
            selected = 2
            engine.ch_tone(x)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "CH decay",
        name = "CH decay",
        min = 10,
        max = 30,
        default = 15,
        action = function(x)
            selected = 2
            engine.ch_decay(x / 10)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "CH level",
        name = "CH level",
        min = 0,
        max = 100,
        default = 90,
        action = function(x)
            engine.ch_level(x/100)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "OH tone",
        name = "OH tone",
        min = 50,
        max = 1000,
        default = 400,
        action = function(x)
            selected = 3
            engine.oh_tone(x)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "OH decay",
        name = "OH decay",
        min = 10,
        max = 40,
        default = 15,
        action = function(x)
            selected = 3
            engine.oh_decay(x / 10)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "OH level",
        name = "OH level",
        min = 0,
        max = 100,
        default = 80,
        action = function(x)
            engine.oh_level(x/100)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "SD tone",
        name = "SD tone",
        min = 50,
        max = 1000,
        default = 300,
        action = function(x)
            selected = 3
            engine.snare_tone(x)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "SD snappy",
        name = "SD snappy",
        min = 1,
        max = 300,
        default = 130,
        action = function(x)
            selected = 3
            engine.snare_snappy(x / 100)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "SD level",
        name = "SD level",
        min = 0,
        max = 100,
        default = 70,
        action = function(x)
            engine.snare_level(x/100)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "CP level",
        name = "CP level",
        min = 0,
        max = 100,
        default = 50,
        action = function(x)
            engine.clap_level(x/100)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "CW level",
        name = "CW level",
        min = 0,
        max = 100,
        default = 40,
        action = function(x)
            engine.cowbell_level(x/100)
            redraw()
        end
    }
    params:add {
        type = "number",
        id = "CL level",
        name = "CL level",
        min = 0,
        max = 100,
        default = 30,
        action = function(x)
            engine.claves_level(x/100)
            redraw()
        end
    }
   
    reset_sequence()
    init_patterns()
    generate_patterns()
    load_state()
    selected = 1
end

function init_patterns()
    for i = 1, drum_number do
        drum[i] = {
            position = 1,
            pattern = {},
            rotated = {}
        }
    end
    -- instant gratification :-)
    for i = 1, drum_number do
        randomize_pattern(i)
    end
    -- default rotation parameter for hi hat and snare
    params:set("CH rotation", 2)
    params:set("OH rotation", 2)
    params:set("SD rotation", 4)
end

function clear_patterns()
    for i = 1, drum_number do
        drum[i] = {
            position = 1,
            pattern = {},
            rotated = {}
        }
        params:set(name[i] .. " rotation", 0)
        params:set(name[i] .. " pulses", 0)
        params:set(name[i] .. " steps", 16)
    end
    
    -- uncomment and expand to your personal taste
    -- default rotation parameter for hi hat and snare
    -- params:set("CH rotation", 2)
    -- params:set("OH rotation", 2)
    -- params:set("SD rotation", 4)
end

function randomize_pattern(sel)
    params:set(name[sel] .. " pulses", math.floor(math.random(6)))
    generate_patterns()
 --   selected = sel
end

function generate_patterns()
    for i = 1, drum_number do
        if params:get(name[i] .. " pulses") == 0 then
            for n = 1, 32 do
                drum[i].pattern[n] = false
            end
        else
            drum[i].pattern = er.gen(params:get(name[i] .. " pulses"), params:get(name[i] .. " steps"))
        end
        rotate_pattern(i)
    end
    redraw()
end

function rotate_pattern(i)
    for n = 1, params:get(name[i] .. " rotation") do
        drum[i].rotated[n] = drum[i].pattern[params:get(name[i] .. " steps") - params:get(name[i] .. " rotation") + n]
    end
    for n = 1, params:get(name[i] .. " steps") - params:get(name[i] .. " rotation") do
        drum[i].rotated[n + params:get(name[i] .. " rotation")] = drum[i].pattern[n]
    end
end

function execute_step()
    if reset then
        for i = 1, drum_number do
            drum[i].position = 1
        end
        reset = false
    else
        for i = 1, drum_number do
            drum[i].position = (drum[i].position % params:get(name[i] .. " steps") + 1)
        end
    end
    trigger_drum()
    redraw()
end

function trigger_drum()
    for i = 1, drum_number do
        if drum[i].rotated[drum[i].position] then
            if i == 1 then
                engine.kick_trigger(1)
            end
            if i == 2 then
                engine.ch_trigger(1)
            end
            if i == 3 then
                engine.oh_trigger(1)
            end
            if i == 4 then
                engine.snare_trigger(1)
            end
            if i == 5 then
                engine.clap_trigger(1)
            end
            if i == 6 then
                engine.cowbell_trigger(1)
            end
            if i == 7 then
                engine.claves_trigger(1)
            end
        end
    end
end

function reset_sequence()
    reset = true
    clk:reset()
end

function key(n, z)
    -- shift
    if n == 1 and z == 1 then
        shift = true
    elseif n == 1 and z == 0 then
        shift = false
    end

    -- start/stop
    if n == 2 and z == 1 and is_running then
        reset_sequence()
        clk:stop()
        is_running = false
        save_state()
    elseif n == 2 and z == 1 and is_running == false then
        reset_sequence()
        clk:start()
        is_running = true
        save_state()
    end

    -- real time programming
    if n == 3 and z == 1 and is_running and not shift then
        if selected == 1 then
            engine.kick_trigger(1)
        end
        if selected == 2 then
            engine.ch_trigger(1)
        end
        if selected == 3 then
            engine.oh_trigger(1)
        end
        if selected == 4 then
            engine.snare_trigger(1)
        end
        if selected == 5 then
            engine.clap_trigger(1)
        end
        if selected == 6 then
            engine.cowbell_trigger(1)
        end
        if selected == 7 then
            engine.claves_trigger(1)
        end
        drum[selected].rotated[drum[selected].position] = "true"
    end

    -- randomize all pattern
    if n == 3 and z == 1 and not is_running and not shift then
        for i = 1, drum_number do
            randomize_pattern(i)
        end
        selected = 1 
    end

    -- randomize selected pattern
    if n == 3 and z == 1 and is_running and shift then
        randomize_pattern(selected)
    end

    -- clear patterns
    if n == 3 and z == 1 and shift and not is_running then
        clear_patterns()
    end
    redraw()
end

function enc(n, d)
    if n == 1 and shift == false then
        selected = util.clamp(selected + d, 1, drum_number)
        redraw()
    end

    if shift == true then
        if n == 1 then
            params:set(name[selected] .. " rotation", util.clamp(params:get(name[selected] .. " rotation") + d, 0, params:get(name[selected] .. " steps")))
            rotate_pattern(selected)
        end

        if n == 2 then
            params:set(name[selected] .. " pulses", util.clamp(params:get(name[selected] .. " pulses") + d, 0, params:get(name[selected] .. " steps")))
        end
        if n == 3 then
            params:delta(name[selected] .. " steps", d)
            params:set(name[selected] .. " pulses", util.clamp(params:get(name[selected] .. " pulses"), 0, params:get(name[selected] .. " steps")))
            params:set(name[selected] .. " rotation", util.clamp(params:get(name[selected] .. " rotation"), 0, params:get(name[selected] .. " steps")))
        end
        generate_patterns()
    end
    if shift == false then

        --kick parameters
        if selected == 1 then
            if n == 2 then
                params:delta("BD tone", d)
            end
            if n == 3 then
                params:delta("BD decay", d)
            end
        end

        -- ch parameters
        if selected == 2 then
            if n == 2 then
                params:delta("CH tone", d)
            end
            if n == 3 then
                params:delta("CH decay", d)
            end
        end

        -- oh parameters
        if selected == 3 then
            if n == 2 then
                params:delta("OH tone", d)
            end
            if n == 3 then
                params:delta("OH decay", d)
            end
        end

        -- snare parameters
        if selected == 4 then
            if n == 2 then
                params:delta("SD tone", d)
            end
            if n == 3 then
                params:delta("SD snappy", d)
            end
        end
    end
end

function save_state()
  params:write(_path.data .. "hachi/hachi.pset")
  local file = io.open(_path.data .. "hachi/hachi_pattern.data", "w+")
  io.output(file)
  io.write("hachi pattern file v2.1" .. "\n")
    for i = 1, drum_number do
      for j = 1, 32 do
        if drum[i].rotated[j] then
          io.write("pulse".."\n")
        else
          io.write("step".."\n")
        end
      end
    end  
  io.close(file)
end  

function load_state()
  params:read(_path.data .. "hachi/hachi.pset")
  local file = io.open(_path.data .. "hachi/hachi_pattern.data", "r")
  if file then
    print("hachi pattern file loaded")
    -- all this stuff is required only to manage the real time recording :-)
    io.input(file)
    if io.read() == "hachi pattern file v2.1" then
      for i = 1, drum_number do
        for j = 1, 32 do
          if io.read() == "pulse" then
            drum[i].rotated[j] = true
          else
            drum[i].rotated[j] = false
          end
        end
      end  
    else
      print("invalid data file")
    end
    io.close(file)
  end

end
function redraw()
    screen.clear()

    -- draw pattern
    for i = 1, params:get(name[selected] .. " steps") do
        screen.level((drum[selected].position == i and not reset) and 12 or 3)
        screen.rect(4 * i - 3, 62, 3, -6)
        screen.stroke()
        if drum[selected].rotated[i] then
            screen.level(10)
            screen.rect(4 * i - 3, 61, 2, -5)
            screen.fill()
        else
        end
    end

    -- draw drums
    for i = 1, drum_number do
      
        local level = math.floor(params:get(name[i].." level") / 25)
        screen.level((i == selected) and 7 or level)
        screen.arc(i * 18 - 4, 49, 3, 0, math.pi / 2)
        screen.arc(i * 18 - 14, 49, 3, math.pi / 2, math.pi)
        if shift then
        screen.arc(i * 18 - 14, 30, 3, math.pi, math.pi * 3 / 2)
        screen.arc(i * 18 - 4, 30, 3, math.pi * 3 / 2, 0)
        else
        screen.arc(i * 18 - 14, 3, 3, math.pi, math.pi * 3 / 2)
        screen.arc(i * 18 - 4, 3, 3, math.pi * 3 / 2, 0)
        end
        screen.fill()
        screen.level(15)
        screen.move(i * 18 - 9, 7)
        screen.text_center(name[i])
        screen.move(i * 18 - 9, 34)
        screen.text_center(params:get(name[i] .. " rotation"))
        screen.move(i * 18 - 9, 42)
        screen.text_center(params:get(name[i] .. " pulses"))
        screen.move(i * 18 - 9, 50)
        screen.text_center(params:get(name[i] .. " steps"))
        screen.stroke()
    end
    screen.move(9, 17)
    screen.text_center(params:get "BD tone")
    screen.move(9, 25)
    screen.text_center(params:get "BD decay")
    screen.move(27, 17)
    screen.text_center(params:get "CH tone")
    screen.move(27, 25)
    screen.text_center(params:get "CH decay")
    screen.move(45, 17)
    screen.text_center(params:get "OH tone")
    screen.move(45, 25)
    screen.text_center(params:get "OH decay")
    screen.move(63, 17)
    screen.text_center(params:get "SD tone")
    screen.move(63, 25)
    screen.text_center(params:get "SD snappy")
    screen.update()
end
