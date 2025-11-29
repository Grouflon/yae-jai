/*

Controller device support.

API
--------------------------------------------------------------
init_gamepad    :: () - Call at startup or anytime you want to refresh the connected gamepads.
update_gamepad  :: () - Call once a frame after update_window_events().

Example
--------------------------------------------------------------
~~~~~~~~~~~~~~~~~~~~~~~~~
#import "Gamepad"(DEBUG_PRINT=false);

WinCr :: #import "Window_Creation";
Input :: #import "Input";
Basic :: #import "Basic";

main :: () {
    window := WinCr.create_window(256, 256, "Gamepad");
    init_gamepad();

    {
        // You can ignore this, just setting up how to print floating point numbers.
        float_format := *context.print_style.default_format_float;
        float_format.trailing_width = 2;
        float_format.zero_removal = .NO;
        float_format.positive_number_prefix = .SPACE;
    }

    running := true;
    while running {
        Input.update_window_events();
        update_gamepad();
        Basic.print("\n- press SPACE to detect gamepads - press ESCAPE to exit -\n");
        
        for gamepad: gamepads {
        
            // Check if a gamepad is actually connected.
            if !gamepad.connected continue;

            Basic.print("% :", gamepad.idx, );
            Basic.print(" LTRIGGER % ", gamepad.left_trigger);
            Basic.print(" RTRIGGER % ", gamepad.right_trigger);
            Basic.print(" LSTICK % ", gamepad.left_stick);
            Basic.print(" RSTICK % ", gamepad.right_stick);

            // Each button can be queried for just-been-pressed, being-down, and just-been-released.
            // The interface for this is identical to keyboad input states.
            print_button :: (label: string, gamepad: Gamepad, code: Gamepad_Code) {
                Basic.print("%1 [%2%3%4] ", label,
                    ifx gamepad.buttons[code] & Input.Key_Current_State.START then "S" else " ", // just-been-pressed
                    ifx gamepad.buttons[code] & Input.Key_Current_State.DOWN  then "D" else " ", // being-down
                    ifx gamepad.buttons[code] & Input.Key_Current_State.END   then "E" else " "  // just-been-released
                );
            }

            print_button(" LS_CLICK", gamepad, Gamepad_Code.LEFT_STICK_CLICK);
            print_button(" RS_CLICK", gamepad, Gamepad_Code.RIGHT_STICK_CLICK);
            print_button(" LSHOULDER", gamepad, Gamepad_Code.LEFT_SHOULDER);
            print_button(" RSHOULDER", gamepad, Gamepad_Code.RIGHT_SHOULDER);
            
            Basic.print(" DPAD ( ");
            print_button("up",    gamepad, Gamepad_Code.DPAD_UP);
            print_button("down",  gamepad, Gamepad_Code.DPAD_DOWN);
            print_button("left",  gamepad, Gamepad_Code.DPAD_LEFT);
            print_button("right", gamepad, Gamepad_Code.DPAD_RIGHT);
            Basic.print(") ");

            print_button(" A", gamepad, Gamepad_Code.A);
            print_button(" B", gamepad, Gamepad_Code.B);
            print_button(" X", gamepad, Gamepad_Code.X);
            print_button(" Y", gamepad, Gamepad_Code.Y);

            print_button(" BACK", gamepad, Gamepad_Code.BACK);
            print_button(" START", gamepad, Gamepad_Code.START);

            Basic.print("\n");
        }

        // Since a controller can connect and disconnect at anytime,
        // it is a good idea to call init_gamepad() every once in a while.
        if Input.input_button_states[Input.Key_Code.SPACEBAR] & .START {
            Basic.print("\nDetecting gamepads...\n");
            init_gamepad();
        }
        else if Input.input_button_states[Input.Key_Code.ESCAPE] & .START {
            running = false;
        }
        else {
            Basic.sleep_milliseconds(100);
        }
    }
}
~~~~~~~~~~~~~~~~~~~~~~~~~
Notes
--------------------------------------------------------------
Mac OS X: The macOS implementation of this API uses Apple's official
[Game Controller](https://developer.apple.com/documentation/gamecontroller) framework.
Due to this, controller support may be limited to MFi-certified controllers. Additionally,
it seems that Game Controller only works properly under an AppKit loop, otherwise, while
this module may recognize a controller is attached, information on the controller's inputs
will not be updated. There is example code on setting up a Cocoa-style app in
[Objective_C/examples/cocoa.jai](#objective_c). Also, refer to the Snake example
for a more in-depth solution on setting up a multi-platform game with Gamepad supprt
on macOS.
*/

#load "Gamepad.jai";
