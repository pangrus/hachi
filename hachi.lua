-- hachi
-- 808 drum machine for norns
--
-- k1 shift
-- k1+k3 clear all (if stopped)
-- k1+k3 randomize (if started)
-- k2 start/stop
-- k3 insert step (if started)
-- k3 randomize all (if stopped)
-- e1 instrument select
-- e2 drum parameter 1
-- e3 drum parameter 2
-- e2+k1 number of pulses
-- e3+k1 number of steps
--
-- pangrus 2020
-- ver 1.1

-- hachi means 8
engine.name = "Hachi"

-- euclidean rhythms
er = require "er"

-- variables
local instrument = {}
local instrument_number = 6
local instrument_names = {"BD", "HH", "SN", "CP", "CW", "CL"}
local reset = false
local is_running = false
local selected = 1
local shift = false
local kick_tone = 58
local kick_decay = 28
local hh_decay = 8
local snare_tone = 288
local snappy = 28

-- midi management
local MIDI_Clock = require "beatclock"
local clk = MIDI_Clock.new()
local clk_midi = midi.connect()

function init()
    clk_midi.event = function(data)
        clk:process_midi(data)
    end
    clk.on_step = execute_step
    clk.on_select_internal = function()
        clk:start()
    end
    clk.on_select_external = reset_sequence
    params:add_separator()
    clk:add_clock_params()
    reset_sequence()
    init_patterns()
    engine.kick_tone(kick_tone)
    engine.kick_decay(kick_decay)
    engine.hh_decay(hh_decay / 10)
end

function init_patterns()
    for i = 1, instrument_number do
        instrument[i] = {
            k = math.floor(math.random() * 6) + 1,
            n = 16,
            pos = 1,
            s = {}
        }
        generate_pattern(i)
    end
end

function clear_patterns()
  for i = 1, instrument_number do
        instrument[i] = {
            k = 0,
            n = 16,
            pos = 1,
            s = {}
        }
        generate_pattern(i)
    end
  end

function randomize_pattern(sel)
    instrument[sel].k = math.floor(math.random() * 7) + 2
    generate_pattern(sel)
end

function generate_pattern(i)
    if instrument[i].k == 0 then
        for n = 1, 32 do
            instrument[i].s[n] = false
        end
    else
        instrument[i].s = er.gen(instrument[i].k, instrument[i].n)
    end
end

function execute_step()
    if reset then
        for i = 1, instrument_number do
            instrument[i].pos = 1
        end
        reset = false
    else
        for i = 1, instrument_number do
            instrument[i].pos = (instrument[i].pos % instrument[i].n) + 1
        end
    end
    trigger_instrument()
    redraw()
end

function trigger_instrument()
    for i = 1, instrument_number do
        if instrument[i].s[instrument[i].pos] then
            if i == 1 then
                engine.kick_trigger(1)
            end
            if i == 2 then
                engine.hhclosed_trigger(1)
            end
            if i == 3 then
                engine.snare_trigger(1)
            end
            if i == 4 then
                engine.clap_trigger(1)
            end
            if i == 5 then
                engine.cowbell_trigger(1)
            end
            if i == 6 then
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
        clk:stop()
        reset_sequence()
        is_running = false
    elseif n == 2 and z == 1 and is_running == false then
        clk:start()
        is_running = true
    end

    -- real time programming
    if n == 3 and z == 1 and is_running and not shift then
        instrument[selected].s[instrument[selected].pos] = "true"
        if selected == 1 then
            engine.kick_trigger(1)
        end
        if selected == 2 then
            engine.hhclosed_trigger(1)
        end
        if selected == 3 then
            engine.snare_trigger(1)
        end
        if selected == 4 then
            engine.clap_trigger(1)
        end
        if selected == 5 then
            engine.cowbell_trigger(1)
        end
        if selected == 6 then
            engine.claves_trigger(1)
        end
    end

    -- randomize all pattern
    if n == 3 and z == 1 and not is_running and not shift then
      for i = 1, instrument_number do
        randomize_pattern(i)
      end
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
    if n == 1 then
        selected = util.clamp(selected + d, 1, instrument_number)
    end

    if shift == true then
        if n == 2 then
            instrument[selected].k = util.clamp(instrument[selected].k + d, 0, instrument[selected].n)
        end
        if n == 3 then
            instrument[selected].n = util.clamp(instrument[selected].n + d, 1, 32)
            instrument[selected].k = util.clamp(instrument[selected].k, 0, instrument[selected].n)
        end
        generate_pattern(selected)
    end

    if shift == false then
        --kick parameters
        if selected == 1 then
            if n == 2 then
                kick_tone = util.clamp(kick_tone + d, 30, 1000)
                engine.kick_tone(kick_tone)
            end
            if n == 3 then
                kick_decay = util.clamp(kick_decay + d, 1, 35)
                engine.kick_decay(kick_decay)
            end
        end

        -- hh parameters
        if selected == 2 then
            if n == 2 then
                hh_decay = util.clamp(hh_decay + d, 1, 15)
                engine.hh_decay(hh_decay / 10)
            end
        end

        -- snare parameters
        if selected == 3 then
            if n == 2 then
                snare_tone = util.clamp(snare_tone + d, 50, 1000)
                engine.snare_tone(snare_tone)
            end
            if n == 3 then
                snappy = util.clamp(snappy + d, 1, 100)
                engine.snappy(snappy / 100)
            end
        end
    end
    redraw()
end

function redraw()
    screen.aa(0)
    screen.clear()
    screen.line_width(1)

    -- draw pattern
    for i = 1, instrument[selected].n do
        screen.level((instrument[selected].pos == i and not reset) and 15 or 3)
        if instrument[selected].s[i] then
            screen.level(10)
        end
        screen.rect(4 * i - 2, 62, 2, -6)
        screen.stroke()
    end

    -- draw instruments
    for i = 1, instrument_number do
        screen.level((i == selected) and 4 or 1)
        screen.arc(i * 21 - 5, 45, 5, 0, math.pi / 2)
        screen.arc(i * 21 - 14, 45, 5, math.pi / 2, math.pi)
        if shift then
            screen.arc(i * 21 - 14, 32, 5, math.pi, math.pi * 3 / 2)
            screen.arc(i * 21 - 5, 32, 5, math.pi * 3 / 2, 0)
        else
            screen.arc(i * 21 - 14, 5, 5, math.pi, math.pi * 3 / 2)
            screen.arc(i * 21 - 5, 5, 5, math.pi * 3 / 2, 0)
        end
        screen:close()
        screen.fill()
        screen.level(12)
        screen.move(i * 21 - 10, 8)
        screen.text_center(instrument_names[i])
        screen.move(i * 21 - 10, 36)
        screen.text_center(instrument[i].k)
        screen.move(i * 21 - 10, 45)
        screen.text_center(instrument[i].n)
        screen.stroke()
    end
    screen.move(11, 17)
    screen.text_center(kick_tone)
    screen.move(11, 26)
    screen.text_center(kick_decay)
    screen.move(32, 17)
    screen.text_center(hh_decay)
    screen.move(53, 17)
    screen.text_center(snare_tone)
    screen.move(53, 26)
    screen.text_center(snappy)
    screen.update()
end
