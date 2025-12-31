#module_parameters (DEBUG_PRINT:=false);

Gamepad :: struct {
    using _ : Gamepad_OS;
    idx: int;
    connected: bool;

    buttons : [] Key_Current_State;     // This is aliased to a subrange of Input.input_button_states.

    left_stick: Vector2;
    right_stick: Vector2;
    left_trigger: float;
    right_trigger: float;

    // Config:
    generate_events: bool;
    generate_left_stick_events: bool;  // Even if generate_events is off, if generate_stick_events is on, you will get stick events and not other things. Probably we should make this into a bitfield for different kinds.
    
    left_stick_rotation_angle: float;
    right_stick_rotation_angle: float;

    left_stick_deadzone: float;
    right_stick_deadzone: float;
    left_trigger_deadzone: float;
    right_trigger_deadzone: float;

    // Threshold used to generate digital events.
    left_stick_threshold: float;
    right_stick_threshold: float;
    left_trigger_threshold: float;
    right_trigger_threshold: float;
};

gamepad : *Gamepad = #run *gamepads[0];
gamepads : [4] Gamepad; // Same amount of gamepads as defined in Input's Key_Code enum.

Gamepad_Code :: enum {
    DPAD_UP;
    DPAD_DOWN;
    DPAD_LEFT;
    DPAD_RIGHT;
    START;
    BACK;
    LEFT_SHOULDER;
    RIGHT_SHOULDER;
    LEFT_TRIGGER;
    RIGHT_TRIGGER;
    A;
    B;
    X;
    Y;
    LEFT_STICK_UP;
    LEFT_STICK_DOWN;
    LEFT_STICK_LEFT;
    LEFT_STICK_RIGHT;
    RIGHT_STICK_UP;
    RIGHT_STICK_DOWN;
    RIGHT_STICK_LEFT;
    RIGHT_STICK_RIGHT;
    LEFT_STICK_CLICK;
    RIGHT_STICK_CLICK;
};


// API:
// init_gamepad()   - Call at startup or anytime you want to refresh the connected gamepads.
// update_gamepad() - Call once a frame after update_window_events()



init_gamepad :: () {
    for * gamepads {
        it.idx = it_index;
        reset_buttons_state(it);
    }
    inline os_init_gamepad();
}

update_gamepad :: () {
    // This expects update_window_events to reset the button flags.
    inline os_update_gamepad();
}


#scope_file

Basic :: #import "Basic";

array_add :: Basic.array_add;
clamp :: Basic.clamp;

Math :: #import "Math";
Vector2 :: Math.Vector2;
rotate :: Math.rotate;
PI :: Math.PI;

Input :: #import "Input";
Key_Current_State :: Input.Key_Current_State;
Key_Code :: Input.Key_Code;
Event :: Input.Event;
Event_Type :: Input.Event_Type;
GAMEPAD_BUTTON_COUNT :: Input.GAMEPAD_BUTTON_COUNT;
//input_button_states :: Input.input_button_states;
//events_this_frame :: Input.events_this_frame;

get_available_gamepad_slot :: inline () -> *Gamepad {
    for * gamepads
        if !it.connected
            return it;
    return null;
}

reset_buttons_state :: (using gamepad: *Gamepad) {
    // Setup buttons alias - stored with an empty space between them (see GAMEPAD_0_END defined on Input/module.jai) thus (+1).
    buttons.data = *Input.input_button_states[xx Key_Code.GAMEPAD_0_BEGIN + (GAMEPAD_BUTTON_COUNT+1) * idx]; 
    buttons.count = GAMEPAD_BUTTON_COUNT;
    
    // Set defaults:
    memset(buttons.data, 0, GAMEPAD_BUTTON_COUNT*size_of(Key_Current_State));
    
    left_stick      = .{};
    right_stick     = .{};
    left_trigger    = 0.0;
    right_trigger   = 0.0;
    
    left_stick_rotation_angle = 0.0;
    right_stick_rotation_angle = 0.0;
    
    left_stick_deadzone = 0.0;          // @@ Not implemented. See disabled code below.
    right_stick_deadzone = 0.0;
    left_trigger_deadzone = 0.0;
    right_trigger_deadzone = 0.0;

    // Threshold used to generate digital events.
    left_stick_threshold = 0.5;
    right_stick_threshold = 0.5;
    left_trigger_threshold = 0.3;       // XINPUT_GAMEPAD_TRIGGER_THRESHOLD / 255.0;
    right_trigger_threshold = 0.3;
}

update_button_state :: (gamepad: *Gamepad, pressed: bool, code: Gamepad_Code) {

    state := gamepad.buttons[code];

    was_pressed := ((state & .DOWN) && !(state & .END));

    already_match := (pressed == was_pressed);
    if already_match return;

    if pressed {
        gamepad.buttons[code] |= Key_Current_State.DOWN | .START;
    } else {
        gamepad.buttons[code] |= .END;
    }

    // Do not generate events for gamepad buttons.
    if !gamepad.generate_events {
        if !gamepad.generate_left_stick_events  return;

        // If generate_left_stick_events is true, return if it's not a stick event.
        if (code < .LEFT_STICK_UP) || (code > .LEFT_STICK_RIGHT) return;
    }
    
    event: Event;
    event.type = .KEYBOARD;   // Use custom events for gamepad?
    event.key_pressed = xx pressed;
    event.key_code = Key_Code.GAMEPAD_0_BEGIN + cast(Key_Code)((GAMEPAD_BUTTON_COUNT+1) * gamepad.idx) + xx code;
    event.packed = 0;
    event.shift_pressed = (Input.input_button_states[Key_Code.SHIFT] & .DOWN) != 0;
    event.ctrl_pressed  = (Input.input_button_states[Key_Code.CTRL ] & .DOWN) != 0;
    event.alt_pressed   = (Input.input_button_states[Key_Code.ALT  ] & .DOWN) != 0;
    event.repeat = false;
    array_add(*Input.events_this_frame, event);
}


#if OS == .WINDOWS {
    #load "Xinput.jai";
    
    
    Gamepad_OS :: struct {
        dwUserIndex : u32;
    }
    
    
    os_init_gamepad :: () {
        
        for * gamepads it.connected = false;
        
        xinput_available := init_xinput();
                
        if xinput_available {
            // @@ We only detect devices at startup since it appears to be a fairly expensive operation when no devices are connected.
            // This is a known issue, but no real solution has been proposed yet, see:
            // http://discussms.hosting.lsoft.com/SCRIPTS/WA-MSD.EXE?A2=DIRECTXDEV;JS%2Biyw;20080530112111%2B1000E
            // A proposed workaround is to detect them every few seconds, but that's untenable since it would cause varying framerate.
            // Maybe a better idea is to do that only at specific points in the game, for example, when entering the input config menu.
            
            for 0..Basic.min(gamepads.count, XUSER_MAX_COUNT-1) {
                dwUserIndex : u32 = xx it;
                state: XINPUT_STATE;
                result := XInputGetState(dwUserIndex, *state);
    
                ERROR_DEVICE_NOT_CONNECTED :: 1167; // From winerror.h
                if result != ERROR_DEVICE_NOT_CONNECTED {
                    gamepad := get_available_gamepad_slot();
                    Basic.assert(gamepad != null, "Request for available gamepad slot returned an unexpected null.");
                    
                    gamepad.connected = true;
                    gamepad.dwUserIndex = dwUserIndex;
                    
                    #if DEBUG_PRINT Basic.print("Gamepad: Xinput gamepad found.\n");
                }
            }
        }
    }
    
    
    os_update_gamepad :: () {
        for * gamepad : gamepads {
            if !gamepad.connected continue;
            
            state: XINPUT_STATE;
            result := XInputGetState(dwUserIndex = gamepad.dwUserIndex, *state);
            if result != 0/*ERROR_SUCCESS*/ {
                return;
            }
            
            buttons := state.Gamepad.wButtons;
            
            button_translate :: (gamepad: *Gamepad, buttons: s32, xinput_code: s32, my_code: Gamepad_Code) {
                pressed := (buttons & xinput_code) != 0;
                update_button_state(gamepad, pressed, my_code);
            }
            
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_DPAD_UP,    .DPAD_UP);
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_DPAD_DOWN,  .DPAD_DOWN);
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_DPAD_LEFT,  .DPAD_LEFT);
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_DPAD_RIGHT, .DPAD_RIGHT);
            
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_START, .START);
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_BACK, .BACK);
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_LEFT\_SHOULDER, .LEFT\_SHOULDER);
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_RIGHT_SHOULDER, .RIGHT_SHOULDER);
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_A, .A);
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_B, .B);
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_X, .X);
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_Y, .Y);
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_LEFT\_THUMB, .LEFT\_STICK_CLICK);
            button_translate(gamepad, buttons, XINPUT_GAMEPAD_RIGHT_THUMB, .RIGHT_STICK_CLICK);

            
            #if 1 {
                // No deadzone:
                gamepad.left\_stick.x = clamp(state.Gamepad.sThumbLX / 32767.0, -1, 1);
                gamepad.left\_stick.y = clamp(state.Gamepad.sThumbLY / 32767.0, -1, 1);
                gamepad.right_stick.x = clamp(state.Gamepad.sThumbRX / 32767.0, -1, 1);
                gamepad.right_stick.y = clamp(state.Gamepad.sThumbRY / 32767.0, -1, 1);
            }
            else #if 0 {
                // Square deadzone:
                process_axis_value :: (value: s16, deadzone: s16) {
                    if value < -deadzone        value += deadzone;
                    else if value > deadzone    value -= deadzone;
                    return clamp(value / (32768.0 - deadzone), -1, 1);
                }
        
                gamepad.left_stick.x = process_axis_value(state.Gamepad.sThumbLX, XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE);
                gamepad.left_stick.y = process_axis_value(state.Gamepad.sThumbLY, XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE);
                gamepad.right_stick.x = process_axis_value(state.Gamepad.sThumbRX, XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE);
                gamepad.right_stick.y = process_axis_value(state.Gamepad.sThumbRY, XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE);
            }
            else #if 0 {
                // Circular deadzone:
                process_stick_value :: (dx: s16, dy: s16, deadzone: s16) -> Vector2 {
        
                    magnitude := sqrt(dx*dx + dy*dy);
        
                    if magnitude < deadzone {
                        return xy(0,0);
                    }
        
                    v: Vector2;
                    v.x = dx / magnitude;
                    v.y = dy / magnitude;
        
                    magnitude = min(magnitude, 32767);
                    magnitude -= deadzone;
                    magnitude = magnitude / (32767 - deadzone);
        
                    return v * magnitude;
                }
        
                gamepad.left_stick  = process_stick_value(state.Gamepad.sThumbLX, state.Gamepad.sThumbLY, XINPUT_GAMEPAD_LEFT\_THUMB_DEADZONE);
                gamepad.right_stick = process_stick_value(state.Gamepad.sThumbRX, state.Gamepad.sThumbRY, XINPUT_GAMEPAD_RIGHT_THUMB_DEADZONE);
            }
            
            //gamepad.left_stick = rotate(gamepad.left_stick, gamepad.left_stick_rotation_angle * (PI / 180.0));
            //gamepad.right_stick = rotate(gamepad.right_stick, gamepad.right_stick_rotation_angle * (PI / 180.0));
            
            stick_translate :: (gamepad: *Gamepad, axis_value: float, threshold: float, button_low: Gamepad_Code, button_high: Gamepad_Code) {
                update_button_state(gamepad, axis_value < -threshold, button_low);
                update_button_state(gamepad, axis_value > +threshold, button_high);
            }
        
            stick_translate(gamepad, gamepad.left_stick.x, gamepad.left_stick_threshold, .LEFT_STICK_LEFT, .LEFT_STICK_RIGHT);
            stick_translate(gamepad, gamepad.left_stick.y, gamepad.left_stick_threshold, .LEFT_STICK_DOWN, .LEFT_STICK_UP);
            stick_translate(gamepad, gamepad.right_stick.x, gamepad.right_stick_threshold, .RIGHT_STICK_LEFT, .RIGHT_STICK_RIGHT);
            stick_translate(gamepad, gamepad.right_stick.y, gamepad.right_stick_threshold, .RIGHT_STICK_DOWN, .RIGHT_STICK_UP);
        
            gamepad.left\_trigger = clamp(state.Gamepad.bLeft\Trigger / 255.0, 0, 1);
            gamepad.right_trigger = clamp(state.Gamepad.bRightTrigger / 255.0, 0, 1);
            update_button_state(gamepad, gamepad.left_trigger > gamepad.left_trigger_threshold, .LEFT_TRIGGER);
            update_button_state(gamepad, gamepad.right_trigger > gamepad.right_trigger_threshold, .RIGHT_TRIGGER);

            if Math.abs(gamepad.left_stick.x) < gamepad.left_stick_deadzone gamepad.left_stick.x = 0;
            if Math.abs(gamepad.left_stick.y) < gamepad.left_stick_deadzone gamepad.left_stick.y = 0;
            if Math.abs(gamepad.right_stick.x) < gamepad.right_stick_deadzone gamepad.right_stick.x = 0;
            if Math.abs(gamepad.right_stick.y) < gamepad.right_stick_deadzone gamepad.right_stick.y = 0;
        }
    }
}


#if OS == .MACOS {
    // #load "IOHID.jai";
    #import "Objective_C";
    #import "Objective_C/GameController";
    
    // Since macOS uses some sort of events/handlers that may be called from other thread, let's use a mutex.
    // If this assumption is incorrect and there's only one thread, then we may remove this.
    #import "Thread";
    gamepads_mutex: Mutex;
    
    Gamepad_OS :: struct {
        game_controller: *GCController;
        _game_controller_paused_pressed := false;
        _game_controller_block_desc: Objective_C_Block_Basic_Descriptor;
        _game_controller_block: Objective_C_Block_Basic;
    }

    
    gamepad_factory: *Gamepad_Factory;
    
    Gamepad_Factory :: struct {
        using #as nsobject: NSObject;
    
        handleControllerDidConnectNotification :: (self: *Gamepad_Factory, sel: Selector, notification: *NSNotification) #c_call {
            push_context {
                lock(*gamepads_mutex);
                defer unlock(*gamepads_mutex);
                
                gamepad := get_available_gamepad_slot();
                if gamepad == null {
                    #if DEBUG_PRINT Basic.print("Gamepad: Cannot connect gamepad because there's no more available slots.");
                    return;
                }
                
                gamepad._game_controller_block.isa = xx _NSConcreteGlobalBlock;
                gamepad._game_controller_block.invoke = xx game_controller_pause_handler_block_func;
                gamepad._game_controller_block.descriptor = *gamepad._game_controller_block_desc;
                gamepad._game_controller_block_desc.size = size_of(Objective_C_Block_Basic);
    
                gamepad.game_controller = cast(*GCController) notification.object(notification);
                gamepad.game_controller.setControllerPausedHandler(gamepad.game_controller, *gamepad._game_controller_block);
                
                reset_buttons_state(gamepad);
                gamepad.connected = true;
            }
            
        } @selector(handleControllerDidConnectNotification:notification:)
    
        handleControllerDidDisconnectNotification :: (self: *Gamepad_Factory, sel: Selector, notification: *NSNotification) #c_call {
            push_context {
                lock(*gamepads_mutex);
                defer unlock(*gamepads_mutex);
                
                controller := cast(*GCController) notification.object(notification);
    
                for * gamepads {
                    if it.game_controller == controller {
                        it.connected = false;
                        it.game_controller = null;
                        break;
                    }
                }
            }
    
        } @selector(handleControllerDidDisconnectNotification:notification:)
    }
    
    game_controller_pause_handler_block_func :: (block: *Objective_C_Block_Basic, controller: *GCController) #c_call {
        ctx: #Context;
        push_context ctx {
            lock(*gamepads_mutex);
            defer unlock(*gamepads_mutex);
            
            for * gamepads {
                if it.game_controller == controller {
                    it._game_controller_paused_pressed = true;
                    break;
                }
            }
        }
    }
    
    
    os_init_gamepad :: () {

        //  Register game controller notifications.
        
        if gamepad_factory return;

        init(*gamepads_mutex);

        init_objective_c();
        init_objective_c_gamecontroller();

        gf_class := objc_create_class(Gamepad_Factory, NSObject);
        objc_add_instance_method(gf_class, Gamepad_Factory.handleControllerDidConnectNotification, "handleControllerDidConnectNotification:notification:");
        objc_add_instance_method(gf_class, Gamepad_Factory.handleControllerDidDisconnectNotification, "handleControllerDidDisconnectNotification:notification:");
        objc_finalize_class(gf_class);

        gamepad_factory = objc_init(objc_alloc(Gamepad_Factory));

        center := NSNotificationCenter.defaultCenter();

        center.addObserver(center, gamepad_factory, selector("handleControllerDidConnectNotification:notification:"),    GCControllerDidConnectNotification,    object=null);
        center.addObserver(center, gamepad_factory, selector("handleControllerDidDisconnectNotification:notification:"), GCControllerDidDisconnectNotification, object=null);

        // GCController.startWirelessControllerDiscoveryWithCompletionHandler(null);
    }
    
    
    os_update_gamepad :: () {
        lock(*gamepads_mutex);
        defer unlock(*gamepads_mutex);
        
        for * gamepad : gamepads {
            if !gamepad.connected continue;
            
            controller := gamepad.game_controller;
        
            // controller.setPlayerIndex(controller, GCControllerPlayerIndex2);
        
            _gamepad      := controller.gamepad(controller);
            micropad     := controller.microGamepad(controller);
            extendedpad  := controller.extendedGamepad(controller);
        
            pressed :: (input: *GCControllerButtonInput) -> bool {
                return input.isPressed(input) != 0;
            }
        
            value :: (input: *GCControllerButtonInput) -> float {
                return input.value(input);
            }
        
            value :: (input: *GCControllerAxisInput) -> float {
                return input.value(input);
            }
        
            get_axes :: (dpad: *GCControllerDirectionPad) -> Vector2 {
                v: Vector2 = ---;
                v.x = value(dpad.xAxis(dpad));
                v.y = value(dpad.yAxis(dpad));
                return v;
            }
        
            if extendedpad {
                pad := extendedpad;
        
                update_button_state(gamepad, pressed(pad.buttonA(pad)), .A);
                update_button_state(gamepad, pressed(pad.buttonB(pad)), .B);
                update_button_state(gamepad, pressed(pad.buttonX(pad)), .X);
                update_button_state(gamepad, pressed(pad.buttonY(pad)), .Y);
        
                update_button_state(gamepad, pressed(pad.leftShoulder(pad)),  .LEFT_SHOULDER);
                update_button_state(gamepad, pressed(pad.rightShoulder(pad)), .RIGHT_SHOULDER);
        
                dpad := pad.dpad(pad);
                update_button_state(gamepad, pressed(dpad.up(dpad)),    .DPAD_UP);
                update_button_state(gamepad, pressed(dpad.down(dpad)),  .DPAD_DOWN);
                update_button_state(gamepad, pressed(dpad.left(dpad)),  .DPAD_LEFT);
                update_button_state(gamepad, pressed(dpad.right(dpad)), .DPAD_RIGHT);
        
        
                gamepad.left_trigger  = clamp(value(pad.leftTrigger(pad)),  0, 1);
                gamepad.right_trigger = clamp(value(pad.rightTrigger(pad)), 0, 1);
                update_button_state(gamepad, value(pad.leftTrigger(pad))  > gamepad.left_trigger_threshold,  .LEFT_TRIGGER);
                update_button_state(gamepad, value(pad.rightTrigger(pad)) > gamepad.right_trigger_threshold, .RIGHT_TRIGGER);
        
                // since 10.14.1
                // update_button_state(gamepad, pressed(pad.leftThumbstickButton(pad)), .LEFT_STICK_CLICK);
                // update_button_state(gamepad, pressed(pad.rightThumbstickButton(pad)), .RIGHT_STICK_CLICK);
        
        
                // No deadzone
                gamepad.left_stick  = get_axes(pad.leftThumbstick(pad));
                gamepad.right_stick = get_axes(pad.rightThumbstick(pad));
            } else if _gamepad {
                pad := _gamepad;
        
                update_button_state(gamepad, pressed(pad.buttonA(pad)), .A);
                update_button_state(gamepad, pressed(pad.buttonB(pad)), .B);
                update_button_state(gamepad, pressed(pad.buttonX(pad)), .X);
                update_button_state(gamepad, pressed(pad.buttonY(pad)), .Y);
        
                update_button_state(gamepad, pressed(pad.leftShoulder(pad)),  .LEFT_SHOULDER);
                update_button_state(gamepad, pressed(pad.rightShoulder(pad)), .RIGHT_SHOULDER);
        
                dpad := pad.dpad(pad);
                update_button_state(gamepad, pressed(dpad.up(dpad)),    .DPAD_UP);
                update_button_state(gamepad, pressed(dpad.down(dpad)),  .DPAD_DOWN);
                update_button_state(gamepad, pressed(dpad.left(dpad)),  .DPAD_LEFT);
                update_button_state(gamepad, pressed(dpad.right(dpad)), .DPAD_RIGHT);
        
        
                // Not available on regular Gamepad profile
                gamepad.left_trigger  = 0;
                gamepad.right_trigger = 0;
                update_button_state(gamepad, false, .LEFT_TRIGGER);
                update_button_state(gamepad, false, .RIGHT_TRIGGER);
        
                // since 10.14.1
                // update_button_state(gamepad, pressed(pad.leftThumbstickButton(pad)), .LEFT_STICK_CLICK);
                // update_button_state(gamepad, pressed(pad.rightThumbstickButton(pad)), .RIGHT_STICK_CLICK);
        
                // No sticks on Gamepad profile
                gamepad.left_stick  = .{0, 0};
                gamepad.right_stick = .{0, 0};
            } else if micropad {
                pad := micropad;
        
                update_button_state(gamepad, pressed(pad.buttonA(pad)), .A);
                update_button_state(gamepad, pressed(pad.buttonX(pad)), .X);
        
                // No B or Y buttons, or shoulder buttons in GCMicroGamepad
                update_button_state(gamepad, false, .B);
                update_button_state(gamepad, false, .Y);
                update_button_state(gamepad, false,  .LEFT_SHOULDER);
                update_button_state(gamepad, false, .RIGHT_SHOULDER);
        
                dpad := pad.dpad(pad);
                update_button_state(gamepad, pressed(dpad.up(dpad)),    .DPAD_UP);
                update_button_state(gamepad, pressed(dpad.down(dpad)),  .DPAD_DOWN);
                update_button_state(gamepad, pressed(dpad.left(dpad)),  .DPAD_LEFT);
                update_button_state(gamepad, pressed(dpad.right(dpad)), .DPAD_RIGHT);
        
        
                // Not available on GCMicroGamepad profile
                gamepad.left_trigger  = 0;
                gamepad.right_trigger = 0;
                update_button_state(gamepad, false, .LEFT_TRIGGER);
                update_button_state(gamepad, false, .RIGHT_TRIGGER);
        
                // since 10.14.1
                // update_button_state(gamepad, pressed(pad.leftThumbstickButton(pad)), .LEFT_STICK_CLICK);
                // update_button_state(gamepad, pressed(pad.rightThumbstickButton(pad)), .RIGHT_STICK_CLICK);
        
        
                // No sticks on GCMicroGamepad profile
                gamepad.left_stick  = .{0, 0};
                gamepad.right_stick = .{0, 0};
            }
        
            stick_translate :: (gamepad: *Gamepad, axis_value: float, threshold: float, button_low: Gamepad_Code, button_high: Gamepad_Code) {
                update_button_state(gamepad, axis_value < -threshold, button_low);
                update_button_state(gamepad, axis_value > +threshold, button_high);
            }
        
            stick_translate(gamepad, gamepad.left_stick.x, gamepad.left_stick_threshold, .LEFT_STICK_LEFT, .LEFT_STICK_RIGHT);
            stick_translate(gamepad, gamepad.left_stick.y, gamepad.left_stick_threshold, .LEFT_STICK_DOWN, .LEFT_STICK_UP);
            stick_translate(gamepad, gamepad.right_stick.x, gamepad.right_stick_threshold, .RIGHT_STICK_LEFT, .RIGHT_STICK_RIGHT);
            stick_translate(gamepad, gamepad.right_stick.y, gamepad.right_stick_threshold, .RIGHT_STICK_DOWN, .RIGHT_STICK_UP);

            update_button_state(gamepad, gamepad._game_controller_paused_pressed, .START);
            gamepad._game_controller_paused_pressed = false;
        }
    }
    
}


#if OS == .LINUX {
    #load "evdev.jai";
    #import "Gamepad/SDL_Input_Map";
    
    
    Gamepad_OS :: struct {
        current_gamepad: *libevdev;
        current_gamepad_mapping: SDL_Gamepad_Mapping; // this is a copy of an entry from known_gamepad_mappings, it does not own its memory!
        current_gamepad_evdev_mappings: struct {
            keys: [KEY_MAX] u16;
            abs : [ABS_MAX] u16; // this maps an ABS event code to an axis index
            absinfo: [ABS_MAX] input_absinfo;
            hats: [4] u8; // Linux only supports up to 4 hats per device. These are masks representing the 4 directions that can be held down.
        };
    };
    
    
    known_gamepad_mappings: [..] SDL_Gamepad_Mapping;
    known_gamepad_mappings_initialized := false;
    
    initialize_known_gamepad_mappings :: () {
        if known_gamepad_mappings_initialized return;
        
        String :: #import "String";
        consume_next_line :: (sp: *string) -> string, bool {
            s := sp.*;
            found, t, remainder := String.split_from_left(s, 10);
    
            if !found {
                // This is the last line.
                sp.* = "";
    
                return s, (s.count > 0);
            }
    
            sp.* = remainder;
    
            if t.count {
                if t[t.count-1] == 13  t.count -= 1;
            }
    
            return t, true;
        }
    
        builtin_maps := SDL_BUILTIN_GAME_CONTROLLER_DB;
        
        success := true;
        while success {
            line: string;
            line, success = consume_next_line(*builtin_maps);
    
            if String.starts_with(line, "#") continue; // skip comments
            if line == "" continue;
    
            map: SDL_Gamepad_Mapping;
            map, success = parse_gamepad_mapping_string(line);
    
            if success array_add(*known_gamepad_mappings, map);
    
            line, success = consume_next_line(*builtin_maps);
        }
        
        known_gamepad_mappings_initialized = true;
    }        

    
    os_init_gamepad :: () {
        initialize_known_gamepad_mappings();

        // Close any previously open file descriptor.
        for * gamepads {
            if !it.connected continue;
            it.connected = false;
            fd := libevdev_get_fd(it.current_gamepad);
            close(fd);
            libevdev_free(it.current_gamepad);
        }
        
        // Scan evdec for gamepads
        available_slots := gamepads.count;
        
        File_Utilities :: #import "File_Utilities";
        Sort :: #import "Sort";
        devices_filepaths := File_Utilities.file_list("/dev/input/by-path");
        Sort.quick_sort(devices_filepaths, Sort.compare_strings);
        defer {
            for devices_filepaths Basic.free(it);
            Basic.array_free(devices_filepaths);
        }
        
        for file_path: devices_filepaths {
            
            if !available_slots break;
            
            found_controller := false;
            
            dev: *libevdev;
            fd := open(Basic.temp_c_string(file_path), O_RDONLY | O_NONBLOCK);
            if fd == -1 {
                #if DEBUG_PRINT Basic.print("Gamepad: Could not open %\n", file_path);
                continue;
            }
    
            res := libevdev_new_from_fd(fd, *dev);
            if res < 0 {
                close(fd);
                #if DEBUG_PRINT Basic.print("Gamepad: Could not open libevdev on %\n", file_path);
                continue;
            }

            get_guid_string :: (dev: *libevdev) -> temp_string: string {
                bustype := cast(s16) libevdev_get_id_bustype(dev);
                vendor  := cast(s16) libevdev_get_id_vendor(dev);
                product := cast(s16) libevdev_get_id_product(dev);
                version := cast(s16) libevdev_get_id_version(dev);
                return get_guid_string(bustype, vendor, product, version);
            }
            
            guid_string := get_guid_string(dev);
    
            for known_gamepad_mappings {
            
                if it.platform != SDL_PLATFORM_LINUX continue;
                
                if it.guid != guid_string continue;
                
                gamepad := get_available_gamepad_slot();
                Basic.assert(gamepad != null, "Request for available gamepad slot returned an unexpected null. There should be % available slots.", available_slots);
                available_slots -= 1;
                found_controller = true;
                
                using gamepad;
                connected = true;
                current_gamepad = dev;
                current_gamepad_mapping = it;
                
                // assigned button indices to the list of keys that input devices theoretically support.
                // see input-event-codes.h from the linux headers for a complete list of the keys. For
                // out purposes, we just care about a button index mapping to an event code so that we
                // can translate the state of an SDL gamepad map to our gamepad interface.

                // This is analagous and partially adapted from ConfigJoystick in <sdl>s/rc/joystick/linux/SDL_sysjoystick.c.
                num_buttons: u16 = 0;
                for * current_gamepad_evdev_mappings.keys { it.* = 0xFFFF; }
                for * current_gamepad_evdev_mappings.abs  { it.* = 0xFFFF; }
                for * current_gamepad_evdev_mappings.hats { it.* = 0; }

                // for some unexplained reason, button indices are not linearly mapped.
                // event codes in range [BTN_JOYSTICK, KEY_MAX) are mapped first,
                // then [0, BTN_JOYSTICK) is mapped.
                for BTN_JOYSTICK..KEY_MAX-1 {
                    if libevdev_has_event_code(current_gamepad, EV_KEY, cast(u32) it) {
                        current_gamepad_evdev_mappings.keys[it] = num_buttons;
                        num_buttons += 1;
                    }
                }

                for 0..BTN_JOYSTICK-1 {
                    if libevdev_has_event_code(current_gamepad, EV_KEY, cast(u32) it) {
                        current_gamepad_evdev_mappings.keys[it] = num_buttons;
                        num_buttons += 1;
                    }
                }

                num_axes: u16 = 0;
                for 0..ABS_MAX-1 {
                    if it >= ABS_HAT0X && it <= ABS_HAT3Y continue; // skip hats

                    if libevdev_has_event_code(current_gamepad, EV_ABS, cast(u32) it) {
                        absinfo := libevdev_get_abs_info(current_gamepad, cast(u32) it);

                        current_gamepad_evdev_mappings.abs[it] = num_axes;
                        current_gamepad_evdev_mappings.absinfo[it] = absinfo.*;
                        num_axes += 1;
                    }
                }
                
                #if DEBUG_PRINT Basic.print("Gamepad: libevdev gamepad found.\n");
                break;
            }
            
            if !found_controller {
                libevdev_free(dev);
                close(fd);
            }
        }
    }
    
    
    os_update_gamepad :: () {
        for * gamepad : gamepads {
            if !gamepad.connected continue;
            
            using gamepad;
            
            // only used for buttons and hats (dpad), not for axes
            sdl_target_to_gamepad_code :: (target: SDL_Input_Target) -> success: bool, code: Gamepad_Code {
                if target == {
                    case .LEFT_TRIGGER;  return true, .LEFT_TRIGGER;
                    case .RIGHT_TRIGGER; return true, .RIGHT_TRIGGER;
        
                    case .DPAD_LEFT;  return true, .DPAD_LEFT;
                    case .DPAD_RIGHT; return true, .DPAD_RIGHT;
                    case .DPAD_UP;    return true, .DPAD_UP;
                    case .DPAD_DOWN;  return true, .DPAD_DOWN;
        
                    case .BACK;       return true, .BACK;
                    // case .GUIDE;     return .GUIDE;
                    case .START;      return true, .START;
        
                    case .LEFT_SHOULDER;  return true, .LEFT_SHOULDER;
                    case .RIGHT_SHOULDER; return true, .RIGHT_SHOULDER;
        
                    case .LEFT_STICK;  return true, .LEFT_STICK_CLICK;
                    case .RIGHT_STICK; return true, .RIGHT_STICK_CLICK;
        
                    case .A; return true, .A;
                    case .B; return true, .B;
                    case .X; return true, .X;
                    case .Y; return true, .Y;
                }
        
                return false, .A;
            }
        
            // Update evdev gamepads
            while true {
                ev: input_event;
                rc := libevdev_next_event(current_gamepad, LIBEVDEV_READ_FLAG_NORMAL, *ev);
                if rc == cast(s32) LIBEVDEV_READ_STATUS_SYNC && ev.type == EV_SYN {
                    rc = libevdev_next_event(current_gamepad, LIBEVDEV_READ_FLAG_SYNC, *ev);
                }
        
                if (rc == -EAGAIN) break;
                if !(rc == 0 || rc == 1) break;
        
                if rc == 0 {
                    if ev.type == {
                        case EV_KEY;
                            button := current_gamepad_evdev_mappings.keys[ev.code];
                            if button == 0xFFFF then continue;
        
                            value  := ev.value;
                            for current_gamepad_mapping.mappings {
                                if it.type == SDL_Input_Type.BUTTON && it.index == button {
                                    success, code := sdl_target_to_gamepad_code(it.target);
                                    if success then update_button_state(gamepad, value != 0, code);
                                }
                            }
                        case EV_ABS;
                            if ev.code >= ABS_HAT0X && ev.code <= ABS_HAT3Y {
                                index    := (ev.code - ABS_HAT0X) / 2;
                                axis     := (ev.code - ABS_HAT0X) % 2; // 0 == x, 1 == y
        
                                UPDOWN    :: SDL_HAT_UP_BIT   | SDL_HAT_DOWN_BIT;
                                LEFTRIGHT :: SDL_HAT_LEFT_BIT | SDL_HAT_RIGHT_BIT;
        
                                value := current_gamepad_evdev_mappings.hats[index];
                                if axis == 0 {
                                    value = (value & UPDOWN);
                                    if      ev.value == -1 then value |= SDL_HAT_LEFT_BIT;
                                    else if ev.value ==  1 then value |= SDL_HAT_RIGHT_BIT;
                                } else if axis == 1 {
                                    value = (value & LEFTRIGHT);
                                    if      ev.value == -1 then value |= SDL_HAT_UP_BIT;
                                    else if ev.value ==  1 then value |= SDL_HAT_DOWN_BIT;
                                }
        
                                current_gamepad_evdev_mappings.hats[index] = value;
                            } else {
                                index := current_gamepad_evdev_mappings.abs[ev.code];
                                if index == 0xFFFF then continue;
        
                                absinfo := current_gamepad_evdev_mappings.absinfo[ev.code];
        
                                value := ev.value;
                                flat := absinfo.flat;
                                normalized_float_value: float;
        
                                if      value < flat && value > -flat then normalized_float_value = 0;
                                else if value < 0 then normalized_float_value =  cast(float) -value / cast(float) absinfo.minimum;
                                else if value > 0 then normalized_float_value =  cast(float)  value / cast(float) absinfo.maximum;
        
                                // @Incomplete this stuff is probably incorrect, SDL does some weird transformation using absinfo.fuzz, .flat, .minimum, .maximum
                                // but I can't find any documentation on why or how this transformation works to comfortably implement it here. -josh 21 May 2019
        
                                for current_gamepad_mapping.mappings {
                                    if it.type == SDL_Input_Type.AXIS && it.index == index {
                                        if it.target == {
                                            case .LEFTX;
                                                gamepad.left_stick.x = normalized_float_value;
                                            case .LEFTY;
                                                gamepad.left_stick.y = -normalized_float_value; // flip the sign bit here because Linux reports Up on the Y axis as -1
                                            case .RIGHTX;
                                                gamepad.right_stick.x = normalized_float_value;
                                            case .RIGHTY;
                                                gamepad.right_stick.y = -normalized_float_value; // flip the sign bit here because Linux reports Up on the Y axis as -1
        
                                            case .LEFT_TRIGGER;
                                                gamepad.left_trigger  = clamp(normalized_float_value, 0, 1);
                                                update_button_state(gamepad, normalized_float_value > gamepad.left_trigger_threshold,  .LEFT_TRIGGER);
                                            case .RIGHT_TRIGGER;
                                                gamepad.right_trigger  = clamp(normalized_float_value, 0, 1);
                                                update_button_state(gamepad, normalized_float_value > gamepad.right_trigger_threshold, .RIGHT_TRIGGER);
        
                                            case;
                                                // if for some reason, someone's mapped an axis to a button target, handle that here
                                                AXIS_BUTTON_PRESSURE_THRESHOLD :: 0.9;
                                                success, code := sdl_target_to_gamepad_code(it.target);
                                                if success then update_button_state(gamepad, normalized_float_value > AXIS_BUTTON_PRESSURE_THRESHOLD, code);
                                        }
                                    }
                                }
                            }
                    }
                }
            }
        
            // Update hats after all hat value updates have been made
            for current_gamepad_mapping.mappings {
                if it.type == SDL_Input_Type.HAT {
                    hat := current_gamepad_evdev_mappings.hats[it.index];
                    success, code := sdl_target_to_gamepad_code(it.target);
                    if success then update_button_state(gamepad, (it.subindex & hat) != 0, code);
                }
            }
        
            // @Cutnpaste from the macOS stuff
            stick_translate :: (gamepad: *Gamepad, axis_value: float, threshold: float, button_low: Gamepad_Code, button_high: Gamepad_Code) {
                update_button_state(gamepad, axis_value < -threshold, button_low);
                update_button_state(gamepad, axis_value > +threshold, button_high);
            }
        
            // @YAE: added threshold logic
            stick_translate(gamepad, gamepad.left_stick.x,  gamepad.left_stick_threshold,  .LEFT_STICK_LEFT,  .LEFT_STICK_RIGHT);
            stick_translate(gamepad, gamepad.left_stick.y,  gamepad.left_stick_threshold,  .LEFT_STICK_DOWN,  .LEFT_STICK_UP);
            stick_translate(gamepad, gamepad.right_stick.x, gamepad.right_stick_threshold, .RIGHT_STICK_LEFT, .RIGHT_STICK_RIGHT);
            stick_translate(gamepad, gamepad.right_stick.y, gamepad.right_stick_threshold, .RIGHT_STICK_DOWN, .RIGHT_STICK_UP);
        }
    }
}


#if OS == .NN_SWITCH {
    // Code deleted for license reasons; we cannot distribute it.
    // See J Blow for the code.
    #load "../NintendoSDK/Gamepad.jai";
    
    
    Gamepad_OS :: struct {
        // ...
    }
    
    
    os_init_gamepad :: () {
        // ...
    }
    
    
    os_update_gamepad :: () {
        // ...
    }
}
