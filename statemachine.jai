StateMachine :: struct(State_Type: Type, Userdata_Type: Type)
{
    StateCallback :: #type (userdata: Userdata_Type);

    State :: struct
    {
        enter: StateCallback;
        exit: StateCallback;
        update: StateCallback;
    }

    STATE_COUNT :: #run enum_highest_value(State_Type) + 1;
    states: [STATE_COUNT]State;

    current_state: State_Type;
    userdata: Userdata_Type;
}

change_state :: (sm: *StateMachine, state: sm.State_Type)
{
    assert(sm != null);
    if sm.current_state == state { return; }

    previous_state: = sm.states[sm.current_state];
    next_state: = sm.states[state];

    if previous_state.exit != null
    {
        previous_state.exit(sm.userdata);
    }
    sm.current_state = state;
    if next_state.enter != null
    {
        next_state.enter(sm.userdata);
    }
}

#scope_file

#import "Basic";