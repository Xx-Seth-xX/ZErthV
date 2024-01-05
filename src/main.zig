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
}

fn setUpCamera() ray.Camera3D {
    var camera = ray.Camera3D{};
    camera.position = Vector3(0.0, 0.0, -150.0);
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

const Astro = struct {
    const Self = @This();
    const rings = 40;
    const slices = 40;

    model: ray.Model,
    pos: ray.Vector3,
    color: ray.Color,

    fn init(r: f32, pos: ray.Vector3, color: ray.Color, textu_: ?ray.Texture) Self {
        var model = ray.LoadModelFromMesh(ray.GenMeshSphere(r, rings, slices));
        if (textu_) |textu| {
            model.materials[0].maps[ray.MATERIAL_MAP_DIFFUSE].texture = textu;
            model.transform = ray.MatrixRotateX(-ray.PI / 2);
        }
        return Self{
            .model = model,
            .pos = pos,
            .color = color,
        };
    }
    fn draw(self: Self) void {
        ray.DrawModel(self.model, self.pos, 1.0, self.color);
    }
};

pub fn main() !void {
    ray.InitWindow(screen_width, screen_height, window_title);
    defer ray.CloseWindow();
    ray.SetTargetFPS(60);

    var camera = setUpCamera();

    var earth = Astro.init(1.0, Vector3(50.0, 0.0, 0.0), ray.WHITE, try loadTexture("res/img/blue_marble.png"));
    var sun = Astro.init(10.0, Vector3(0.0, 0.0, 0.0), ray.YELLOW, null);

    while (!ray.WindowShouldClose()) {
        const dt = ray.GetFrameTime();
        updateCamera(&camera, dt);

        ray.BeginDrawing();
        ray.ClearBackground(ray.RAYWHITE);
        ray.BeginMode3D(camera);
        earth.draw();
        sun.draw();
        ray.EndMode3D();
        ray.EndDrawing();
    }
}
