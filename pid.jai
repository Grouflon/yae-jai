PIDController :: struct($T: Type)
{
    p: float = 1.0;
    i: float = 1.0;
    d: float = 1.0;

    error: T;
    integral: T;
    derivative: T;
}

pid_controller_update :: (controller: *PIDController($T), current: T, target: T, dt: float) -> T
{
    assert(controller != null);

    // https://en.wikipedia.org/wiki/PID_controller#Pseudocode
    last_error: T = controller.error;
    controller.error = target - current;
    controller.integral = controller.integral + controller.error * dt;
    controller.derivative = (controller.error - last_error) / dt;

    return controller.p * controller.error + controller.i * controller.integral + controller.d * controller.derivative;
}

pid_controller_reset :: (controller: *PIDController($T))
{
    assert(controller != null);

    p: = controller.p;
    i: = controller.i;
    d: = controller.d;

    controller.* = .{};
    controller.p = p;
    controller.i = i;
    controller.d = d;
}