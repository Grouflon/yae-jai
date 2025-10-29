CameraType :: enum
{
    ORTHOGRAPHIC;
    PERSPECTIVE;
}

Camera :: struct
{
    position: Vector3;
    rotation: Quaternion;
    type: CameraType;
    union {
        orthographic: struct
        {
            left: float;
            right: float;
            bottom: float;
            top: float;
            near: float;
            far: float;
        };
        perspective: struct
        {
            fov: float;
            aspect_ratio: float;
            near: float;
            far: float;
        };
    }
}

camera_to_vp_matrix :: (camera: Camera) -> Matrix4
{
    projection: Matrix4;
    if camera.type == .ORTHOGRAPHIC
    {
        projection = orthographic_projection_matrix(
            camera.orthographic.left,
            camera.orthographic.right,
            camera.orthographic.bottom,
            camera.orthographic.top,
            camera.orthographic.near,
            camera.orthographic.far
        );
    }
    else
    {
        projection = make_projection_matrix(
            camera.perspective.fov,
            camera.perspective.aspect_ratio,
            camera.perspective.near,
            camera.perspective.far
        );
    }
    view: = Matrix4_Identity;
    view = translate(view, camera.position);
    view = rotate(view, camera.rotation);
    _:, view = inverse(view);
    return projection * view;
}

#scope_file
#import "Math";
