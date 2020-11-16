-- hachi
-- 808 drum machine for norns
-- V2.0 @pangrus
-- https://llllllll.co/t/hachi-euclidean-drum-machine/35947
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
-- e1+k1 rotate pattern
-- e2+k1 number of pulses
-- e3+k1 number of steps


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
local kick_tone = 60
local kick_decay = 15
local hh_tone = 200
local hh_decay = 10
local snare_tone = 360
local snappy = 100

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
    params:add_separator()
    clk:add_clock_params()

    -- reset
    reset_sequence()
    init_patterns()

    -- load previous state
    local file = io.open(_path.data .. "hachi/hachi_data.txt", "r")
    if file then
        loadstate()
    else
        savestate()
    end

    -- instrument parameters
    engine.kick_tone(kick_tone)
    engine.kick_decay(kick_decay)
    engine.hh_tone(hh_tone)
    engine.hh_decay(hh_decay / 10)
    engine.snappy(snappy / 100)
    engine.snare_tone(snare_tone)

    -- generate pattens
    for i = 1, instrument_number do
        generate_pattern(i)
    end
end

function init_patterns()
    for i = 1, instrument_number do
        instrument[i] = {
            k = 0,
            n = 16,
            r = 0,
            pos = 1,
            s = {},
            rot = {}
        }
        generate_pattern(i)
    end
    -- instant gratification :-)
    for i = 1, instrument_number do
            randomize_pattern(i)
    end
        -- default rotation parameter for hh and snare
        instrument[2].r = 2
        instrument[3].r = 4
end

function clear_patterns()
    for i = 1, instrument_number do
        instrument[i] = {
            k = 0,
            n = 16,
            r = 0,
            pos = 1,
            s = {},
            rot = {}
        }
        generate_pattern(i)
    end
     -- default rotation parameter for hh and snare
        instrument[2].r = 2
        instrument[3].r = 4
end

function randomize_pattern(sel)
    instrument[sel].k = math.floor(math.random(6))
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
    rotate_pattern(i)
end

function rotate_pattern(i)
    for n = 1, instrument[i].r do
        instrument[i].rot[n] = instrument[i].s[instrument[i].n - instrument[i].r + n]
    end
    for n = 1, instrument[i].n - instrument[i].r do
        instrument[i].rot[n + instrument[i].r] = instrument[i].s[n]
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
        if instrument[i].rot[instrument[i].pos] then
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
        savestate()
    elseif n == 2 and z == 1 and is_running == false then
        clk:start()
        is_running = true
        savestate()
    end

    -- real time programming
    if n == 3 and z == 1 and is_running and not shift then
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
        instrument[selected].rot[instrument[selected].pos] = "true"
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
    if n == 1 and shift == false then
        selected = util.clamp(selected + d, 1, instrument_number)
    end

    if shift == true then
        if n == 1 then
            instrument[selected].r = util.clamp(instrument[selected].r + d, 0, instrument[selected].n)
            rotate_pattern(selected)
        end

        if n == 2 then
            instrument[selected].k = util.clamp(instrument[selected].k + d, 0, instrument[selected].n)
        end
        if n == 3 then
            instrument[selected].n = util.clamp(instrument[selected].n + d, 1, 32)
            instrument[selected].k = util.clamp(instrument[selected].k, 0, instrument[selected].n)
            instrument[selected].r = util.clamp(instrument[selected].r, 0, instrument[selected].n)
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
                hh_tone = util.clamp(hh_tone + d, 50, 700)
                engine.hh_tone(hh_tone)
            end
            if n == 3 then
                hh_decay = util.clamp(hh_decay + d, 10, 30)
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
                snappy = util.clamp(snappy + d, 1, 300)
                engine.snappy(snappy / 100)
            end
        end
    end
    redraw()
end

-- save state in hachi_data.txt
function savestate()
    local file = io.open(_path.data .. "hachi/hachi_data.txt", "w+")
    io.output(file)
    for i = 1, instrument_number do
        io.write(instrument[i].r .. "\n")
        io.write(instrument[i].k .. "\n")
        io.write(instrument[i].n .. "\n")
    end
    io.write(kick_tone .. "\n")
    io.write(kick_decay .. "\n")
    io.write(hh_tone .. "\n")
    io.write(hh_decay .. "\n")
    io.write(snare_tone .. "\n")
    io.write(snappy .. "\n")
    io.close(file)
end

-- load previous state
function loadstate()
    local file = io.open(_path.data .. "hachi/hachi_data.txt", "r")
    io.input(file)
    for i = 1, instrument_number do
        instrument[i].r = tonumber(io.read())
        instrument[i].k = tonumber(io.read())
        instrument[i].n = tonumber(io.read())
    end
    kick_tone = tonumber(io.read())
    kick_decay = tonumber(io.read())
    hh_tone = tonumber(io.read())
    hh_decay = tonumber(io.read())
    snare_tone = tonumber(io.read())
    snappy = tonumber(io.read())
    io.close(file)
end

function redraw()
    screen.clear()

    -- draw pattern
    for i = 1, instrument[selected].n do
        screen.level((instrument[selected].pos == i and not reset) and 12 or 3)
        screen.rect(4 * i - 3, 62, 3, -6)
        screen.stroke()
        if instrument[selected].rot[i] then
            screen.level(10)
            screen.rect(4 * i - 3, 61, 2, -5)
            screen.fill()
        else
        end
    end

    -- draw instruments
    for i = 1, instrument_number do
        screen.level((i == selected) and 3 or 1)
        screen.arc(i * 21 - 5, 47, 5, 0, math.pi / 2)
        screen.arc(i * 21 - 14, 47, 5, math.pi / 2, math.pi)
        if shift then
            screen.arc(i * 21 - 14, 32, 5, math.pi, math.pi * 3 / 2)
            screen.arc(i * 21 - 5, 32, 5, math.pi * 3 / 2, 0)
        else
            screen.arc(i * 21 - 14, 5, 5, math.pi, math.pi * 3 / 2)
            screen.arc(i * 21 - 5, 5, 5, math.pi * 3 / 2, 0)
        end
        screen.fill()
        screen.level(12)
        screen.move(i * 21 - 10, 8)
        screen.text_center(instrument_names[i])
        screen.move(i * 21 - 10, 34)
        screen.text_center(instrument[i].r)
        screen.move(i * 21 - 10, 42)
        screen.text_center(instrument[i].k)
        screen.move(i * 21 - 10, 50)
        screen.text_center(instrument[i].n)
        screen.stroke()
    end
    screen.move(11, 17)
    screen.text_center(kick_tone)
    screen.move(11, 25)
    screen.text_center(kick_decay)
    screen.move(32, 17)
    screen.text_center(hh_tone)
    screen.move(32, 25)
    screen.text_center(hh_decay)
    screen.move(53, 17)
    screen.text_center(snare_tone)
    screen.move(53, 25)
    screen.text_center(snappy)
    screen.update()
end
