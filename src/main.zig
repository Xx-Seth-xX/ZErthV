const std = @import("std");
const ray = @cImport({
    @cInclude("raylib.h");
    @cInclude("rcamera.h");
    @cInclude("raymath.h");
});

// Constants defintions
const screen_width = 800;
const screen_height = 800;
const window_title = "ZErthV";

fn Vector3(x: f32, y: f32, z: f32) ray.Vector3 {
    return ray.Vector3{ .x = x, .y = y, .z = z };
}

fn updateCamera(camera: *ray.Camera3D, dt: f32) void {
    const CameraSpeed = struct {
        var zoom: f32 = 0;
        var yaw: f32 = 0;
        var pitch: f32 = 0;
        const base_zoom: comptime_float = 10;
        const base_yaw: comptime_float = 0.04;
        const base_pitch: comptime_float = 0.04;
    };

    CameraSpeed.zoom *= 0.8;
    CameraSpeed.yaw *= 0.8;
    CameraSpeed.pitch *= 0.8;

    if (ray.IsKeyDown(ray.KEY_EQUAL)) {
        CameraSpeed.zoom = -CameraSpeed.base_zoom;
    } else if (ray.IsKeyDown(ray.KEY_MINUS)) {
        CameraSpeed.zoom = CameraSpeed.base_zoom;
    }
    if (ray.IsKeyDown(ray.KEY_W)) {
        CameraSpeed.pitch = -CameraSpeed.base_pitch;
    } else if (ray.IsKeyDown(ray.KEY_S)) {
        CameraSpeed.pitch = CameraSpeed.base_pitch;
    }
    if (ray.IsKeyDown(ray.KEY_A)) {
        CameraSpeed.yaw = -CameraSpeed.base_yaw;
    } else if (ray.IsKeyDown(ray.KEY_D)) {
        CameraSpeed.yaw = CameraSpeed.base_yaw;
    }

    ray.CameraMoveToTarget(camera, CameraSpeed.zoom * dt);
    ray.CameraYaw(camera, CameraSpeed.yaw, true);
    ray.CameraPitch(camera, CameraSpeed.pitch, true, true, false);
    // if (ray.isKeyDown(ray.KEY_D)) {

    // // Camera rotation
    // RLAPI void CameraYaw(Camera *camera, float angle, bool rotateAroundTarget);
    // RLAPI void CameraPitch(Camera *camera, float angle, bool lockView, bool rotateAroundTarget, bool rotateUp);
    // RLAPI void CameraRoll(Camera *camera, float angle);
    // } else if (ray.isKeyDown(ray,))
}

fn setUpCamera() ray.Camera3D {
    var camera = ray.Camera3D{};
    camera.position = Vector3(0.0, 0.0, -20.0);
    camera.target = Vector3(0.0, 0.0, 0.0);
    camera.up = Vector3(0.0, 1.0, 0.0);
    camera.fovy = 45.0;
    camera.projection = ray.CAMERA_PERSPECTIVE;
    return camera;
}
fn loadTexture(filename: [*c]const u8) !ray.Texture {
    const texture = ray.LoadTexture(filename);
    if (!ray.IsTextureReady(texture)) {
        return error.ErrorLoadingTexture;
    }
    return texture;
}
pub fn main() !void {
    ray.InitWindow(screen_width, screen_height, window_title);
    defer ray.CloseWindow();
    ray.SetTargetFPS(60);

    var camera = setUpCamera();
    // RLAPI Mesh GenMeshSphere(float radius, int rings, int slices);                              // Generate sphere mesh (standard sphere)
    var sphere_model = ray.LoadModelFromMesh(ray.GenMeshSphere(5.0, 40, 40));
    const sphere_texture = try loadTexture("res/img/land_ocean_ice_cloud_2048_90.png");
    sphere_model.materials[0].maps[ray.MATERIAL_MAP_DIFFUSE].texture = sphere_texture;
    sphere_model.transform = ray.MatrixRotateX(-ray.PI / 2);

    while (!ray.WindowShouldClose()) {
        const dt = ray.GetFrameTime();
        updateCamera(&camera, dt);

        // rotation = ray.QuaternionMultiply(rotation, ray.QuaternionFromAxisAngle(Vector3(1.0, 0.0, 0.0), dt));
        // sphere_model.transform = ray.QuaternionToMatrix(rotation);

        ray.BeginDrawing();
        ray.ClearBackground(ray.RAYWHITE);
        ray.BeginMode3D(camera);
        ray.DrawModel(sphere_model, ray.Vector3Zero(), 1.0, ray.WHITE);
        ray.EndMode3D();
        ray.EndDrawing();
    }
}
