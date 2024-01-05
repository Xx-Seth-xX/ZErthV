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

const km_per_au = 1 / 1.5e11;
const earth_r = 6_371.0;
const earth_r_au = earth_r * km_per_au;
const sun_r = 700_000.0;
const sun_r_au = sun_r * km_per_au;

fn Vector3(x: f32, y: f32, z: f32) ray.Vector3 {
    return ray.Vector3{ .x = x, .y = y, .z = z };
}

fn updateCamera(camera: *ray.Camera3D, dt: f32) void {
    const CameraSpeed = struct {
        var zoom: f32 = 0;
        var yaw: f32 = 0;
        var pitch: f32 = 0;
        const base_zoom: comptime_float = 10;
        const base_yaw: comptime_float = 0.02;
        const base_pitch: comptime_float = 0.02;
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
    camera.position = Vector3(-150.0, 0.0, 0.0);
    camera.target = Vector3(0.0, 0.0, 0.0);
    camera.up = Vector3(0.0, 0.0, 1.0);
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
    axis: ray.Vector3,

    fn init(r: f32, pos: ray.Vector3, axis: ray.Vector3, color: ray.Color, textu_: ?ray.Texture) Self {
        var model = ray.LoadModelFromMesh(ray.GenMeshSphere(r, rings, slices));
        // We calculate the rotation so the axis becomes the Z vector of the model
        const z_v = Vector3(0.0, 0.0, 1.0);
        const rot = ray.Vector3Normalize(ray.Vector3CrossProduct(z_v, axis));
        const rot_angle = std.math.acos(ray.Vector3DotProduct(axis, z_v));
        std.debug.print("rot_vector = {}, rot_angle = {}", .{ rot, rot_angle });
        model.transform = ray.MatrixRotate(rot, rot_angle);
        if (textu_) |textu| {
            model.materials[0].maps[ray.MATERIAL_MAP_DIFFUSE].texture = textu;
        }
        return Self{
            .model = model,
            .pos = pos,
            .color = color,
            .axis = axis,
        };
    }
    fn draw(self: Self) void {
        ray.DrawModel(self.model, self.pos, 1.0, self.color);
    }
    fn rotateByAxis(self: *Self, theta: f32) void {
        const rm = ray.MatrixRotate(self.*.axis, theta);
        self.*.model.transform = ray.MatrixMultiply(self.*.model.transform, rm);
    }
};

pub fn main() !void {
    ray.InitWindow(screen_width, screen_height, window_title);
    defer ray.CloseWindow();
    ray.SetTargetFPS(60);

    var camera = setUpCamera();

    const earth_axis = Vector3(0.0, std.math.sin(std.math.degreesToRadians(f32, 17.8)), std.math.cos(std.math.degreesToRadians(f32, 17.8)));
    var earth = Astro.init(1.0, Vector3(30.0, 0.0, 0.0), earth_axis, ray.WHITE, try loadTexture("res/img/blue_marble.png"));
    var sun = Astro.init(10.0, Vector3(0.0, 0.0, 0.0), Vector3(0.0, 0.0, 1.0), ray.RED, null);

    while (!ray.WindowShouldClose()) {
        const dt = ray.GetFrameTime();
        updateCamera(&camera, dt);

        earth.rotateByAxis(dt);
        ray.BeginDrawing();
        ray.ClearBackground(ray.RAYWHITE);
        ray.BeginMode3D(camera);
        earth.draw();
        sun.draw();
        ray.EndMode3D();
        ray.EndDrawing();
    }
}
